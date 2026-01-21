# ==============================================================================
# CONFIGURATION MODULE: Rowing Performance Analyzer
# VERSION: 1.0.0
# PURPOSE: Centralized configuration management with validation and documentation
# ==============================================================================

<#
.SYNOPSIS
    Configuration module for the Rowing Performance Analyzer system.

.DESCRIPTION
    This module provides centralized configuration management for all analysis parameters,
    including validation, default values, and parameter documentation. It supports
    both default configurations and user customization while ensuring data integrity.

.NOTES
    Requirements Coverage:
    - 8.1: Heart rate work zone boundaries as configurable parameters
    - 8.2: Stroke rate work range as configurable parameters  
    - 8.3: Minimum block distance as configurable parameter
    - 8.4: DPS target threshold as configurable parameter
    - 8.5: Efficiency calculation bounds as configurable parameters
#>

# Configuration class to encapsulate all parameters
class RowingAnalyzerConfig {
    # Heart Rate Configuration (Requirement 8.1)
    [ValidateRange(60, 200)]
    [int] $TargetMinHR = 124
    
    [ValidateRange(60, 200)]
    [int] $TargetMaxHR = 138
    
    # Stroke Rate Configuration (Requirement 8.2)
    [ValidateRange(10, 50)]
    [double] $MinWorkRate = 16.0
    
    [ValidateRange(10, 50)]
    [double] $MaxWorkRate = 24.0
    
    # Block Distance Configuration (Requirement 8.3)
    [ValidateRange(100, 5000)]
    [int] $MinBlockDist = 500
    
    # DPS Target Configuration (Requirement 8.4)
    [ValidateRange(5.0, 20.0)]
    [double] $TargetDPSThreshold = 10.5
    
    # Efficiency Calculation Bounds (Requirement 8.5)
    [ValidateRange(0.001, 0.100)]
    [double] $EffFloor = 0.020
    
    [ValidateRange(0.001, 0.100)]
    [double] $EffCeiling = 0.035
    
    # File System Configuration
    [string] $InputDir = ""
    [string] $OutputDir = ""
    [string] $ScriptVersion = "4.9.3"
    
    # Constructor with validation
    RowingAnalyzerConfig() {
        $this.InitializeFilePaths()
        $this.ValidateConfiguration()
    }
    
    # Initialize file paths using environment variables
    [void] InitializeFilePaths() {
        $username = $env:USERNAME
        if ([string]::IsNullOrEmpty($username)) {
            throw "Unable to determine current user. Environment variable USERNAME is not set."
        }
        
        $this.InputDir = "C:\Users\$username\iCloudDrive\Speed coach\exported-sessions"
        $this.OutputDir = "C:\Users\$username\iCloudDrive\Speed coach\AnalysedData\BlockAnalysis"
    }
    
    # Validate all configuration parameters
    [void] ValidateConfiguration() {
        # Heart rate validation
        if ($this.TargetMinHR -ge $this.TargetMaxHR) {
            throw "Invalid heart rate configuration: TargetMinHR ($($this.TargetMinHR)) must be less than TargetMaxHR ($($this.TargetMaxHR))"
        }
        
        # Stroke rate validation
        if ($this.MinWorkRate -ge $this.MaxWorkRate) {
            throw "Invalid stroke rate configuration: MinWorkRate ($($this.MinWorkRate)) must be less than MaxWorkRate ($($this.MaxWorkRate))"
        }
        
        # Efficiency bounds validation
        if ($this.EffFloor -ge $this.EffCeiling) {
            throw "Invalid efficiency bounds: EffFloor ($($this.EffFloor)) must be less than EffCeiling ($($this.EffCeiling))"
        }
        
        # Path validation
        if ([string]::IsNullOrEmpty($this.InputDir) -or [string]::IsNullOrEmpty($this.OutputDir)) {
            throw "File paths cannot be empty after initialization"
        }
    }
    
