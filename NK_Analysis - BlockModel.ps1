# ==============================================================================
# SCRIPT: Rowing Performance Analyzer
# VERSION: 4.9.3 (Individual Stroke Files + Bug Fixes)
# LAST UPDATED: 2026-01-21
# ==============================================================================

# Import configuration module
. "$PSScriptRoot\Config.ps1"

# 1. INITIALIZE CONFIGURATION
try {
    $config = New-RowingAnalyzerConfig
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    Write-Host "Config: $($config.GetConfigurationSummary())" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. SETUP PATHS USING CONFIGURATION
$ScriptVersion = $config.ScriptVersion
$inputDir = $config.InputDir
$outputDir = $config.OutputDir
$filePaths = $config.GetFilePaths()
$summaryCSV = $filePaths.SummaryCSV
$restCSV = $filePaths.RestCSV
$logFile = $filePaths.LogFile

# Extract configuration parameters for use in processing
$targetMinHR = $config.TargetMinHR
$targetMaxHR = $config.TargetMaxHR
$minWorkRate = $config.MinWorkRate
$maxWorkRate = $config.MaxWorkRate
$minBlockDist = $config.MinBlockDist
$targetDPSThreshold = $config.TargetDPSThreshold
$effFloor = $config.EffFloor
$effCeiling = $config.EffCeiling

# Ensure directories exist using configuration
$config.EnsureOutputDirectory()

# --- HELPER FUNCTIONS ---

function Get-EffRating ([double]$score) {
    if ($score -ge 8.5) { return "Elite" }
    if ($score -ge 6.5) { return "Strong" }
    if ($score -ge 4.5) { return "Good" }
    return "Developing"
}

function Get-EffScore ([double]$speed, [double]$hr) {
    if ($hr -eq 0) { return 0 }
    $rawEff = $speed / $hr
    $score = (($rawEff - $effFloor) / ($effCeiling - $effFloor)) * 10
    return [Math]::Max(0, [Math]::Min(10, $score))
}

function Convert-TimeToSeconds ([string]$timeStr) {
    if ($timeStr -eq "---" -or $timeStr -eq "") { return 0 }
    try {
        # Handle formats like "00:02:21.6" or "04:24.5"
        if ($timeStr -match "(\d+):(\d+):(\d+)\.(\d+)") {
            # HH:MM:SS.tenths format
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2] 
            $seconds = [int]$matches[3]
            $tenths = [int]$matches[4]
            return ($hours * 3600) + ($minutes * 60) + $seconds + ($tenths / 10)
        } elseif ($timeStr -match "(\d+):(\d+)\.(\d+)") {
            # MM:SS.tenths format
            $minutes = [int]$matches[1]
            $seconds = [int]$matches[2]
            $tenths = [int]$matches[3]
            return ($minutes * 60) + $seconds + ($tenths / 10)
        } else {
            return 0
        }
    } catch {
        return 0
    }
}

function Write-Log ([string]$message, [string]$color = "White") {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $message"
    Write-Host "[$timestamp] $message" -ForegroundColor $color
}

# --- 3. MAIN EXECUTION ---
Write-Log "--- STARTING ANALYSIS V$ScriptVersion (IMP ONLY) ---" -color Cyan

$masterSummaryList = [System.Collections.Generic.List[PSObject]]::new()
$restSummaryList   = [System.Collections.Generic.List[PSObject]]::new()
$files = Get-ChildItem -Path $inputDir -Filter "*.csv"

if ($files.Count -eq 0) { Write-Log "No files found in $inputDir" -color Red; return }

