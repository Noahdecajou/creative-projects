$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$sampsa=@(2490,3690,7950,12930,16380,20100,24600,29310,34200,41490,44850,53100,64350,72360,77760,79920,86340,89640,96900,109650)
$riz=@(1260,5400,19200,32820)
$closed=@(26940,57060,54990)
$data=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'capture_manifest.csv')
$selected=@();$review=foreach($row in $data){
 $frame=[int]$row.Frame;$status='Not selected';$reason='Similar pose or less suitable expression/framing';$person='Sampsa'
 if($frame -in @(1260,5400,19200,32820,54990,87750)){$person='Riz'}
 if($frame -in $closed){$reason='Blink or lowered/partly closed eyes'}
 if($frame -eq 94200){$person='Duo';$reason='Wide shot; faces too small for portrait source'}
 if($frame -in $sampsa -or $frame -in $riz){
  $status='Selected';$reason='Natural expression, open eyes, usable portrait'
  $name=$person+'_'+$row.Timecode.Replace(':','-')+'.jpg'
  $target=Join-Path $root ('sources_HD\'+$person+'\'+$name)
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('candidates\'+$row.File)) -Destination $target -Force
  if((Get-FileHash -LiteralPath $target).Hash -ne $row.SHA256){throw 'Source copy hash mismatch'}
  $selected+=[pscustomobject]@{Person=$person;Name=$name;Path=$target;Timecode=$row.Timecode;Width=$row.Width;Height=$row.Height;SHA256=$row.SHA256}
 }
 [pscustomobject]@{File=$row.File;Frame=$frame;Person=$person;Timecode=$row.Timecode;Width=$row.Width;Height=$row.Height;Status=$status;Reason=$reason;SHA256=$row.SHA256}
}
$review | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Review_50_passages.csv') -NoTypeInformation -Encoding utf8
$selected | Select-Object Person,Name,Timecode,Width,Height,SHA256 | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Selected_sources_24.csv') -NoTypeInformation -Encoding utf8
$font=[Drawing.Font]::new('Arial',17,[Drawing.FontStyle]::Bold)
foreach($person in @('Sampsa','Riz')){
 $photos=@($selected | Where-Object Person -eq $person)
 $bmp=[Drawing.Bitmap]::new(1600,([int][Math]::Ceiling($photos.Count/4)*260))
 $g=[Drawing.Graphics]::FromImage($bmp);$g.Clear([Drawing.Color]::FromArgb(20,20,23));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($i=0;$i -lt $photos.Count;$i++){
  $x=($i%4)*400;$y=[Math]::Floor($i/4)*260;$im=[Drawing.Image]::FromFile($photos[$i].Path)
  $g.DrawImage($im,$x,$y,400,225);$im.Dispose();$g.DrawString(($person+' | '+$photos[$i].Timecode),$font,[Drawing.Brushes]::White,($x+10),($y+231))
 }
 $bmp.Save((Join-Path $root ('apercus\Photos_HD_'+$person+'_selection.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$bmp.Dispose()
}
$font.Dispose();$selected | Group-Object Person | Select-Object Name,Count | ConvertTo-Json
