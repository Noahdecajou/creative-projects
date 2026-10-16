$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$version='V08_StyleNaturel'
foreach($folder in @('Masters','Exports_4K','Apercus','Suivi')){$null=New-Item -ItemType Directory -Force -Path (Join-Path $root ($folder+'\'+$version))}
$null=New-Item -ItemType Directory -Force -Path (Join-Path $root ('Apercus\'+$version+'\Controle_100pct'))
$null=New-Item -ItemType Directory -Force -Path (Join-Path $root 'References\StyleNaturel_V08')
$refs=foreach($name in @('_of876Yi6V4-HD.jpg','Xu_Hpqz0pgQ-HD.jpg','8Tf6O01B_UU-HD.jpg')){$src=Join-Path 'C:\Users\notti\Downloads' $name;$dst=Join-Path $root ('References\StyleNaturel_V08\'+$name);Copy-Item -LiteralPath $src -Destination $dst;[pscustomobject]@{File=$name;Source=$src;SHA256=(Get-FileHash -LiteralPath $dst).Hash;Role='Composition, natural daylight interview photograph, white/yellow lower-third type only'}}
$refs|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $root ('Suivi\'+$version+'\References_manifest.csv'))
Copy-Item -LiteralPath (Join-Path $root 'Apercus\V04\Casper_gaze_local_patch.png') -Destination (Join-Path $root ('Masters\'+$version+'\Casper_head_photo_reference.png'))
Copy-Item -LiteralPath (Join-Path $root 'Apercus\V06\Riz_local_gaze_patch.png') -Destination (Join-Path $root ('Masters\'+$version+'\Riz_head_photo_reference.png'))
Copy-Item -LiteralPath (Join-Path $root 'Suivi\V07\drawing_functions.ps1') -Destination (Join-Path $root ('Suivi\'+$version+'\drawing_functions.ps1'))
'One new direction prepared. Existing eight-thumbnail versions unchanged.'
