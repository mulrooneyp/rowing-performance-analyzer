# Work/Rest Pattern Generator for Property-Based Testing
# Generates various work and rest patterns for testing classification logic

function New-WorkRestPattern {
    param(
        [int]$TotalStrokes = (Get-Random -Minimum 100 -Maximum 500),
        [double]$WorkRatio = (Get-Random -Minimum 0.3 -Maximum 0.7),
        [int]$MinBlockSize = 5,
        [int]$MaxBlockSize = 50,
        [switch]$IncludeBoundaryValues,
        [switch]$IncludeEdgeCases
    )
    
    $pattern = @()
    $remainingStrokes = $TotalStrokes
    $isWorkPhase = $true
    
    while ($remainingStrokes -gt 0) {
        # Determine block size
        $blockSize = Get-Random -Minimum $MinBlockSize -Maximum ([Math]::Min($MaxBlockSize, $remainingStrokes))
        
        # Adjust for work ratio
        if ($isWorkPhase) {
            $targetWorkStrokes = [Math]::Floor($TotalStrokes * $WorkRatio)
            $currentWorkStrokes = ($pattern | Where-Object { $_.IsWork -eq $true }).Count
            if ($currentWorkStrokes + $blockSize -gt $targetWorkStrokes) {
                $blockSize = [Math]::Max(1, $targetWorkStrokes - $currentWorkStrokes)
            }
        }
        
        # Generate block
        for ($i = 1; $i -le $blockSize -and $remainingStrokes -gt 0; $i++) {
            $stroke = New-WorkRestStroke -IsWork $isWorkPhase -IncludeBoundaryValues:$IncludeBoundaryValues -IncludeEdgeCases:$IncludeEdgeCases
            $pattern += $stroke
            $remainingStrokes--
        }
        
        # Switch phase
        $isWorkPhase = -not $isWorkPhase
    }
    
    return $pattern
}

function New-WorkRestStroke {
    param(
        [bool]$IsWork,
        [switch]$IncludeBoundaryValues,
        [switch]$IncludeEdgeCases
    )
    
    if ($IncludeBoundaryValues) {
        # Generate boundary values for testing classification edge cases
        if ($IsWork) {
            $heartRate = switch (Get-Random -Minimum 1 -Maximum 4) {
                1 { 124 } # Minimum work HR
                2 { 138 } # Maximum work HR
                3 { Get-Random -Minimum 124 -Maximum 138 } # Normal work HR
            }
            $strokeRate = switch (Get-Random -Minimum 1 -Maximum 4) {
                1 { 16 } # Minimum work rate
                2 { 24 } # Maximum work rate
                3 { Get-Random -Minimum 16 -Maximum 24 } # Normal work rate
            }
        } else {
            $heartRate = switch (Get-Random -Minimum 1 -Maximum 4) {
                1 { 123 } # Just below work HR
                2 { 139 } # Just above work HR
                3 { Get-Random -Minimum 90 -Maximum 123 } # Normal rest HR
            }
            $strokeRate = switch (Get-Random -Minimum 1 -Maximum 4) {
                1 { 15 } # Just below work rate
                2 { 25 } # Just above work rate
                3 { Get-Random -Minimum 10 -Maximum 15 } # Normal rest rate
            }
        }
    } elseif ($IncludeEdgeCases) {
        # Generate edge cases for robustness testing
        $heartRate = switch (Get-Random -Minimum 1 -Maximum 6) {
            1 { 0 } # Zero HR
            2 { -1 } # Negative HR
            3 { 300 } # Extremely high HR
            4 { $null } # Null HR
            5 { "---" } # Missing HR
            default { if ($IsWork) { Get-Random -Minimum 124 -Maximum 138 } else { Get-Random -Minimum 90 -Maximum 120 } }
        }
        $strokeRate = switch (Get-Random -Minimum 1 -Maximum 6) {
            1 { 0 } # Zero rate
            2 { -5 } # Negative rate
            3 { 100 } # Extremely high rate
            4 { $null } # Null rate
            5 { "---" } # Missing rate
            default { if ($IsWork) { Get-Random -Minimum 16 -Maximum 24 } else { Get-Random -Minimum 8 -Maximum 15 } }
        }
    } else {
        # Generate normal values
        if ($IsWork) {
            $heartRate = Get-Random -Minimum 124 -Maximum 138
            $strokeRate = Get-Random -Minimum 16 -Maximum 24
            $speed = Get-Random -Minimum 4.0 -Maximum 5.5
            $dps = Get-Random -Minimum 9.5 -Maximum 12.0
        } else {
            $heartRate = Get-Random -Minimum 85 -Maximum 123
            $strokeRate = Get-Random -Minimum 8 -Maximum 15
            $speed = Get-Random -Minimum 2.0 -Maximum 3.8
            $dps = Get-Random -Minimum 6.0 -Maximum 9.0
        }
    }
    
    # Generate other values if not set by edge cases
    if (-not $speed) { $speed = if ($IsWork) { Get-Random -Minimum 4.0 -Maximum 5.5 } else { Get-Random -Minimum 2.0 -Maximum 3.8 } }
    if (-not $dps) { $dps = if ($IsWork) { Get-Random -Minimum 9.5 -Maximum 12.0 } else { Get-Random -Minimum 6.0 -Maximum 9.0 } }
    
    $power = if ($IsWork) { Get-Random -Minimum 220 -Maximum 350 } else { Get-Random -Minimum 80 -Maximum 200 }
    $distance = Get-Random -Minimum 100 -Maximum 5000 # Cumulative distance
    
    return [PSCustomObject]@{
        IsWork = $IsWork
        "Heart Rate" = $heartRate
        "Stroke Rate" = $strokeRate
        "Speed (IMP)" = [Math]::Round($speed, 1)
        "Distance/Stroke (IMP)" = [Math]::Round($dps, 1)
        "Distance (IMP)" = [Math]::Round($distance, 1)
        "Power" = [Math]::Round($power, 0)
        "Elapsed Time" = "00:00:00.0" # Will be updated by caller
    }
}

