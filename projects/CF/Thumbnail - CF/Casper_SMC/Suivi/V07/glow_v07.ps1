# Native layer rendering: directional, feathered light accents, no white outlines.
$script:glowMetrics=[System.Collections.Generic.List[object]]::new()
$glowRuntime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$glowCode=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class LocalLightV7{
 static void Save(Bitmap b,byte[] data){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(data,0,d.Scan0,data.Length);b.UnlockBits(d);}
 public static Bitmap Rim(double w,double h,double radius,int pad,Color color,int mode,double peak,double sigma){int bw=(int)Math.Ceiling((w+2*pad)*3),bh=(int)Math.Ceiling((h+2*pad)*3);var b=new Bitmap(bw,bh,PixelFormat.Format32bppArgb);var v=new byte[bw*bh*4];radius=Math.Min(radius,Math.Min(w,h)/2);for(int py=0;py<bh;py++)for(int px=0;px<bw;px++){double x=(px+.5)/3-pad,y=(py+.5)/3-pad;double qx=Math.Abs(x-w/2)-(w/2-radius),qy=Math.Abs(y-h/2)-(h/2-radius);double d=Math.Sqrt(Math.Pow(Math.Max(qx,0),2)+Math.Pow(Math.Max(qy,0),2))+Math.Min(Math.Max(qx,qy),0)-radius;if(d<0||d>pad)continue;double u=Math.Max(0,Math.Min(1,x/w)),t=Math.Max(0,Math.Min(1,y/h)),gain=1;switch(mode){case 0:gain=.04+.96*Math.Exp(-Math.Pow((u-.03)/.48,2))*(.55+.45*(1-t));break;case 1:gain=.04+.96*Math.Exp(-Math.Pow((u-.96)/.44,2));break;case 2:gain=.12+.88*Math.Exp(-Math.Pow((u-.08)/.64,2));break;case 3:gain=.04+.96*Math.Exp(-Math.Pow((u-.78)/.62,2))*(.10+.90*t);break;case 4:gain=.04+.96*Math.Exp(-Math.Pow((t-.02)/.5,2))*(.30+.70*Math.Exp(-Math.Pow((u-.67)/.36,2)));break;}
 double a=peak*Math.Exp(-d*d/(2*sigma*sigma))*gain;int p=(py*bw+px)*4;v[p]=color.B;v[p+1]=color.G;v[p+2]=color.R;v[p+3]=(byte)Math.Min(255,Math.Round(a));}Save(b,v);return b;}
 public static Bitmap Spot(int w,int h,Color color,double peak){var b=new Bitmap(w*3,h*3,PixelFormat.Format32bppArgb);var v=new byte[b.Width*b.Height*4];for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){double u=(x-b.Width*.5)/(b.Width*.29),t=(y-b.Height*.5)/(b.Height*.29);double a=peak*Math.Exp(-(u*u+t*t)*1.7);int p=(y*b.Width+x)*4;v[p]=color.B;v[p+1]=color.G;v[p+2]=color.R;v[p+3]=(byte)Math.Round(a);}Save(b,v);return b;}
}
'@
Add-Type -TypeDefinition $glowCode -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $glowRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $glowRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
function GlowMode($x,$y){
 switch($script:id){
 '01'{if($y -gt 500){1}else{0}}
 '02'{if($y -gt 500){2}else{4}}
 '03'{if($y -gt 300){1}elseif($y -gt 80){2}else{3}}
 '04'{if($y -gt 500){3}else{0}}
 '06'{if($y -gt 600){1}elseif($x -gt 800){4}elseif($y -gt 400){3}else{2}}
 '07'{if($y -gt 200){3}elseif($x -gt 900){0}elseif($x -lt 100){1}else{2}}
 '08'{if($y -lt 100){0}elseif($y -gt 340){3}elseif($x -lt 100){0}elseif($x -lt 600){1}else{4}}
 default{0}
 }
}
function Glow($x,$y,$w,$h,$color,$radius=11){
 # Dark shadows and the physical grey board rim retain their approved treatment.
 if([math]::Max($color.R,[math]::Max($color.G,$color.B)) -lt 150){for($n=26;$n -ge 1;$n--){$a=[int][math]::Round(5*[math]::Exp(-$n*$n/175));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a $color.R $color.G $color.B) ($radius+$n)}};return}
 $mode=GlowMode $x $y;$pad=32;$peak=100.0;$sigma=9.0
 if($script:id -eq '08'){$pad=24;$peak=48.0;$sigma=6.5}
 $rim=[LocalLightV7]::Rim($w,$h,$radius,$pad,$color,$mode,$peak,$sigma)
 $g.DrawImage($rim,[single]($x-$pad),[single]($y-$pad),[single]($rim.Width/3.0),[single]($rim.Height/3.0));$rim.Dispose()
 $glowMetrics.Add([pscustomobject]@{Image=$script:id;X=$x;Y=$y;Width=$w;Height=$h;Radius=$radius;Pad=$pad;Colour=('{0},{1},{2}' -f $color.R,$color.G,$color.B);Mode=$mode;PeakAlpha=$peak;Sigma=$sigma})
}
function ElectricPanel($x,$y,$w,$h,$radius=10){
 Glow $x $y $w $h (C 255 0 153 255) $radius
 $p=RoundPath $x $y $w $h $radius
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(C 255 7 125 255),(C 255 0 68 238))
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
function InkYellowGradient($s,$x,$y,$size,$weight='SemiBold'){
 $p=Glyph $s $size $weight;$bb=$p.GetBounds();$m=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x-$bb.X),[single]($y-$bb.Y));$p.Transform($m);$m.Dispose()
 for($sw=32;$sw -ge 2;$sw-=2){
  $aa=[int][math]::Round(4*[math]::Exp(-$sw*$sw/560));if($aa -eq 0){continue}
  $light=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new(($x-20),$y),[System.Drawing.PointF]::new(($x+$bb.Width+20),$y),(C 0 255 224 0),(C 0 255 224 0))
  $blend=[System.Drawing.Drawing2D.ColorBlend]::new(5);$blend.Positions=[single[]]@(0,.18,.45,.78,1);$blend.Colors=[System.Drawing.Color[]]@((C ([int]($aa*.5)) 255 224 0),(C $aa 255 224 0),(C ([int]($aa*.6)) 255 224 0),(C 0 255 224 0),(C 1 255 224 0));$light.InterpolationColors=$blend
  $pen=[System.Drawing.Pen]::new($light,[single]$sw);$pen.LineJoin='Round';$g.DrawPath($pen,$p);$pen.Dispose();$light.Dispose()
 }
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$bb.Height)),(C 255 255 249 148),$YellowColor);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $metrics.Add([pscustomobject]@{Image=$script:id;Text=$s;X=$x;Y=$y;Width=[math]::Round($bb.Width,2);Height=[math]::Round($bb.Height,2);Font=$size;Weight=$weight})
 $glowMetrics.Add([pscustomobject]@{Image=$script:id;X=$x;Y=$y;Width=$bb.Width;Height=$bb.Height;Radius=0;Pad=18;Colour='255,224,0';Mode='Glyph left accent';PeakAlpha=4;Sigma=0})
}
function ChartSpot($x,$y,$w,$h,$color,$alpha=22){$im=[LocalLightV7]::Spot($w,$h,$color,$alpha);$g.DrawImage($im,[single]$x,[single]$y,[single]$w,[single]$h);$im.Dispose()}
