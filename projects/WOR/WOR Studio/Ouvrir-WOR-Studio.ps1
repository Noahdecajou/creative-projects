$ErrorActionPreference = 'Stop'
$studioRoot = $PSScriptRoot
$studioUrl = 'http://127.0.0.1:8765'
$studioReady = $false
try {
    $studioHealth = Invoke-RestMethod -Uri "$studioUrl/api/health" -TimeoutSec 2
    $studioReady = $studioHealth.app -eq 'WOR Studio'
} catch {}
if (-not $studioReady) {
    $studioNode = (Get-Command node -ErrorAction Stop).Source
    if (-not (Test-Path -LiteralPath (Join-Path $studioRoot 'node_modules/pdf-lib/package.json'))) {
        Push-Location -LiteralPath $studioRoot
        try {
            & npm.cmd install --package-lock=false --ignore-scripts --no-audit --no-fund
            if ($LASTEXITCODE -ne 0) { throw 'Installation PDF impossible.' }
        } finally { Pop-Location }
    }

    Start-Process -FilePath $studioNode -ArgumentList ('"' + (Join-Path $studioRoot 'server.mjs') + '"') -WorkingDirectory $studioRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $studioRoot 'data\server.log') -RedirectStandardError (Join-Path $studioRoot 'data\server-error.log')
    for ($studioAttempt = 0; $studioAttempt -lt 20; $studioAttempt++) {
        Start-Sleep -Milliseconds 250
        try {
            $studioHealth = Invoke-RestMethod -Uri "$studioUrl/api/health" -TimeoutSec 1
            if ($studioHealth.app -eq 'WOR Studio') { $studioReady = $true; break }
        } catch {}
    }
}
if ($studioReady) { Start-Process $studioUrl }
else { Write-Host 'Le studio ne peut pas démarrer. Ouvrez dist\index.html pour utiliser le mode navigateur.'; Read-Host 'Entrée pour fermer' }
