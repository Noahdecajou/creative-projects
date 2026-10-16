$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants_V05_source.json') -Raw|ConvertFrom-Json
$exports=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_exports.json') -Raw|ConvertFrom-Json
if($rows.Count-ne28-or$exports.Count-ne28){throw 'Invalid variant count'}
if(@(Get-ChildItem -LiteralPath (Join-Path $root 'masters') -Filter '*.png').Count-ne28){throw 'Invalid master count'}
if(@(Get-ChildItem -LiteralPath (Join-Path $root 'exports_4K') -Filter '*.png').Count-ne28){throw 'Invalid export count'}
$audit=@();$rng=[Random]::new(1041526)
foreach($r in $rows){
 $entry=$exports|Where-Object Id -eq $r.id
 $path=Join-Path $root ('exports_4K/'+$entry.Filename)
 if((Get-FileHash -LiteralPath $path).Hash-ne$entry.SHA256){throw ('Hash mismatch '+$r.id)}
 foreach($preview in @(('apercus/Sampsa_'+$r.id+'_1280.jpg'),('apercus/Sampsa_'+$r.id+'_320.jpg'),('apercus/avant_V05/Sampsa_'+$r.id+'_1280.jpg'))){if(!(Test-Path -LiteralPath (Join-Path $root $preview))){throw ('Missing preview '+$preview)}}
 $im=[Drawing.Bitmap]::new((Join-Path $root ('masters/Sampsa_'+$r.id+'.png')))
 $clean=[Drawing.Bitmap]::new(3840,2160,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($clean);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.CompositingQuality='HighQuality';$height=$im.Width*9.0/16.0
 $g.DrawImage($im,[Drawing.RectangleF]::new(0,0,3840,2160),[Drawing.RectangleF]::new(0,($im.Height-$height)/2,$im.Width,$height),[Drawing.GraphicsUnit]::Pixel);$g.Dispose();$im.Dispose()
 $out=[Drawing.Bitmap]::new($path);if($out.Width-ne3840-or$out.Height-ne2160){throw ('Bad size '+$r.id)}
 $count=0;$changed=0;$max=0;$sum=0;$errors=0
 for($i=0;$i-lt2000;$i++){$x=$rng.Next(3840);$y=$rng.Next(2160);$a=$clean.GetPixel($x,$y);$b=$out.GetPixel($x,$y);if($a.R-lt11-or$a.G-lt11-or$a.B-lt11-or$a.R-gt244-or$a.G-gt244-or$a.B-gt244){continue};$dr=[int]$b.R-[int]$a.R;$dg=[int]$b.G-[int]$a.G;$db=[int]$b.B-[int]$a.B;$count++;if($dr-ne0){$changed++};$max=[math]::Max($max,[math]::Abs($dr));$sum+=$dr*$dr;if($dr-ne$dg-or$dr-ne$db-or[math]::Abs($dr)-gt10){$errors++}}
 $clean.Dispose();$out.Dispose();if($errors-ne0-or$count-lt100-or$changed/$count-lt0.8){throw ('Grain audit failed '+$r.id+' '+$errors)}
 $audit+=[pscustomobject]@{Id=$r.id;Width=3840;Height=2160;VerifiedSHA256=$entry.SHA256;SampledUnclippedPixels=$count;ChangedPixels=$changed;MaxAbsoluteNoise=$max;RMSNoise=[math]::Round([math]::Sqrt($sum/$count),3);NonMonochromeOrExcessNoise=$errors;PreviewLinksExist=$true}
}
$audit|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_grain_and_links.json') -Encoding utf8
$html=Get-Content -LiteralPath (Join-Path $root 'Galerie.html') -Raw
$script=[regex]::Match($html,'(?s)<script>(.*?)</script>').Groups[1].Value
$js=Join-Path $PSScriptRoot 'gallery-syntax-check.js';$script|Set-Content -LiteralPath $js -Encoding utf8
& node --check $js
if($LASTEXITCODE-ne0){throw 'Gallery JavaScript syntax check failed'}
$pres=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_preservation.json') -Raw|ConvertFrom-Json
$faces=@($pres|ForEach-Object RestoredFaces)
if(@($faces|Where-Object ChangedPixels -ne 0).Count-ne0){throw 'Preserved face check failed'}
$summary=[pscustomobject]@{Variants=28;Dimensions='3840x2160';NativeMaster='1672x941';Native4K=$false;GrainAppliedOnce=$true;GrainMethod='Uniform monochrome +/-4 percent';VerifiedFaceRegions=$faces.Count;ChangedPixelsInsideProtectedFaceCores=0;GalleryJavaScriptSyntax='Passed';GalleryBrowserTest='Not run: local file protocol blocked by browser tool';GalleryAssetLinks='84 preview files and 28 PNG paths verified';ExportSHA256='28 verified';Date=(Get-Date -Format o)}
$summary|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_summary.json') -Encoding utf8
$summary|ConvertTo-Json
