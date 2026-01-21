# Stroke Data Generator for Property-Based Testing
# Generates individual stroke records with realistic rowing data

function New-RandomStroke {
    param(
        [string]$Type = "Random", # "Work", "Rest", "Random", "Invalid"
        [double]$ElapsedTime = (Get-Random -Minimum 0 -Maximum 3600),
        [double]$CumulativeDistance = $null
    )
    
    switch ($Type) {
        "Work" {
            $heartRate = Get-Random -Minimum 124 -Maximum 138
            $strokeRate = Get-Random -Minimum 16 -Maximum 24
            $speed = Get-Random -Minimum 4.0 -Maximum 5.5
            $dps = Get-Random -Minimum 9.5 -Maximum 12.0
            $power = Get-Random -Minimum 220 -Maximum 350
        }
        "Rest" {
            $heartRate = Get-Random -Minimum 85 -Maximum 120
            $strokeRate = Get-Random -Minimum 8 -Maximum 16
            $speed = Get-Random -Minimum 1.5 -Maximum 3.5
            $dps = Get-Random -Minimum 6.0 -Maximum 9.0
            $power = Get-Random -Minimum 80 -Maximum 200
        }
        "Invalid" {
            # Generate invalid data for edge case testing
            $heartRate = if ((Get-Random) -lt 0.5) { -1 } else { 250 }
            $strokeRate = if ((Get-Random) -lt 0.5) { -5 } else { 50 }
            $speed = if ((Get-Random) -lt 0.5) { -2.0 } else { 15.0 }
            $dps = if ((Get-Random) -lt 0.5) { -1.0 } else { 25.0 }
            $power = if ((Get-Random) -lt 0.5) { -50 } else { 1000 }
        }
        default { # Random
            $heartRate = Get-Random -Minimum 60 -Maximum 180
            $strokeRate = Get-Random -Minimum 8 -Maximum 35
            $speed = Get-Random -Minimum 1.0 -Maximum 6.0
            $dps = Get-Random -Minimum 5.0 -Maximum 15.0
            $power = Get-Random -Minimum 50 -Maximum 400
        }
    }
    
    # Calculate cumulative distance if not provided
    if ($null -eq $CumulativeDistance) {
        $CumulativeDistance = $dps * (Get-Random -Minimum 1 -Maximum 100)
    }
    
    # Format elapsed time
    $minutes = [Math]::Floor($ElapsedTime / 60)
    $seconds = $ElapsedTime % 60
    $elapsedTimeStr = "{0:D2}:{1:F1}" -f $minutes, $seconds
    
    # Handle missing values randomly
    $missingValueChance = 0.05
    $heartRateStr = if ((Get-Random) -lt $missingValueChance) { "---" } else { [Math]::Round($heartRate, 0) }
    $speedStr = if ((Get-Random) -lt $missingValueChance) { "---" } else { [Math]::Round($speed, 1) }
    $dpsStr = if ((Get-Random) -lt $missingValueChance) { "---" } else { [Math]::Round($dps, 1) }
    $powerStr = if ((Get-Random) -lt $missingValueChance) { "---" } else { [Math]::Round($power, 0) }
    
    return [PSCustomObject]@{
        "Elapsed Time" = $elapsedTimeStr
        "Distance (IMP)" = [Math]::Round($CumulativeDistance, 1)
        "Speed (IMP)" = $speedStr
        "Stroke Rate" = [Math]::Round($strokeRate, 1)
        "Distance/Stroke (IMP)" = $dpsStr
        "Heart Rate" = $heartRateStr
        "Power" = $powerStr
    }
}

function New-StrokeSequence {
    param(
        [int]$Count = (Get-Random -Minimum 10 -Maximum 200),
        [string[]]$Pattern = @("Work", "Rest"), # Array of stroke types to cycle through
        [int]$BlockSize = (Get-Random -Minimum 5 -Maximum 25) # Strokes per pattern block
    )
    
    $strokes = @()
    $cumulativeDistance = 0.0
    $cumulativeTime = 0.0
    $patternIndex = 0
    
    for ($i = 1; $i -le $Count; $i++) {
        # Determine current pattern type
        $currentPattern = $Pattern[$patternIndex]
        
        # Switch pattern every BlockSize strokes
        if ($i % $BlockSize -eq 0) {
            $patternIndex = ($patternIndex + 1) % $Pattern.Length
        }
        
        # Generate stroke
        $stroke = New-RandomStroke -Type $currentPattern -ElapsedTime $cumulativeTime -CumulativeDistance $cumulativeDistance
        
        # Update cumulative values
        $dpsValue = if ($stroke."Distance/Stroke (IMP)" -eq "---") { 
            8.0 # Default value for missing DPS
        } else { 
            [double]$stroke."Distance/Stroke (IMP)" 
        }
        
        $speedValue = if ($stroke."Speed (IMP)" -eq "---") { 
            3.0 # Default value for missing speed
        } else { 
            [double]$stroke."Speed (IMP)" 
        }
        
        $cumulativeDistance += $dpsValue
        $strokeTime = if ($speedValue -gt 0) { $dpsValue / $speedValue } else { 2.0 }
        $cumulativeTime += $strokeTime
        
        # Update stroke with correct cumulative distance and time
        $stroke."Distance (IMP)" = [Math]::Round($cumulativeDistance, 1)
        
        $minutes = [Math]::Floor($cumulativeTime / 60)
        $seconds = $cumulativeTime % 60
        $stroke."Elapsed Time" = "{0:D2}:{1:F1}" -f $minutes, $seconds
        
        $strokes += $stroke
    }
    
    return $strokes
}

