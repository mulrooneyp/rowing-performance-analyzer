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
Key parameters are defined at the top of the script:
- `$targetMinHR, $targetMaxHR`: Heart rate work zone (default: 124-138)
- `$minWorkRate, $maxWorkRate`: Stroke rate range (default: 16-24)
- `$minBlockDist`: Minimum block distance in meters (default: 500)
- `$targetDPSThreshold`: Distance per stroke target (default: 10.5)
- `$effFloor, $effCeiling`: Efficiency calculation bounds (default: 0.020-0.035)

### File Paths
Update these variables for different environments:
- `$inputDir`: Source directory for Speed Coach CSV exports
- `$outputDir`: Destination for analysis results
- Paths currently configured for iCloud Drive integration

## Performance Considerations

- Uses .NET Generic Lists for better memory efficiency with large datasets
- UTF-8 encoding specifically chosen to handle iCloud file sync issues
- Processes files sequentially to avoid memory pressure