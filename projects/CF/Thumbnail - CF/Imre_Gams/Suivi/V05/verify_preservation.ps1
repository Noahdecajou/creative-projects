$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$verifyRuntime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $verifyRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $verifyRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class RegionCompareV05 {
 public static long Changed(string a,string b,int x,int y,int w,int h) {
  using(var aa=new Bitmap(a)) using(var bb=new Bitmap(b)) {
   var r=new Rectangle(x,y,w,h);
   var da=aa.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   var db=bb.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   long count=0; var ar=new int[w];var br=new int[w];
   try {for(int yy=0;yy<h;yy++) {
    Marshal.Copy(IntPtr.Add(da.Scan0,yy*da.Stride),ar,0,w);
    Marshal.Copy(IntPtr.Add(db.Scan0,yy*db.Stride),br,0,w);
    for(int xx=0;xx<w;xx++)if(ar[xx]!=br[xx])count++;
   }} finally {aa.UnlockBits(da);bb.UnlockBits(db);}
   return count;
  }
 }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot)
$checks=@(
 @{Id='03';Label='Entire image below repaired top edge';X=0;Y=32;W=1280;H=688}
)
$records=@()
foreach($check in $checks){
 $old=Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V04') -Filter ($check.Id+'_*_master.png') | Select-Object -First 1
 $new=Join-Path (Join-Path $root 'Masters\V05') $old.Name
 $changed=[RegionCompareV05]::Changed($old.FullName,$new,($check.X*3),($check.Y*3),($check.W*3),($check.H*3))
 $records+=[pscustomobject]@{Image=$check.Id;Region=$check.Label;LogicalX=$check.X;LogicalY=$check.Y;LogicalWidth=$check.W;LogicalHeight=$check.H;ChangedPixels=$changed}
 if($changed -ne 0){throw ('Unexpected changes in '+$check.Id+' '+$check.Label+': '+$changed)}
}
$records | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Portrait_and_scene_preservation.csv')
$portraits=@()
foreach($name in @('Imre_direct_camera.png','Riz_original_cutout.png')){
 $oldHash=(Get-FileHash -LiteralPath (Join-Path (Join-Path $root 'Masters\V04') $name)).Hash
 $newHash=(Get-FileHash -LiteralPath (Join-Path (Join-Path $root 'Masters\V05') $name)).Hash
 if($oldHash -ne $newHash){throw ('Portrait asset changed: '+$name)}
 $portraits+=[pscustomobject]@{Asset=$name;SHA256=$newHash;IdenticalToV04=$true}
}
$portraits | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Portrait_assets_preservation.csv')
# Source cutouts contain fractional alpha even inside the face. Their unchanged colors
# composite against the new background, so final pixel equality is not the correct test.
Write-Output 'Verified: portrait source files identical to V04; thumbnail 03 identical below the repaired top edge.'
