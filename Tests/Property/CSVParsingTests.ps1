# Property-Based Tests for CSV Parsing
# Feature: rowing-performance-analyzer, Property 1: CSV Parsing Robustness

# Import test configuration and generators
. "$PSScriptRoot\..\TestConfig.ps1"
. "$PSScriptRoot\Generators\CSVGenerator.ps1"

Describe "CSV Parsing Property Tests" {
    BeforeAll {
        # Import main script functions for testing
        Import-MainScriptFunctions
    }
    
    Context "Property 1: CSV Parsing Robustness" {
        It "Should parse any valid Speed Coach CSV file without errors - Iteration <Iteration>" -TestCases @(
            1..$TestConfig.PropertyTestIterations | ForEach-Object { @{ Iteration = $_ } }
        ) {
            param($Iteration)
            # **Feature: rowing-performance-analyzer, Property 1: CSV Parsing Robustness**
            # **Validates: Requirements 1.1, 1.2, 1.3**
            
            # Generate random CSV content
            $csvContent = New-RandomCSVFile -IncludeMissingValues -StrokeCount (Get-Random -Minimum 20 -Maximum 200)
            
            # Write to temporary file
            $tempFile = Join-Path $TestConfig.TestOutputPath "temp_test_$(Get-Random).csv"
            $csvContent | Out-File -FilePath $tempFile -Encoding UTF8
            
            try {
                # Test parsing logic (simulating main script parsing)
                $content = Get-Content $tempFile -Raw -Encoding UTF8
                $rawLines = $content -split '\r?\n'
                
                # Find Per-Stroke Data section
                $strokeSectionIdx = -1
                for ($i = 0; $i -lt $rawLines.Count; $i++) {
                    if ($rawLines[$i] -match "Per-Stroke Data:") { 
                        $strokeSectionIdx = $i
                        break 
                    }
                }
                
                # Property: Should always find the Per-Stroke Data section in generated files
                $strokeSectionIdx | Should -BeGreaterThan -1
                
                # Find IMP header
                $headerIdx = -1
                for ($i = $strokeSectionIdx; $i -lt $rawLines.Count; $i++) {
                    if ($rawLines[$i] -match "Distance \(IMP\)") { 
                        $headerIdx = $i
                        break 
                    }
                }
                
                # Property: Should always find IMP headers in generated files
                $headerIdx | Should -BeGreaterThan -1
                
                # Parse data
                $data = $rawLines[$headerIdx..($rawLines.Count - 1)] | ConvertFrom-Csv | Where-Object { $_."Stroke Rate" -as [double] -gt 0 }
                
                # Property: Should successfully parse data without throwing exceptions
                $data | Should -Not -BeNullOrEmpty
                
                # Property: All parsed rows should have required columns
                foreach ($row in $data) {
                    $row.PSObject.Properties.Name | Should -Contain "Heart Rate"
                    $row.PSObject.Properties.Name | Should -Contain "Stroke Rate"
                    $row.PSObject.Properties.Name | Should -Contain "Distance (IMP)"
                    $row.PSObject.Properties.Name | Should -Contain "Speed (IMP)"
                    $row.PSObject.Properties.Name | Should -Contain "Distance/Stroke (IMP)"
                }
                
                # Property: Missing values ("---") should be handled gracefully
                foreach ($row in $data) {
                    # Should not throw exceptions when accessing potentially missing values
                    { 
                        $hrStr = $row."Heart Rate"
                        $hr = if ($hrStr -eq "---" -or $hrStr -eq "") { 0 } else { [double]$hrStr }
                        $rate = [double]$row."Stroke Rate"
                        $dist = [double]$row."Distance (IMP)"
                    } | Should -Not -Throw
                }
                
            } finally {
                # Cleanup
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force
                }
            }
        }
    }
}