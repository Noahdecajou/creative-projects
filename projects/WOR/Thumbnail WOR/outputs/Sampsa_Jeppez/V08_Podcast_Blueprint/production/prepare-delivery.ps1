$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V07_Selected_Titles'
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Raw|ConvertFrom-Json
$r=$rows|Where-Object id -eq '10'
$r.source='Sampsa_16-13-00-00.jpg';$r.rizSource='Riz_23-53-02-12.jpg';$r.direct=$false
foreach($r in $rows){$note=switch($r.id){'10' {'Conversation podcast, deux micros, geste de Sampsa et auditeurs flous au premier plan.'};'11_Green' {'Bougie verte, rouleau de recherche et schémas de trading sur la table.'};'12' {'Titre agrandi et descendu vers les intervenants.'};'13_Blur10' {'Titre agrandi et descendu ; flou A conservé.'};'13_Blur15' {'Titre agrandi et descendu ; flou B conservé.'};default {'Version V07 conservée.'}};$r|Add-Member -NotePropertyName revision -NotePropertyValue $note -Force}
$rows|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Encoding utf8
$regions=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$regions['10'].faces=@(@(354,295,230,240),@(1134,277,224,272))
$regions|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Encoding utf8
foreach($name in @('export.ps1','finish-delivery.ps1','verify-delivery.ps1','package.ps1')){
 $s=Get-Content -LiteralPath (Join-Path $base ('production/'+$name)) -Raw
 $s=$s.Replace('V07_','V08_').Replace('avant_V06','avant_V07').Replace('V06_Aubergine_Branding','V07_Selected_Titles').Replace('V07 client title applied','V08 client revisions applied')
 $s=$s.Replace('Count-ne14','Count-ne13').Replace('Expected 14','Expected 13').Replace('/14 :','/13 :').Replace('Planche_14_variantes','Planche_13_variantes').Replace('Variants=14','Variants=13').Replace('42 preview files and 14 PNG paths verified','39 preview files and 13 PNG paths verified').Replace("ExportSHA256='14 verified'","ExportSHA256='13 verified'").Replace('_14_Thumbnails','_13_Thumbnails')
 $s|Set-Content -LiteralPath (Join-Path $PSScriptRoot $name) -Encoding utf8
}
# Unchanged exports are inherited byte-for-byte, including their existing grain.
$previous=Get-Content -LiteralPath (Join-Path $base 'production/Verification_exports.json') -Raw|ConvertFrom-Json
$report=@()
foreach($r in $rows|Where-Object {!$_.changed}){
 $entry=$previous|Where-Object Id -eq $r.id
 $oldName=$entry.Filename;$entry.Filename=$oldName.Replace('V07_','V08_')
 Copy-Item -LiteralPath (Join-Path $base ('exports_4K/'+$oldName)) -Destination (Join-Path $root ('exports_4K/'+$entry.Filename))
 foreach($size in @(1280,320)){Copy-Item -LiteralPath (Join-Path $base ('apercus/Sampsa_'+$r.id+'_'+$size+'.jpg')) -Destination (Join-Path $root 'apercus')}
 $report+=$entry
}
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_exports.json') -Encoding utf8
$html=Get-Content -LiteralPath (Join-Path $base 'production/gallery-template.html') -Raw
$html=$html.Replace('V07','__NEW_VERSION__').Replace('V06','V07').Replace('__NEW_VERSION__','V08')
$html=$html.Replace('Quatre accroches. Quatorze variantes.','Plus de présence. Plus de lisibilité.').Replace('Tes quatre textes répartis sur les 14 variantes retenues. Décors aubergine, encadrés jaunes et compositions conservés. Clique sur une image pour comparer avec la V07.','Cinq retouches dans une sélection de 13 thumbnails : conversation podcast, bougie verte et recherche, titres Hybrid Trader agrandis. Clique sur une image pour comparer avec la V07.')
$html=$html.Replace('14 variantes','13 variantes').Replace('Tout · 14','Tout · 13').Replace('_14_Thumbnails','_13_Thumbnails').Replace('Planche_14_variantes','Planche_13_variantes')
$html=$html.Replace('href="#colors">Bougie verte / jaune','href="#colors">La bougie et son blueprint')
$html=$html.Replace('Les deux bougies, avec le même traitement aubergine et jaune.','La bougie verte révèle le graphique ; les feuilles de recherche prolongent le visuel sur la table.')
$html=$html.Replace('<div><img src="apercus/Sampsa_11_Green_1280.jpg"','<div><img src="apercus/avant_V07/Sampsa_11_Green_1280.jpg"').Replace('<p>11 · Verte</p>','<p>V07 · Avant</p>')
$html=$html.Replace('apercus/Sampsa_11_Yellow_1280.jpg','apercus/Sampsa_11_Green_1280.jpg').Replace('bougie jaune','bougie verte et recherche').Replace('<p>11 · Jaune</p>','<p>V08 · Blueprint</p>')
$html=$html.Replace('<button data-filter="solo"','<button data-filter="changed" aria-pressed="false">Les 5 retouches</button><button data-filter="solo"')
$html=$html.Replace("filter==='all'||filter==='duo'","filter==='all'||filter==='changed'&&r.changed||filter==='duo'")
$html=$html.Replace('${old?''V07 · Avant'':''V08 · Aubergine''}', '${old?''V07 · Avant'':r.changed?''V08 · Retouchée'':''V07 · Conservée''}')
$html=$html.Replace("document.querySelector('#evidence').textContent='Origine du texte : '+r.evidence;","document.querySelector('#evidence').textContent=r.revision+' Origine du texte : '+r.evidence;")
$html|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'gallery-template.html') -Encoding utf8
Write-Output 'Prepared V08 delivery scripts, metadata, gallery template and eight inherited exports.'
