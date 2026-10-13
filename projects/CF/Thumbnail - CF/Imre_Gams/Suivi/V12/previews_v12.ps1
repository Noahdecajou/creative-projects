$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot)
$preview=Join-Path $root 'Apercus\V12'
$exports=Join-Path $root 'Exports\V12'
$jpeg=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$quality=[System.Drawing.Imaging.EncoderParameters]::new(1)
$quality.Param[0]=[System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality,[long]95)
function C($a,$r,$gg,$bb){return [System.Drawing.Color]::FromArgb([int]$a,[int]$r,[int]$gg,[int]$bb)}
foreach($file in Get-ChildItem -LiteralPath $exports -Filter '*.png' | Where-Object Name -NotLike '08_*'){
 $id=$file.Name.Substring(0,2);$canvas=[System.Drawing.Image]::FromFile($file.FullName)
 foreach($size in @(1280,640,320)){
  $small=[System.Drawing.Bitmap]::new($size,[int]($size*9/16));$sg=[System.Drawing.Graphics]::FromImage($small)
  $sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose()
  $small.Save((Join-Path $preview ($id+'_'+$size+'.jpg')),$jpeg,$quality);$small.Dispose()
 };$canvas.Dispose()
}
foreach($tw in @(640,320)){
 $th=[int]($tw*9/16);$sheet=New-Object System.Drawing.Bitmap(($tw*2),(($th+26)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear((C 255 20 20 20));$sg.InterpolationMode='HighQualityBicubic';$font=New-Object System.Drawing.Font('Arial',12,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
 for($j=0;$j -lt 8;$j++){$label='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($label+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+26);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(('IMRE GAMS / '+$label),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+6));$im.Dispose()};$sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $preview ('Planche_V12_'+$tw+'.jpg')),$jpeg,$quality);$sheet.Dispose()
}













$quality.Dispose()

