# Final drawing functions override the V10 geometry with the approved V11 finish.
$photoCode=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFPhotoFinish {
 static double Clamp(double x){return Math.Max(0,Math.Min(1,x));}
 static double Tone(double x){x=Clamp(x);return Clamp(Math.Pow(x,0.975)+0.12*(x-0.5)*(1-Math.Abs(2*x-1)));}
 public static Bitmap Apply(Bitmap input){
  int width=input.Width,height=input.Height;var data=new int[width*height];
  var rd=input.LockBits(new Rectangle(0,0,width,height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  try{Marshal.Copy(rd.Scan0,data,0,data.Length);}finally{input.UnlockBits(rd);}
  for(int i=0;i<data.Length;i++){
   uint px=(uint)data[i];int a=(int)(px>>24);if(a==0)continue;
   double r=((px>>16)&255)/255.0,g=((px>>8)&255)/255.0,b=(px&255)/255.0;
   double l=0.2126*r+0.7152*g+0.0722*b;
   r=Tone(l+(r-l)*1.055);g=Tone(l+(g-l)*1.055);b=Tone(l+(b-l)*1.055);
   data[i]=(a<<24)|((int)Math.Round(r*255)<<16)|((int)Math.Round(g*255)<<8)|(int)Math.Round(b*255);
  }
  var output=new Bitmap(width,height,PixelFormat.Format32bppArgb);
  var wr=output.LockBits(new Rectangle(0,0,width,height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  try{Marshal.Copy(data,0,wr.Scan0,data.Length);}finally{output.UnlockBits(wr);}
  return output;
 }
}
'@
Add-Type -TypeDefinition $photoCode -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$photoCache=@{}
$arrows=[System.Collections.Generic.List[object]]::new()
function GradedAsset($name){
 if(-not $photoCache.ContainsKey($name)){$original=[System.Drawing.Bitmap]::FromFile((Join-Path $assets $name));$photoCache[$name]=[CFPhotoFinish]::Apply($original);$original.Dispose()}
 return $photoCache[$name]
}
function SoftGlow($path,$color,$sigma,$opacity){
 $bounds=$path.GetBounds();$pad=[int][math]::Ceiling(3*$sigma)+2
 $x=[int][math]::Floor($bounds.X)-$pad;$y=[int][math]::Floor($bounds.Y)-$pad
 $w=[int][math]::Ceiling($bounds.Width)+2*$pad;$h=[int][math]::Ceiling($bounds.Height)+2*$pad
 $mask=[System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $mg=[System.Drawing.Graphics]::FromImage($mask);$mg.SmoothingMode='AntiAlias';$mg.TranslateTransform(-$x,-$y);$mg.FillPath([System.Drawing.Brushes]::White,$path);$mg.Dispose()
 $halo=[CFSoftGlow]::Blur($mask,$sigma,$color,$opacity)
 $savedQuality=$g.CompositingQuality;$g.CompositingQuality='AssumeLinear';$g.DrawImage($halo,[single]$x,[single]$y,[single]$w,[single]$h);$g.CompositingQuality=$savedQuality;$halo.Dispose();$mask.Dispose()
}
function Panel($x,$y,$w,$h,$color,$glow=$false,$radius=11){
 $p=RoundPath $x $y $w $h $radius
 $isWhite=$color.ToArgb() -eq $WhiteColor.ToArgb()
 $isYellow=$color.ToArgb() -eq $YellowColor.ToArgb()
 $isRed=$color.ToArgb() -eq $RedColor.ToArgb()
 $brightColor=$color.A -gt 239 -and ([math]::Max($color.R,[math]::Max($color.G,$color.B))-[math]::Min($color.R,[math]::Min($color.G,$color.B))) -gt 80
 if($glow -or ($brightColor -and $script:id -ne '06')){
  if($isRed){SoftGlow $p $color 25 0.64;SoftGlow $p $color 8 0.76}
  elseif($isWhite){SoftGlow $p $color 19 0.24;SoftGlow $p $color 6 0.36}
  elseif($isYellow){SoftGlow $p $color 22 0.38;SoftGlow $p $color 7 0.44}
  else{SoftGlow $p $color 13 0.28;SoftGlow $p $color 4 0.28}
 }elseif($script:id -eq '06' -and $color.R -gt 245 -and $color.G -gt 245 -and $color.B -gt 245){SoftGlow $p (C 255 18 31 47) 7 0.10}
 $bottom=$color
 if($isWhite){$bottom=C 255 250 252 255}elseif($isRed){$bottom=C 255 239 0 9}
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),$color,$bottom)
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
function Ink($s,$x,$y,$size,$color,$weight='SemiBold',$maxW=9999,$shadow=$false){
 $p=Glyph $s $size $weight;$bb=$p.GetBounds();$scale=[math]::Min(1.0,$maxW/$bb.Width)
 $m=[System.Drawing.Drawing2D.Matrix]::new([single]$scale,0,0,[single]$scale,[single]($x-$bb.X*$scale),[single]($y-$bb.Y*$scale));$p.Transform($m);$m.Dispose()
 if($shadow -and $size -ge 33 -and ($color.R+$color.G+$color.B) -gt 400){SoftGlow $p $color 4.5 0.18}
 $br=[System.Drawing.SolidBrush]::new($color);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $metrics.Add([pscustomobject]@{Image=$script:id;Text=$s;X=$x;Y=$y;Width=[math]::Round($bb.Width*$scale,2);Height=[math]::Round($bb.Height*$scale,2);Font=$size;Weight=$weight})
}
function Photo($name,$x=0,$y=0,$w=1280,$h=720){$im=GradedAsset $name;$g.DrawImage($im,[single]$x,[single]$y,[single]$w,[single]$h)}
function PortraitHead($name,$cx,$top,$headHeight,$srcCX,$srcTop,$srcHeadHeight){$im=GradedAsset $name;$scale=$headHeight/$srcHeadHeight;$g.DrawImage($im,[single]($cx-$srcCX*$scale),[single]($top-$srcTop*$scale),[single]($im.Width*$scale),[single]($im.Height*$scale))}
function PhotoExtendedTop($name,$offset){
 $im=GradedAsset $name
 for($xx=0;$xx -lt 1280;$xx++){$sx=[math]::Min($im.Width-1,[int]($xx*$im.Width/1280));Rect $xx 0 1 ($offset+1) ($im.GetPixel($sx,0))}
 $g.DrawImage($im,[single]0,[single]$offset,[single]1280,[single]720)
}
function DiagramBackdrop(){$im=[System.Drawing.Image]::FromFile((Join-Path $assets 'background_charcoal.png'));$g.DrawImage($im,0,0,1280,720);$im.Dispose()}
function LightStroke($points,$color,$width=3){
 $path=[System.Drawing.Drawing2D.GraphicsPath]::new();$pts=[System.Collections.Generic.List[System.Drawing.PointF]]::new()
 for($q=0;$q -lt $points.Count;$q+=2){$pts.Add([System.Drawing.PointF]::new($points[$q],$points[$q+1]))}
 $path.AddLines($pts.ToArray());$pen=[System.Drawing.Pen]::new($color,[single]$width);$pen.LineJoin='Round';$pen.StartCap='Round';$pen.EndCap='Round';$path.Widen($pen);$pen.Dispose()
 SoftGlow $path $color 9 1.2;SoftGlow $path $color 2.7 0.8
 $br=[System.Drawing.SolidBrush]::new($color);$g.FillPath($br,$path);$br.Dispose();$path.Dispose()
}
function Arrow($x1,$y1,$c1x,$c1y,$c2x,$c2y,$x2,$y2,$color,$width=6,$dash=$false){
 # One closed silhouette: flat start, constant-width curved shaft, integrated sharp tip.
 $centres=[System.Collections.Generic.List[System.Drawing.PointF]]::new()
 for($n=0;$n -le 120;$n++){$t=$n/120.0;$u=1-$t;$px=$u*$u*$u*$x1+3*$u*$u*$t*$c1x+3*$u*$t*$t*$c2x+$t*$t*$t*$x2;$py=$u*$u*$u*$y1+3*$u*$u*$t*$c1y+3*$u*$t*$t*$c2y+$t*$t*$t*$y2;$centres.Add([System.Drawing.PointF]::new($px,$py))}
 $head=[math]::Max(12.0,3.2*$width);$distance=0.0;$base=119
 while($base -gt 1 -and $distance -lt $head){$dx=$centres[$base+1].X-$centres[$base].X;$dy=$centres[$base+1].Y-$centres[$base].Y;$distance+=[math]::Sqrt($dx*$dx+$dy*$dy);if($distance -lt $head){$base--}}
 $left=[System.Collections.Generic.List[System.Drawing.PointF]]::new();$right=[System.Collections.Generic.List[System.Drawing.PointF]]::new()
 for($n=0;$n -le $base;$n++){$a=[math]::Max(0,$n-1);$b=[math]::Min($base+1,$n+1);$dx=$centres[$b].X-$centres[$a].X;$dy=$centres[$b].Y-$centres[$a].Y;$len=[math]::Sqrt($dx*$dx+$dy*$dy);$nx=-$dy/$len;$ny=$dx/$len;$left.Add([System.Drawing.PointF]::new(($centres[$n].X+$nx*$width/2),($centres[$n].Y+$ny*$width/2)));$right.Add([System.Drawing.PointF]::new(($centres[$n].X-$nx*$width/2),($centres[$n].Y-$ny*$width/2)))}
 $dx=$x2-$centres[$base].X;$dy=$y2-$centres[$base].Y;$len=[math]::Sqrt($dx*$dx+$dy*$dy);$nx=-$dy/$len;$ny=$dx/$len;$half=$head*0.46
 $poly=[System.Collections.Generic.List[System.Drawing.PointF]]::new();$poly.AddRange($left.ToArray());$poly.Add([System.Drawing.PointF]::new(($centres[$base].X+$nx*$half),($centres[$base].Y+$ny*$half)));$poly.Add([System.Drawing.PointF]::new($x2,$y2));$poly.Add([System.Drawing.PointF]::new(($centres[$base].X-$nx*$half),($centres[$base].Y-$ny*$half)))
 for($n=$right.Count-1;$n -ge 0;$n--){$poly.Add($right[$n])}
 $p=[System.Drawing.Drawing2D.GraphicsPath]::new();$p.AddPolygon($poly.ToArray())
 if($script:id -ne '06'){SoftGlow $p $color 3 0.20}
 $brush=[System.Drawing.SolidBrush]::new($color);$g.FillPath($brush,$p);$brush.Dispose();$bounds=$p.GetBounds();$p.Dispose()
 $arrows.Add([pscustomobject]@{Image=$script:id;StartX=$x1;StartY=$y1;TipX=$x2;TipY=$y2;Width=$width;BoundsX=$bounds.X;BoundsY=$bounds.Y;BoundsWidth=$bounds.Width;BoundsHeight=$bounds.Height;IntegratedTip=$true})
}
function Youtube($x,$y,$w){
 $h=$w*.66;$p=RoundPath $x $y $w $h ($w*.15)
 SoftGlow $p $RedColor 28 0.64;SoftGlow $p $RedColor 9 0.68
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(C 255 255 5 21),(C 255 242 0 12));$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $tri=[System.Drawing.PointF[]]@([System.Drawing.PointF]::new(($x+$w*.40),($y+$h*.25)),[System.Drawing.PointF]::new(($x+$w*.40),($y+$h*.75)),[System.Drawing.PointF]::new(($x+$w*.69),($y+$h*.50)))
 $g.FillPolygon([System.Drawing.Brushes]::White,$tri)
}

