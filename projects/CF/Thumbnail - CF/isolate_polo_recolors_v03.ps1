$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$items = Get-Content -Raw -LiteralPath (Join-Path $root 'Suivi\Scott_Pulcini_Thumbnails_V03\Generated_sources.json') | ConvertFrom-Json
$polygons = @{
    '01' = @(650,540,1672,540,1672,941,650,941)
    '02' = @(650,570,1672,570,1672,941,650,941)
    '03' = @(870,340,1610,340,1610,780,870,780)
    '04' = @(0,480,925,480,925,941,0,941)
    '05' = @(290,370,1320,370,1320,850,290,850)
    '06' = @(305,460,1345,460,1345,941,305,941)
    '07' = @(970,315,1672,315,1672,780,970,780)
    '08' = @(20,310,735,310,735,780,20,780)
}
$code = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class LocalPoloComposite {
  public static long Apply(string originalPath, string generatedPath, string outputPath, string maskPath, int[] coordinates, string id) {
    using (var original = new Bitmap(originalPath))
    using (var generated = new Bitmap(generatedPath))
    using (var result = new Bitmap(original))
    using (var mask = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb))
    using (var path = new GraphicsPath()) {
      if (original.Width != generated.Width || original.Height != generated.Height) throw new Exception("Image dimensions must match before localized compositing: " + id);
      var points = new Point[coordinates.Length / 2];
      for (int i=0;i<points.Length;i++) points[i] = new Point(coordinates[i*2], coordinates[i*2+1]);
      path.AddPolygon(points);
      long changed = 0;
      var bounds = Rectangle.Ceiling(path.GetBounds());
      for (int y=Math.Max(0,bounds.Top);y<Math.Min(original.Height,bounds.Bottom);y++) {
        for (int x=Math.Max(0,bounds.Left);x<Math.Min(original.Width,bounds.Right);x++) {
          if (!path.IsVisible(x,y)) continue;
          // Keep the native platform inserts entirely locked.
          if (id=="01" && x>=134 && x<916 && y>=320 && y<804 && (y < 752 || x < 915-(y-752)*83.0/52.0)) continue;
          if (id=="02" && x>=134 && x<916 && y>=322 && y<803 && (y < 781 || x < 915-(y-781)*30.0/22.0)) continue;
          if (id=="04" && x>=486 && y>=127 && y<=620) continue;
          Color a=original.GetPixel(x,y);
          // Use the generated recolor only where the original contains cyan cloth
          // and the generated result is neutral fabric with a significant change.
          Color b=generated.GetPixel(x,y);
          bool cyanHint=a.G>a.R+2 && a.B>a.R+2 && a.B>0.70*a.G && a.G>0.50*a.B;
          bool neutralResult=Math.Abs(b.G-b.R)<45 && Math.Abs(b.B-b.R)<55;
          int delta=Math.Max(Math.Abs(a.R-b.R),Math.Max(Math.Abs(a.G-b.G),Math.Abs(a.B-b.B)));
          if (!cyanHint || !neutralResult || delta<13) continue;
          bool strongTeal=a.G>a.R+20 && a.B>a.R+20 && a.B>0.85*a.G && a.G>0.65*a.B;
          // Facial interiors remain pixel-locked; teal collar corners are excluded.
          if (!strongTeal) {
            if (id=="01" && x>=1110 && y<550) continue;
            if (id=="02" && x>=1110 && y<575) continue;
            if (id=="03" && x>=1180 && x<=1340 && y<405) continue;
            if (id=="04" && x>=60 && x<=407 && y<535) continue;
            if (id=="05" && x>=735 && x<=930 && y<525) continue;
            if (id=="06" && x>=710 && x<=972 && y<555) continue;
            if (id=="07" && x>=1205 && x<=1420 && y<435) continue;
            if (id=="08" && x>=265 && x<=425 && y<405) continue;
          }
          double opacity = 1.0;
          int r=(int)Math.Round(a.R*(1-opacity)+b.R*opacity);
          int g=(int)Math.Round(a.G*(1-opacity)+b.G*opacity);
          int bl=(int)Math.Round(a.B*(1-opacity)+b.B*opacity);
          result.SetPixel(x,y,Color.FromArgb(255,r,g,bl));
          mask.SetPixel(x,y,Color.FromArgb((int)Math.Round(opacity*255),255,255,255));
          changed++;
        }
      }
      result.Save(outputPath,ImageFormat.Png);
      mask.Save(maskPath,ImageFormat.Png);
      return changed;
    }
  }
}
'@
$drawingRuntime = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime')
$checks = @()
foreach ($item in $items) {
    $source = Join-Path $root ('Masters\Scott_Pulcini_Thumbnails_V02\'+$item.id+'_'+$item.slug+'_master.png')
    $dest = Join-Path $root ('Masters\Scott_Pulcini_Thumbnails_V03\'+$item.id+'_'+$item.slug+'_master.png')
    $mask = Join-Path $root ('Suivi\Scott_Pulcini_Thumbnails_V03\'+$item.id+'_masque_polo.png')
    $changed = [LocalPoloComposite]::Apply($source,$item.path,$dest,$mask,[int[]]$polygons[$item.id],$item.id)
    $checks += [pscustomobject]@{ id=$item.id; recolored_pixels=$changed; method='Generated clothing edit isolated with original teal garment mask'; original_non_garment_pixels='preserved'; garment_color=$item.color }
}
$checks | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $root 'Suivi\Scott_Pulcini_Thumbnails_V03\Garment_composite_checks.json')
$checks | Format-Table