function New-EdgeCaseStroke {
    param([string]$EdgeCase)
    
    switch ($EdgeCase) {
        "AllMissing" {
            return [PSCustomObject]@{
                "Elapsed Time" = "---"
                "Distance (IMP)" = "---"
                "Speed (IMP)" = "---"
                "Stroke Rate" = "---"
                "Distance/Stroke (IMP)" = "---"
                "Heart Rate" = "---"
                "Power" = "---"
            }
        }
        "ZeroValues" {
            return [PSCustomObject]@{
                "Elapsed Time" = "00:00:00.0"
                "Distance (IMP)" = "0.0"
                "Speed (IMP)" = "0.0"
                "Stroke Rate" = "0.0"
                "Distance/Stroke (IMP)" = "0.0"
                "Heart Rate" = "0"
                "Power" = "0"
            }
        }
        "ExtremeValues" {
            return [PSCustomObject]@{
                "Elapsed Time" = "99:59:59.9"
                "Distance (IMP)" = "99999.9"
                "Speed (IMP)" = "99.9"
                "Stroke Rate" = "99.9"
                "Distance/Stroke (IMP)" = "99.9"
                "Heart Rate" = "999"
                "Power" = "9999"
            }
        }
        "MixedValidInvalid" {
            return [PSCustomObject]@{
                "Elapsed Time" = "00:05:30.5"
                "Distance (IMP)" = "1250.5"
                "Speed (IMP)" = "---"
                "Stroke Rate" = "20.5"
                "Distance/Stroke (IMP)" = "10.8"
                "Heart Rate" = "---"
                "Power" = "245"
            }
        }
        default {
            return New-RandomStroke -Type "Random"
        }
    }
}

function New-RealisticRowingSession {
    param(
        [int]$WarmupStrokes = (Get-Random -Minimum 20 -Maximum 50),
        [int]$WorkBlocks = (Get-Random -Minimum 3 -Maximum 8),
        [int]$StrokesPerBlock = (Get-Random -Minimum 20 -Maximum 60),
        [int]$RestBetweenBlocks = (Get-Random -Minimum 10 -Maximum 30),
        [int]$CooldownStrokes = (Get-Random -Minimum 15 -Maximum 40)
    )
    
    $session = @()
    $cumulativeDistance = 0.0
    $cumulativeTime = 0.0
    
    # Helper function to add strokes and update cumulative values
    function Add-StrokesToSession {
        param($StrokeArray, $SessionArray, [ref]$CumDistance, [ref]$CumTime)
        
        foreach ($stroke in $StrokeArray) {
            $dpsValue = if ($stroke."Distance/Stroke (IMP)" -eq "---") { 8.0 } else { [double]$stroke."Distance/Stroke (IMP)" }
            $speedValue = if ($stroke."Speed (IMP)" -eq "---") { 3.0 } else { [double]$stroke."Speed (IMP)" }
            
            $CumDistance.Value += $dpsValue
            $strokeTime = if ($speedValue -gt 0) { $dpsValue / $speedValue } else { 2.0 }
            $CumTime.Value += $strokeTime
            
            $stroke."Distance (IMP)" = [Math]::Round($CumDistance.Value, 1)
            $minutes = [Math]::Floor($CumTime.Value / 60)
            $seconds = $CumTime.Value % 60
            $stroke."Elapsed Time" = "{0:D2}:{1:F1}" -f $minutes, $seconds
            
            $SessionArray += $stroke
        }
        return $SessionArray
    }
    
    # Warmup
    $warmupStrokes = New-StrokeSequence -Count $WarmupStrokes -Pattern @("Rest") -BlockSize $WarmupStrokes
    $session = Add-StrokesToSession -StrokeArray $warmupStrokes -SessionArray $session -CumDistance ([ref]$cumulativeDistance) -CumTime ([ref]$cumulativeTime)
    
    # Work blocks with rest periods
    for ($block = 1; $block -le $WorkBlocks; $block++) {
        # Work block
        $workStrokes = New-StrokeSequence -Count $StrokesPerBlock -Pattern @("Work") -BlockSize $StrokesPerBlock
        $session = Add-StrokesToSession -StrokeArray $workStrokes -SessionArray $session -CumDistance ([ref]$cumulativeDistance) -CumTime ([ref]$cumulativeTime)
        
        # Rest period (except after last block)
        if ($block -lt $WorkBlocks) {
            $restStrokes = New-StrokeSequence -Count $RestBetweenBlocks -Pattern @("Rest") -BlockSize $RestBetweenBlocks
            $session = Add-StrokesToSession -StrokeArray $restStrokes -SessionArray $session -CumDistance ([ref]$cumulativeDistance) -CumTime ([ref]$cumulativeTime)
        }
    }
    
    # Cooldown
    $cooldownStrokes = New-StrokeSequence -Count $CooldownStrokes -Pattern @("Rest") -BlockSize $CooldownStrokes
    $session = Add-StrokesToSession -StrokeArray $cooldownStrokes -SessionArray $session -CumDistance ([ref]$cumulativeDistance) -CumTime ([ref]$cumulativeTime)
    
    return $session
}

# Functions are available when dot-sourced