param([string]$Rscript = 'Rscript')
$ErrorActionPreference = 'Stop'
$taskRepo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Push-Location -LiteralPath $taskRepo
try {
  & $Rscript (Join-Path $taskRepo 'run.R') muscle-resume
  if ($LASTEXITCODE -ne 0) { throw 'A stage failed; inspect the error above.' }
}
finally { Pop-Location }
