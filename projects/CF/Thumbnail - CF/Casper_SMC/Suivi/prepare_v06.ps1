$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot
foreach($d in @('Masters\V06','Exports_4K\V06','Apercus\V06','Apercus\V06\Controle_100pct','Suivi\V06')){$null=New-Item -ItemType Directory -Force -Path (Join-Path $root $d)}
$a=Join-Path $root 'Masters\V06'
foreach($f in @('Casper_front_photo.png','Riz_front_photo.png','laptop_plate.png','03_scene_retouch.png','05_scene_photo_test.png','07_scene_photo_test.png','08_scene_photo_test.png','chart_balance.png','chart_trend.png','chart_trigger.png','chart_profile.png','chart_accept.png')){Copy-Item -LiteralPath (Join-Path $root ('Masters\V05\'+$f)) -Destination (Join-Path $a $f)}
foreach($f in @('render_v05.ps1','style_v05.ps1')){$t=Get-Content -Raw -LiteralPath (Join-Path $root ('Suivi\V05\'+$f));$t=$t.Replace('V05','V06').Replace('v05','v06').Replace('V5Grain','V6Grain');if($f -eq 'render_v05.ps1'){$t=$t.Replace(". (Join-Path (Split-Path `$PSScriptRoot) 'drawing_functions.ps1')",". (Join-Path `$PSScriptRoot 'drawing_functions.ps1')").Replace("Person 'Casper_front_photo.png' 638 160 359","Person 'Casper_front_photo.png' 638 139 420").Replace("Panel 995 412 238 56 (C 224 12 17 22) `$false 23;Fit 'CASPER' 1006 424 216 33 43 `$WhiteColor 'Medium'","Panel 32 642 214 54 (C 224 12 17 22) `$false 12;Fit 'CASPER' 44 654 190 32 41 `$WhiteColor 'Medium'")};$t|Set-Content -LiteralPath (Join-Path $root ('Suivi\V06\'+$f.Replace('v05','v06'))) -Encoding utf8}
Copy-Item -LiteralPath (Join-Path $root 'Suivi\drawing_functions.ps1') -Destination (Join-Path $root 'Suivi\V06\drawing_functions.ps1')
$source=[System.Drawing.Bitmap]::FromFile((Join-Path $root 'Sources_HD\Riz\Riz_01-16-00.jpg'))
$crop=$source.Clone([System.Drawing.Rectangle]::new(1470,160,950,1120),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$crop.Save((Join-Path $a 'Riz_original_head_reference.png'));$crop.Dispose();$source.Dispose()
'V06 prepared without modifying V05 or original sources.'
