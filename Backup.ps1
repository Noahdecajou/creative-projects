$ErrorActionPreference = 'Stop'
$backupRoot = $PSScriptRoot
$backupPython = 'C:\Users\notti\AppData\Local\Programs\Python\Python313-32\python.exe'
$encryptedAuth = Join-Path $backupRoot '.local\github-auth.dpapi'
$previousToken = $env:GH_TOKEN
try {
    if (Test-Path -LiteralPath $encryptedAuth) {
        $secureToken = (Get-Content -LiteralPath $encryptedAuth -Raw).Trim() | ConvertTo-SecureString
        $tokenPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        try { $env:GH_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPointer) }
    }
    & $backupPython (Join-Path $backupRoot 'backup.py')
    if ($LASTEXITCODE -ne 0) { throw 'Sauvegarde echouee. Consulter .local/last-status.json et .local/backup.log.' }
} finally { $env:GH_TOKEN = $previousToken }
