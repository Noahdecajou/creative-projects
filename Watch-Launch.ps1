$ErrorActionPreference = 'Stop'
$backupRoot = $PSScriptRoot
$backupPython = 'C:\Users\notti\AppData\Local\Programs\Python\Python313-32\python.exe'
$watchMutex = New-Object System.Threading.Mutex($false, 'Local\CreativeProjectsBackupLaunchWatcher')
$watchOwned = $false
try {
    $watchOwned = $watchMutex.WaitOne(0)
    if (-not $watchOwned) { exit 0 }
    $wasOpen = $false
    $retryAt = [DateTime]::MinValue
    while ($true) {
        $isOpen = @(Get-Process -Name ChatGPT -ErrorAction SilentlyContinue).Count -gt 0
        if ($isOpen -and ((-not $wasOpen) -or [DateTime]::UtcNow -ge $retryAt)) {
            try {
                & (Join-Path $backupRoot 'Backup.ps1')
                $retryAt = [DateTime]::MaxValue
            } catch {
                $retryAt = [DateTime]::UtcNow.AddMinutes(5)
            }
        }
        if (-not $isOpen) { $retryAt = [DateTime]::MinValue }
        $wasOpen = $isOpen
        Start-Sleep -Seconds 15
    }
} finally {
    if ($watchOwned) { $watchMutex.ReleaseMutex() }
    $watchMutex.Dispose()
}
