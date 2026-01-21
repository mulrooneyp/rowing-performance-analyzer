# Unit Tests

This directory contains unit tests for specific functions and edge cases in the Rowing Performance Analyzer.

## Structure
- Each module/component has its own test file
- Tests focus on specific examples and boundary conditions
- Uses Pester testing framework

## Running Tests
```powershell
# Run all unit tests
Invoke-Pester -Path "Tests/Unit" -Verbose

# Run specific test file
Invoke-Pester -Path "Tests/Unit/ConfigurationTests.ps1" -Verbose
```