# Technology Stack

## Core Technology

- **Language**: PowerShell 5.1+
- **Platform**: Windows (primary target)
- **Data Format**: CSV input/output
- **Encoding**: UTF-8 (specifically to handle iCloud file compatibility)

## Dependencies

- No external dependencies required
- Uses built-in PowerShell cmdlets and .NET collections
- Compatible with Windows PowerShell and PowerShell Core

## Common Commands

### Running the Analysis
```powershell
# Execute the main analysis script
.\NK_Analysis\ -\ BlockModel.ps1
```

### Configuration

Configuration is now managed through a dedicated `Config.ps1` module:

```powershell
# Load configuration module
. .\Config.ps1

# Create validated configuration instance
$config = New-RowingAnalyzerConfig

# Customize parameters if needed
$config = New-RowingAnalyzerConfig -TargetMinHR 120 -TargetMaxHR 140
```

Key configuration parameters:
- `TargetMinHR, TargetMaxHR`: Heart rate work zone (default: 124-138)
- `MinWorkRate, MaxWorkRate`: Stroke rate range (default: 16-24)
- `MinBlockDist`: Minimum block distance in meters (default: 500)
- `TargetDPSThreshold`: Distance per stroke target (default: 10.5)
- `EffFloor, EffCeiling`: Efficiency calculation bounds (default: 0.020-0.035)

The configuration module provides:
- Parameter validation with range checking
- Default value management
- Configuration documentation via `Get-ConfigurationDocumentation`
- Error handling with meaningful messages

### File Paths
Update these variables for different environments:
- `$inputDir`: Source directory for Speed Coach CSV exports
- `$outputDir`: Destination for analysis results
- Paths currently configured for iCloud Drive integration using `$env:USERNAME`

## Performance Considerations

- Uses .NET Generic Lists for better memory efficiency with large datasets
- UTF-8 encoding specifically chosen to handle iCloud file sync issues
- Processes files sequentially to avoid memory pressure
- Individual stroke files created per session to manage output size

## Recent Updates

- **Version 4.9.3**: Added individual stroke-by-stroke output files
- **Configuration Refactoring**: Moved to dedicated Config.ps1 module with validation
- **Generic User Support**: Uses `$env:USERNAME` for cross-user compatibility
- **Enhanced Filtering**: Improved stroke rate and DPS target tracking
- **PowerShell Compliance**: Updated function names to use approved verbs
- **Testing Framework**: Added comprehensive unit and property-based testing