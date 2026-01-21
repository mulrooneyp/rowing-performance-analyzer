# Basic Unit Tests to verify framework setup

# Import test configuration
. "$PSScriptRoot\..\TestConfig.ps1"

Describe "Test Framework Setup" {
    Context "Configuration" {
        It "Should have test configuration loaded" {
            $TestConfig | Should Not BeNullOrEmpty
            $TestConfig.PropertyTestIterations | Should Be 100
        }
        
        It "Should have test directories created" {
            Test-Path $TestConfig.TestDataPath | Should Be $true
            Test-Path $TestConfig.TestOutputPath | Should Be $true
        }
        
        It "Should have sample test data" {
            Test-Path "$($TestConfig.TestDataPath)\SampleSession.csv" | Should Be $true
        }
    }
    
    Context "Test Generators" {
        BeforeAll {
            . "$PSScriptRoot\..\Property\Generators\CSVGenerator.ps1"
        }
        
        It "Should be able to generate test CSV content" {
            { New-RandomCSVFile -StrokeCount 5 } | Should Not Throw
        }
        
        It "Should generate CSV with proper headers" {
            $csv = New-RandomCSVFile -StrokeCount 3
            $csv | Should Match "Speed Coach GPS 2"
            $csv | Should Match "Per-Stroke Data:"
            $csv | Should Match "Elapsed Time,Distance \(IMP\)"
        }
    }
}