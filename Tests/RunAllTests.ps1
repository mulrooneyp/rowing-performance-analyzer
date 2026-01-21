# Test Runner for Rowing Performance Analyzer
# Runs all unit tests and property-based tests

param(
    [string]$TestType = "All", # "All", "Unit", "Property"
    [string]$TestName = $null,  # Specific test file to run
    [switch]$Verbose
)

# Import test configuration
. "$PSScriptRoot\TestConfig.ps1"

Write-Host "=== Rowing Performance Analyzer Test Suite ===" -ForegroundColor Cyan
Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Property Test Iterations: $($TestConfig.PropertyTestIterations)" -ForegroundColor Gray
Write-Host "  Test Data Path: $($TestConfig.TestDataPath)" -ForegroundColor Gray
Write-Host "  Test Output Path: $($TestConfig.TestOutputPath)" -ForegroundColor Gray
Write-Host ""

# Ensure Pester is available
if (-not (Get-Module -ListAvailable Pester)) {
    Write-Error "Pester module is not installed. Please install it with: Install-Module -Name Pester -Force"
    exit 1
}

# Import Pester
Import-Module Pester -Force

$testResults = @()

try {
    if ($TestName) {
        # Run specific test file
        Write-Host "Running specific test: $TestName" -ForegroundColor Green
        $result = Invoke-Pester -Path $TestName -PassThru
        $testResults += $result
    } else {
        # Run tests based on type
        switch ($TestType) {
            "Unit" {
                Write-Host "Running Unit Tests..." -ForegroundColor Green
                if (Test-Path "$PSScriptRoot\Unit") {
                    $result = Invoke-Pester -Path "$PSScriptRoot\Unit" -PassThru
                    $testResults += $result
                } else {
                    Write-Warning "No unit tests found in $PSScriptRoot\Unit"
                }
            }
            "Property" {
                Write-Host "Running Property-Based Tests..." -ForegroundColor Green
                if (Test-Path "$PSScriptRoot\Property") {
                    $result = Invoke-Pester -Path "$PSScriptRoot\Property" -PassThru
                    $testResults += $result
                } else {
                    Write-Warning "No property tests found in $PSScriptRoot\Property"
                }
            }
            "All" {
                Write-Host "Running All Tests..." -ForegroundColor Green
                
                # Run Unit Tests
                if (Test-Path "$PSScriptRoot\Unit") {
                    Write-Host "`nUnit Tests:" -ForegroundColor Yellow
                    $unitResult = Invoke-Pester -Path "$PSScriptRoot\Unit" -PassThru
                    $testResults += $unitResult
                }
                
                # Run Property Tests
                if (Test-Path "$PSScriptRoot\Property") {
                    Write-Host "`nProperty-Based Tests:" -ForegroundColor Yellow
                    $propertyResult = Invoke-Pester -Path "$PSScriptRoot\Property" -PassThru
                    $testResults += $propertyResult
                }
            }
        }
    }
    
    # Summary
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    $totalTests = ($testResults | Measure-Object -Property TotalCount -Sum).Sum
    $passedTests = ($testResults | Measure-Object -Property PassedCount -Sum).Sum
    $failedTests = ($testResults | Measure-Object -Property FailedCount -Sum).Sum
    $skippedTests = ($testResults | Measure-Object -Property SkippedCount -Sum).Sum
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    if ($failedTests -gt 0) {
        Write-Host "Failed: $failedTests" -ForegroundColor Red
    }
    if ($skippedTests -gt 0) {
        Write-Host "Skipped: $skippedTests" -ForegroundColor Yellow
    }
    
    # Exit with appropriate code
    if ($failedTests -gt 0) {
        Write-Host "`nSome tests failed!" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "`nAll tests passed!" -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Error "Error running tests: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}