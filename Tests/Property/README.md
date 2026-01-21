# Property-Based Tests

This directory contains property-based tests that validate universal properties across randomized inputs.

## Structure
- Each correctness property from the design document has its own test
- Tests use custom generators to create diverse test data
- Minimum 100 iterations per property test

## Running Tests
```powershell
# Run all property tests
Invoke-Pester -Path "Tests/Property" -Verbose

# Run specific property test
Invoke-Pester -Path "Tests/Property/CSVParsingTests.ps1" -Verbose
```

## Test Data Generators
- `CSVGenerator.ps1`: Creates valid Speed Coach CSV files
- `StrokeGenerator.ps1`: Generates individual stroke records
- `WorkRestGenerator.ps1`: Creates work/rest pattern data