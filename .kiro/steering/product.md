# Product Overview

## Rowing Performance Analyzer

A PowerShell-based data analysis tool for rowing performance metrics. The system processes exported session data from Speed Coach devices to analyze rowing technique, efficiency, and recovery patterns.

### Key Features

- **Block Analysis**: Identifies and analyzes work intervals based on heart rate and stroke rate criteria
- **Efficiency Scoring**: Calculates performance efficiency using speed-to-heart rate ratios with configurable thresholds
- **Recovery Tracking**: Monitors heart rate recovery patterns during rest periods
- **Distance Per Stroke (DPS) Analysis**: Tracks stroke efficiency against target thresholds
- **Individual Stroke Tracking**: Exports detailed stroke-by-stroke data for each work block
- **Multi-format Export**: Generates CSV summaries and individual stroke files for comprehensive analysis

### Output Files

- **Block_Work_Summary.csv**: Primary analysis results with block-level metrics
- **Rest_Recovery_Summary.csv**: Recovery pattern data between work intervals
- **[SessionName]_Stroke_Details.csv**: Individual stroke data for each input session
- **Log.txt**: Execution logging and debugging information

### Target Users

Rowing coaches and athletes who use Speed Coach devices and need detailed performance analytics beyond basic session data.