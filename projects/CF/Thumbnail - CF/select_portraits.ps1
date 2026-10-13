param([string]$Subject,[string[]]$Times,[int]$CropX=1400,[int]$CropY=180,[int]$CropWidth=1200,[int]$CropHeight=1300)
Add-Type -AssemblyName System.Drawing
$root=$PSScriptRoot
$sel=Join-Path $root "Selections\$Subject"
$qa=Join-Path $root "Apercus\QA_$Subject"
New-Item -ItemType Directory -Force -Path $sel,$qa | Out-Null
foreach($tc in $Times){
 $name="${Subject}_$tc.jpg"
 Copy-Item -LiteralPath (Join-Path $root "Sources_HD\$Subject\$name") -Destination (Join-Path $sel $name)
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $sel $name))
 $rect=New-Object System.Drawing.Rectangle($CropX,$CropY,$CropWidth,$CropHeight)
 $crop=$im.Clone($rect,$im.PixelFormat)
 $crop.Save((Join-Path $qa $name),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $crop.Dispose();$im.Dispose()
}
$files=@(Get-ChildItem -LiteralPath $sel -Filter '*.jpg' | Sort-Object Name)
$canvas=New-Object System.Drawing.Bitmap(1920,([int]([math]::Ceiling($files.Count/4)*300)))
$g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear([System.Drawing.Color]::FromArgb(24,24,24));$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=New-Object System.Drawing.Font('Arial',15)
for($j=0;$j -lt $files.Count;$j++){
 $im=[System.Drawing.Image]::FromFile($files[$j].FullName);$x=($j%4)*480;$y=[math]::Floor($j/4)*300
 $g.DrawImage($im,[int]$x,[int]$y,480,270);$g.DrawString($files[$j].BaseName,$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+274));$im.Dispose()
}
$canvas.Save((Join-Path $root "Apercus\${Subject}_selection.jpg"),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$font.Dispose();$g.Dispose();$canvas.Dispose()
Write-Output "Selected $($files.Count) portraits"
