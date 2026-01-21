# CSV Generator for Property-Based Testing
# Generates valid Speed Coach CSV files with randomized data patterns

function New-RandomCSVFile {
    param(
        [int]$StrokeCount = (Get-Random -Minimum 50 -Maximum 500),
        [double]$WorkPercentage = (Get-Random -Minimum 0.3 -Maximum 0.8),
        [string]$SessionName = "TestSession_$(Get-Random)",
        [switch]$IncludeMissingValues,
        [switch]$IncludeInvalidData
    )
    
    # Generate session metadata
    $sessionDate = Get-Date -Format "yyyy-MM-dd"
    $sessionTime = Get-Date -Format "HH:mm:ss"
    
    # CSV Header sections (mimicking Speed Coach format)
    $csvContent = @()
    $csvContent += "Speed Coach GPS 2"
    $csvContent += "Session: $SessionName"
    $csvContent += "Date: $sessionDate"
    $csvContent += "Time: $sessionTime"
    $csvContent += ""
    $csvContent += "Per-Stroke Data:"
    $csvContent += ""
    
    # Column headers (IMP sensor data)
    $headers = "Elapsed Time,Distance (IMP),Speed (IMP),Stroke Rate,Distance/Stroke (IMP),Heart Rate,Power"
    $csvContent += $headers
    
    # Generate stroke data
    $currentDistance = 0.0
    $currentTime = 0.0
    
    for ($i = 1; $i -le $StrokeCount; $i++) {
        # Determine if this stroke should be "work" based on WorkPercentage
        $isWorkStroke = (Get-Random) -lt $WorkPercentage
        
        # Generate realistic values based on work/rest state
        if ($isWorkStroke) {
            $heartRate = Get-Random -Minimum 120 -Maximum 145
            $strokeRate = Get-Random -Minimum 15 -Maximum 26
            $speed = Get-Random -Minimum 3.5 -Maximum 5.2
            $dps = Get-Random -Minimum 9.0 -Maximum 12.0
            $power = Get-Random -Minimum 200 -Maximum 350
        } else {
            $heartRate = Get-Random -Minimum 90 -Maximum 130
            $strokeRate = Get-Random -Minimum 10 -Maximum 18
            $speed = Get-Random -Minimum 2.0 -Maximum 4.0
            $dps = Get-Random -Minimum 7.0 -Maximum 10.0
            $power = Get-Random -Minimum 100 -Maximum 220
        }
        
        # Update cumulative values
        $strokeDistance = $dps
        $currentDistance += $strokeDistance
        $strokeTime = $strokeDistance / $speed
        $currentTime += $strokeTime
        
        # Format elapsed time as MM:SS.t
        $minutes = [Math]::Floor($currentTime / 60)
        $seconds = [Math]::Round($currentTime % 60, 1)
        $elapsedTimeStr = $minutes.ToString("00") + ":" + $seconds.ToString("00.0")
        
        # Handle missing values if requested
        $heartRateStr = if ($IncludeMissingValues -and (Get-Random) -lt 0.1) { "---" } else { [Math]::Round($heartRate, 0) }
        $speedStr = if ($IncludeMissingValues -and (Get-Random) -lt 0.05) { "---" } else { [Math]::Round($speed, 1) }
        $dpsStr = if ($IncludeMissingValues -and (Get-Random) -lt 0.05) { "---" } else { [Math]::Round($dps, 1) }
        $powerStr = if ($IncludeMissingValues -and (Get-Random) -lt 0.15) { "---" } else { [Math]::Round($power, 0) }
        
        # Handle invalid data if requested
        if ($IncludeInvalidData -and (Get-Random) -lt 0.02) {
            $heartRateStr = "INVALID"
            $speedStr = "ERROR"
        }
        
        # Create CSV row
        $row = "$elapsedTimeStr,$([Math]::Round($currentDistance, 1)),$speedStr,$([Math]::Round($strokeRate, 1)),$dpsStr,$heartRateStr,$powerStr"
        $csvContent += $row
    }
    
    return $csvContent -join "`n"
}

