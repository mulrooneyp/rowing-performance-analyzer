# Project Structure

## Repository Organization

```
/
├── .kiro/                          # Kiro AI assistant configuration
│   └── steering/                   # AI guidance documents
├── .vscode/                        # VS Code workspace settings
│   └── settings.json              # Editor configuration
├── Config.ps1                     # Configuration management module
├── Tests/                          # Test framework and test files
│   ├── Unit/                      # Unit tests
│   ├── Property/                  # Property-based tests
│   └── TestConfig.ps1             # Test configuration
└── NK_Analysis - BlockModel.ps1   # Main analysis script
```

## File Naming Conventions

- **Main Script**: Uses descriptive naming with version tracking in header comments
- **Output Files**: Generated with clear, structured names:
  - `Block_Work_Summary.csv`: Primary analysis results
  - `Rest_Recovery_Summary.csv`: Recovery pattern data
  - `[SessionName]_Stroke_Details.csv`: Individual stroke data per session
  - `Log.txt`: Execution logging

## Code Organization Patterns

### Script Structure
1. **Header Section**: Version info, update history, and description
2. **Configuration Import**: Loads and validates configuration from Config.ps1 module
3. **Helper Functions**: Utility functions before main execution
4. **Main Execution**: Primary processing logic using configuration parameters
5. **Export & Validation**: Output generation and integrity checks

### Function Naming
- Use verb-noun pattern: `Get-EffRating`, `Get-EffScore`
- Descriptive names that indicate purpose and return type
- Pascal case for function names
- Follow PowerShell approved verbs (Get, Set, New, etc.)

### Variable Naming
- Descriptive camelCase for local variables: `$targetMinHR`, `$currentBlock`
- Clear abbreviations: `HR` (Heart Rate), `DPS` (Distance Per Stroke), `Eff` (Efficiency)
- Path variables clearly indicate purpose: `$inputDir`, `$outputDir`, `$summaryCSV`

## Data Flow Architecture

1. **Input**: CSV files from Speed Coach exports (iCloud Drive integration)
2. **Processing**: Row-by-row analysis with state tracking for work/rest blocks
3. **Filtering**: Strict criteria for IMP (Impeller) sensor data only
4. **Stroke Capture**: Individual stroke details collected during work blocks
5. **Output**: Structured CSV summaries, individual stroke files, and detailed logging

## Error Handling Patterns

- Try-catch blocks around file processing
- Graceful degradation with informative logging
- Color-coded console output for different message types
- Comprehensive validation of output files