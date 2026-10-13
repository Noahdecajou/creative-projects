$ErrorActionPreference='Stop'
$p=Join-Path $PSScriptRoot 'package_verify_v04.ps1'
$s=Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V03\package_verify_v03.ps1') -Raw
$s=$s.Replace('V03','V04')
$s=$s.Replace("VisualReview='All eight previews at 320 and 1280 pixels; native face, hair, beard, glasses and hand crops; corrected double eyeglass overlays and hair fringe before final delivery'","VisualReview='All eight previews at 320 and 1280 pixels; native eye crops on 01, 02, 04, 06; marker diagrams and luminous blue panels inspected';ModifiedThumbnails=@('01','02','04','06','08');IdenticalToV03=@('03','05','07');LocalPixelComparison='Pixel_comparison_V03_V04.csv'")
$old=@'
foreach($path in @('LISEZ_MOI_V04.txt','Suivi\drawing_functions.ps1','Suivi\Transcript_Frameio_lu.txt','Suivi\Notes_editoriales.txt','Suivi\Sources_HD_manifest_complet.csv','Suivi\Casper_manifest.csv','Suivi\Riz_manifest.csv','Suivi\Tableau_manifest.csv','Masters\V02\Casper_front_photo.png','Masters\V02\Riz_front_photo.png','Masters\V02\Casper_00-16-00_cutout.png','Masters\V02\Casper_00-20-00_cutout.png','Masters\V02\Riz_01-16-00_cutout.png'))
'@
$new=@'
foreach($path in @('LISEZ_MOI_V04.txt','LISEZ_MOI_V03.txt','Suivi\drawing_functions.ps1','Suivi\Transcript_Frameio_lu.txt','Suivi\Notes_editoriales.txt','Suivi\Sources_HD_manifest_complet.csv','Suivi\Casper_manifest.csv','Suivi\Riz_manifest.csv','Suivi\Tableau_manifest.csv','Masters\V03\Casper_front_photo.png','Suivi\V03\render_v03.ps1'))
'@
$s=$s.Replace($old.Trim(),$new.Trim())
Set-Content -LiteralPath $p -Value $s -Encoding utf8
