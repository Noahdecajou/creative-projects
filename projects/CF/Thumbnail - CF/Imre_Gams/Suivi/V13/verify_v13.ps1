$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFV13Diff {
 static int[] Pixels(string path){using(var b=new Bitmap(path)){var r=new Rectangle(0,0,b.Width,b.Height);var d=b.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new int[b.Width*b.Height];try{Marshal.Copy(d.Scan0,p,0,p.Length);}finally{b.UnlockBits(d);}return p;}}
 public static long[] Check(string older,string newer,Rectangle allowed){
  var a=Pixels(older);var b=Pixels(newer);long changed=0,outside=0;int xmin=3840,ymin=2160,xmax=-1,ymax=-1;
  for(int i=0;i<a.Length;i++){if(a[i]==b[i])continue;int x=i%3840,y=i/3840;changed++;if(!allowed.Contains(x,y))outside++;xmin=Math.Min(xmin,x);ymin=Math.Min(ymin,y);xmax=Math.Max(xmax,x);ymax=Math.Max(ymax,y);}
  return new long[]{changed,outside,xmin,ymin,xmax,ymax};
 }
 public static long Region(string older,string newer,Rectangle region){var a=Pixels(older);var b=Pixels(newer);long diff=0;for(int y=region.Top;y<region.Bottom;y++)for(int x=region.Left;x<region.Right;x++)if(a[y*3840+x]!=b[y*3840+x])diff++;return diff;}
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$root=Split-Path (Split-Path $PSScriptRoot)
$checks=[System.Collections.Generic.List[object]]::new()
function Check($name,$passed,$detail){$checks.Add([pscustomobject]@{Check=$name;Passed=[bool]$passed;Detail=$detail});if(-not $passed){throw ($name+': '+$detail)}}
function Same($a,$b){return (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash}
function Number($s){return [double]::Parse($s.Replace(',','.'),[System.Globalization.CultureInfo]::InvariantCulture)}
$files=@(Get-ChildItem -LiteralPath (Join-Path $root 'Exports/V13') -Filter '*.png' -File | Sort-Object Name)
Check 'Eight exports' ($files.Count -eq 8) 'Complete set'
$diffs=@()
foreach($file in $files){
 $old=Join-Path (Join-Path $root 'Exports/V12') $file.Name
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 Check ($file.Name+' dimensions') ($im.Width -eq 3840 -and $im.Height -eq 2160) '3840 x 2160';$im.Dispose()
 $id=[int]$file.Name.Substring(0,2)
 if($id -gt 2){Check ($file.Name+' unchanged') (Same $old $file.FullName) 'Byte-identical to V12'}else{
  $allowed=[System.Drawing.Rectangle]::new(0,570,2430,1260)
  $stats=[CFV13Diff]::Check($old,$file.FullName,$allowed)
  $diffs+=[pscustomobject]@{Image=$id;ChangedPixels=$stats[0];OutsideDiagram=$stats[1];MinX=$stats[2];MinY=$stats[3];MaxX=$stats[4];MaxY=$stats[5]}
  Check ($file.Name+' localized edit') ($stats[0] -gt 0 -and $stats[1] -eq 0) ('Changed pixels '+$stats[0]+'; outside diagram '+$stats[1]+'; bounds '+($stats[2..5] -join ','))
  $portrait=[System.Drawing.Rectangle]::new(2430,0,1410,2160)
  Check ($file.Name+' portrait unchanged') ([CFV13Diff]::Region($old,$file.FullName,$portrait) -eq 0) 'Every pixel in portrait region identical to V12'
  $footer=[System.Drawing.Rectangle]::new(0,1845,3840,315)
  Check ($file.Name+' footer unchanged') ([CFV13Diff]::Region($old,$file.FullName,$footer) -eq 0) 'Every pixel below logical y615 identical'
 }
 $master=Join-Path (Join-Path $root 'Masters/V13') ($file.Name.Replace('_3840x2160','_master'))
 Check ($file.Name+' clean master') (Same $file.FullName $master) 'No grain added on export'
}
$diffs | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Pixel_preservation.csv')
$oldGeometry=Import-Csv -LiteralPath (Join-Path $root 'Suivi/V12/Typography_geometry.csv')
$current=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$protected=@('PRICE IS NOT','VALUE','Auction Market Theory','WHY','BREAKOUTS','FAIL','Read the Market Regime')
$oldTitles=@($oldGeometry | Where-Object {[int]$_.Image -le 2 -and $_.Text -in $protected})
$newTitles=@($current | Where-Object Text -In $protected)
$delta=Compare-Object $oldTitles $newTitles -Property Image,Text,X,Y,Width,Height,Font,Weight
Check 'All titles and straplines retained' (-not $delta) 'Exact positions, wording, font sizes and weights'
foreach($title in $oldTitles){
 $file=$files | Where-Object {$_.Name.StartsWith($title.Image+'_')}
 $x=[int][math]::Floor(3*(Number $title.X));$y=[int][math]::Floor(3*(Number $title.Y));$w=[int][math]::Ceiling(3*(Number $title.Width));$h=[int][math]::Ceiling(3*(Number $title.Height))
 $rectangle=[System.Drawing.Rectangle]::new($x,$y,$w,$h)
 Check ('Title pixels '+$title.Image+' '+$title.Text) ([CFV13Diff]::Region((Join-Path (Join-Path $root 'Exports/V12') $file.Name),$file.FullName,$rectangle) -eq 0) 'Exact original title pixels'
}
$originalCopy=@($oldGeometry | Where-Object {[int]$_.Image -le 2})
$delta=Compare-Object $originalCopy $current -Property Image,Text
Check 'Diagram wording retained' (-not $delta) 'All existing English labels kept'
$candles=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Illustrative_candles.csv')
Check 'Candles recorded' ($candles.Count -eq 44) '22 in image 01; 11 per regime in image 02'
foreach($c in $candles){
 $valid=(Number $c.HighY) -le [math]::Min((Number $c.OpenY),(Number $c.CloseY)) -and (Number $c.LowY) -ge [math]::Max((Number $c.OpenY),(Number $c.CloseY))
 Check ('OHLC '+$c.Image+' '+$c.X) $valid 'Wick encloses body'
}
foreach($imageId in 1..8){foreach($size in @(1280,640,320)){Check ('Preview '+$imageId+' '+$size) (Test-Path -LiteralPath (Join-Path $root ('Apercus/V13/'+('{0:00}' -f $imageId)+'_'+$size+'.jpg'))) 'Preview exists'}}
$checks | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_artwork_V13.csv')
Write-Output ('VERIFIED: '+$checks.Count+' checks passed; changes confined to diagrams 01/02; portrait/title pixels preserved; 03-08 unchanged.')
