$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot
$out=Join-Path $root 'Exports\V03'
$preview=Join-Path $root 'Apercus\V03'
$delivery=Join-Path $root 'Livraison'
New-Item -ItemType Directory -Force -Path $delivery | Out-Null
$titles=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Titres_et_sources_V01.txt')
$titles=$titles.Replace('V01','V03').Replace('frame_39600 (1).jpg; frame_115200 (4).jpg; frame_66600.jpg','frame_39600 (1).jpg; frame_600.jpg; frame_66600.jpg')
$titles+="`r`nCorrections V03 : ordre de lecture WHY BREAKOUTS FAIL dans 02; Riz frontal issu du still original 00:00:20 dans 04. V01 conservee.`r`n"
Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Titres_et_sources_V03.txt') -Value $titles -Encoding utf8
$prompts=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Prompts_ImageGen_V01.txt')
$prompts+="`r`n"+(Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Retouche_Riz_V02.txt'))
$prompts+="`r`n"+(Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Retouche_Imre_V03.txt'))
Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Prompts_ImageGen_V03.txt') -Value $prompts -Encoding utf8

# All mobile captions stay inside their own column.
$sheet=New-Object System.Drawing.Bitmap(640,840)
$sg=[System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::FromArgb(22,22,22))
$sg.InterpolationMode='HighQualityBicubic'
$font=New-Object System.Drawing.Font('Arial',14,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
for($j=0;$j -lt 8;$j++){
 $id='{0:00}' -f ($j+1)
 $im=[System.Drawing.Image]::FromFile((Join-Path $preview ($id+'_320.jpg')))
 $x=($j%2)*320;$y=[int][math]::Floor($j/2)*210
 $sg.DrawImage($im,$x,$y,320,180)
 $sg.DrawString(('IMRE GAMS - '+$id),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+186))
 $im.Dispose()
}
$font.Dispose();$sg.Dispose()
$sheet.Save((Join-Path $preview 'Controle_Mobile_V03_ID.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()

$files=@(Get-ChildItem -LiteralPath $out -Filter '*.png' -File | Sort-Object Name)
if($files.Count -ne 8){throw 'Expected exactly eight PNG exports.'}
$manifest=@()
foreach($file in $files){
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 if($im.Width -ne 3840 -or $im.Height -ne 2160){throw ('Wrong dimensions: '+$file.Name)}
 $manifest+=[pscustomobject]@{File=$file.Name;Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
 $im.Dispose()
}
$manifest | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_V03.csv')
$zipPath=Join-Path $delivery 'Imre_Gams_8_Thumbnails_V03_3840x2160.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; preserve it.'}
$zip=[System.IO.Compression.ZipFile]::Open($zipPath,[System.IO.Compression.ZipArchiveMode]::Create)
try{foreach($file in $files){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$file.Name,[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null}}finally{$zip.Dispose()}
$zip=[System.IO.Compression.ZipFile]::OpenRead($zipPath)
try{
 if($zip.Entries.Count -ne 8){throw 'Wrong archive entry count.'}
 foreach($entry in $zip.Entries){
  $expected=$manifest | Where-Object File -eq $entry.FullName
  if(-not $expected -or $entry.Length -ne $expected.Bytes){throw ('Archive size mismatch: '+$entry.FullName)}
  $stream=$entry.Open();$sha=[System.Security.Cryptography.SHA256]::Create()
  try{$actual=([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
  if($actual -ne $expected.SHA256){throw ('Archive hash mismatch: '+$entry.FullName)}
 }
}finally{$zip.Dispose()}
@'
IMRE GAMS - CHARTFANATICS - LIVRAISON V03

Livraison : 8 PNG 3840 x 2160 dans Exports/V03 et archive contenant exactement ces 8 fichiers. Archive verifiee par taille et SHA256; dimensions de chaque PNG verifiees. Verification_V03.csv contient les empreintes.
Planche : Apercus/V03/Planche_8_Thumbnails_V03.jpg.
Controle mobile : Apercus/V03/Controle_Mobile_V03_ID.jpg, huit images 320 x 180.

Sources : 51 stills natifs via Frame.io Download Still, 1920 x 1080, qualite maximale disponible 1080p. Aucun telechargement video ou proxy. Sources_manifest.csv contient timecodes, dimensions, SHA256 et provenance. Transcript fourni copie dans Sources_HD/Transcript_Imre.txt.
Asset : https://next.frame.io/project/77d3822c-1ffb-48cd-8ff6-602a702372de/view/03067022-6f86-4567-acb5-b0116ad44886
Video : Without Charts CF Imre_1.mp4. La sequence sur plateforme annoncee a la fin ne figure pas dans cette video; les supports de 01, 02 et 04 utilisent les vrais stills du tableau pedagogique de cet episode.

Construction : references Scott conservees dans References; originaux dans Sources_HD. Retouches generatives et scenes reconstruites a partir des photographies originales des personnes. Ces portraits ne sont pas des copies pixel pour pixel des originaux. Texte ajoute separement en Poppins. Les schemas de 06 sont des illustrations pedagogiques simplifiees.
Masters/V03 contient les plaques, decoupages et compositions 1280 x 720 avant bruit. Exports 3840 x 2160 agrandis : NON NATIFS 4K. Bruit gaussien monochromatique 5%, sigma 12.75, applique une seule fois apres agrandissement; masters sans bruit final.
Tenues Imre : blanc 01/02/04/05/06; noir 03/07/08. Riz conserve son polo beige. Aucun microphone visible. 08 : pixellisation volontaire du visage d'Imre, sans modification du visage de Riz.
Les accroches sont editoriales, pas des citations litterales. Elles correspondent au contenu indique dans Titres_et_sources_V03.txt. Aucun montant de gains ou statistique de performance invente.

Versions : V01 conservee. V03 corrige l'ordre de lecture de 02 et utilise un portrait frontal original de Riz pour 04.
Reproduction : render_v03.ps1 et les PNG sources Masters/V03; add_final_noise.ps1 se trouve dans le dossier parent Thumbnail - CF. Polices Poppins installees sur cet ordinateur. Prompts_ImageGen_V03.txt documente les retouches initiales et la correction de Riz. Generations non deterministes; plaques conservees pour reproduire l'assemblage final.
Rien n'a ete publie sur YouTube.
'@ | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Livraison_V03.txt') -Encoding utf8
Write-Output ('VERIFIED: 8 PNG, 3840x2160, 8 ZIP entries with matching SHA256. Archive: '+$zipPath)

