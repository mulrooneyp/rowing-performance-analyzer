# ==============================================================================
# SCRIPT: Rowing Performance Analyzer
# VERSION: 4.9.2 (Strict IMP Filter + Recovery + Integrity Tests)
# LAST UPDATED: 2026-01-14
# ==============================================================================

# 1. SETUP PATHS
$inputDir      = "C:\Users\patrickm\iCloudDrive\Speed coach\exported-sessions"
$outputDir     = "C:\Users\patrickm\iCloudDrive\Speed coach\AnalysedData\BlockAnalysis"
$summaryCSV    = Join-Path $outputDir "Block_Work_Summary.csv"
$restCSV       = Join-Path $outputDir "Rest_Recovery_Summary.csv"
$logFile       = Join-Path $outputDir "Log.txt"

# 2. CONFIGURATION PARAMETERS
$targetMinHR, $targetMaxHR = 124, 138
$minWorkRate, $maxWorkRate = 16, 24
$minBlockDist = 500  
$targetDPSThreshold = 10.5  
$effFloor, $effCeiling = 0.020, 0.035

# Ensure directories exist
if (!(Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

# --- HELPER FUNCTIONS ---

function Get-EffRating ([double]$score) {
    if ($score -ge 8.5) { return "Elite" }
    if ($score -ge 6.5) { return "Strong" }
    if ($score -ge 4.5) { return "Good" }
    return "Developing"
}

function Calculate-EffScore ([double]$speed, [double]$hr) {
    if ($hr -eq 0) { return 0 }
    $rawEff = $speed / $hr
    $score = (($rawEff - $effFloor) / ($effCeiling - $effFloor)) * 10
    return [Math]::Max(0, [Math]::Min(10, $score))
}

function Write-Log ([string]$message, [string]$color = "White") {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $message"
    Write-Host "[$timestamp] $message" -ForegroundColor $color
}

# --- 3. MAIN EXECUTION ---
Write-Log "--- STARTING ANALYSIS V4.9.2 (IMP ONLY) ---" -color Cyan

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
        
        # FIND THE HEADER LINE (Looking specifically for IMP columns)
        $headerIdx = -1
        for ($i=0; $i -lt $rawLines.Count; $i++) {
            if ($rawLines[$i] -match "Distance \(IMP\)") { $headerIdx = $i; break }
        }

        if ($headerIdx -eq -1) { 
            Write-Log "  Skip: No Impeller (IMP) data found in this file." -color Yellow
            continue 
        }

        $data = $rawLines[$headerIdx..($rawLines.Count - 1)] | ConvertFrom-Csv | Where-Object { $_."Stroke Rate" -as [double] -gt 0 }
        Write-Log "  Found $($data.Count) total strokes." -color Gray

        $currentBlock = [System.Collections.Generic.List[PSObject]]::new()
        $currentRest  = [System.Collections.Generic.List[PSObject]]::new()

        foreach ($row in $data) {
            $hr   = [double]$row."Heart Rate"
            $rate = [double]$row."Stroke Rate"
            $dist = [double]$row."Distance (IMP)"
            
            # WORK FILTER: HR, Rate, and must have IMP distance
            $isWork = ($hr -ge $targetMinHR -and $hr -le $targetMaxHR -and $rate -ge $minWorkRate -and $rate -le $maxWorkRate -and $dist -gt 0)
            
            if ($isWork) {
                # Handle Rest Transition
                if ($currentRest.Count -gt 5) {
                    $hrStart, $hrEnd = [double]$currentRest[0]."Heart Rate", [double]$currentRest[-1]."Heart Rate"
                    $dur = [double]$currentRest[-1]."Elapsed Time" - [double]$currentRest[0]."Elapsed Time"
                    if ($dur -gt 30) {
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
                    $totalDist = [double]$currentBlock[-1]."Distance (IMP)" - [double]$currentBlock[0]."Distance (IMP)"
                    if ($totalDist -ge $minBlockDist) {
                        $dpsValues = $currentBlock | ForEach-Object { [double]$_."Distance/Stroke (IMP)" }
                        $avgSpeed  = ($currentBlock | ForEach-Object { [double]$_."Speed (IMP)" } | Measure-Object -Avg).Average
                        $avgHR     = ([double[]]$currentBlock."Heart Rate" | Measure-Object -Avg).Average
                        $effScore  = Calculate-EffScore $avgSpeed $avgHR
                        $targetCount = ($dpsValues | Where-Object { $_ -ge $targetDPSThreshold }).Count

                        $masterSummaryList.Add([PSCustomObject]@{
                            Date = $file.BaseName; Sensor = "IMP"; AvgDPS = [Math]::Round(($dpsValues | Measure-Object -Avg).Average, 2)
                            StrokesAtTarget = $targetCount; SuccessRate = "$([Math]::Round(($targetCount/$currentBlock.Count)*100, 1))%"
                            EffScore = [Math]::Round($effScore, 1); Rating = Get-EffRating $effScore; AvgHR = [Math]::Round($avgHR, 0)
                            Dist_m = [Math]::Round($totalDist, 0); Strokes = $currentBlock.Count
                        })
                    }
                }
                $currentBlock.Clear()
                $currentRest.Add($row)
            }
        }
    } catch { Write-Log "  ERROR: $($_.Exception.Message)" -color Red }
}

# --- 4. EXPORT AND UNIT TESTS ---
if ($masterSummaryList.Count -gt 0) {
    # Headers
    $headers = @("# ROWING SUMMARY v$ScriptVersion", "# Config: HR $targetMinHR-$targetMaxHR | DPS Target $targetDPSThreshold", "")
    $headers + ($masterSummaryList | Sort-Object Date -Descending | ConvertTo-Csv -NoTypeInformation) | Out-File $summaryCSV -Force -Encoding utf8
    $restSummaryList | Export-Csv $restCSV -NoTypeInformation -Force

    Write-Log "Validation: Checking results..." -color Gray
    if (Test-Path $summaryCSV) { Write-Log "  [PASS] Work Summary created." -color Green }
    if (Test-Path $restCSV) { Write-Log "  [PASS] Rest Summary created." -color Green }

    Invoke-Item $outputDir
} else {
    Write-Log "FAILED: No data matched your work criteria. Check HR/Rate limits." -color Red
}