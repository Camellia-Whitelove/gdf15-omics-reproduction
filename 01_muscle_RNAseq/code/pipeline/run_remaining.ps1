$ErrorActionPreference = 'Stop'
$taskR = 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'
$taskProcesses = @()
foreach ($taskWorker in 1,2) {
    $taskProcesses += Start-Process -FilePath $taskR -ArgumentList @('work/gdf15/align_count_worker.R', "$taskWorker", '2') -WindowStyle Hidden -PassThru -RedirectStandardOutput "work/gdf15/align_worker$taskWorker.log" -RedirectStandardError "work/gdf15/align_worker$taskWorker.stderr.log"
}
foreach ($taskProcess in $taskProcesses) {
    $taskProcess.WaitForExit()
    if ($taskProcess.ExitCode -ne 0) { throw "Alignment worker process $($taskProcess.Id) failed; inspect its logs" }
}
& $taskR work/gdf15/collect_counts.R *> work/gdf15/collect_counts.log
if ($LASTEXITCODE -ne 0) { throw 'Count collection failed' }
& $taskR work/gdf15/analyze.R *> work/gdf15/analyze.log
if ($LASTEXITCODE -ne 0) { throw 'RNA statistics failed; inspect analyze.log' }
Write-Output 'ALL ALIGNMENT, COUNTING AND RNA STATISTICS COMPLETE'
