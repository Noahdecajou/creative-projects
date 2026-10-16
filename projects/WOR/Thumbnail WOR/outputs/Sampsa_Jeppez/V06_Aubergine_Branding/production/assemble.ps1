$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V05_Natural_Set'
$refs=@('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'LocalBlend.cs') -Raw) -ReferencedAssemblies $refs
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'FinishBrand.cs') -Raw) -ReferencedAssemblies $refs
[LocalV5]::SkipCyan=$true
$regions=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants_V05_source.json') -Raw|ConvertFrom-Json
$checks=@()
foreach($row in $rows){
 $id=$row.id;$r=$regions[$id]
 $orig=[LocalV5]::Read((Join-Path $base ('masters\Sampsa_'+$id+'.png')))
 $im=[LocalV5]::Read((Join-Path $PSScriptRoot ('generated\'+$id+'.png')))
 if($im.Width-ne$orig.Width-or$im.Height-ne$orig.Height){throw ('Unaligned '+$id)}
 [BrandV6]::NormalizeYellow($im,[int[]]$r.box)
 if($r.redraw){[BrandV6]::Box($im,[int[]]$r.redraw.rect,[string]$r.redraw.text,[bool]$r.redraw.serif)}
 if($id-eq'14'){[BrandV6]::Box($im,[int[]]@(611,49,805,175),'Overfitting',$false)}
 $fabric=0
 
 foreach($f in $r.faces){[LocalV5]::Blend($im,$orig,[int[]]$f,$true,12)}
 foreach($f in $r.hands){[LocalV5]::Blend($im,$orig,[int[]]$f,$true,10)}
 if($id-like'11_*'){
  $gen=[LocalV5]::Read((Join-Path $PSScriptRoot ('generated\'+$id+'.png')))
  [ExtraV5]::Polygon($im,$gen,[int[]]@(1088,188,1112,185,1145,201,1166,220,1088,220));$gen.Dispose()
 }
 if($id-eq'19'){
  $gen=[LocalV5]::Read((Join-Path $PSScriptRoot ('generated\'+$id+'.png')))
  [ExtraV5]::Polygon($im,$gen,[int[]]@(910,192,926,202,941,214,955,229,966,246,925,250));$gen.Dispose()
 }
 if($id-eq'15'){
  $patch=Join-Path $PSScriptRoot 'generated/15_background_cleanup.png'
  if(Test-Path -LiteralPath $patch){$clean=[LocalV5]::Read($patch);[LocalV5]::Blend($im,$clean,[int[]]@(941,306,47,88),$false,3);$clean.Dispose()}
 }
 $faceChecks=@();foreach($f in $r.faces){$v=[BrandV6]::CheckFace($im,$orig,[int[]]$f,12);if($v[1]-ne0){throw ('Face drift '+$id)};$faceChecks+=[pscustomobject]@{Region=$f;ComparedPixels=$v[0];ChangedPixels=$v[1]}}
 $p=Join-Path $root ('masters\Sampsa_'+$id+'.png');$im.Save($p,[Drawing.Imaging.ImageFormat]::Png)
 $checks+=[pscustomobject]@{Id=$id;Width=$im.Width;Height=$im.Height;RestoredFaces=$faceChecks;FabricPixels=$fabric}
 $im.Dispose();$orig.Dispose();Write-Output ('Assembled '+$id)
}
$checks|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_preservation.json') -Encoding utf8


