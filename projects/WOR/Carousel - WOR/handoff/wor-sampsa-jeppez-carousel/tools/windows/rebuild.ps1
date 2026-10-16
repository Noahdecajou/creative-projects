# Rebuild the original typography from included raster inputs. Windows + PowerShell 7.
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This optional reconstruction requires Windows and PowerShell 7.' }
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputRoot = Join-Path $repoRoot 'build/windows-rebuilt'
if (Test-Path -LiteralPath $outputRoot) { throw 'Output exists; preserve this version and choose another output.' }
Add-Type -AssemblyName System.Drawing
$assemblies = @('System.Drawing.Common', 'System.Drawing.Primitives', 'System.Runtime.InteropServices', 'System.Runtime')
foreach ($optional in @('System.Private.Windows.GdiPlus', 'System.Private.Windows.Core')) {
    try { Add-Type -AssemblyName $optional -ErrorAction Stop; $assemblies += $optional } catch { }
}
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'FinishTypography.cs') -Raw) -ReferencedAssemblies $assemblies
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Grain.cs') -Raw) -ReferencedAssemblies $assemblies
foreach ($folder in @('Masters','PNG','JPEG')) {
    New-Item -ItemType Directory -Path (Join-Path $outputRoot $folder) -Force | Out-Null
}
$bold = Join-Path $repoRoot 'fonts/Poppins-Bold.ttf'
$semibold = Join-Path $repoRoot 'fonts/Poppins-SemiBold.ttf'
foreach ($number in 1..7) {
    $name = 'Slide-{0:00}' -f $number
    $approved = Join-Path $repoRoot ('history/v02/' + $name + '.png')
    $artwork = if ($number -in @(1,2,7)) { Join-Path $repoRoot ('masters/native/' + $name + '-imagegen-native.png') } else { $approved }
    $master = Join-Path $outputRoot ('Masters/' + $name + '-before-grain.png')
    [SampsaV4Type]::Prepare($artwork,$approved,$master,$number,$bold,$semibold)
    if ($number -ge 3) { $null = [SampsaV4Type]::VerifyProtected($approved,$master,$number) }
    $png = Join-Path $outputRoot ('PNG/' + $name + '.png')
    $jpeg = Join-Path $outputRoot ('JPEG/' + $name + '.jpg')
    [SampsaGrain3]::Render($master,$png,$jpeg,(20261013+$number))
    $null = [SampsaGrain3]::Verify($master,$png,(20261013+$number))
    Write-Output ($name + ': reconstructed; protected regions and grain verified.')
}
Write-Output ('Output: ' + $outputRoot)
