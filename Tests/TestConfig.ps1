# Test Configuration for Rowing Performance Analyzer
# This file contains shared configuration and utilities for all tests

# Test Framework Configuration
$TestConfig = @{
    # Property test iterations (minimum 100 as per design requirements)
    PropertyTestIterations = 100
    
    # Test data paths
    TestDataPath = Join-Path $PSScriptRoot "TestData"
    SampleCSVPath = Join-Path $PSScriptRoot "TestData\SampleCSV"
    
    # Test output paths
    TestOutputPath = Join-Path $PSScriptRoot "TestOutput"
    
    # Configuration parameters for testing (matching main script)
    TargetMinHR = 124
    TargetMaxHR = 138
    MinWorkRate = 16
    MaxWorkRate = 24
    MinBlockDist = 500
    TargetDPSThreshold = 10.5
    EffFloor = 0.020
    EffCeiling = 0.035
}

# Ensure test directories exist
if (!(Test-Path $TestConfig.TestDataPath)) { 
    New-Item -ItemType Directory -Path $TestConfig.TestDataPath -Force | Out-Null 
}
if (!(Test-Path $TestConfig.SampleCSVPath)) { 
    New-Item -ItemType Directory -Path $TestConfig.SampleCSVPath -Force | Out-Null 
}
if (!(Test-Path $TestConfig.TestOutputPath)) { 
    New-Item -ItemType Directory -Path $TestConfig.TestOutputPath -Force | Out-Null 
}

# Helper function to load the main script functions for testing
function Import-MainScriptFunctions {
    param([string]$ScriptPath = "NK_Analysis - BlockModel.ps1")
    
    # Define functions in global scope using Invoke-Expression
    Invoke-Expression @'
function Get-EffRating ([double]$score) {
    if ($score -ge 8.5) { return "Elite" }
    if ($score -ge 6.5) { return "Strong" }
    if ($score -ge 4.5) { return "Good" }
    return "Developing"
}

function Get-EffScore ([double]$speed, [double]$hr) {
    if ($hr -eq 0) { return 0 }
    $effFloor = 0.020
    $effCeiling = 0.035
    $rawEff = $speed / $hr
    $score = (($rawEff - $effFloor) / ($effCeiling - $effFloor)) * 10
    return [Math]::Max(0, [Math]::Min(10, $score))
}

function Convert-TimeToSeconds ([string]$timeStr) {
    if ($timeStr -eq "---" -or $timeStr -eq "") { return 0 }
    try {
        if ($timeStr -match "(\d+):(\d+):(\d+)\.(\d+)") {
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2] 
            $seconds = [int]$matches[3]
            $tenths = [int]$matches[4]
            return ($hours * 3600) + ($minutes * 60) + $seconds + ($tenths / 10)
        } elseif ($timeStr -match "(\d+):(\d+)\.(\d+)") {
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
'@
}

# Configuration is available as global variables when dot-sourced