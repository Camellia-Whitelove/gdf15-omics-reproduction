$ErrorActionPreference = 'Stop'
$taskDataDir = Join-Path $PSScriptRoot 'data'
$taskRawDir = Join-Path $taskDataDir 'raw'
New-Item -ItemType Directory -Force -Path $taskRawDir | Out-Null
$taskRuns = Import-Csv -LiteralPath (Join-Path $taskDataDir 'ena_runs.tsv') -Delimiter "`t"
$taskCompleted = 0
foreach ($taskRun in ($taskRuns | Sort-Object sample_alias)) {
    $taskUrls = $taskRun.fastq_ftp -split ';'
    $taskSizes = $taskRun.fastq_bytes -split ';'
    $taskHashes = $taskRun.fastq_md5 -split ';'
    for ($taskIndex = 0; $taskIndex -lt $taskUrls.Count; $taskIndex++) {
        $taskName = ($taskUrls[$taskIndex] -split '/')[-1]
        $taskFinal = Join-Path $taskRawDir $taskName
        $taskPartial = "$taskFinal.part"
        if (-not (Test-Path -LiteralPath $taskFinal)) {
            Write-Output "Downloading $($taskRun.sample_alias): $taskName ($($taskSizes[$taskIndex]) bytes)"
            $taskMaxAttempts = 10
            $taskAttempt = 0
            $taskOk = $false
            while (-not $taskOk -and $taskAttempt -lt $taskMaxAttempts) {
                $taskAttempt++
                & curl.exe --noproxy '*' -L --fail --connect-timeout 30 --speed-limit 1024 --speed-time 60 --continue-at - --output $taskPartial --silent --show-error "https://$($taskUrls[$taskIndex])"
                if ($LASTEXITCODE -eq 0) { $taskOk = $true } else { Write-Output "Attempt $taskAttempt/$taskMaxAttempts failed (curl exit $LASTEXITCODE); retrying in 15s..."; Start-Sleep -Seconds 15 }
            }
            if (-not $taskOk) { throw "Download failed after $taskMaxAttempts attempts (curl exit $LASTEXITCODE): $taskName. Pausing; partial file retained." }
            if ((Get-Item -LiteralPath $taskPartial).Length -ne [long]$taskSizes[$taskIndex]) { throw "Size mismatch: $taskName. Pausing." }
            $taskActualHash = (Get-FileHash -LiteralPath $taskPartial -Algorithm MD5).Hash.ToLowerInvariant()
            if ($taskActualHash -ne $taskHashes[$taskIndex]) { throw "MD5 mismatch: $taskName. Pausing." }
            Move-Item -LiteralPath $taskPartial -Destination $taskFinal
        } else {
            if ((Get-Item -LiteralPath $taskFinal).Length -ne [long]$taskSizes[$taskIndex]) { throw "Existing file size mismatch: $taskName. Pausing." }
            if ((Get-FileHash -LiteralPath $taskFinal -Algorithm MD5).Hash.ToLowerInvariant() -ne $taskHashes[$taskIndex]) { throw "Existing file MD5 mismatch: $taskName. Pausing." }
        }
        $taskCompleted++
        Write-Output "Verified $taskCompleted/32: $taskName"
    }
}
Write-Output 'All 32 FASTQ files downloaded and verified. Data download stage complete.'
