# Project Structure

## Repository Organization

```
/
├── .kiro/                          # Kiro AI assistant configuration
│   └── steering/                   # AI guidance documents
├── .vscode/                        # VS Code workspace settings
│   └── settings.json              # Editor configuration
└── NK_Analysis - BlockModel.ps1   # Main analysis script
```

## File Naming Conventions

- **Main Script**: Uses descriptive naming with version tracking in header comments
- **Output Files**: Generated with clear, structured names:
  - `Block_Work_Summary.csv`: Primary analysis results
  - `Rest_Recovery_Summary.csv`: Recovery pattern data
  - `Log.txt`: Execution logging

## Code Organization Patterns

### Script Structure
1. **Header Section**: Version info, update history, and description
2. **Configuration Block**: All configurable parameters at the top
3. **Helper Functions**: Utility functions before main execution
4. **Main Execution**: Primary processing logic
5. **Export & Validation**: Output generation and integrity checks

### Function Naming
- Use verb-noun pattern: `Get-EffRating`, `Calculate-EffScore`
- Descriptive names that indicate purpose and return type
- Pascal case for function names

### Variable Naming
- Descriptive camelCase for local variables: `$targetMinHR`, `$currentBlock`
- Clear abbreviations: `HR` (Heart Rate), `DPS` (Distance Per Stroke), `Eff` (Efficiency)
- Path variables clearly indicate purpose: `$inputDir`, `$outputDir`, `$summaryCSV`

## Data Flow Architecture

1. **Input**: CSV files from Speed Coach exports (iCloud Drive integration)
2. **Processing**: Row-by-row analysis with state tracking for work/rest blocks
3. **Filtering**: Strict criteria for IMP (Impeller) sensor data only
4. **Output**: Structured CSV summaries and detailed logging

## Error Handling Patterns

- Try-catch blocks around file processing
- Graceful degradation with informative logging
- Color-coded console output for different message types
- Comprehensive validation of output files