$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$out=Join-Path $root 'Apercus\V07\Controle_100pct'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class CompareV7{
static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
public static long[] Outside(Bitmap a,Bitmap b,Rectangle[] areas){var av=Read(a);var bv=Read(b);long changed=0,outside=0;for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int p=(y*a.Width+x)*4;bool diff=false;for(int c=0;c<4;c++)if(av[p+c]!=bv[p+c]){diff=true;break;}if(!diff)continue;changed++;bool allowed=false;foreach(var r in areas)if(r.Contains(x,y)){allowed=true;break;}if(!allowed)outside++;}return new long[]{changed,outside};}
public static long Region(Bitmap a,Bitmap b,Rectangle r){var av=Read(a);var bv=Read(b);long n=0;for(int y=r.Top;y<r.Bottom;y++)for(int x=r.Left;x<r.Right;x++){int p=(y*a.Width+x)*4;for(int c=0;c<4;c++)if(av[p+c]!=bv[p+c]){n++;break;}}return n;}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
function Num($x){[double]::Parse(([string]$x).Replace(',','.'),[System.Globalization.CultureInfo]::InvariantCulture)}
$lights=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Glow_geometry_V07.csv')
$report=foreach($i in 1..8){
 $id='{0:00}' -f $i;$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V07') -Filter ($id+'_*.png')|Select-Object -First 1
 $a=[System.Drawing.Bitmap]::FromFile((Join-Path $root ('Exports_4K\V06\'+$file.Name)));$b=[System.Drawing.Bitmap]::FromFile($file.FullName)
 $areas=[System.Collections.Generic.List[System.Drawing.Rectangle]]::new()
 foreach($light in ($lights|Where-Object {$_.Image -eq $id})){$pad=[math]::Max(34,(Num $light.Pad)+2);$x=[int][math]::Floor(((Num $light.X)-$pad)*3);$y=[int][math]::Floor(((Num $light.Y)-$pad)*3);$w=[int][math]::Ceiling(((Num $light.Width)+2*$pad)*3)+3;$h=[int][math]::Ceiling(((Num $light.Height)+2*$pad)*3)+3;$areas.Add([System.Drawing.Rectangle]::new($x,$y,$w,$h))}
 if($id -in @('01','02')){$areas.Add([System.Drawing.Rectangle]::new(278,740,1830,1092))}
 if($id -eq '06'){$areas.Add([System.Drawing.Rectangle]::new(790,367,2280,1793))}
 $diff=[CompareV7]::Outside($a,$b,$areas.ToArray());$a.Dispose();$b.Dispose()
 if($diff[1] -ne 0){throw ('Unexpected changes outside requested zones '+$id+': '+$diff[1])}
 [pscustomobject]@{Image=$id;ChangedPixels=$diff[0];OutsideRequestedAreas=$diff[1];AllowedAreas=($areas|ForEach-Object {$_.ToString()}) -join ';'}
}
$report|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Corrections_locales_V06_V07.csv')
$assets=foreach($name in @('Casper_front_photo.png','Riz_front_photo.png','laptop_plate.png','03_scene_retouch.png','05_scene_photo_test.png','07_scene_photo_test.png','08_scene_photo_test.png','chart_balance.png','chart_trend.png','chart_trigger.png','chart_profile.png','chart_accept.png')){$a=(Get-FileHash -LiteralPath (Join-Path $root ('Masters\V06\'+$name))).Hash;$b=(Get-FileHash -LiteralPath (Join-Path $root ('Masters\V07\'+$name))).Hash;if($a -ne $b){throw ('Preserved component changed: '+$name)};[pscustomobject]@{File=$name;SHA256=$b;ByteIdenticalToV06=$true}}
$assets|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Composants_preserves_V06_V07.csv')
$checks=@(@('01','Casper',900,230,300,290),@('02','Casper',900,230,300,290),@('03','Riz',286,165,84,102),@('03','Casper',940,180,85,90),@('04','Casper',200,270,75,110),@('04','Riz',935,172,208,228),@('05','Casper',598,177,130,178),@('07','Riz',251,224,154,115),@('07','Casper',860,203,140,153),@('08','Riz',945,166,129,161))
$faces=foreach($v in $checks){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V07') -Filter ($v[0]+'_*.png')|Select-Object -First 1;$a=[System.Drawing.Bitmap]::FromFile((Join-Path $root ('Exports_4K\V06\'+$file.Name)));$b=[System.Drawing.Bitmap]::FromFile($file.FullName);$r=[System.Drawing.Rectangle]::new(($v[2]*3),($v[3]*3),($v[4]*3),($v[5]*3));$n=[CompareV7]::Region($a,$b,$r);$a.Dispose();$b.Dispose();if($n -ne 0){throw ('Facial sample changed: '+$v[0]+' '+$v[1])};[pscustomobject]@{Image=$v[0];Person=$v[1];NativeRegion=$r.ToString();ChangedPixels=$n}}
$faces|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Visages_preserves_V06_V07.csv')
$typOld=Import-Csv -LiteralPath (Join-Path $root 'Suivi\V06\Typography_geometry_V06.csv')|Where-Object {$_.Image -notlike 'SCREEN*'}
$typNew=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry_V07.csv')|Where-Object {$_.Image -notlike 'SCREEN*'}
$typDiff=Compare-Object $typOld $typNew -Property Image,Text,X,Y,Width,Height,Font,Weight
if($typDiff){throw 'Approved external typography changed'}
$jobs=@(@('01',95,260,605,349,'01_Ecran'),@('02',95,260,605,349,'02_Ecran'),@('06',446,179,392,410,'06_Casper_visage'),@('08',14,156,872,172,'08_Lueurs_reduites'))
foreach($j in $jobs){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V07') -Filter ($j[0]+'_*.png')|Select-Object -First 1;$im=[System.Drawing.Bitmap]::FromFile($file.FullName);$crop=$im.Clone([System.Drawing.Rectangle]::new(($j[1]*3),($j[2]*3),($j[3]*3),($j[4]*3)),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $out ($j[5]+'.png')));$im.Dispose();$crop.Dispose()}
$report|Format-Table Image,ChangedPixels,OutsideRequestedAreas
'12 components unchanged; 10 face regions preserved; external copy and geometry unchanged.'