function New-ClassificationTestCase {
    param(
        [string]$TestType = "Valid" # "Valid", "Invalid", "Boundary", "Missing"
    )
    
    switch ($TestType) {
        "Valid" {
            # Should classify as work
            return [PSCustomObject]@{
                "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                "Distance (IMP)" = Get-Random -Minimum 100 -Maximum 5000
                "Speed (IMP)" = Get-Random -Minimum 4.0 -Maximum 5.5
                "Distance/Stroke (IMP)" = Get-Random -Minimum 9.0 -Maximum 12.0
                ExpectedClassification = "Work"
            }
        }
        "Invalid" {
            # Should NOT classify as work (fails one or more criteria)
            $failureType = Get-Random -Minimum 1 -Maximum 4
            switch ($failureType) {
                1 { # HR too low
                    return [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 60 -Maximum 123
                        "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                        "Distance (IMP)" = Get-Random -Minimum 100 -Maximum 5000
                        ExpectedClassification = "Rest"
                    }
                }
                2 { # HR too high
                    return [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 139 -Maximum 180
                        "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                        "Distance (IMP)" = Get-Random -Minimum 100 -Maximum 5000
                        ExpectedClassification = "Rest"
                    }
                }
                3 { # Stroke rate too low
                    return [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                        "Stroke Rate" = Get-Random -Minimum 8 -Maximum 15
                        "Distance (IMP)" = Get-Random -Minimum 100 -Maximum 5000
                        ExpectedClassification = "Rest"
                    }
                }
                4 { # No distance data
                    return [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                        "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                        "Distance (IMP)" = 0
                        ExpectedClassification = "Rest"
                    }
                }
            }
        }
        "Boundary" {
            # Test exact boundary values
            $boundaryType = Get-Random -Minimum 1 -Maximum 4
            switch ($boundaryType) {
                1 { # Minimum work values
                    return [PSCustomObject]@{
                        "Heart Rate" = 124
                        "Stroke Rate" = 16
                        "Distance (IMP)" = 1
                        ExpectedClassification = "Work"
                    }
                }
                2 { # Maximum work values
                    return [PSCustomObject]@{
                        "Heart Rate" = 138
                        "Stroke Rate" = 24
                        "Distance (IMP)" = 5000
                        ExpectedClassification = "Work"
                    }
                }
                3 { # Just below minimum
                    return [PSCustomObject]@{
                        "Heart Rate" = 123
                        "Stroke Rate" = 15
                        "Distance (IMP)" = 1
                        ExpectedClassification = "Rest"
                    }
                }
                4 { # Just above maximum
                    return [PSCustomObject]@{
                        "Heart Rate" = 139
                        "Stroke Rate" = 25
                        "Distance (IMP)" = 1
                        ExpectedClassification = "Rest"
                    }
                }
            }
        }
        "Missing" {
            # Test missing value handling
            return [PSCustomObject]@{
                "Heart Rate" = if ((Get-Random) -lt 0.5) { "---" } else { Get-Random -Minimum 124 -Maximum 138 }
                "Stroke Rate" = if ((Get-Random) -lt 0.5) { "---" } else { Get-Random -Minimum 16 -Maximum 24 }
                "Distance (IMP)" = if ((Get-Random) -lt 0.5) { "---" } else { Get-Random -Minimum 100 -Maximum 5000 }
                ExpectedClassification = "Rest" # Missing values should result in rest classification
            }
        }
    }
}

