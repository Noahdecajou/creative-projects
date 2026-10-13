Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=$PSScriptRoot
$delivery=Join-Path $root 'Livraison'
New-Item -ItemType Directory -Force -Path $delivery,(Join-Path $root 'Exports_4K') | Out-Null
$boardMinutes=@(14..28)+@(34..42)+@(44..50)+@(52..56)+@(58..63)+@(65..68)+@(71..76)+@(79..82)+@(84..87)
$boardSelect=Join-Path $root 'Selections\Tableau'
foreach($m in $boardMinutes){$tc='{0:00}-{1:00}-00' -f [math]::Floor($m/60),($m%60);Copy-Item -LiteralPath (Join-Path $root "Sources_HD\Tableau\Tableau_$tc.jpg") -Destination $boardSelect}
$priority=@(42,46,47,55,60,63,68,74,75,76,82,87)
$top=Join-Path $root 'Selections\Tableau_Prioritaires'
New-Item -ItemType Directory -Force -Path $top | Out-Null
foreach($m in $priority){$tc='{0:00}-{1:00}-00' -f [math]::Floor($m/60),($m%60);Copy-Item -LiteralPath (Join-Path $boardSelect "Tableau_$tc.jpg") -Destination $top}
function Make-Sheet($files,$out,[int]$columns=4){
 $files=@($files);$rows=[int][math]::Ceiling($files.Count/$columns)
 $canvas=New-Object System.Drawing.Bitmap(($columns*480),($rows*300))
 $g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear([System.Drawing.Color]::FromArgb(24,24,24));$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $font=New-Object System.Drawing.Font('Arial',15)
 for($j=0;$j -lt $files.Count;$j++){$im=[System.Drawing.Image]::FromFile($files[$j].FullName);$x=($j%$columns)*480;$y=[math]::Floor($j/$columns)*300;$g.DrawImage($im,[int]$x,[int]$y,480,270);$g.DrawString($files[$j].BaseName,$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+274));$im.Dispose()}
 $canvas.Save($out,[System.Drawing.Imaging.ImageFormat]::Jpeg);$font.Dispose();$g.Dispose();$canvas.Dispose()
}
$camFiles=@(Get-ChildItem -LiteralPath (Join-Path $root 'Selections\Riz_Camera') -Filter '*.jpg' | Sort-Object Name)+@(Get-ChildItem -LiteralPath (Join-Path $root 'Selections\Scott_Camera') -Filter '*.jpg' | Sort-Object Name)
Make-Sheet $camFiles (Join-Path $root 'Apercus\Regards_Camera_selection.jpg') 3
Make-Sheet @(Get-ChildItem -LiteralPath $top -Filter '*.jpg' | Sort-Object Name) (Join-Path $root 'Apercus\Tableau_prioritaires.jpg')
$bfiles=@(Get-ChildItem -LiteralPath $boardSelect -Filter '*.jpg' | Sort-Object Name)
for($p=0;$p -lt $bfiles.Count;$p+=20){Make-Sheet @($bfiles | Select-Object -Skip $p -First 20) (Join-Path $root ('Apercus\Tableau_selection_'+([int]($p/20)+1)+'.jpg'))}
$exportFiles=$camFiles+@(Get-ChildItem -LiteralPath $top -Filter '*.jpg' | Sort-Object Name)
foreach($f in $exportFiles){$group=if($f.Name.StartsWith('Riz')){'Riz_Camera'}elseif($f.Name.StartsWith('Scott')){'Scott_Camera'}else{'Tableau_Prioritaires'};$dir=Join-Path $root "Exports_4K\$group";New-Item -ItemType Directory -Force -Path $dir | Out-Null;$im=[System.Drawing.Image]::FromFile($f.FullName);if($im.Width -ne 3840 -or $im.Height -ne 2160){throw "Wrong dimensions $($f.Name)"};$im.Save((Join-Path $dir ($f.BaseName+'.png')),[System.Drawing.Imaging.ImageFormat]::Png);$im.Dispose()}
$notes=@'
Selection Frame.io - Riz, Scott Pulcini et tableau - 8 octobre 2026

