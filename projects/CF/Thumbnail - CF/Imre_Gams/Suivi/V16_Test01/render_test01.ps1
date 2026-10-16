$ErrorActionPreference='Stop'
$baseline=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render_v14.ps1') -Raw
$boundary=$baseline.IndexOf('$slugs=@');if($boundary -lt 0){throw 'Missing native drawing functions'}
$functionsPath=Join-Path $PSScriptRoot 'drawing_functions.ps1'
[IO.File]::WriteAllText($functionsPath,$baseline.Substring(0,$boundary));. $functionsPath
$assets=Join-Path $root 'Masters\V16_Test01'
$preview=Join-Path $root 'Apercus\V16_Test01'
$exports=Join-Path $root 'Exports\V16_Test01'
$knockoutCode=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFShadowKnockout {
 public static void Apply(Bitmap shadow,Bitmap foreground){
  int n=shadow.Width*shadow.Height;int[] s=new int[n],f=new int[n];var rect=new Rectangle(0,0,shadow.Width,shadow.Height);
  var sd=shadow.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);var fd=foreground.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  try{Marshal.Copy(sd.Scan0,s,0,n);Marshal.Copy(fd.Scan0,f,0,n);for(int i=0;i<n;i++){if(((uint)f[i]>>24)>8)s[i]=0;}Marshal.Copy(s,0,sd.Scan0,n);}finally{shadow.UnlockBits(sd);foreground.UnlockBits(fd);}
 }
}
'@
Add-Type -TypeDefinition $knockoutCode -ReferencedAssemblies @([Drawing.Bitmap].Assembly.Location,[Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
# Keep the validated V15 portrait exactly; no new photo processing or image generation.
$photoCache['Imre_direct_camera.png']=[Drawing.Bitmap]::FromFile((Join-Path $assets 'Imre_relight_preserved.png'))
function DiagramBackdrop(){
 $bg=[Drawing.Bitmap]::FromFile((Join-Path $assets 'background_test.png'));$g.DrawImage($bg,0,0,1280,720);$bg.Dispose()
}
function PortraitShadow(){
 $mask=[Drawing.Bitmap]::new(1280,720,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $mg=[Drawing.Graphics]::FromImage($mask);$mg.InterpolationMode='HighQualityBicubic';$mg.PixelOffsetMode='HighQuality'
 $im=$photoCache['Imre_direct_camera.png'];$scale=545.0/780
 # The key light is from viewer-right: cast a soft neutral shadow to viewer-left and down.
 $mg.DrawImage($im,[single](1030-572*$scale-23),[single](28-85*$scale+17),[single]($im.Width*$scale),[single]($im.Height*$scale));$mg.Dispose()
 $broad=[CFSoftGlow]::Blur($mask,28,[Drawing.Color]::Black,0.46)
 $near=[CFSoftGlow]::Blur($mask,13,[Drawing.Color]::Black,0.76)
 # Original portrait has alpha 253 internally: exclude it from the shadow to keep its pixels unchanged.
 $protection=[Drawing.Bitmap]::new(1280,720,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $pg=[Drawing.Graphics]::FromImage($protection);$pg.InterpolationMode='HighQualityBicubic';$pg.PixelOffsetMode='HighQuality'
 $pg.DrawImage($im,[single](1030-572*$scale),[single](28-85*$scale),[single]($im.Width*$scale),[single]($im.Height*$scale));$pg.Dispose()
 [CFShadowKnockout]::Apply($broad,$protection);[CFShadowKnockout]::Apply($near,$protection);$protection.Dispose()
 $saved=$g.CompositingQuality;$g.CompositingQuality='AssumeLinear'
 $g.DrawImage($broad,0,0,1280,720);$g.DrawImage($near,0,0,1280,720);$g.CompositingQuality=$saved
 $broad.Save((Join-Path $assets 'Portrait_shadow_broad.png'),[Drawing.Imaging.ImageFormat]::Png)
 $near.Save((Join-Path $assets 'Portrait_shadow_near.png'),[Drawing.Imaging.ImageFormat]::Png)
 $broad.Dispose();$near.Dispose();$mask.Dispose()
}
function FocusRing($x,$y,$radius=26){
 if($x -eq 474){
  $ring=[Drawing.Drawing2D.GraphicsPath]::new();$ring.AddEllipse([single]($x-$radius),[single]($y-$radius),[single](2*$radius),[single](2*$radius))
  $outline=[Drawing.Pen]::new($YellowColor,4.5);$ring.Widen($outline);$outline.Dispose()
  SoftGlow $ring $YellowColor 10 0.38;SoftGlow $ring $YellowColor 3 0.32;$ring.Dispose()
 }
 $pen=[Drawing.Pen]::new($YellowColor,4.5);$g.DrawEllipse($pen,[single]($x-$radius),[single]($y-$radius),[single]($radius*2),[single]($radius*2));$pen.Dispose()
}
function Panel($x,$y,$w,$h,$color,$glow=$false,$radius=11){
 $p=RoundPath $x $y $w $h $radius
 $isWhite=$color.ToArgb() -eq $WhiteColor.ToArgb()
 # Symmetric layered light bloom, no offset: matches the supplied red-box reference in white/yellow.
 if($glow){
  if($isWhite){SoftGlow $p $color 29 0.29;SoftGlow $p $color 9 0.52;SoftGlow $p $color 2.5 0.18}
  else{SoftGlow $p $color 28 0.43;SoftGlow $p $color 9 0.62;SoftGlow $p $color 2.5 0.20}
 }
 $bottom=if($isWhite){C 255 250 252 255}else{$color}
 $br=[Drawing.Drawing2D.LinearGradientBrush]::new([Drawing.PointF]::new($x,$y),[Drawing.PointF]::new($x,($y+$h)),$color,$bottom)
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
$script:id='01'
$script:canvas=[Drawing.Bitmap]::new(3840,2160,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$script:g=[Drawing.Graphics]::FromImage($canvas)
$g.Clear((C 255 4 4 4));$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
DiagramBackdrop;PortraitShadow;AuctionDiagram
PortraitHead 'Imre_direct_camera.png' 1030 28 545 572 85 780
Ink 'PRICE IS NOT' 28 24 99 $WhiteColor 'SemiBold' 740 $true
$null=Badge 'VALUE' 28 117 117 $WhiteColor $BlackColor 'Bold' 14 11
$null=Badge 'Auction Market Theory' 245 641 47 $YellowColor $BlackColor 'Medium' 17 11 690
Arrow 754 628 798 559 792 484 755 450 $YellowColor 7
$g.Dispose()
$name='01_Price_Is_Not_Value_V16_Test'
$canvas.Save((Join-Path $assets ($name+'_master.png')),[Drawing.Imaging.ImageFormat]::Png)
$exportPath=Join-Path $exports ($name+'_3840x2160.png');$canvas.Save($exportPath,[Drawing.Imaging.ImageFormat]::Png)
foreach($size in @(1280,640,320)){
 $small=[Drawing.Bitmap]::new($size,[int]($size*9/16));$sg=[Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $preview ('01_'+$size+'.jpg')),$jpeg,$quality);$small.Dispose()
}
$canvas.Dispose()
$metrics.ToArray() | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$candleRecords | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Illustrative_candles.csv')
$arrows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Arrow_geometry.csv')
foreach($im in $photoCache.Values){$im.Dispose()};$quality.Dispose()
Write-Output 'Rendered V16 Test01 with portrait shadow and white/yellow box glow.'
