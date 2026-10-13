$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class Finish23 {
 public static void Grain(Bitmap im,double amount,int seed) {
  var d=im.LockBits(new Rectangle(0,0,im.Width,im.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var b=new byte[d.Stride*im.Height];Marshal.Copy(d.Scan0,b,0,b.Length);var rng=new Random(seed);
  for(int y=0;y<im.Height;y++)for(int x=0;x<im.Width;x++){int i=y*d.Stride+x*4;double n=(rng.NextDouble()*2-1)*255*amount;for(int c=0;c<3;c++)b[i+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(b[i+c]+n)));}
  Marshal.Copy(b,0,d.Scan0,b.Length);im.UnlockBits(d);
 }
 public static void LocalPatch(Bitmap target,Bitmap patch,int x0,int y0,int feather) {
  var rect=new Rectangle(0,0,target.Width,target.Height);
  var d=target.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var p=patch.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  var b=new byte[d.Stride*target.Height];var q=new byte[p.Stride*patch.Height];
  Marshal.Copy(d.Scan0,b,0,b.Length);Marshal.Copy(p.Scan0,q,0,q.Length);
  for(int y=y0;y<target.Height;y++)for(int x=x0;x<target.Width;x++){
   double a=Math.Min(1.0,Math.Min((x-x0)/(double)feather,(y-y0)/(double)feather));
   for(int c=0;c<3;c++){int i=y*d.Stride+x*4+c;int j=y*p.Stride+x*4+c;b[i]=(byte)Math.Round(b[i]*(1-a)+q[j]*a);}
  }
  Marshal.Copy(b,0,d.Scan0,b.Length);target.UnlockBits(d);patch.UnlockBits(p);
 }
 public static bool SameOutside(Bitmap a,Bitmap b,int x0,int y0) {
  for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++)if(x<x0||y<y0)if(a.GetPixel(x,y)!=b.GetPixel(x,y))return false;
  return true;
 }
}
'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices')
# Limit revision 20 to the right foreground. Original faces and title pixels remain exact.
$editPath=Join-Path $root 'production\Sampsa_20_generated_local_revision.png'
if(-not (Test-Path -LiteralPath $editPath)){
 Copy-Item -LiteralPath (Join-Path $root 'masters\Sampsa_20.png') -Destination $editPath
}
$before=[Drawing.Bitmap]::new((Join-Path $root 'production\Sampsa_20_before_local_revision.png'))
$local=[Drawing.Bitmap]::new($before.Width,$before.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$lg=[Drawing.Graphics]::FromImage($local);$lg.DrawImageUnscaled($before,0,0);$lg.Dispose()
$edit=[Drawing.Bitmap]::new($editPath)
[Finish23]::LocalPatch($local,$edit,1410,185,16)
$edit.Dispose()
$unchanged=[Finish23]::SameOutside($before,$local,1410,185)
if(-not $unchanged){throw 'Local revision altered protected pixels'}
$before.Dispose()
$local.Save((Join-Path $root 'masters\Sampsa_20.png'),[Drawing.Imaging.ImageFormat]::Png);$local.Dispose()

function Save-Preview($img,$width,$path){
 $height=[int]($width*9/16)
 $p=[Drawing.Bitmap]::new($width,$height)
 $g=[Drawing.Graphics]::FromImage($p);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality'
 $g.DrawImage($img,0,0,$width,$height);$g.Dispose()
 $p.Save($path,[Drawing.Imaging.ImageFormat]::Jpeg);$p.Dispose()
}
$rows=Get-Content -Raw -LiteralPath (Join-Path $root 'production\variants_final_prompts.json') | ConvertFrom-Json
$report=@()
foreach($r in $rows){
 $source=Join-Path $root ('masters\Sampsa_'+$r.id+'.png')
 $im=[Drawing.Bitmap]::new($source)
 $out=[Drawing.Bitmap]::new(3840,2160,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($out);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.CompositingQuality='HighQuality'
 $srcHeight=$im.Width*9.0/16.0
 $g.DrawImage($im,[Drawing.RectangleF]::new(0,0,3840,2160),[Drawing.RectangleF]::new(0,($im.Height-$srcHeight)/2,$im.Width,$srcHeight),[Drawing.GraphicsUnit]::Pixel)
 $g.Dispose()
 $nativeWidth=$im.Width;$nativeHeight=$im.Height;$im.Dispose()
 [Finish23]::Grain($out,0.04,(20261012+[int]$r.id))
 $name='Sampsa_Jeppez_'+$r.id+'_3840x2160_Grain4.png'
 $path=Join-Path $root ('exports_4K\'+$name)
 $out.Save($path,[Drawing.Imaging.ImageFormat]::Png)
 Save-Preview $out 1280 (Join-Path $root ('apercus\Sampsa_'+$r.id+'_1280.jpg'))
 Save-Preview $out 320 (Join-Path $root ('apercus\Sampsa_'+$r.id+'_320.jpg'))
 $out.Dispose()
 $check=[Drawing.Image]::FromFile($path)
 if($check.Width-ne3840-or$check.Height-ne2160){throw "Wrong dimensions: $name"}
 $check.Dispose()
 $report+= [pscustomobject]@{Id=$r.id;Title=$r.title;Filename=$name;NativeWidth=$nativeWidth;NativeHeight=$nativeHeight;ExportWidth=3840;ExportHeight=2160;Native4K=$false;Grain='Monochrome uniform noise +/-4% of 255, applied once at 4K';Bytes=(Get-Item -LiteralPath $path).Length;SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
 Write-Output ('Exported '+$r.id+' / 23')
}
$report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $root 'production\Verification_exports.json') -Encoding utf8
@{ProtectedPixels20Unchanged=$unchanged;PatchX=1410;PatchY=185;Feather=16} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'production\Revision20_pixel_check.json') -Encoding utf8
# Overview, exactly 320-pixel-wide thumbnails for mobile readability.
$sheet=[Drawing.Bitmap]::new(1380,1380)
$sg=[Drawing.Graphics]::FromImage($sheet);$sg.Clear([Drawing.Color]::FromArgb(18,22,27));$sg.TextRenderingHint='AntiAliasGridFit'
$font=[Drawing.Font]::new('Arial',16,[Drawing.FontStyle]::Bold)
foreach($r in $rows){
 $i=[int]$r.id-1;$x=20+($i%4)*340;$y=20+[math]::Floor($i/4)*224
 $p=[Drawing.Image]::FromFile((Join-Path $root ('apercus\Sampsa_'+$r.id+'_320.jpg')))
 $sg.DrawImageUnscaled($p,[int]$x,[int]$y);$p.Dispose()
 $sg.DrawString(('REF '+$r.id),$font,[Drawing.Brushes]::White,[float]$x,[float]($y+186))
}
$sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $root 'apercus\Planche_23_variantes.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
# Four larger contact sheets.
for($page=0;$page-lt4;$page++){
 $pageRows=@($rows | Select-Object -Skip ($page*6) -First 6)
 $sheet=[Drawing.Bitmap]::new(1320,1240);$sg=[Drawing.Graphics]::FromImage($sheet);$sg.Clear([Drawing.Color]::FromArgb(18,22,27))
 $sg.InterpolationMode='HighQualityBicubic';$sg.TextRenderingHint='AntiAliasGridFit';$font=[Drawing.Font]::new('Arial',18,[Drawing.FontStyle]::Bold)
 for($j=0;$j-lt$pageRows.Count;$j++){
  $r=$pageRows[$j];$x=10+($j%2)*660;$y=10+[math]::Floor($j/2)*410
  $p=[Drawing.Image]::FromFile((Join-Path $root ('apercus\Sampsa_'+$r.id+'_1280.jpg')))
  $sg.DrawImage($p,[int]$x,[int]$y,640,360);$p.Dispose()
  $sg.DrawString(($r.id+'  '+$r.title),$font,[Drawing.Brushes]::White,[float]$x,[float]($y+368))
 }
 $sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $root ('apercus\Planche_detail_'+($page+1)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}
Write-Output 'Finished: 23 PNG exports, previews and contact sheets.'