function New-RandomStrokeData {
    param(
        [int]$Count = (Get-Random -Minimum 10 -Maximum 100),
        [string]$Pattern = "Mixed" # "Work", "Rest", "Mixed"
    )
    
    $strokes = @()
    
    for ($i = 1; $i -le $Count; $i++) {
        switch ($Pattern) {
            "Work" {
                $hr = Get-Random -Minimum 124 -Maximum 138
                $rate = Get-Random -Minimum 16 -Maximum 24
                $speed = Get-Random -Minimum 4.0 -Maximum 5.5
            }
            "Rest" {
                $hr = Get-Random -Minimum 90 -Maximum 120
                $rate = Get-Random -Minimum 10 -Maximum 16
                $speed = Get-Random -Minimum 2.0 -Maximum 3.5
            }
            default { # Mixed
                if ((Get-Random) -lt 0.6) {
                    # Work stroke
                    $hr = Get-Random -Minimum 124 -Maximum 138
                    $rate = Get-Random -Minimum 16 -Maximum 24
                    $speed = Get-Random -Minimum 4.0 -Maximum 5.5
                } else {
                    # Rest stroke
                    $hr = Get-Random -Minimum 90 -Maximum 120
                    $rate = Get-Random -Minimum 10 -Maximum 16
                    $speed = Get-Random -Minimum 2.0 -Maximum 3.5
                }
            }
        }
        
        $dps = Get-Random -Minimum 8.0 -Maximum 12.0
        $distance = $i * $dps # Cumulative distance
        $power = Get-Random -Minimum 150 -Maximum 300
        
        $strokes += [PSCustomObject]@{
            "Elapsed Time" = "00:{0:D2}:{1:F1}" -f ([Math]::Floor($i * 3 / 60)), (($i * 3) % 60)
            "Distance (IMP)" = [Math]::Round($distance, 1)
            "Speed (IMP)" = [Math]::Round($speed, 1)
            "Stroke Rate" = [Math]::Round($rate, 1)
            "Distance/Stroke (IMP)" = [Math]::Round($dps, 1)
            "Heart Rate" = [Math]::Round($hr, 0)
            "Power" = [Math]::Round($power, 0)
        }
    }
    
    return $strokes
}

function New-WorkRestPattern {
    param(
        [int]$WorkBlocks = (Get-Random -Minimum 2 -Maximum 8),
        [int]$MinWorkStrokes = 15,
        [int]$MaxWorkStrokes = 50,
        [int]$MinRestStrokes = 5,
        [int]$MaxRestStrokes = 20
    )
    
    $pattern = @()
    
    for ($block = 1; $block -le $WorkBlocks; $block++) {
        # Add work block
        $workStrokes = Get-Random -Minimum $MinWorkStrokes -Maximum $MaxWorkStrokes
        $workData = New-RandomStrokeData -Count $workStrokes -Pattern "Work"
        $pattern += $workData
        
        # Add rest block (except after last work block)
        if ($block -lt $WorkBlocks) {
            $restStrokes = Get-Random -Minimum $MinRestStrokes -Maximum $MaxRestStrokes
            $restData = New-RandomStrokeData -Count $restStrokes -Pattern "Rest"
            $pattern += $restData
        }
    }
    
    # Update cumulative distances and times
    $cumulativeDistance = 0
    $cumulativeTime = 0
    
    foreach ($stroke in $pattern) {
        $dps = [double]$stroke."Distance/Stroke (IMP)"
        $speed = [double]$stroke."Speed (IMP)"
        
        $cumulativeDistance += $dps
        $strokeTime = $dps / $speed
        $cumulativeTime += $strokeTime
        
        $stroke."Distance (IMP)" = [Math]::Round($cumulativeDistance, 1)
        
        $minutes = [Math]::Floor($cumulativeTime / 60)
        $seconds = $cumulativeTime % 60
        $stroke."Elapsed Time" = "{0:D2}:{1:F1}" -f $minutes, $seconds
    }
    
    return $pattern
}

# Functions are available when dot-sourced