foreach ($file in $files) {
    Write-Log "Processing: $($file.Name)..."
    try {
        # Using UTF8 encoding specifically to bypass some iCloud reading bugs
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $rawLines = $content -split '\r?\n'
        
        # FIND THE PER-STROKE DATA SECTION FIRST
        $strokeSectionIdx = -1
        for ($i=0; $i -lt $rawLines.Count; $i++) {
            if ($rawLines[$i] -match "Per-Stroke Data:") { $strokeSectionIdx = $i; break }
        }
        
        if ($strokeSectionIdx -eq -1) {
            Write-Log "  Skip: No Per-Stroke Data section found in this file." -color Yellow
            continue
        }

        # FIND THE HEADER LINE after the Per-Stroke Data section (Looking specifically for IMP columns)
        $headerIdx = -1
        for ($i=$strokeSectionIdx; $i -lt $rawLines.Count; $i++) {
            if ($rawLines[$i] -match "Distance \(IMP\)") { $headerIdx = $i; break }
        }

        if ($headerIdx -eq -1) { 
            # DEBUG: Show what headers are actually available
            Write-Log "  DEBUG: No IMP data found. Checking first 15 lines for headers:" -color Yellow
            for ($j=0; $j -lt [Math]::Min(15, $rawLines.Count); $j++) {
                if ($rawLines[$j].Length -gt 10) {  # Only show non-empty lines
                    Write-Log "    Line $j`: $($rawLines[$j].Substring(0, [Math]::Min(100, $rawLines[$j].Length)))" -color Gray
                }
            }
            continue 
        }

        $data = $rawLines[$headerIdx..($rawLines.Count - 1)] | ConvertFrom-Csv | Where-Object { $_."Stroke Rate" -as [double] -gt 0 }
        Write-Log "  Found $($data.Count) total strokes." -color Gray
        
        # DEBUG: Show sample data and filtering criteria
        if ($data.Count -gt 0) {
            $sampleRow = $data[0]
            Write-Log "  DEBUG: Sample row - HR: $($sampleRow.'Heart Rate'), Rate: $($sampleRow.'Stroke Rate'), Dist: $($sampleRow.'Distance (IMP)')" -color Gray
            Write-Log "  DEBUG: Filtering for HR $targetMinHR-$targetMaxHR, Rate $minWorkRate-$maxWorkRate" -color Gray
        }

        $currentBlock = [System.Collections.Generic.List[PSObject]]::new()
        $currentRest  = [System.Collections.Generic.List[PSObject]]::new()
        $strokeDetailList = [System.Collections.Generic.List[PSObject]]::new()
        $blockNumber = 1

        foreach ($row in $data) {
            # Handle missing values (convert "---" to 0)
            $hrStr = $row."Heart Rate"
            $hr = if ($hrStr -eq "---" -or $hrStr -eq "") { 0 } else { [double]$hrStr }
            
            $rate = [double]$row."Stroke Rate"
            $dist = [double]$row."Distance (IMP)"
            
            # WORK FILTER: HR, Rate, and must have IMP distance
            $isWork = ($hr -ge $targetMinHR -and $hr -le $targetMaxHR -and $rate -ge $minWorkRate -and $rate -le $maxWorkRate -and $dist -gt 0)
            
            # DEBUG: Show first few work/non-work decisions
            if ($currentBlock.Count + $currentRest.Count -lt 5) {
                Write-Log "    Row: HR=$hr, Rate=$rate, Dist=$dist, IsWork=$isWork" -color DarkGray
            }
            
            if ($isWork) {
                # Handle Rest Transition
                if ($currentRest.Count -gt 5) {
                    $hrStartStr = $currentRest[0]."Heart Rate"
                    $hrEndStr = $currentRest[-1]."Heart Rate"
                    $hrStart = if ($hrStartStr -eq "---" -or $hrStartStr -eq "") { 0 } else { [double]$hrStartStr }
                    $hrEnd = if ($hrEndStr -eq "---" -or $hrEndStr -eq "") { 0 } else { [double]$hrEndStr }
                    
                    $dur = Convert-TimeToSeconds $currentRest[-1]."Elapsed Time" - Convert-TimeToSeconds $currentRest[0]."Elapsed Time"
                    if ($dur -gt 30 -and $hrStart -gt 0 -and $hrEnd -gt 0) {
                        $restSummaryList.Add([PSCustomObject]@{
                            Date = $file.BaseName; StartHR = $hrStart; EndHR = $hrEnd; HR_Drop = ($hrStart - $hrEnd); Recovery_Rate = [Math]::Round(($hrStart - $hrEnd) / ($dur / 60), 1)
                        })
                    }
                }
                $currentRest.Clear()
                $currentBlock.Add($row)
            } else {
                # Handle Work Transition
                if ($currentBlock.Count -gt 10) {
                    $totalDist = if ($currentBlock[-1]."Distance (IMP)" -eq "---" -or $currentBlock[0]."Distance (IMP)" -eq "---") { 
                        0 
                    } else { 
                        [double]$currentBlock[-1]."Distance (IMP)" - [double]$currentBlock[0]."Distance (IMP)" 
                    }
                    if ($totalDist -ge $minBlockDist) {
                        # Capture individual stroke details for this block
                        $strokeNumber = 1
                        foreach ($stroke in $currentBlock) {
                            $strokeDetailList.Add([PSCustomObject]@{
                                Date = $file.BaseName
                                BlockNumber = $blockNumber
                                StrokeNumber = $strokeNumber
                                ElapsedTime = $stroke."Elapsed Time"
                                HeartRate = if ($stroke."Heart Rate" -eq "---") { "" } else { $stroke."Heart Rate" }
                                StrokeRate = $stroke."Stroke Rate"
                                Speed_IMP = if ($stroke."Speed (IMP)" -eq "---") { "" } else { $stroke."Speed (IMP)" }
                                Distance_IMP = $stroke."Distance (IMP)"
                                DPS_IMP = if ($stroke."Distance/Stroke (IMP)" -eq "---") { "" } else { $stroke."Distance/Stroke (IMP)" }
                                Power = if ($stroke."Power" -eq "---") { "" } else { $stroke."Power" }
                                AtTarget = if ([double]$stroke."Distance/Stroke (IMP)" -ge $targetDPSThreshold) { "Yes" } else { "No" }
                            })
                            $strokeNumber++
                        }
                        
                        $dpsValues = $currentBlock | ForEach-Object { 
                            $dpsStr = $_."Distance/Stroke (IMP)"
                            if ($dpsStr -eq "---" -or $dpsStr -eq "") { 0 } else { [double]$dpsStr }
                        }
                        $avgSpeed  = ($currentBlock | ForEach-Object { 
                            $speedStr = $_."Speed (IMP)"
                            if ($speedStr -eq "---" -or $speedStr -eq "") { $null } else { [double]$speedStr }
                        } | Where-Object { $_ -ne $null } | Measure-Object -Average).Average
                        $avgHR     = ($currentBlock | ForEach-Object { 
                            $hrStr = $_."Heart Rate"
                            if ($hrStr -eq "---" -or $hrStr -eq "") { $null } else { [double]$hrStr }
                        } | Where-Object { $_ -ne $null } | Measure-Object -Average).Average
                        $avgRate   = ($currentBlock | ForEach-Object { 
                            $rateStr = $_."Stroke Rate"
                            if ($rateStr -eq "---" -or $rateStr -eq "") { $null } else { [double]$rateStr }
                        } | Where-Object { $_ -ne $null } | Measure-Object -Average).Average
                        $effScore  = Get-EffScore $avgSpeed $avgHR
                        $targetCount = ($dpsValues | Where-Object { $_ -ge $targetDPSThreshold }).Count

                        $masterSummaryList.Add([PSCustomObject]@{
                            Date = $file.BaseName; Sensor = "IMP"; BlockNumber = $blockNumber; AvgDPS = [Math]::Round(($dpsValues | Measure-Object -Average).Average, 2)
                            StrokesAtTarget = $targetCount; SuccessRate = "$([Math]::Round(($targetCount/$currentBlock.Count)*100, 1))%"
                            EffScore = [Math]::Round($effScore, 1); Rating = Get-EffRating $effScore; AvgHR = [Math]::Round($avgHR, 0)
                            AvgRate = [Math]::Round($avgRate, 1); Dist_m = [Math]::Round($totalDist, 0); Strokes = $currentBlock.Count
                        })
                        
                        $blockNumber++
                    }
                }
                $currentBlock.Clear()
                $currentRest.Add($row)
            }
        }
        
        # Export individual stroke details for this file
        if ($strokeDetailList.Count -gt 0) {
            $strokeFileName = "$($file.BaseName)_Stroke_Details.csv"
            $strokeCSV = Join-Path $outputDir $strokeFileName
            $strokeHeaders = @("# INDIVIDUAL STROKE DETAILS v$ScriptVersion", "# File: $($file.Name)", "# Each row represents one stroke within a work block", "")
            $strokeHeaders + ($strokeDetailList | Sort-Object BlockNumber, StrokeNumber | ConvertTo-Csv -NoTypeInformation) | Out-File $strokeCSV -Force -Encoding utf8
            Write-Log "  Created stroke details: $strokeFileName" -color Green
        }
        
    } catch { 
        Write-Log "  ERROR processing $($file.Name): $($_.Exception.Message)" -color Red 
        Write-Log "  ERROR details: $($_.Exception.GetType().Name)" -color Red
    }
}

# --- 4. EXPORT AND UNIT TESTS ---
if ($masterSummaryList.Count -gt 0) {
    # Headers using configuration summary
    $configSummary = $config.GetConfigurationSummary()
    $headers = @("# ROWING SUMMARY v$ScriptVersion", "# Config: $configSummary", "")
    $headers + ($masterSummaryList | Sort-Object Date -Descending | ConvertTo-Csv -NoTypeInformation) | Out-File $summaryCSV -Force -Encoding utf8
    $restSummaryList | Export-Csv $restCSV -NoTypeInformation -Force

    Write-Log "Validation: Checking results..." -color Gray
    if (Test-Path $summaryCSV) { Write-Log "  [PASS] Work Summary created." -color Green }
    if (Test-Path $restCSV) { Write-Log "  [PASS] Rest Summary created." -color Green }

    Invoke-Item $outputDir
} else {
    Write-Log "FAILED: No data matched your work criteria. Check HR/Rate limits." -color Red
}