$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$old=Join-Path (Split-Path $root -Parent) 'V04_Trading_Refinements'
$pairs=@(@('11_Green','11_Yellow','BOUGIE VERTE','BOUGIE JAUNE','Comparatif_11_Vert_Jaune.jpg'),@('13_Blur10','13_Blur15','FLOU 10 %','FLOU 15 %','Comparatif_13_Flou_10_15.jpg'))
foreach($pair in $pairs){
 $s=[Drawing.Bitmap]::new(1640,520);$g=[Drawing.Graphics]::FromImage($s);$g.Clear([Drawing.Color]::FromArgb(18,22,27));$g.InterpolationMode='HighQualityBicubic';$font=[Drawing.Font]::new('Arial',22,[Drawing.FontStyle]::Bold)
 for($i=0;$i-lt2;$i++){$im=[Drawing.Image]::FromFile((Join-Path $root ('apercus/Sampsa_'+$pair[$i]+'_1280.jpg')));$g.DrawImage($im,(10+$i*820),10,800,450);$im.Dispose();$g.DrawString($pair[$i+2],$font,[Drawing.Brushes]::White,[float](10+$i*820),[float]470)}
 $g.Dispose();$font.Dispose();$s.Save((Join-Path $root ('apercus/'+$pair[4])),[Drawing.Imaging.ImageFormat]::Jpeg);$s.Dispose()
}
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'variants_final_prompts.json') -Raw|ConvertFrom-Json
$checks=@()
foreach($r in $rows){
 $mp=Join-Path $root ('masters/Sampsa_'+$r.id+'.png');$ep=Join-Path $root ('exports_4K/Sampsa_Jeppez_V05_'+$r.id+'_3840x2160_Grain4.png')
 $im=[Drawing.Image]::FromFile($ep);if($im.Width-ne3840-or$im.Height-ne2160){throw 'Dimensions mismatch'};$im.Dispose()
 $same=$null
 if(-not$r.changed){$same=((Get-FileHash -LiteralPath $mp).Hash-eq(Get-FileHash -LiteralPath (Join-Path $old ('masters/Sampsa_'+$r.id+'.png'))).Hash)-and((Get-FileHash -LiteralPath $ep).Hash-eq(Get-FileHash -LiteralPath (Join-Path $old ('exports_4K/Sampsa_Jeppez_V04_'+$r.id+'_3840x2160_Grain4.png'))).Hash);if(!$same){throw 'Unchanged variant mismatch'}}
 $checks+=[pscustomobject]@{Id=$r.id;DimensionVerified=$true;PreservedV04=$same;MasterSHA256=(Get-FileHash -LiteralPath $mp).Hash;ExportSHA256=(Get-FileHash -LiteralPath $ep).Hash}
}
if(@($checks).Count-ne28){throw 'Expected 28'}
if(@(Get-ChildItem -LiteralPath (Join-Path $root 'masters') -Filter '*.png').Count-ne28){throw 'Master count mismatch'}
$checks|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_final.json') -Encoding utf8
$h=Get-Content -LiteralPath (Join-Path $root 'Galerie.html') -Raw
$links=[regex]::Matches($h,'(?:src|href|data-before|data-after)="([^"]+)"')
foreach($m in $links){$v=$m.Groups[1].Value;if($v.StartsWith('#')-or$v.EndsWith('.zip')){continue};if(!(Test-Path -LiteralPath (Join-Path $root $v))){throw ('Missing gallery file '+$v)}}
'28 PNG and gallery links verified; 13 unchanged V04 variants verified identical.'
