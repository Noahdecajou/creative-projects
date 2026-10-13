$ErrorActionPreference = 'Stop'
$backupRoot = $PSScriptRoot
$backupPython = 'C:\Users\notti\AppData\Local\Programs\Python\Python313-32\python.exe'
& $backupPython (Join-Path $backupRoot 'backup.py')
if ($LASTEXITCODE -ne 0) { throw 'Sauvegarde echouee. Consulter .local/last-status.json et .local/backup.log.' }
