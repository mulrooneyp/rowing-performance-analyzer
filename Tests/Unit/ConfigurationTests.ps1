# Configuration Management Unit Tests
# Tests for configuration validation, default values, and parameter boundaries
# Requirements: 8.1, 8.2, 8.3, 8.4, 8.5

# Import test configuration and main configuration module
. "$PSScriptRoot\..\TestConfig.ps1"

# Import the configuration module
$ConfigModulePath = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "Config.ps1"
. $ConfigModulePath

Describe "Configuration Management" {
    
    Context "Default Configuration Creation" {
        It "Should create configuration with default values" {
            $config = New-RowingAnalyzerConfig
            $config | Should Not BeNullOrEmpty
            $config.GetType().Name | Should Be "RowingAnalyzerConfig"
        }
        
        It "Should have correct default heart rate values (Requirement 8.1)" {
            $config = New-RowingAnalyzerConfig
            $config.TargetMinHR | Should Be 124
            $config.TargetMaxHR | Should Be 138
        }
        
        It "Should have correct default stroke rate values (Requirement 8.2)" {
            $config = New-RowingAnalyzerConfig
            $config.MinWorkRate | Should Be 16.0
            $config.MaxWorkRate | Should Be 24.0
        }
        
        It "Should have correct default block distance (Requirement 8.3)" {
            $config = New-RowingAnalyzerConfig
            $config.MinBlockDist | Should Be 500
        }
        
        It "Should have correct default DPS threshold (Requirement 8.4)" {
            $config = New-RowingAnalyzerConfig
            $config.TargetDPSThreshold | Should Be 10.5
        }
        
        It "Should have correct default efficiency bounds (Requirement 8.5)" {
            $config = New-RowingAnalyzerConfig
            $config.EffFloor | Should Be 0.020
            $config.EffCeiling | Should Be 0.035
        }
        
        It "Should initialize file paths using environment variables" {
            $config = New-RowingAnalyzerConfig
            $config.InputDir | Should Not BeNullOrEmpty
            $config.OutputDir | Should Not BeNullOrEmpty
            $config.InputDir | Should Match $env:USERNAME
            $config.OutputDir | Should Match $env:USERNAME
        }
    }
    
    Context "Parameter Validation - Heart Rate (Requirement 8.1)" {
        It "Should accept valid heart rate ranges" {
            { New-RowingAnalyzerConfig -TargetMinHR 100 -TargetMaxHR 150 } | Should Not Throw
        }
        
        It "Should reject heart rate minimum below 60" {
            { New-RowingAnalyzerConfig -TargetMinHR 50 } | Should Throw
        }
        
        It "Should reject heart rate maximum above 200" {
            { New-RowingAnalyzerConfig -TargetMaxHR 250 } | Should Throw
        }
        
        It "Should reject when minimum HR >= maximum HR" {
            { New-RowingAnalyzerConfig -TargetMinHR 140 -TargetMaxHR 130 } | Should Throw
        }
        
        It "Should reject when minimum HR equals maximum HR" {
            { New-RowingAnalyzerConfig -TargetMinHR 130 -TargetMaxHR 130 } | Should Throw
        }
    }
    
    Context "Parameter Validation - Stroke Rate (Requirement 8.2)" {
        It "Should accept valid stroke rate ranges" {
            { New-RowingAnalyzerConfig -MinWorkRate 18.0 -MaxWorkRate 26.0 } | Should Not Throw
        }
        
        It "Should reject stroke rate minimum below 10" {
            { New-RowingAnalyzerConfig -MinWorkRate 5.0 } | Should Throw
        }
        
        It "Should reject stroke rate maximum above 50" {
            { New-RowingAnalyzerConfig -MaxWorkRate 60.0 } | Should Throw
        }
        
        It "Should reject when minimum rate >= maximum rate" {
            { New-RowingAnalyzerConfig -MinWorkRate 25.0 -MaxWorkRate 20.0 } | Should Throw
        }
        
        It "Should accept decimal stroke rates" {
            $config = New-RowingAnalyzerConfig -MinWorkRate 16.5 -MaxWorkRate 23.5
            $config.MinWorkRate | Should Be 16.5
            $config.MaxWorkRate | Should Be 23.5
        }
    }
    
    Context "Parameter Validation - Block Distance (Requirement 8.3)" {
        It "Should accept valid block distances" {
            { New-RowingAnalyzerConfig -MinBlockDist 750 } | Should Not Throw
        }
        
        It "Should reject block distance below 100" {
            { New-RowingAnalyzerConfig -MinBlockDist 50 } | Should Throw
        }
        
        It "Should reject block distance above 5000" {
            { New-RowingAnalyzerConfig -MinBlockDist 6000 } | Should Throw
        }
        
        It "Should accept boundary values" {
            { New-RowingAnalyzerConfig -MinBlockDist 100 } | Should Not Throw
            { New-RowingAnalyzerConfig -MinBlockDist 5000 } | Should Not Throw
        }
    }
    
    Context "Parameter Validation - DPS Threshold (Requirement 8.4)" {
        It "Should accept valid DPS thresholds" {
            { New-RowingAnalyzerConfig -TargetDPSThreshold 12.0 } | Should Not Throw
        }
        
        It "Should reject DPS threshold below 5.0" {
            { New-RowingAnalyzerConfig -TargetDPSThreshold 4.0 } | Should Throw
        }
        
        It "Should reject DPS threshold above 20.0" {
            { New-RowingAnalyzerConfig -TargetDPSThreshold 25.0 } | Should Throw
        }
        
        It "Should accept decimal DPS values" {
            $config = New-RowingAnalyzerConfig -TargetDPSThreshold 10.75
            $config.TargetDPSThreshold | Should Be 10.75
        }
    }
    
    Context "Parameter Validation - Efficiency Bounds (Requirement 8.5)" {
        It "Should accept valid efficiency bounds" {
            { New-RowingAnalyzerConfig -EffFloor 0.015 -EffCeiling 0.040 } | Should Not Throw
        }
        
        It "Should reject efficiency floor below 0.001" {
            { New-RowingAnalyzerConfig -EffFloor 0.0005 } | Should Throw
        }
        
        It "Should reject efficiency ceiling above 0.100" {
            { New-RowingAnalyzerConfig -EffCeiling 0.150 } | Should Throw
        }
        
        It "Should reject when floor >= ceiling" {
            { New-RowingAnalyzerConfig -EffFloor 0.030 -EffCeiling 0.025 } | Should Throw
        }
        
        It "Should reject when floor equals ceiling" {
            { New-RowingAnalyzerConfig -EffFloor 0.025 -EffCeiling 0.025 } | Should Throw
        }
    }
    
    Context "Configuration Methods" {
        BeforeEach {
            $config = New-RowingAnalyzerConfig
        }
        
        It "Should provide configuration summary" {
            $summary = $config.GetConfigurationSummary()
            $summary | Should Not BeNullOrEmpty
            $summary | Should Match "HR: 124-138"
            $summary | Should Match "Rate: 16-24"
            $summary | Should Match "MinDist: 500"
            $summary | Should Match "DPS Target: 10.5"
            $summary | Should Match "Eff Bounds: 0.02-0.035"
        }
        
        It "Should provide file paths" {
            $paths = $config.GetFilePaths()
            $paths | Should Not BeNullOrEmpty
            $paths.SummaryCSV | Should Not BeNullOrEmpty
            $paths.RestCSV | Should Not BeNullOrEmpty
            $paths.LogFile | Should Not BeNullOrEmpty
            $paths.SummaryCSV | Should Match "Block_Work_Summary.csv"
            $paths.RestCSV | Should Match "Rest_Recovery_Summary.csv"
            $paths.LogFile | Should Match "Log.txt"
        }
        
        It "Should ensure output directory creation" {
            # Use a test directory to avoid affecting real paths
            $testConfig = New-RowingAnalyzerConfig
            $testOutputPath = Join-Path $PSScriptRoot "..\TestOutput"
            if (!(Test-Path $testOutputPath)) {
                New-Item -ItemType Directory -Path $testOutputPath -Force | Out-Null
            }
            $testConfig.OutputDir = Join-Path $testOutputPath "ConfigTest"
            
            # Ensure directory doesn't exist first
            if (Test-Path $testConfig.OutputDir) {
                Remove-Item $testConfig.OutputDir -Recurse -Force
            }
            
            { $testConfig.EnsureOutputDirectory() } | Should Not Throw
            Test-Path $testConfig.OutputDir | Should Be $true
        }
    }
    
    Context "Configuration Documentation" {
        It "Should provide complete parameter documentation" {
            $docs = Get-ConfigurationDocumentation
            $docs | Should Not BeNullOrEmpty
            $docs.Keys.Count | Should Be 8
        }
        
        It "Should provide specific parameter documentation" {
            $hrDoc = Get-ConfigurationDocumentation -ParameterName "TargetMinHR"
            $hrDoc | Should Not BeNullOrEmpty
            $hrDoc.Description | Should Not BeNullOrEmpty
            $hrDoc.Default | Should Be 124
            $hrDoc.Requirements | Should Be "8.1"
        }
        
        It "Should throw for invalid parameter names" {
            { Get-ConfigurationDocumentation -ParameterName "InvalidParam" } | Should Throw
        }
        
        It "Should document all configuration parameters" {
            $docs = Get-ConfigurationDocumentation
            $expectedParams = @("TargetMinHR", "TargetMaxHR", "MinWorkRate", "MaxWorkRate", 
                              "MinBlockDist", "TargetDPSThreshold", "EffFloor", "EffCeiling")
            
            foreach ($param in $expectedParams) {
                $docs.ContainsKey($param) | Should Be $true
                $docs[$param].Description | Should Not BeNullOrEmpty
                $docs[$param].Default | Should Not BeNullOrEmpty
                $docs[$param].Requirements | Should Not BeNullOrEmpty
            }
        }
    }
    
    Context "Boundary Conditions" {
        It "Should handle minimum valid values" {
            $config = New-RowingAnalyzerConfig -TargetMinHR 60 -TargetMaxHR 61 -MinWorkRate 10.0 -MaxWorkRate 10.1 -MinBlockDist 100 -TargetDPSThreshold 5.0 -EffFloor 0.001 -EffCeiling 0.002
            $config | Should Not BeNullOrEmpty
        }
        
        It "Should handle maximum valid values" {
            $config = New-RowingAnalyzerConfig -TargetMinHR 199 -TargetMaxHR 200 -MinWorkRate 49.0 -MaxWorkRate 50.0 -MinBlockDist 5000 -TargetDPSThreshold 20.0 -EffFloor 0.099 -EffCeiling 0.100
            $config | Should Not BeNullOrEmpty
        }
        
        It "Should handle realistic rowing values" {
            $config = New-RowingAnalyzerConfig -TargetMinHR 130 -TargetMaxHR 160 -MinWorkRate 18.0 -MaxWorkRate 28.0 -MinBlockDist 1000 -TargetDPSThreshold 11.0 -EffFloor 0.025 -EffCeiling 0.045
            $config | Should Not BeNullOrEmpty
            $config.GetConfigurationSummary() | Should Match "HR: 130-160"
        }
    }
    
    Context "Error Handling" {
        It "Should provide meaningful error messages for invalid heart rate" {
            try {
                New-RowingAnalyzerConfig -TargetMinHR 150 -TargetMaxHR 140
                $false | Should Be $true  # Should not reach here
            }
            catch {
                $_.Exception.Message | Should Match "TargetMinHR.*must be less than.*TargetMaxHR"
            }
        }
        
        It "Should provide meaningful error messages for invalid stroke rate" {
            try {
                New-RowingAnalyzerConfig -MinWorkRate 25.0 -MaxWorkRate 20.0
                $false | Should Be $true  # Should not reach here
            }
            catch {
                $_.Exception.Message | Should Match "MinWorkRate.*must be less than.*MaxWorkRate"
            }
        }
        
        It "Should provide meaningful error messages for invalid efficiency bounds" {
            try {
                New-RowingAnalyzerConfig -EffFloor 0.040 -EffCeiling 0.030
                $false | Should Be $true  # Should not reach here
            }
            catch {
                $_.Exception.Message | Should Match "EffFloor.*must be less than.*EffCeiling"
            }
        }
    }
}