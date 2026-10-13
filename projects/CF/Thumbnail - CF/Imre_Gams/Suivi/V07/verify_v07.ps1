$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot)
$records=@()
foreach($id in @('03','05','07')){
 $f=Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V06') -Filter ($id+'_*_master.png') | Select-Object -First 1
 $new=Join-Path (Join-Path $root 'Masters\V07') $f.Name
 if((Get-FileHash -LiteralPath $f.FullName).Hash -ne (Get-FileHash -LiteralPath $new).Hash){throw ('Master changed: '+$f.Name)}
 $records+=[pscustomobject]@{File=$f.Name;Type='Unchanged clean master';IdenticalToV06=$true}
}
foreach($name in @('Imre_direct_camera.png','Riz_original_cutout.png','03_plate.png','05_plate.png','07_plate.png','08_plate.png')){
 $old=Join-Path (Join-Path $root 'Masters\V06') $name
 $new=Join-Path (Join-Path $root 'Masters\V07') $name
 if((Get-FileHash -LiteralPath $old).Hash -ne (Get-FileHash -LiteralPath $new).Hash){throw ('Photo asset changed: '+$name)}
 $records+=[pscustomobject]@{File=$name;Type='Photo asset';IdenticalToV06=$true}
}
$records | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Preservation_V06_V07.csv')
$oldGeometry=Import-Csv -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V06\Typography_geometry.csv') | Where-Object {[int]$_.Image -ne 6}
$newGeometry=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry.csv') | Where-Object {[int]$_.Image -ne 6}
$diff=Compare-Object $oldGeometry $newGeometry -Property Image,Text,X,Y,Width,Height,Font,Weight
if($diff){$diff | Format-Table;throw 'Unrequested typography change'}
$render=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'render_v07.ps1')
if($render -notmatch '\[ThumbnailNoise\]::Apply\(\$canvas,3\.0'){throw 'Noise must be 3 percent'}
if($render -match '\[ThumbnailNoise\]::Apply\(\$canvas,5\.0'){throw 'Unexpected previous noise setting'}
Write-Output 'VERIFIED: clean inherited masters and photo assets identical; preserved typography unchanged; final noise set to 3 percent.'
