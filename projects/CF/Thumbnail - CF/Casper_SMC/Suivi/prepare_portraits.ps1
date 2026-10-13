$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot
$assets=Join-Path $root 'Masters\V01'
function Polygon($numbers){
 $p=New-Object System.Drawing.Drawing2D.GraphicsPath
 $pts=for($i=0;$i -lt $numbers.Count;$i+=2){[System.Drawing.PointF]::new([single]$numbers[$i],[single]$numbers[$i+1])}
 $p.AddPolygon([System.Drawing.PointF[]]$pts);return $p
}
function CleanPortrait($original,$repair,$output,$patch,$exclude=@()){
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $assets $original));$fix=[System.Drawing.Bitmap]::FromFile((Join-Path $assets $repair))
 $b=New-Object System.Drawing.Bitmap(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[System.Drawing.Graphics]::FromImage($b);$g.CompositingMode='SourceCopy';$g.DrawImageUnscaled($im,0,0)
 $g.ScaleTransform(3,3);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.SmoothingMode='AntiAlias'
 $p=Polygon $patch;$g.SetClip($p);$p.Dispose()
 foreach($shape in $exclude){$p=Polygon $shape;$g.SetClip($p,[System.Drawing.Drawing2D.CombineMode]::Exclude);$p.Dispose()}
 $g.DrawImage($fix,[single]0,[single]0,[single]1280,[single]720)
 $g.Dispose();$im.Dispose();$fix.Dispose();$b.Save((Join-Path $assets $output),[System.Drawing.Imaging.ImageFormat]::Png);$b.Dispose()
}
# Logical 1280 x 720 coordinates. All untouched pixels remain the original cutout.
$head12=@(0,0,1280,0,1280,282,816,282,774,303,750,317,744,356,737,403,730,443,725,469,705,471,676,462,658,432,643,399,631,364,623,327,619,298,618,282,0,282)
$arm12left=@(480,720,470,692,468,663,478,647,501,637,529,638,555,645,579,658,625,674,681,696,737,712,788,720)
$arm12right=@(1280,720,895,720,881,681,884,650,900,621,921,604,946,598,966,599,989,617,1013,648,1040,686,1050,720)
CleanPortrait 'Casper_00-12-00_cutout.png' 'Casper_front_clean_generated.png' 'Casper_front_photo.png' @(0,282,1280,282,1280,720,0,720) @($head12,$arm12left,$arm12right)
$head16=@(0,0,1280,0,1280,290,852,290,807,319,789,351,773,386,759,425,746,460,734,480,707,481,679,471,667,446,655,409,648,369,645,327,646,291,0,291)
$arm16left=@(0,720,0,690,336,690,343,660,361,643,378,638,401,645,428,658,450,664,453,657,465,648,481,650,492,665,505,680,510,720)
$arm16right=@(1280,720,978,720,939,693,926,673,914,648,918,630,935,615,957,604,980,600,1002,607,1024,624,1044,637,1073,631,1081,652,1091,685,1096,720)
CleanPortrait 'Casper_00-16-00_cutout.png' 'Casper_explain_clean_generated.png' 'Casper_explain_photo.png' @(0,290,1280,290,1280,720,0,720) @($head16,$arm16left,$arm16right)
CleanPortrait 'Casper_00-20-00_cutout.png' 'Casper_conversation_clean_generated.png' 'Casper_conversation_photo.png' @(800,392,858,397,898,447,940,515,970,575,954,608,897,623,894,720,816,720,836,633,819,579,815,543,801,514,791,471,788,430)
$micRiz=@(542,405,598,405,628,429,631,455,619,495,606,523,620,558,612,584,580,620,578,720,518,720,520,653,490,646,458,633,442,605,447,574,471,531,480,510,486,476,510,441)
CleanPortrait 'Riz_01-16-00_cutout.png' 'Riz_front_clean_generated.png' 'Riz_front_photo.png' $micRiz
CleanPortrait 'Riz_01-34-00_cutout.png' 'Riz_conversation_clean_generated.png' 'Riz_conversation_photo.png' $micRiz
# Review sheet at 640 pixels per original 16:9 canvas.
$files=@('Casper_front_photo.png','Casper_explain_photo.png','Casper_conversation_photo.png','Riz_front_photo.png','Riz_conversation_photo.png')
$sheet=New-Object System.Drawing.Bitmap(1920,760);$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.Color]::FromArgb(35,35,35));$g.InterpolationMode='HighQualityBicubic'
$font=New-Object System.Drawing.Font('Arial',18)
for($i=0;$i -lt $files.Count;$i++){$im=[System.Drawing.Image]::FromFile((Join-Path $assets $files[$i]));$x=($i%3)*640;$y=[math]::Floor($i/3)*380;$g.DrawImage($im,[single]$x,[single]$y,[single]640,[single]360);$g.DrawString($files[$i],$font,[System.Drawing.Brushes]::White,[single]($x+5),[single]($y+353));$im.Dispose()}
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $root 'Apercus\Sources\Portraits_detoures.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()