function New-BlockFormationTestCase {
    param(
        [string]$TestType = "Valid" # "Valid", "TooFewStrokes", "TooShortDistance", "Mixed"
    )
    
    switch ($TestType) {
        "Valid" {
            # Should form a valid block (>10 strokes, >500m)
            $strokeCount = Get-Random -Minimum 15 -Maximum 50
            $strokes = @()
            $cumulativeDistance = 0
            
            for ($i = 1; $i -le $strokeCount; $i++) {
                $dps = Get-Random -Minimum 10.0 -Maximum 12.0
                $cumulativeDistance += $dps
                
                $strokes += [PSCustomObject]@{
                    "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                    "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                    "Distance (IMP)" = [Math]::Round($cumulativeDistance, 1)
                    "Distance/Stroke (IMP)" = [Math]::Round($dps, 1)
                    IsWork = $true
                }
            }
            
            return @{
                Strokes = $strokes
                ExpectedBlockCount = 1
                ExpectedTotalDistance = $cumulativeDistance
            }
        }
        "TooFewStrokes" {
            # Should NOT form a block (<=10 strokes)
            $strokeCount = Get-Random -Minimum 3 -Maximum 10
            $strokes = @()
            
            for ($i = 1; $i -le $strokeCount; $i++) {
                $strokes += [PSCustomObject]@{
                    "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                    "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                    "Distance (IMP)" = $i * 10
                    IsWork = $true
                }
            }
            
            return @{
                Strokes = $strokes
                ExpectedBlockCount = 0
            }
        }
        "TooShortDistance" {
            # Should NOT form a block (<500m total)
            $strokeCount = Get-Random -Minimum 15 -Maximum 30
            $strokes = @()
            $cumulativeDistance = 0
            
            for ($i = 1; $i -le $strokeCount; $i++) {
                $dps = Get-Random -Minimum 5.0 -Maximum 8.0 # Low DPS to keep total distance low
                $cumulativeDistance += $dps
                
                $strokes += [PSCustomObject]@{
                    "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                    "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                    "Distance (IMP)" = [Math]::Round($cumulativeDistance, 1)
                    "Distance/Stroke (IMP)" = [Math]::Round($dps, 1)
                    IsWork = $true
                }
            }
            
            return @{
                Strokes = $strokes
                ExpectedBlockCount = 0
                TotalDistance = $cumulativeDistance
            }
        }
        "Mixed" {
            # Mix of work and rest strokes
            $totalStrokes = Get-Random -Minimum 20 -Maximum 60
            $strokes = @()
            $workStrokes = 0
            
            for ($i = 1; $i -le $totalStrokes; $i++) {
                $isWork = (Get-Random) -lt 0.7 # 70% chance of work stroke
                
                if ($isWork) {
                    $workStrokes++
                    $strokes += [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 124 -Maximum 138
                        "Stroke Rate" = Get-Random -Minimum 16 -Maximum 24
                        "Distance (IMP)" = $i * 10
                        IsWork = $true
                    }
                } else {
                    $strokes += [PSCustomObject]@{
                        "Heart Rate" = Get-Random -Minimum 90 -Maximum 120
                        "Stroke Rate" = Get-Random -Minimum 8 -Maximum 15
                        "Distance (IMP)" = $i * 10
                        IsWork = $false
                    }
                }
            }
            
            $expectedBlocks = if ($workStrokes -gt 10) { 1 } else { 0 }
            
            return @{
                Strokes = $strokes
                ExpectedBlockCount = $expectedBlocks
                WorkStrokeCount = $workStrokes
            }
        }
    }
}

# Functions are available when dot-sourced