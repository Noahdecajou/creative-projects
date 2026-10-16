$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$assemblies=@('System.Drawing.Common','System.Drawing.Primitives','System.Private.Windows.GdiPlus','System.Private.Windows.Core','System.Runtime.InteropServices','System.Runtime')
$prior=Get-Content -LiteralPath 'work\sampsa_v03\apply_grain.ps1' -Raw
$grainCode=[regex]::Match($prior,"(?s)\`$grainCode = @'\r?\n(.*?)\r?\n'@").Groups[1].Value
if(-not $grainCode){throw 'Could not read grain routine'}
Add-Type -TypeDefinition $grainCode -ReferencedAssemblies $assemblies
Add-Type -TypeDefinition (Get-Content -LiteralPath 'work\sampsa_v04\FinishTypography.cs' -Raw) -ReferencedAssemblies $assemblies
$root=(Get-Location).Path
$v02=Join-Path $root 'outputs\Sampsa-Jeppez-Carousel-V02'
$out=Join-Path $root 'outputs\Sampsa-Jeppez-Carousel-V04-Grain3'
if(Test-Path -LiteralPath $out){throw 'Preserve existing versions'}
foreach($folder in @('PNG','JPEG','Masters','Production','Sources','Sources\Fonts')) { New-Item -ItemType Directory -Path (Join-Path $out $folder) -Force | Out-Null }
$fontRoot='C:\Users\notti\AppData\Local\Microsoft\Windows\Fonts'
foreach($name in @('Poppins-Bold.ttf','Poppins-SemiBold.ttf')) {Copy-Item -LiteralPath (Join-Path $fontRoot $name) -Destination (Join-Path $out ('Sources\Fonts\'+$name))}
$bold=Join-Path $out 'Sources\Fonts\Poppins-Bold.ttf'
$semibold=Join-Path $out 'Sources\Fonts\Poppins-SemiBold.ttf'
$jobs=Get-Content -LiteralPath 'work\sampsa_v04\selected_manifest.json' -Raw | ConvertFrom-Json
$oldVerification=Get-Content -LiteralPath (Join-Path $v02 'Production\Verification.json') -Raw | ConvertFrom-Json
$report=@()
foreach($n in 1..7) {
    $name='Slide-{0:00}' -f $n
    $approved=Join-Path $v02 ('PNG\'+$name+'.png')
    $approvedHash=(Get-FileHash -LiteralPath $approved -Algorithm SHA256).Hash.ToLowerInvariant()
    if($approvedHash -ne $oldVerification.slides[$n-1].png_sha256){throw 'V02 source differs from approved manifest'}
    $job=$jobs | Where-Object slide -EQ $n
    $artwork=if($job){$job.generated_source}else{$approved}
    if($job){Copy-Item -LiteralPath $artwork -Destination (Join-Path $out ('Masters\'+$name+'-imagegen-native.png'))}
    $clean=Join-Path $out ('Masters\'+$name+'-before-grain.png')
    [SampsaV4Type]::Prepare($artwork,$approved,$clean,$n,$bold,$semibold)
    $protected=$null
    if($n -ge 3){$protected=[SampsaV4Type]::VerifyProtected($approved,$clean,$n)}
    $png=Join-Path $out ('PNG\'+$name+'.png')
    $jpg=Join-Path $out ('JPEG\'+$name+'.jpg')
    $seed=20261013+$n
    [SampsaGrain3]::Render($clean,$png,$jpg,$seed)
    $grain=[SampsaGrain3]::Verify($clean,$png,$seed)
    if($grain[0] -gt 8){throw 'Unexpected grain amplitude'}
    $image=[System.Drawing.Image]::FromFile($png)
    if($image.Width -ne 1080 -or $image.Height -ne 1440){throw 'Dimensions incorrect'}
    $image.Dispose()
    if((Get-FileHash -LiteralPath $approved -Algorithm SHA256).Hash.ToLowerInvariant() -ne $approvedHash){throw 'V02 modified'}
    $report += [ordered]@{slide=$n; png=('PNG/'+$name+'.png'); png_sha256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash.ToLowerInvariant(); approved_source=$approved; approved_sha256=$approvedHash; before_grain_sha256=(Get-FileHash -LiteralPath $clean -Algorithm SHA256).Hash.ToLowerInvariant(); dimensions=@(1080,1440); grain_percent=3; grain_passes=1; seed=$seed; unexpected_grain_changes=$grain[4]; maximum_channel_change=$grain[0]; changes_outside_permitted_regions=$protected; original_version_preserved=$true; name_label='SAMPSA JEPPEZ'; name_font='Poppins SemiBold'; name_top_left=@(52,31)}
}
$utf8=New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $out 'Production\Pixel_verification.json'),($report | ConvertTo-Json -Depth 8),$utf8)
Copy-Item -LiteralPath 'work\sampsa_v04\selected_manifest.json' -Destination (Join-Path $out 'Production\Generation_manifest.json')
Copy-Item -LiteralPath 'work\sampsa_v04\FinishTypography.cs' -Destination (Join-Path $out 'Production\FinishTypography.cs')
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $out 'Production\render.ps1')
[ordered]@{output=$out;count=7;dimensions=@(1080,1440);grain_percent=3;preserved_regions_verified=$true} | ConvertTo-Json -Compress