    # Get configuration summary for logging
    [string] GetConfigurationSummary() {
        return "HR: $($this.TargetMinHR)-$($this.TargetMaxHR) BPM | " +
               "Rate: $($this.MinWorkRate)-$($this.MaxWorkRate) SPM | " +
               "MinDist: $($this.MinBlockDist)m | " +
               "DPS Target: $($this.TargetDPSThreshold)m | " +
               "Eff Bounds: $($this.EffFloor)-$($this.EffCeiling)"
    }
    
    # Create file paths based on configuration
    [hashtable] GetFilePaths() {
        return @{
            SummaryCSV = Join-Path $this.OutputDir "Block_Work_Summary.csv"
            RestCSV = Join-Path $this.OutputDir "Rest_Recovery_Summary.csv"
            LogFile = Join-Path $this.OutputDir "Log.txt"
        }
    }
    
    # Ensure output directory exists
    [void] EnsureOutputDirectory() {
        if (!(Test-Path $this.OutputDir)) {
            try {
                New-Item -ItemType Directory -Path $this.OutputDir -Force | Out-Null
                Write-Verbose "Created output directory: $($this.OutputDir)"
            }
            catch {
                throw "Failed to create output directory '$($this.OutputDir)': $($_.Exception.Message)"
            }
        }
    }
}

# Configuration parameter documentation
$ConfigurationDocumentation = @{
    TargetMinHR = @{
        Description = "Minimum heart rate for work classification (BPM)"
        Default = 124
        Range = "60-200"
        Requirements = "8.1"
        Notes = "Lower bound of target heart rate zone for identifying work intervals"
    }
    
    TargetMaxHR = @{
        Description = "Maximum heart rate for work classification (BPM)"
        Default = 138
        Range = "60-200"
        Requirements = "8.1"
        Notes = "Upper bound of target heart rate zone for identifying work intervals"
    }
    
    MinWorkRate = @{
        Description = "Minimum stroke rate for work classification (SPM)"
        Default = 16.0
        Range = "10-50"
        Requirements = "8.2"
        Notes = "Lower bound of stroke rate range for identifying work intervals"
    }
    
    MaxWorkRate = @{
        Description = "Maximum stroke rate for work classification (SPM)"
        Default = 24.0
        Range = "10-50"
        Requirements = "8.2"
        Notes = "Upper bound of stroke rate range for identifying work intervals"
    }
    
    MinBlockDist = @{
        Description = "Minimum distance for valid work blocks (meters)"
        Default = 500
        Range = "100-5000"
        Requirements = "8.3"
        Notes = "Work blocks must cover at least this distance to be included in analysis"
    }
    
    TargetDPSThreshold = @{
        Description = "Target distance per stroke threshold (meters)"
        Default = 10.5
        Range = "5.0-20.0"
        Requirements = "8.4"
        Notes = "Strokes achieving this DPS or higher are marked as 'AtTarget'"
    }
    
    EffFloor = @{
        Description = "Lower bound for efficiency score calculation"
        Default = 0.020
        Range = "0.001-0.100"
        Requirements = "8.5"
        Notes = "Used in efficiency formula: ((speed/hr - floor)/(ceiling-floor)) * 10"
    }
    
    EffCeiling = @{
        Description = "Upper bound for efficiency score calculation"
        Default = 0.035
        Range = "0.001-0.100"
        Requirements = "8.5"
        Notes = "Used in efficiency formula: ((speed/hr - floor)/(ceiling-floor)) * 10"
    }
}

