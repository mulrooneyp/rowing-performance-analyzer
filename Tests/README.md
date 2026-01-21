# Rowing Performance Analyzer - Test Suite

## Overview

This directory contains the complete testing framework for the Rowing Performance Analyzer, including both unit tests and property-based tests as specified in the design document.

## Structure

```
Tests/
├── Unit/                    # Unit tests for specific functions and edge cases
│   ├── BasicTests.ps1      # Framework verification tests
│   └── README.md           # Unit test documentation
├── Property/               # Property-based tests for universal properties
│   ├── Generators/         # Test data generators
│   │   ├── CSVGenerator.ps1        # Speed Coach CSV file generator
│   │   ├── StrokeGenerator.ps1     # Individual stroke data generator
│   │   └── WorkRestGenerator.ps1   # Work/rest pattern generator
│   ├── CSVParsingTests.ps1 # Property tests for CSV parsing (Property 1)
│   └── README.md           # Property test documentation
├── TestData/               # Sample test data and generated files
│   ├── SampleSession.csv   # Sample Speed Coach CSV file
│   └── README.md           # Test data documentation
├── TestConfig.ps1          # Shared test configuration and utilities
└── RunAllTests.ps1         # Test runner script
```

## Configuration

The test framework is configured with the following settings:
- **Property Test Iterations**: 100 (minimum as per design requirements)
- **Test Framework**: Pester 3.4.0
- **Test Data Path**: `Tests/TestData`
- **Test Output Path**: `Tests/TestOutput`

## Running Tests

### All Tests
```powershell
.\Tests\RunAllTests.ps1
```

### Unit Tests Only
```powershell
.\Tests\RunAllTests.ps1 -TestType Unit
```

### Property Tests Only
```powershell
.\Tests\RunAllTests.ps1 -TestType Property
```

### Specific Test File
```powershell
.\Tests\RunAllTests.ps1 -TestName "Tests\Unit\BasicTests.ps1"
```

## Test Data Generators

The framework includes sophisticated generators for creating test data:

### CSV Generator (`CSVGenerator.ps1`)
- **New-RandomCSVFile**: Creates complete Speed Coach CSV files with randomized data
- **New-RandomStrokeData**: Generates individual stroke records
- **New-WorkRestPattern**: Creates work/rest pattern sequences

### Stroke Generator (`StrokeGenerator.ps1`)
- **New-RandomStroke**: Creates individual stroke records with realistic values
- **New-StrokeSequence**: Generates sequences of strokes with patterns
- **New-EdgeCaseStroke**: Creates edge case data for robustness testing
- **New-RealisticRowingSession**: Generates complete rowing sessions

### Work/Rest Generator (`WorkRestGenerator.ps1`)
- **New-WorkRestPattern**: Creates work/rest classification test cases
- **New-ClassificationTestCase**: Generates boundary and edge cases for classification
- **New-BlockFormationTestCase**: Creates test cases for block formation logic

## Property-Based Testing

The framework implements 14 correctness properties as defined in the design document:

1. **CSV Parsing Robustness** - Validates Requirements 1.1, 1.2, 1.3
2. **Work Classification Accuracy** - Validates Requirements 2.1, 2.2, 2.3, 2.4
3. **Block Formation Consistency** - Validates Requirements 2.5, 2.6
4. **Efficiency Score Calculation** - Validates Requirements 3.1, 3.2
5. **Rating Classification Consistency** - Validates Requirements 3.3
6. **DPS Target Evaluation** - Validates Requirements 3.4, 4.2
7. **Missing Value Handling** - Validates Requirements 3.5
8. **Stroke Detail Capture** - Validates Requirements 4.1
9. **File Generation Per Session** - Validates Requirements 4.3, 4.4, 4.5
10. **Recovery Analysis Criteria** - Validates Requirements 5.1, 5.2, 5.3, 5.5
11. **Summary Report Completeness** - Validates Requirements 6.1, 6.2, 6.3
12. **Error Logging Consistency** - Validates Requirements 7.2, 7.3
13. **Validation Verification** - Validates Requirements 7.5
14. **Path Construction Reliability** - Validates Requirements 9.1, 9.4

Each property test runs a minimum of 100 iterations with randomized inputs to ensure comprehensive coverage.

## Framework Status

✅ **Completed Components:**
- Pester testing framework configured
- Test directory structure created
- Test configuration system implemented
- Property test generators created
- Sample test data provided
- Test runner script implemented
- Basic framework verification tests passing

🔧 **Known Issues:**
- CSV generator formatting needs refinement for some edge cases
- Main script function extraction needs improvement
- Property test implementation needs completion

## Next Steps

1. Complete implementation of all 14 property-based tests
2. Add comprehensive unit tests for each module
3. Improve function extraction from main script
4. Add performance benchmarking tests
5. Implement test coverage reporting