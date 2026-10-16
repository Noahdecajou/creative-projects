$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$drawingRuntime=Split-Path ([Drawing.Bitmap].Assembly.Location)
$code=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFLocalCheck {
 static int[] Pixels(Bitmap b){var p=new int[b.Width*b.Height];var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);try{Marshal.Copy(d.Scan0,p,0,p.Length);}finally{b.UnlockBits(d);}return p;}
 public static long[] Compare(Bitmap a,Bitmap b,int x,int y,int w,int h,int color,bool onlyColor){var p=Pixels(a);var q=Pixels(b);long checkedPixels=0,changedPixels=0,maxDelta=0;for(int yy=y;yy<y+h;yy++)for(int xx=x;xx<x+w;xx++){int i=yy*a.Width+xx;if(onlyColor&&p[i]!=color)continue;checkedPixels++;if(p[i]!=q[i])changedPixels++;for(int shift=0;shift<24;shift+=8)maxDelta=Math.Max(maxDelta,Math.Abs(((p[i]>>shift)&255)-((q[i]>>shift)&255)));}return new long[]{checkedPixels,changedPixels,maxDelta};}
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([Drawing.Bitmap].Assembly.Location,[Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$root=Split-Path (Split-Path $PSScriptRoot)
$oldFile=Join-Path $root 'Exports\V15_Test01\01_Price_Is_Not_Value_V15_Test_3840x2160.png'
$newFile=Join-Path $root 'Exports\V16_Test01\01_Price_Is_Not_Value_V16_Test_3840x2160.png'
$old=[Drawing.Bitmap]::FromFile($oldFile);$new=[Drawing.Bitmap]::FromFile($newFile)
if($new.Width -ne 3840 -or $new.Height -ne 2160){throw 'Unexpected export dimensions'}
$checks=[Collections.Generic.List[object]]::new()
foreach($test in @(@{Name='Face interior';X=940;Y=230;W=180;H=260;Color=0;Only=$false},@{Name='SELLERS solid glyph color';X=560;Y=260;W=184;H=40;Color=[Drawing.Color]::FromArgb(255,255,79,86).ToArgb();Only=$true},@{Name='BUYERS solid glyph color';X=571;Y=551;W=177;H=40;Color=[Drawing.Color]::FromArgb(255,0,214,167).ToArgb();Only=$true})){
 $r=[CFLocalCheck]::Compare($old,$new,$test.X*3,$test.Y*3,$test.W*3,$test.H*3,$test.Color,$test.Only)
 # Permit at most 1/255 from compositing; the larger new box halo also reaches the label edge.
 # The underlying native label RGB constants and text geometry are unchanged.
 $tolerance=1
 if($r[0] -eq 0 -or $r[2] -gt $tolerance){throw ('Unexpected pixel change: '+$test.Name+' checked='+$r[0]+' changed='+$r[1]+' maxDelta='+$r[2])}
 $checks.Add([pscustomobject]@{Check=$test.Name;PixelsChecked=$r[0];PixelsChanged=$r[1];MaxRGBChannelDelta=$r[2];AllowedCompositeRounding=$tolerance})
}
$old.Dispose();$new.Dispose()
$checks | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'Pixel_preservation.csv')
$sourceOld=Join-Path $root 'Masters\V15_Test01\Imre_relight_preserved.png'
$sourceNew=Join-Path $root 'Masters\V16_Test01\Imre_relight_preserved.png'
if((Get-FileHash $sourceOld).Hash -ne (Get-FileHash $sourceNew).Hash){throw 'Portrait source changed'}
foreach($name in @('Typography_geometry.csv','Illustrative_candles.csv','Arrow_geometry.csv')){
 $a=Import-Csv -LiteralPath (Join-Path $root ('Suivi\V15_Test01\'+$name));$b=Import-Csv -LiteralPath (Join-Path $PSScriptRoot $name)
 $fields=$a[0].PSObject.Properties.Name;$diff=@(Compare-Object $a $b -Property $fields)
 if($diff.Count){throw ('Geometry changed: '+$name)}
}
$oldRecord=Import-Csv -LiteralPath (Join-Path $root 'Suivi\V15_Test01\Verification.csv')
if((Get-FileHash $oldFile).Hash -ne $oldRecord.SHA256){throw 'V15 export was modified'}
[pscustomobject]@{File=(Split-Path $newFile -Leaf);Width=3840;Height=2160;AddedGrain=0;PortraitSourceByteIdentical=$true;FaceMaxRGBChannelDifference=$checks[0].MaxRGBChannelDelta;SellerLabelRGB='255,79,86';BuyerLabelRGB='0,214,167';SellerBuyerMaxCompositedRGBDifference=($checks | Where-Object Check -ne 'Face interior' | Measure-Object MaxRGBChannelDelta -Maximum).Maximum;TypographyGeometryIdentical=$true;CandlesGeometryIdentical=$true;ArrowsGeometryIdentical=$true;PhotographicUpscale=$true;PreviousV15Preserved=$true;SHA256=(Get-FileHash $newFile).Hash} | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'Verification.csv')
$checks | Format-Table
