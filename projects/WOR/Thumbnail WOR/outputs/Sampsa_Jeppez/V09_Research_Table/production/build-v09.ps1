$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V08_Podcast_Blueprint'
foreach($f in @('LocalBlend.cs','FinishBrand.cs','Preservation_regions.json')){Copy-Item -LiteralPath (Join-Path $base ('production/'+$f)) -Destination (Join-Path $PSScriptRoot $f)}
$refs=@('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')
foreach($f in @('LocalBlend.cs','FinishBrand.cs')){Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot $f) -Raw) -ReferencedAssemblies $refs}
$rows=Get-Content -LiteralPath (Join-Path $base 'production/Variants.json') -Raw|ConvertFrom-Json
foreach($r in $rows){$r.changed=$r.id-eq'11_Green';$r.revision=if($r.changed){'Recherches superposées sur la table, feuille soulevée par Riz avec dos vierge visible, sculptures de bougies supprimées.'}else{'Version V08 conservée.'}}
$rows|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Encoding utf8
foreach($r in $rows){Copy-Item -LiteralPath (Join-Path $base ('masters/Sampsa_'+$r.id+'.png')) -Destination (Join-Path $root 'masters');Copy-Item -LiteralPath (Join-Path $base ('apercus/Sampsa_'+$r.id+'_1280.jpg')) -Destination (Join-Path $root 'apercus/avant_V08')}
Get-ChildItem -LiteralPath (Join-Path $base 'sources_HD') -File|Copy-Item -Destination (Join-Path $root 'sources_HD')
$original=[LocalV5]::Read((Join-Path $base 'masters/Sampsa_11_Green.png'))
$im=[LocalV5]::Read((Join-Path $base 'masters/Sampsa_11_Green.png'))
$gen=[LocalV5]::Read((Join-Path $PSScriptRoot 'generated/11_Green.png'))
$rects=@(@(815,365,175,265),@(0,520,1672,421),@(65,490,135,160),@(1480,490,130,160))
$feathers=@(16,20,15,15)
for($i=0;$i-lt$rects.Count;$i++){[LocalV5]::Blend($im,$gen,[int[]]$rects[$i],$false,$feathers[$i])}
$correction=[LocalV5]::Read((Join-Path $PSScriptRoot 'generated/11_Green_final.png'))
$correctionRects=@(@(0,490,240,410),@(1460,490,212,410),@(465,540,395,260))
for($i=0;$i-lt$correctionRects.Count;$i++){[LocalV5]::Blend($im,$correction,[int[]]$correctionRects[$i],$false,8)}
$correction.Dispose();$rects+=$correctionRects
$regions=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$faces=@();foreach($r in $regions['11_Green'].faces){$c=[BrandV6]::CheckFace($im,$original,[int[]]$r,18);if($c[1]-ne0){throw 'Protected face pixels changed'};$faces+=[pscustomobject]@{Region=$r;CheckedPixels=$c[0];ChangedPixels=$c[1]}}
$outside=[LocalV5]::OutsideChanged($im,$original,[int[][]]$rects);if($outside-ne0){throw 'Pixels changed outside edit zones'}
$im.Save((Join-Path $root 'masters/Sampsa_11_Green.png'),[Drawing.Imaging.ImageFormat]::Png)
$im.Dispose();$original.Dispose();$gen.Dispose()
@([pscustomobject]@{Id='11_Green';Mode='Localized';OutsideChangedPixels=$outside;RestoredFaces=$faces;EditRegions=$rects;Title='Unchanged from V08'})|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_preservation.json') -Encoding utf8
foreach($name in @('export.ps1','finish-delivery.ps1','verify-delivery.ps1','package.ps1')){
 $s=Get-Content -LiteralPath (Join-Path $base ('production/'+$name)) -Raw
 $s=$s.Replace('V08_','V09_').Replace('avant_V07','avant_V08').Replace('V07_Selected_Titles','V08_Podcast_Blueprint').Replace('V08 client revisions applied','V09 client revision applied')
 $s|Set-Content -LiteralPath (Join-Path $PSScriptRoot $name) -Encoding utf8
}
$previous=Get-Content -LiteralPath (Join-Path $base 'production/Verification_exports.json') -Raw|ConvertFrom-Json
$report=@()
foreach($r in $rows|Where-Object {!$_.changed}){
 $entry=$previous|Where-Object Id -eq $r.id
 $oldName=$entry.Filename;$entry.Filename=$oldName.Replace('V08_','V09_')
 Copy-Item -LiteralPath (Join-Path $base ('exports_4K/'+$oldName)) -Destination (Join-Path $root ('exports_4K/'+$entry.Filename))
 foreach($size in @(1280,320)){Copy-Item -LiteralPath (Join-Path $base ('apercus/Sampsa_'+$r.id+'_'+$size+'.jpg')) -Destination (Join-Path $root 'apercus')}
 $report+=$entry
}
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_exports.json') -Encoding utf8
$html=Get-Content -LiteralPath (Join-Path $base 'production/gallery-template.html') -Raw
$html=$html.Replace('V08','__NEW_VERSION__').Replace('V07','V08').Replace('__NEW_VERSION__','V09')
$html=$html.Replace('Plus de présence. Plus de lisibilité.','La recherche prend toute la table.').Replace('Cinq retouches dans une sélection de 13 thumbnails : conversation podcast, bougie verte et recherche, titres Hybrid Trader agrandis. Clique sur une image pour comparer avec la V08.','La référence 11 évolue : une vingtaine de feuilles superposées, Riz qui en soulève une avec son dos vierge tourné vers nous, et Sampsa qui pointe un graphique. Les sculptures de bougies sont supprimées. Les 12 autres thumbnails sont conservés.')
$html=$html.Replace('Les 5 retouches','La retouche · Réf. 11').Replace('La bougie et son blueprint','Avant / après · Réf. 11').Replace('La bougie verte révèle le graphique ; les feuilles de recherche prolongent le visuel sur la table.','Riz examine une feuille dont nous voyons le dos vierge ; Sampsa pointe un graphique parmi les recherches.').Replace('V09 · Blueprint','V09 · Recherche sur table')
$html=$html.Replace("r.id.includes('Green')?' · Verte'","r.id.includes('Green')?' · Recherche'").Replace('bougie verte et recherche','recherches sur table').Replace('bougie verte','version précédente')
$html=$html.Replace("let filter='all'","let filter='changed'").Replace('data-filter="all" aria-pressed="true"','data-filter="all" aria-pressed="false"').Replace('data-filter="changed" aria-pressed="false"','data-filter="changed" aria-pressed="true"')
$html|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'gallery-template.html') -Encoding utf8
Write-Output 'V09 built: one localized revision, two protected faces, twelve inherited exports.'
