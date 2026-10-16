$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V06_Aubergine_Branding'
$refs=@('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'LocalBlend.cs') -Raw) -ReferencedAssemblies $refs
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'FinishBrand.cs') -Raw) -ReferencedAssemblies $refs
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Raw|ConvertFrom-Json
$cfg=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Edit_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$faceRegions=Get-Content -LiteralPath (Join-Path $base 'production/Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
Copy-Item -LiteralPath (Join-Path $base 'production/Preservation_regions.json') -Destination $PSScriptRoot
$report=@()
foreach($row in $rows){
 $id=$row.id;$c=$cfg[$id];$genId=$id;if($c.ContainsKey('gen')){$genId=$c.gen}
 $original=[LocalV5]::Read((Join-Path $base ('masters/Sampsa_'+$id+'.png')))
 $im=[LocalV5]::Read((Join-Path $base ('masters/Sampsa_'+$id+'.png')))
 $gen=[LocalV5]::Read((Join-Path $PSScriptRoot ('generated/'+$genId+'.png')))
 foreach($r in $c.rects){[LocalV5]::Blend($im,$gen,[int[]]$r,$false,6)}
 foreach($poly in $c.polys){[ExtraV5]::Polygon($im,$original,[int[]]$poly)}
 $outside=[LocalV5]::OutsideChanged($im,$original,[int[][]]$c.rects)
 if($outside-ne0){throw ('Unexpected edits outside headline: '+$id)}
 $faces=@();foreach($r in $faceRegions[$id].faces){$check=[BrandV6]::CheckFace($im,$original,[int[]]$r,0);if($check[1]-ne0){throw ('Face modified: '+$id)};$faces+=[pscustomobject]@{Region=$r;CheckedPixels=$check[0];ChangedPixels=$check[1]}}
 $hands=@();foreach($r in $faceRegions[$id].hands){$check=[BrandV6]::CheckFace($im,$original,[int[]]$r,0);if($check[1]-ne0){throw ('Hand modified: '+$id)};$hands+=[pscustomobject]@{Region=$r;CheckedPixels=$check[0];ChangedPixels=$check[1]}}
 $im.Save((Join-Path $root ('masters/Sampsa_'+$id+'.png')),[Drawing.Imaging.ImageFormat]::Png)
 $report+=[pscustomobject]@{Id=$id;GeneratedSource=$genId;HeadlineRegions=$c.rects;OutsideChangedPixels=$outside;RestoredFaces=$faces;ProtectedHands=$hands;AllNonHeadlinePixelsIdentical=$true}
 $im.Dispose();$original.Dispose();$gen.Dispose()
 Write-Output ('Built '+$id)
}
$report|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_preservation.json') -Encoding utf8
