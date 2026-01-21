# Debug script to examine CSV structure
$testFile = "C:\Users\patrickm\iCloudDrive\Speed coach\exported-sessions\SpdCoach 20251109 1230PM.csv"

Write-Host "Testing file: $testFile"

if (Test-Path $testFile) {
    $content = Get-Content $testFile -Raw -Encoding UTF8
    $lines = $content -split '\r?\n'
    
    Write-Host "Total lines: $($lines.Count)"
    
    # Search for any line containing "stroke" (case insensitive)
    Write-Host "`nSearching for lines containing 'stroke':"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "stroke" -or $lines[$i] -match "Stroke") {
            Write-Host "Line $i`: $($lines[$i])"
        }
    }
    
    # Search for any line containing "Per" 
    Write-Host "`nSearching for lines containing 'Per':"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "Per") {
            Write-Host "Line $i`: $($lines[$i])"
        }
    }
    
    # Show lines around the end to see structure
    Write-Host "`nLast 10 lines:"
    $start = [Math]::Max(0, $lines.Count - 10)
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim().Length -gt 0) {
            Write-Host "Line $i`: $($lines[$i])"
        }
    }
}