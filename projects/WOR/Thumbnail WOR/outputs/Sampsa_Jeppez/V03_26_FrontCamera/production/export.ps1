$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class Finish26 {
 public static void Grain(Bitmap im,double amount,int seed) {
  var d=im.LockBits(new Rectangle(0,0,im.Width,im.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var b=new byte[d.Stride*im.Height];Marshal.Copy(d.Scan0,b,0,b.Length);var rng=new Random(seed);
  for(int y=0;y<im.Height;y++)for(int x=0;x<im.Width;x++){int i=y*d.Stride+x*4;double n=(rng.NextDouble()*2-1)*255*amount;for(int c=0;c<3;c++)b[i+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(b[i+c]+n)));}
  Marshal.Copy(b,0,d.Scan0,b.Length);im.UnlockBits(d);
 }
}
'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices')
function Save-Preview($img,$width,$path){
 $height=[int]($width*9/16)
 $p=[Drawing.Bitmap]::new($width,$height)
 $g=[Drawing.Graphics]::FromImage($p);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality'
 $g.DrawImage($img,0,0,$width,$height);$g.Dispose()
 $p.Save($path,[Drawing.Imaging.ImageFormat]::Jpeg);$p.Dispose()
}
$rows=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'variants_final_prompts.json') | ConvertFrom-Json
if($rows.Count-ne26){throw 'Expected 26 variants'}
$report=@();$index=0
foreach($r in $rows){
 $source=Join-Path $root ('masters\Sampsa_'+$r.id+'.png')
 $im=[Drawing.Bitmap]::new($source)
 $out=[Drawing.Bitmap]::new(3840,2160,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($out);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.CompositingQuality='HighQuality'
 $srcHeight=$im.Width*9.0/16.0
 $g.DrawImage($im,[Drawing.RectangleF]::new(0,0,3840,2160),[Drawing.RectangleF]::new(0,($im.Height-$srcHeight)/2,$im.Width,$srcHeight),[Drawing.GraphicsUnit]::Pixel)
 $g.Dispose();$nw=$im.Width;$nh=$im.Height;$im.Dispose()
 [Finish26]::Grain($out,0.04,(20261012+$index))
 $name='Sampsa_Jeppez_V03_'+$r.id+'_3840x2160_Grain4.png';$path=Join-Path $root ('exports_4K\'+$name)
 $out.Save($path,[Drawing.Imaging.ImageFormat]::Png)
 Save-Preview $out 1280 (Join-Path $root ('apercus\Sampsa_'+$r.id+'_1280.jpg'))
 Save-Preview $out 320 (Join-Path $root ('apercus\Sampsa_'+$r.id+'_320.jpg'))
 $out.Dispose();$check=[Drawing.Image]::FromFile($path)
 if($check.Width-ne3840-or$check.Height-ne2160){throw ('Wrong dimensions '+$name)};$check.Dispose()
 $report+=[pscustomobject]@{Id=$r.id;Reference=$r.refId;Title=$r.title;Filename=$name;Duo=$r.duo;DirectGaze=$r.direct;NativeWidth=$nw;NativeHeight=$nh;ExportWidth=3840;ExportHeight=2160;Native4K=$false;Grain='Uniform monochrome noise +/-4% of 255, applied once at 4K';Bytes=(Get-Item -LiteralPath $path).Length;SHA256=(Get-FileHash -LiteralPath $path).Hash}
 $index++;Write-Output ('Exported '+$index+'/26 : '+$r.id)
}
if(@($report.SHA256|Select-Object -Unique).Count-ne26){throw 'Duplicate export files'}
$report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_exports.json') -Encoding utf8
# Overview: native mobile-sized 320px previews, four columns.
$sheet=[Drawing.Bitmap]::new(1380,1630);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(18,22,27));$g.TextRenderingHint='AntiAliasGridFit'
$font=[Drawing.Font]::new('Arial',16,[Drawing.FontStyle]::Bold)
for($i=0;$i-lt$rows.Count;$i++){
 $r=$rows[$i];$x=20+($i%4)*340;$y=20+[math]::Floor($i/4)*228
 $p=[Drawing.Image]::FromFile((Join-Path $root ('apercus\Sampsa_'+$r.id+'_320.jpg')));$g.DrawImageUnscaled($p,[int]$x,[int]$y);$p.Dispose()
 $label='REF '+$r.refId;if($r.id -like '*_Duo'){$label+=' - DUO'}elseif($r.refId-in@('02','03','04')){$label+=' - SOLO'}
 $g.DrawString($label,$font,[Drawing.Brushes]::White,[float]$x,[float]($y+186))
}
$font.Dispose();$g.Dispose();$sheet.Save((Join-Path $root 'apercus\Planche_26_variantes.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
for($page=0;$page-lt5;$page++){
 $part=@($rows|Select-Object -Skip ($page*6) -First 6)
 $sheet=[Drawing.Bitmap]::new(1320,1240);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(18,22,27));$g.TextRenderingHint='AntiAliasGridFit';$g.InterpolationMode='HighQualityBicubic';$font=[Drawing.Font]::new('Arial',18,[Drawing.FontStyle]::Bold)
 for($j=0;$j-lt$part.Count;$j++){$r=$part[$j];$x=10+($j%2)*660;$y=10+[math]::Floor($j/2)*410;$p=[Drawing.Image]::FromFile((Join-Path $root ('apercus\Sampsa_'+$r.id+'_1280.jpg')));$g.DrawImage($p,[int]$x,[int]$y,640,360);$p.Dispose();$g.DrawString(($r.id+'  '+$r.title),$font,[Drawing.Brushes]::White,[float]$x,[float]($y+368))}
 $font.Dispose();$g.Dispose();$sheet.Save((Join-Path $root ('apercus\Planche_detail_'+($page+1)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}
# Compare all three solo/duo pairs, same guest HD source within each pair.
$sheet=[Drawing.Bitmap]::new(1640,1510);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(18,22,27));$g.InterpolationMode='HighQualityBicubic';$g.TextRenderingHint='AntiAliasGridFit';$font=[Drawing.Font]::new('Arial',22,[Drawing.FontStyle]::Bold)
for($n=0;$n-lt3;$n++){$id=('{0:D2}'-f($n+2));for($col=0;$col-lt2;$col++){$key=$id;if($col-eq1){$key+='_Duo'};$x=10+$col*820;$y=10+$n*500;$p=[Drawing.Image]::FromFile((Join-Path $root ('apercus\Sampsa_'+$key+'_1280.jpg')));$g.DrawImage($p,$x,$y,800,450);$p.Dispose();$label='REF '+$id+' - SAMPSA SOLO';if($col-eq1){$label='REF '+$id+' - SAMPSA + RIZ'};$g.DrawString($label,$font,[Drawing.Brushes]::White,[float]$x,[float]($y+457))}}
$font.Dispose();$g.Dispose();$sheet.Save((Join-Path $root 'apercus\Comparatif_Solo_Duo_02_03_04.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
Write-Output '26 exports verified, mobile previews and comparisons ready.'
