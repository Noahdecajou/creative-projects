param([Parameter(Mandatory=$true)][string]$Message)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
function Invoke-Git {
    param([string[]]$GitArgs)
    $result = & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw ('Git a echoue : ' + ($GitArgs -join ' ')) }
    return $result
}
$target = 'https://github.com/Noahdecajou/wor-studio.git'
if ((Invoke-Git @('remote','get-url','origin')) -ne $target) { throw 'Depot distant non autorise.' }
if ((Invoke-Git @('branch','--show-current')) -ne 'main') { throw 'Utiliser la branche main ou traiter la branche explicitement.' }
$allowed = @(Get-Content -LiteralPath 'sync-allowlist.json' -Raw | ConvertFrom-Json)
$tracked = @(Invoke-Git @('ls-files'))
foreach ($name in $tracked) { if ($allowed -notcontains $name) { throw ('Fichier suivi hors perimetre : ' + $name) } }
Invoke-Git (@('add','--') + $allowed) | Out-Null
$staged = @(Invoke-Git @('diff','--cached','--name-only'))
foreach ($name in $staged) { if ($allowed -notcontains $name) { throw ('Fichier indexe hors perimetre : ' + $name) } }
Invoke-Git @('diff','--cached','--check') | Out-Null
if ($staged.Count -gt 0) { Invoke-Git @('commit','-m',$Message) | Out-Null }
Invoke-Git @('push','-u','origin','main')
Write-Output 'WOR Studio synchronise. Donnees locales et conversations exclues.'
