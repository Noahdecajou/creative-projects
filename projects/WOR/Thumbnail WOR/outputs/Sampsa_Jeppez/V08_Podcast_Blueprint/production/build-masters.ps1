$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V07_Selected_Titles'
$refs=@('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')
foreach($f in @('LocalBlend.cs','FinishBrand.cs','SkinV8.cs')){Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot $f) -Raw) -ReferencedAssemblies $refs}
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Raw|ConvertFrom-Json
$cfg=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Edit_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$faceRegions=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$report=@()
foreach($row in $rows){
 $id=$row.id
 if($id-eq'10'){
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'generated/10.png') -Destination (Join-Path $root 'masters/Sampsa_10.png')
  $report+=[pscustomobject]@{Id=$id;Mode='Recomposition autorisee; portraits guides par les photos HD originales';RestoredFaces=@();OutsideChangedPixels=$null};continue
 }
 if(!$row.changed){
  $same=(Get-FileHash -LiteralPath (Join-Path $root ('masters/Sampsa_'+$id+'.png'))).Hash-eq(Get-FileHash -LiteralPath (Join-Path $base ('masters/Sampsa_'+$id+'.png'))).Hash
  if(!$same){throw ('Inherited master mismatch '+$id)}
  $report+=[pscustomobject]@{Id=$id;Mode='Inherited';ByteIdenticalToV07=$same;RestoredFaces=@();OutsideChangedPixels=0};continue
 }
 $c=$cfg[$id]
 $original=[LocalV5]::Read((Join-Path $base ('masters/Sampsa_'+$id+'.png')))
 $im=[LocalV5]::Read((Join-Path $base ('masters/Sampsa_'+$id+'.png')))
 $gen=[LocalV5]::Read((Join-Path $PSScriptRoot ('generated/'+$c.gen+'.png')))
 $ri=0;foreach($r in $c.rects){$feather=4;if($c.ContainsKey('feathers')){$feather=$c.feathers[$ri]};[LocalV5]::FeatherSides=$null;if($c.ContainsKey('edgeFeathers')){[LocalV5]::FeatherSides=[int[]]$c.edgeFeathers[$ri]};[LocalV5]::Blend($im,$gen,[int[]]$r,$false,$feather);$ri++}
 foreach($p in $c.polys){[ExtraV5]::Polygon($im,$original,[int[]]$p)}
 $skin=0;if($c.ContainsKey('skin')){$skin=[SkinV8]::Preserve($im,$original,[int[]]$c.skin)}
 $outside=[LocalV5]::OutsideChanged($im,$original,[int[][]]$c.rects)
 if($outside-ne0){throw ('Edits outside requested region '+$id)}
 $faces=@();foreach($r in $faceRegions[$id].faces){$check=[BrandV6]::CheckFace($im,$original,[int[]]$r,18);if($check[1]-ne0){throw ('Face changed '+$id)};$faces+=[pscustomobject]@{Region=$r;CheckedPixels=$check[0];ChangedPixels=$check[1]}}
 $im.Save((Join-Path $root ('masters/Sampsa_'+$id+'.png')),[Drawing.Imaging.ImageFormat]::Png)
 $report+=[pscustomobject]@{Id=$id;Mode='Localized';OutsideChangedPixels=$outside;HeadlineOrPropRegions=$c.rects;RestoredFaces=$faces;ProtectedHandSkinPixels=$skin}
 $im.Dispose();$original.Dispose();$gen.Dispose();Write-Output ('Built '+$id)
}
$report|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_preservation.json') -Encoding utf8



