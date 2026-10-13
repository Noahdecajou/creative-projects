$ErrorActionPreference='Stop'
$p=Join-Path $PSScriptRoot 'package_verify_v05.ps1'
$s=Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V04\package_verify_v04.ps1') -Raw
$s=$s.Replace('V04','V05').Replace("Date='2026-10-12'","Date='2026-10-13'")
$s=$s.Replace("VisualReview='All eight previews at 320 and 1280 pixels; native eye crops on 01, 02, 04, 06; marker diagrams and luminous blue panels inspected';ModifiedThumbnails=@('01','02','04','06','08');IdenticalToV03=@('03','05','07');LocalPixelComparison='Pixel_comparison_V03_V05.csv'","VisualReview='All eight previews at 320 and 1280 pixels; native faces and hands on new scene 03; local hand texture correction; gradient on VOLUME and arrow occlusion on 08; borderless panels inspected';ModifiedThumbnails=@('01','02','03','04','05','06','07','08');FacialRegionComparison='Visages_preserves_V04_V05.csv'")
$old=@'
foreach($path in @('LISEZ_MOI_V05.txt','LISEZ_MOI_V03.txt','Suivi\drawing_functions.ps1','Suivi\Transcript_Frameio_lu.txt','Suivi\Notes_editoriales.txt','Suivi\Sources_HD_manifest_complet.csv','Suivi\Casper_manifest.csv','Suivi\Riz_manifest.csv','Suivi\Tableau_manifest.csv','Masters\V03\Casper_front_photo.png','Suivi\V03\render_v03.ps1'))
'@
$new=@'
foreach($path in @('LISEZ_MOI_V05.txt','LISEZ_MOI_V04.txt','LISEZ_MOI_V03.txt','Suivi\Transcript_Frameio_lu.txt','Suivi\Notes_editoriales.txt','Suivi\Sources_HD_manifest_complet.csv','Suivi\Casper_manifest.csv','Suivi\Riz_manifest.csv','Suivi\Tableau_manifest.csv'))
'@
$s=$s.Replace($old.Trim(),$new.Trim())
Set-Content -LiteralPath $p -Value $s -Encoding utf8
