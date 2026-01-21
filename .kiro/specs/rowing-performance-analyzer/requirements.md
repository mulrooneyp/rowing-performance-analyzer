# Requirements Document

## Introduction

The Rowing Performance Analyzer is a PowerShell-based data analysis tool that processes exported session data from Speed Coach devices to analyze rowing technique, efficiency, and recovery patterns. The system transforms raw stroke data into actionable performance insights for rowing coaches and athletes.

## Glossary

- **Speed_Coach**: NK Speed Coach device that records rowing session data
- **IMP_Sensor**: Impeller sensor that measures boat speed and distance
- **Work_Block**: A continuous sequence of strokes meeting heart rate and stroke rate criteria
- **Rest_Period**: Time between work blocks used for recovery analysis
- **DPS**: Distance Per Stroke - efficiency metric measuring meters traveled per stroke
- **Efficiency_Score**: Calculated metric based on speed-to-heart rate ratio
- **System**: The Rowing Performance Analyzer PowerShell script

## Requirements

### Requirement 1: CSV Data Processing

**User Story:** As a rowing coach, I want to process Speed Coach CSV exports, so that I can analyze multiple training sessions efficiently.

#### Acceptance Criteria

1. WHEN the System processes a CSV file, THE System SHALL locate the "Per-Stroke Data:" section header
2. WHEN the System finds stroke data, THE System SHALL parse IMP sensor columns including Distance, Speed, Stroke Rate, and Heart Rate
3. WHEN the System encounters missing values marked as "---", THE System SHALL handle them gracefully without errors
4. WHEN the System processes multiple CSV files, THE System SHALL process them sequentially from the input directory
5. THE System SHALL use UTF-8 encoding to ensure compatibility with iCloud Drive file synchronization

### Requirement 2: Work Block Detection

**User Story:** As a performance analyst, I want to identify work intervals automatically, so that I can focus analysis on training efforts rather than rest periods.

#### Acceptance Criteria

1. WHEN a stroke meets heart rate criteria (124-138 BPM), THE System SHALL consider it for work classification
2. WHEN a stroke meets stroke rate criteria (16-24 SPM), THE System SHALL consider it for work classification  
3. WHEN a stroke has valid IMP distance data, THE System SHALL consider it for work classification
4. WHEN all three criteria are met simultaneously, THE System SHALL classify the stroke as work
5. WHEN a work sequence contains more than 10 strokes, THE System SHALL create a work block
6. WHEN a work block covers at least 500 meters total distance, THE System SHALL include it in analysis

### Requirement 3: Performance Metrics Calculation

**User Story:** As a rowing athlete, I want detailed performance metrics calculated, so that I can track my technique and efficiency improvements.

#### Acceptance Criteria

1. WHEN calculating efficiency scores, THE System SHALL use the formula: (speed / heart_rate - floor) / (ceiling - floor) * 10
2. WHEN efficiency score is calculated, THE System SHALL bound results between 0 and 10
3. WHEN determining efficiency ratings, THE System SHALL classify scores: Elite (8.5+), Strong (6.5+), Good (4.5+), Developing (<4.5)
4. WHEN analyzing Distance Per Stroke, THE System SHALL compare against the target threshold of 10.5 meters
5. WHEN calculating averages, THE System SHALL exclude missing values marked as "---"

### Requirement 4: Individual Stroke Tracking

**User Story:** As a technique coach, I want stroke-by-stroke data for each work block, so that I can analyze detailed rowing mechanics and identify specific improvement areas.

#### Acceptance Criteria

1. WHEN processing a work block, THE System SHALL capture individual stroke details including stroke number, heart rate, stroke rate, speed, distance, and DPS
2. WHEN a stroke achieves DPS above the target threshold, THE System SHALL mark it as "AtTarget"
3. WHEN exporting stroke details, THE System SHALL create a separate CSV file for each input session
4. WHEN naming stroke detail files, THE System SHALL use the format "[SessionName]_Stroke_Details.csv"
5. WHEN writing stroke files, THE System SHALL include headers with version information and file metadata

### Requirement 5: Recovery Analysis

**User Story:** As a fitness coach, I want to analyze heart rate recovery patterns, so that I can assess athlete cardiovascular fitness and training adaptation.

#### Acceptance Criteria

1. WHEN a rest period contains more than 5 strokes, THE System SHALL analyze it for recovery metrics
2. WHEN rest duration exceeds 30 seconds, THE System SHALL calculate heart rate drop and recovery rate
3. WHEN both start and end heart rates are valid, THE System SHALL compute recovery rate as HR_drop per minute
4. THE System SHALL export recovery data to a separate Rest_Recovery_Summary.csv file
5. WHEN calculating recovery rate, THE System SHALL use the formula: (start_HR - end_HR) / (duration_minutes)

### Requirement 6: Summary Report Generation

**User Story:** As a rowing program director, I want consolidated summary reports, so that I can review training effectiveness across multiple sessions and athletes.

#### Acceptance Criteria

1. WHEN generating work summaries, THE System SHALL include block-level metrics: average DPS, strokes at target, success rate, efficiency score, and distance
2. WHEN creating summary headers, THE System SHALL document configuration parameters including HR range, stroke rate range, and DPS target
3. WHEN sorting summary data, THE System SHALL order by date in descending order (most recent first)
4. THE System SHALL export summary data to Block_Work_Summary.csv with proper CSV formatting
5. WHEN no valid work blocks are found, THE System SHALL log an informative error message

### Requirement 7: Error Handling and Logging

**User Story:** As a system administrator, I want comprehensive error handling and logging, so that I can troubleshoot issues and ensure reliable data processing.

#### Acceptance Criteria

1. WHEN processing files, THE System SHALL wrap operations in try-catch blocks to handle errors gracefully
2. WHEN errors occur, THE System SHALL log detailed error messages including file name and exception details
3. WHEN logging events, THE System SHALL include timestamps and color-coded severity levels
4. THE System SHALL create a Log.txt file with all processing events and debug information
5. WHEN validation checks run, THE System SHALL verify output file creation and log results

### Requirement 8: Configuration Management

**User Story:** As a performance analyst, I want configurable analysis parameters, so that I can adapt the system for different training zones and athlete profiles.

#### Acceptance Criteria

1. THE System SHALL define heart rate work zone boundaries as configurable parameters (default: 124-138 BPM)
2. THE System SHALL define stroke rate work range as configurable parameters (default: 16-24 SPM)
3. THE System SHALL define minimum block distance as a configurable parameter (default: 500 meters)
4. THE System SHALL define DPS target threshold as a configurable parameter (default: 10.5 meters)
5. THE System SHALL define efficiency calculation bounds as configurable parameters (default: 0.020-0.035)

### Requirement 9: File System Integration

**User Story:** As an end user, I want seamless file system integration, so that I can process data from my existing Speed Coach workflow without manual file management.

#### Acceptance Criteria

1. WHEN determining file paths, THE System SHALL use the current user's environment variable ($env:USERNAME)
2. THE System SHALL read input files from the iCloud Drive Speed Coach exported-sessions directory
3. THE System SHALL write output files to the iCloud Drive AnalysedData/BlockAnalysis directory
4. WHEN output directories don't exist, THE System SHALL create them automatically
5. WHEN processing completes successfully, THE System SHALL open the output directory for user review