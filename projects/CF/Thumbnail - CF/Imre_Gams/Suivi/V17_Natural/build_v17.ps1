$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot '..\V16_Test01\soft_glow.ps1')
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$master = Join-Path $project 'Masters\V17_Natural'
$exports = Join-Path $project 'Exports\V17_Natural'
$preview = Join-Path $project 'Apercus\V17_Natural'
$drawingRuntime = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFNatural {
 static int[] Read(Bitmap im) { var a=new int[im.Width*im.Height]; var d=im.LockBits(new Rectangle(0,0,im.Width,im.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); try{Marshal.Copy(d.Scan0,a,0,a.Length);}finally{im.UnlockBits(d);} return a; }
 static Bitmap Write(int[] a,int w,int h) { var im=new Bitmap(w,h,PixelFormat.Format32bppArgb); var d=im.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);try{Marshal.Copy(a,0,d.Scan0,a.Length);}finally{im.UnlockBits(d);}return im; }
 public static Bitmap Cutout(Bitmap original,Bitmap repair,Bitmap mask,Bitmap hole) {
  int[] a=Read(original),b=Read(repair),m=Read(mask),q=Read(hole);
  for(int i=0;i<a.Length;i++){
   double t=((uint)q[i]>>24)/255.0; int x=i%original.Width;
   int r=(a[i]>>16)&255,g=(a[i]>>8)&255,bl=a[i]&255;
   if(t>0){int rr=(b[i]>>16)&255,gg=(b[i]>>8)&255,bb=b[i]&255;
    // Reconstruct clothing to remove microphones; preserve native faces and silhouette geometry.
    if(x<690){rr=(int)Math.Min(255,rr*0.99);gg=(int)Math.Min(255,gg*0.99);bb=(int)Math.Min(255,bb*0.99);}
    r=(int)Math.Round(r*(1-t)+rr*t);g=(int)Math.Round(g*(1-t)+gg*t);bl=(int)Math.Round(bl*(1-t)+bb*t);
   }
   a[i]=((int)((uint)m[i]>>24)<<24)|(r<<16)|(g<<8)|bl;
  }return Write(a,original.Width,original.Height);
 }
 public static void BackgroundGrade(Bitmap im){int[] a=Read(im);for(int i=0;i<a.Length;i++){int r=(a[i]>>16)&255,g=(a[i]>>8)&255,b=a[i]&255;double l=.2126*r+.7152*g+.0722*b;double f=(i/im.Width<650)?.92:1.0; r=(int)Math.Min(255,(l+(r-l)*.8)*f);g=(int)Math.Min(255,(l+(g-l)*.8)*f);b=(int)Math.Min(255,(l+(b-l)*.8)*f);a[i]=unchecked((int)0xff000000)|(r<<16)|(g<<8)|b;}var d=im.LockBits(new Rectangle(0,0,im.Width,im.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);try{Marshal.Copy(a,0,d.Scan0,a.Length);}finally{im.UnlockBits(d);}}
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([Drawing.Bitmap].Assembly.Location,[Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')

function New-Canvas([int]$w=1440,[int]$h=810){return [Drawing.Bitmap]::new($w,$h,[Drawing.Imaging.PixelFormat]::Format32bppArgb)}
function Graphics-For($im){$g=[Drawing.Graphics]::FromImage($im);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';return $g}
function Poly($g,[string]$coords){$pts=[Collections.Generic.List[Drawing.PointF]]::new();foreach($pair in ($coords -split ' ')){if($pair.Trim()){ $n=$pair -split ',';$pts.Add([Drawing.PointF]::new([single]$n[0],[single]$n[1])) }};$g.FillPolygon([Drawing.Brushes]::White,$pts.ToArray())}
function Save-Jpeg($im,$path,[int]$quality=96){$enc=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where-Object MimeType -eq 'image/jpeg';$p=[Drawing.Imaging.EncoderParameters]::new(1);$p.Param[0]=[Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality,[long]$quality);$im.Save($path,$enc,$p);$p.Dispose()}
function Resize-Image($im,[int]$w,[int]$h){$out=New-Canvas $w $h;$g=Graphics-For $out;$g.DrawImage($im,[Drawing.Rectangle]::new(0,0,$w,$h));$g.Dispose();return $out}

$source=[Drawing.Bitmap]::new((Join-Path $master 'source_locked_layout.png'))
$repairInput=[Drawing.Bitmap]::new((Join-Path $master 'Generated_plate_1440.png'))
$repair=New-Canvas;$rg=Graphics-For $repair
$rg.DrawImage($repairInput,[Drawing.RectangleF]::new(24.5,-15.8,1378.5,797.85),[Drawing.RectangleF]::new(0,0,1440,810),[Drawing.GraphicsUnit]::Pixel)
$rg.SetClip([Drawing.Rectangle]::new(690,0,750,810));$rg.DrawImage($repairInput,[Drawing.RectangleF]::new(62.3,-17.3,1358.2,803.3),[Drawing.RectangleF]::new(0,0,1440,810),[Drawing.GraphicsUnit]::Pixel);$rg.Dispose();$repairInput.Dispose()
$empty=[Drawing.Bitmap]::new((Join-Path $master 'Empty_room.png'))
$room=New-Canvas;$g=Graphics-For $room
$tableY=789.0
$g.DrawImage($empty,[Drawing.RectangleF]::new(0,0,1440,650),[Drawing.RectangleF]::new(0,0,$empty.Width,$tableY),[Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($empty,[Drawing.RectangleF]::new(0,650,1440,160),[Drawing.RectangleF]::new(0,$tableY,$empty.Width,($empty.Height-$tableY)),[Drawing.GraphicsUnit]::Pixel)
$g.Dispose();[CFNatural]::BackgroundGrade($room)

$mask=New-Canvas;$g=Graphics-For $mask
# Both silhouettes retain the native source scale and body geometry.
Poly $g '313,137 313,116 324,94 345,78 368,64 392,53 411,51 430,54 451,60 474,70 491,83 504,99 514,116 518,133 516,145 510,153 515,164 520,174 523,192 525,216 524,235 519,248 520,267 520,277 545,285 570,296 598,310 616,325 634,355 647,389 656,430 661,477 663,518 664,552 665,588 662,623 656,654 156,654 153,620 150,581 148,548 147,518 149,479 155,439 166,398 177,368 193,341 215,320 239,307 270,295 296,280 314,270 338,265 349,245 345,236 341,224 341,205 344,192 332,180 321,163'
Poly $g '975,103 988,89 1012,77 1038,71 1060,71 1080,76 1101,85 1120,99 1135,116 1144,137 1148,158 1151,179 1146,200 1135,222 1113,242 1105,264 1104,291 1118,303 1145,316 1173,334 1202,351 1229,365 1244,383 1256,407 1264,446 1272,487 1281,526 1290,568 1298,608 1294,624 1280,636 1280,659 831,657 827,668 816,675 789,675 758,672 738,666 723,655 717,643 718,628 724,614 735,602 744,582 755,556 762,545 749,530 751,516 772,488 791,460 812,433 827,405 839,377 852,348 869,330 891,324 918,319 945,311 965,306 950,296 944,281 943,266 941,255 947,247 941,241 934,235 934,227 942,213 946,200 946,183 943,175 949,161 956,144 962,124'
$g.Dispose()
$maskSoft=[CFSoftGlow]::Blur($mask,0.65,[Drawing.Color]::White,1.0)
$maskSoft.Save((Join-Path $master 'Original_people_mask.png'))
$holes=New-Canvas;$g=Graphics-For $holes
Poly $g '337,254 349,254 356,286 370,316 391,346 410,360 429,352 446,341 463,325 485,314 511,276 541,280 574,293 610,311 641,347 665,402 676,472 676,541 654,553 599,560 559,560 560,595 552,635 556,664 252,664 252,610 261,576 260,533 207,536 144,537 135,520 137,462 154,390 178,339 211,309 258,291 308,270'
Poly $g '955,306 975,311 979,335 994,355 1019,366 1047,370 1072,366 1097,349 1114,321 1117,297 1162,323 1215,352 1253,380 1278,445 1297,538 1307,619 1278,640 1196,641 1185,662 829,662 829,632 817,610 818,596 801,585 771,589 769,572 767,547 746,533 744,519 786,462 823,399 850,343 873,323 921,314'
$g.Dispose();$holesSoft=[CFSoftGlow]::Blur($holes,3.0,[Drawing.Color]::White,1.0)
$people=[CFNatural]::Cutout($source,$repair,$maskSoft,$holesSoft)
$people.Save((Join-Path $master 'Original_people_reconstructed_clothing.png'))
$photo=New-Canvas;$g=Graphics-For $photo;$g.DrawImageUnscaled($room,0,0)
$contact=New-Canvas;$cg=Graphics-For $contact;$cg.FillEllipse([Drawing.Brushes]::Black,146,646,519,16);$cg.FillEllipse([Drawing.Brushes]::Black,722,652,566,17);$cg.Dispose();$contactSoft=[CFSoftGlow]::Blur($contact,5,[Drawing.Color]::Black,0.25)
$g.DrawImageUnscaled($contactSoft,0,0);$g.DrawImageUnscaled($people,0,0);$g.Dispose();$photo.Save((Join-Path $master 'Photographic_composite.png'))

# Minimal white / yellow headline with no quote attribution.
$final=New-Canvas;$g=Graphics-For $final;$g.DrawImageUnscaled($photo,0,0)
$shade=[Drawing.Drawing2D.LinearGradientBrush]::new([Drawing.Point]::new(0,370),[Drawing.Point]::new(0,810),[Drawing.Color]::FromArgb(0,0,0,0),[Drawing.Color]::FromArgb(35,0,0,0));$g.FillRectangle($shade,0,370,1440,440);$shade.Dispose()
$whitePath=[Drawing.Drawing2D.GraphicsPath]::new();$yellowPath=[Drawing.Drawing2D.GraphicsPath]::new();$fam=[Drawing.FontFamily]::new('Arial');$format=[Drawing.StringFormat]::GenericTypographic
$whitePath.AddString('price is not',$fam,[int][Drawing.FontStyle]::Bold,158,[Drawing.PointF]::new(0,0),$format)
$bw=$whitePath.GetBounds();$yellowPath.AddString('value.',$fam,[int][Drawing.FontStyle]::Bold,158,[Drawing.PointF]::new(($bw.Right+38),0),$format)
$whole=[Drawing.Drawing2D.GraphicsPath]::new();$whole.AddPath($whitePath,$false);$whole.AddPath($yellowPath,$false);$b=$whole.GetBounds();$sc=[single](1288/$b.Width);$matrix=[Drawing.Drawing2D.Matrix]::new();$matrix.Translate([single](76-$b.X*$sc),[single](473-$b.Y*$sc));$matrix.Scale($sc,$sc);$whitePath.Transform($matrix);$yellowPath.Transform($matrix);$whole.Transform($matrix)
$textmask=New-Canvas;$tg=Graphics-For $textmask;$tg.FillPath([Drawing.Brushes]::White,$whole);$tg.Dispose();$shadow=[CFSoftGlow]::Blur($textmask,5,[Drawing.Color]::Black,0.8);$g.DrawImageUnscaled($shadow,0,4)
$g.FillPath([Drawing.Brushes]::White,$whitePath);$yellow=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,245,0));$g.FillPath($yellow,$yellowPath);$g.Dispose();$yellow.Dispose()
$final.Save((Join-Path $master 'Imre_Riz_Natural_V17_1440x810.png'))
$youtube=Resize-Image $final 1280 720;Save-Jpeg $youtube (Join-Path $exports 'Imre_Riz_Natural_V17_1280x720.jpg');Save-Jpeg $youtube (Join-Path $preview 'Imre_Riz_Natural_V17_1280.jpg')
$mobile=Resize-Image $final 320 180;Save-Jpeg $mobile (Join-Path $preview 'Imre_Riz_Natural_V17_320.jpg')
$big=Resize-Image $final 3840 2160;$big.Save((Join-Path $exports 'Imre_Riz_Natural_V17_3840x2160.png'))
$source.Dispose();$repair.Dispose();$empty.Dispose();$room.Dispose();$mask.Dispose();$maskSoft.Dispose();$holes.Dispose();$holesSoft.Dispose();$people.Dispose();$photo.Dispose();$final.Dispose();$youtube.Dispose();$mobile.Dispose();$big.Dispose();$contact.Dispose();$contactSoft.Dispose();$textmask.Dispose();$shadow.Dispose()
Write-Output 'V17 natural variant rendered.'
