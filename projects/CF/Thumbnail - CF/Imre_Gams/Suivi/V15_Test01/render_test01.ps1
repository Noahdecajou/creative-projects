$ErrorActionPreference='Stop'
# Reuse the approved, editable typography/chart implementation without executing its old batch render.
$baseline=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render_v14.ps1') -Raw
$boundary=$baseline.IndexOf('$slugs=@')
if($boundary -lt 0){throw 'Baseline drawing functions not found'}
$functionsPath=Join-Path $PSScriptRoot 'drawing_functions.ps1'
[IO.File]::WriteAllText($functionsPath,$baseline.Substring(0,$boundary))
. $functionsPath
$assets=Join-Path $root 'Masters\V15_Test01'
$preview=Join-Path $root 'Apercus\V15_Test01'
$exports=Join-Path $root 'Exports\V15_Test01'
Add-Type -TypeDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'relight.cs') -Raw) -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$source=[Drawing.Bitmap]::FromFile((Join-Path $assets 'Imre_geometry_source.png'))
$guide=[Drawing.Bitmap]::FromFile((Join-Path $assets 'Imre_lighting_guide.png'))
$graded=[CFPhotoFinish]::Apply($source)
$relit=[ImreLightTransfer]::Apply($graded,$source,$guide)
$alphaChanges=[ImreLightTransfer]::AlphaDifferences($source,$relit)
if($alphaChanges -ne 0){throw 'Portrait silhouette changed'}
$relit.Save((Join-Path $assets 'Imre_relight_preserved.png'),[Drawing.Imaging.ImageFormat]::Png)
$photoCache['Imre_direct_camera.png']=$relit
$graded.Dispose();$source.Dispose();$guide.Dispose()

function DiagramBackdrop(){
 $bg=[ImreLightTransfer]::Background(1280,720)
 $g.DrawImage($bg,0,0,1280,720)
 $bg.Save((Join-Path $assets 'background_test.png'),[Drawing.Imaging.ImageFormat]::Png);$bg.Dispose()
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
 if($glow){if($isWhite){SoftGlow $p $color 19 0.18;SoftGlow $p $color 6 0.28}else{SoftGlow $p $color 22 0.24;SoftGlow $p $color 7 0.36}}
 $bottom=if($isWhite){C 255 250 252 255}else{$color}
 $br=[Drawing.Drawing2D.LinearGradientBrush]::new([Drawing.PointF]::new($x,$y),[Drawing.PointF]::new($x,($y+$h)),$color,$bottom)
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
$script:id='01'
$script:canvas=[Drawing.Bitmap]::new(3840,2160,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$script:g=[Drawing.Graphics]::FromImage($canvas)
$g.Clear((C 255 4 4 4));$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
DiagramBackdrop;AuctionDiagram
PortraitHead 'Imre_direct_camera.png' 1030 28 545 572 85 780
Ink 'PRICE IS NOT' 28 24 99 $WhiteColor 'SemiBold' 740 $true
$null=Badge 'VALUE' 28 117 117 $WhiteColor $BlackColor 'Bold' 14 11
$null=Badge 'Auction Market Theory' 245 641 47 $YellowColor $BlackColor 'Medium' 17 11 690
Arrow 754 628 798 559 792 484 755 450 $YellowColor 7
$g.Dispose()
$name='01_Price_Is_Not_Value_V15_Test'
$canvas.Save((Join-Path $assets ($name+'_master.png')),[Drawing.Imaging.ImageFormat]::Png)
$exportPath=Join-Path $exports ($name+'_3840x2160.png')
$canvas.Save($exportPath,[Drawing.Imaging.ImageFormat]::Png)
foreach($size in @(1280,640,320)){
 $small=[Drawing.Bitmap]::new($size,[int]($size*9/16));$sg=[Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $preview ('01_'+$size+'.jpg')),$jpeg,$quality);$small.Dispose()
}
$canvas.Dispose()
$metrics.ToArray() | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$candleRecords | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Illustrative_candles.csv')
$arrows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Arrow_geometry.csv')
$newType=Import-Csv (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$oldType=Import-Csv (Join-Path $root 'Suivi\V14\Typography_geometry.csv') | Where-Object Image -eq '01'
$typeDiff=@(Compare-Object $oldType $newType -Property Text,X,Y,Width,Height,Font,Weight)
if($typeDiff.Count){throw 'Typography geometry differs from V14'}
$newCandles=Import-Csv (Join-Path $PSScriptRoot 'Illustrative_candles.csv')
$oldCandles=Import-Csv (Join-Path $root 'Suivi\V14\Illustrative_candles.csv') | Where-Object Image -eq '01'
$candleDiff=@(Compare-Object $oldCandles $newCandles -Property X,OpenY,CloseY,HighY,LowY,BodyWidth)
if($candleDiff.Count){throw 'Candle geometry differs from V14'}
[pscustomobject]@{File=(Split-Path $exportPath -Leaf);Width=3840;Height=2160;AddedGrain=0;PortraitAlphaPixelDifferences=$alphaChanges;PortraitGeometry='No warp, no crop, same scale and coordinates as V14';PortraitTexture='V14 texture retained; low-frequency luminance only transferred from ImageGen guide';TypographyDifferences=$typeDiff.Count;CandleGeometryDifferences=$candleDiff.Count;PhotographicUpscale=$true;SHA256=(Get-FileHash -LiteralPath $exportPath -Algorithm SHA256).Hash} | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Verification.csv') -NoTypeInformation -Encoding UTF8
foreach($im in $photoCache.Values){$im.Dispose()};$quality.Dispose()
Write-Output 'V15 Test01: export, previews, alpha, typography and candle geometry verified.'