Tous les fichiers sources sont des JPG exportes depuis Viewer Settings > Download Still, qualite 2160p. Dimensions verifiees : 3840 x 2160. Aucun agrandissement, aucune retouche de visage, aucune capture d'ecran utilisee comme photo finale. Les videos et leurs proxies n'ont pas ete telecharges en tant que fichiers.

Regards camera : 3 Riz et 2 Scott. Scott 07:38 et 07:40 sont deux alternatives proches d'un meme passage avec regard vers l'objectif. Les alternatives de profil sont conservees separement.

Tableau : 87 passages exportes ; 60 images avec ecriture ou dessins retenues ; 12 vues prioritaires. Les vues de plateau vide, ordinateur et effacement sont exclues de la selection. Les etapes proches sont conservees pour offrir davantage de choix. L'orientation des images reste celle de la source : les inscriptions du tableau sont a l'envers dans le cadrage natif.

Les noms de fichiers indiquent HH-MM-SS. Les PNG sont des conversions sans agrandissement des JPG Frame.io ; ils ne restituent pas de details perdus dans la compression JPG. Les sources JPG restent intactes.

Dossiers : Sources_HD = tous les exports ; Selections = photos retenues ; Exports_4K = PNG des 5 portraits camera et 12 tableaux prioritaires ; Apercus = planches de comparaison ; Suivi = dimensions et provenance.
'@
$notes | Set-Content -LiteralPath (Join-Path $root 'Suivi\LIRE_MOI.txt') -Encoding UTF8
$urls=@'
Riz: https://next.frame.io/project/77d3822c-1ffb-48cd-8ff6-602a702372de/view/9cfbb3f5-24c1-4f96-abf1-4f6cc3183ae8
Scott Pulcini: https://next.frame.io/project/77d3822c-1ffb-48cd-8ff6-602a702372de/view/d90ba990-d224-457b-8fb9-be358b6494ba
Tableau: https://next.frame.io/project/77d3822c-1ffb-48cd-8ff6-602a702372de/view/e499f940-d8bd-41ee-bc6e-7c9033f55bfe
'@
$urls | Set-Content -LiteralPath (Join-Path $root 'Suivi\Sources_Frameio.txt') -Encoding UTF8
Compress-Archive -LiteralPath (Join-Path $root 'Selections\Riz_Camera'),(Join-Path $root 'Selections\Scott_Camera'),(Join-Path $root 'Exports_4K\Riz_Camera'),(Join-Path $root 'Exports_4K\Scott_Camera'),(Join-Path $root 'Apercus\Regards_Camera_selection.jpg'),(Join-Path $root 'Suivi\LIRE_MOI.txt') -DestinationPath (Join-Path $delivery 'Riz_Scott_Regards_Camera_4K.zip')
Compress-Archive -LiteralPath $boardSelect,$top,(Join-Path $root 'Exports_4K\Tableau_Prioritaires'),(Join-Path $root 'Apercus\Tableau_prioritaires.jpg'),(Join-Path $root 'Apercus\Tableau_selection_1.jpg'),(Join-Path $root 'Apercus\Tableau_selection_2.jpg'),(Join-Path $root 'Apercus\Tableau_selection_3.jpg'),(Join-Path $root 'Suivi\LIRE_MOI.txt') -DestinationPath (Join-Path $delivery 'Tableau_60_Images_4K.zip')
Compress-Archive -LiteralPath (Join-Path $root 'Sources_HD'),(Join-Path $root 'Suivi') -DestinationPath (Join-Path $delivery 'Tous_les_Exports_Frameio_JPG.zip')
foreach($z in Get-ChildItem -LiteralPath $delivery -Filter '*.zip'){$zip=[System.IO.Compression.ZipFile]::OpenRead($z.FullName);$count=@($zip.Entries | Where-Object {$_.FullName -match '\.(jpg|png)$'}).Count;Write-Output "$($z.Name): $count images, $($z.Length) bytes";$zip.Dispose()}
Write-Output "Sources: $(@(Get-ChildItem -LiteralPath (Join-Path $root 'Sources_HD') -Filter '*.jpg' -Recurse).Count), Selected board: $($bfiles.Count), PNGs: $($exportFiles.Count)"