# Factory function to create and validate configuration
function New-RowingAnalyzerConfig {
    <#
    .SYNOPSIS
        Creates a new validated configuration instance for the Rowing Performance Analyzer.
    
    .DESCRIPTION
        Factory function that creates a new RowingAnalyzerConfig instance with default values
        and performs comprehensive validation. Supports parameter overrides for customization.
    
    .PARAMETER TargetMinHR
        Minimum heart rate for work classification (60-200 BPM). Default: 124
    
    .PARAMETER TargetMaxHR
        Maximum heart rate for work classification (60-200 BPM). Default: 138
    
    .PARAMETER MinWorkRate
        Minimum stroke rate for work classification (10-50 SPM). Default: 16.0
    
    .PARAMETER MaxWorkRate
        Maximum stroke rate for work classification (10-50 SPM). Default: 24.0
    
    .PARAMETER MinBlockDist
        Minimum distance for valid work blocks (100-5000 meters). Default: 500
    
    .PARAMETER TargetDPSThreshold
        Target distance per stroke threshold (5.0-20.0 meters). Default: 10.5
    
    .PARAMETER EffFloor
        Lower bound for efficiency calculation (0.001-0.100). Default: 0.020
    
    .PARAMETER EffCeiling
        Upper bound for efficiency calculation (0.001-0.100). Default: 0.035
    
    .EXAMPLE
        $config = New-RowingAnalyzerConfig
        Creates configuration with default values
    
    .EXAMPLE
        $config = New-RowingAnalyzerConfig -TargetMinHR 120 -TargetMaxHR 140
        Creates configuration with custom heart rate zone
    
    .OUTPUTS
        RowingAnalyzerConfig instance with validated parameters
    #>
    
    [CmdletBinding()]
    param(
        [ValidateRange(60, 200)]
        [int] $TargetMinHR,
        
        [ValidateRange(60, 200)]
        [int] $TargetMaxHR,
        
        [ValidateRange(10, 50)]
        [double] $MinWorkRate,
        
        [ValidateRange(10, 50)]
        [double] $MaxWorkRate,
        
        [ValidateRange(100, 5000)]
        [int] $MinBlockDist,
        
        [ValidateRange(5.0, 20.0)]
        [double] $TargetDPSThreshold,
        
        [ValidateRange(0.001, 0.100)]
        [double] $EffFloor,
        
        [ValidateRange(0.001, 0.100)]
        [double] $EffCeiling
    )
    
    try {
        $config = [RowingAnalyzerConfig]::new()
        
        # Apply parameter overrides if provided
        if ($PSBoundParameters.ContainsKey('TargetMinHR')) { $config.TargetMinHR = $TargetMinHR }
        if ($PSBoundParameters.ContainsKey('TargetMaxHR')) { $config.TargetMaxHR = $TargetMaxHR }
        if ($PSBoundParameters.ContainsKey('MinWorkRate')) { $config.MinWorkRate = $MinWorkRate }
        if ($PSBoundParameters.ContainsKey('MaxWorkRate')) { $config.MaxWorkRate = $MaxWorkRate }
        if ($PSBoundParameters.ContainsKey('MinBlockDist')) { $config.MinBlockDist = $MinBlockDist }
        if ($PSBoundParameters.ContainsKey('TargetDPSThreshold')) { $config.TargetDPSThreshold = $TargetDPSThreshold }
        if ($PSBoundParameters.ContainsKey('EffFloor')) { $config.EffFloor = $EffFloor }
        if ($PSBoundParameters.ContainsKey('EffCeiling')) { $config.EffCeiling = $EffCeiling }
        
        # Re-validate after applying overrides
        $config.ValidateConfiguration()
        
        return $config
    }
    catch {
        throw "Failed to create configuration: $($_.Exception.Message)"
    }
}

# Function to get configuration parameter documentation
function Get-ConfigurationDocumentation {
    <#
    .SYNOPSIS
        Returns documentation for all configuration parameters.
    
    .DESCRIPTION
        Provides detailed documentation for each configuration parameter including
        description, default values, valid ranges, and requirement mappings.
    
    .PARAMETER ParameterName
        Optional. If specified, returns documentation for a specific parameter only.
    
    .EXAMPLE
        Get-ConfigurationDocumentation
        Returns documentation for all parameters
    
    .EXAMPLE
        Get-ConfigurationDocumentation -ParameterName "TargetMinHR"
        Returns documentation for the TargetMinHR parameter only
    #>
    
    [CmdletBinding()]
    param(
        [string] $ParameterName
    )
    
    if ($ParameterName) {
        if ($ConfigurationDocumentation.ContainsKey($ParameterName)) {
            return $ConfigurationDocumentation[$ParameterName]
        } else {
            throw "Parameter '$ParameterName' not found in configuration documentation"
        }
    } else {
        return $ConfigurationDocumentation
    }
}

# Module functions and variables are available when dot-sourced
# New-RowingAnalyzerConfig, Get-ConfigurationDocumentation, and ConfigurationDocumentation are exported