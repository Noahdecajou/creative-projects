Add-Type -AssemblyName System.Drawing
$base = Split-Path $PSScriptRoot -Parent
$seconds = @(78,12) + @(1..49 | ForEach-Object { $_ * 48 }) + @(63,70,88,112,155,425,455,498,550,590,675,748,876,1140,1170,82,86,149,152,462,465,502,505,668,1138,27,32,35,100,105,1186,2310,2315)
$font = New-Object System.Drawing.Font('Arial',20,[System.Drawing.FontStyle]::Bold)
$items = @()
for ($idx=0; $idx -lt $seconds.Count; $idx++) {
    $sec = $seconds[$idx]
    $path = 'C:\Users\notti\Downloads\frame_' + ($sec*25) + '.jpg'
    $img = [System.Drawing.Image]::FromFile($path)
    $items += [pscustomobject]@{Number=$idx+1;Seconds=$sec;Timecode=([TimeSpan]::FromSeconds($sec).ToString('hh\:mm\:ss')+':00');Path=$path;Width=$img.Width;Height=$img.Height}
    $img.Dispose()
}
$items | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'native_exports.json') -Encoding utf8
for ($page=6; $page -lt [Math]::Ceiling($items.Count/12); $page++) {
    $sheet = New-Object System.Drawing.Bitmap(1920,1584)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(18,20,24))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($j=0; $j -lt 12; $j++) {
        $i=$page*12+$j
        if ($i -ge $items.Count) { break }
        $item=$items[$i];$x=($j%3)*640;$y=[Math]::Floor($j/3)*396
        $im=[System.Drawing.Image]::FromFile($item.Path)
        $g.DrawImage($im,[int]$x,[int]$y,640,360)
        $g.DrawString(('#{0:00}  {1}' -f $item.Number,$item.Timecode),$font,[System.Drawing.Brushes]::White,[single]($x+12),[single]($y+361))
        $im.Dispose()
    }
    $sheet.Save((Join-Path $PSScriptRoot ('reperage_{0:00}.jpg' -f ($page+1))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
    $g.Dispose();$sheet.Dispose()
}
$font.Dispose()
$items | Group-Object Width,Height | Select-Object Count,Name
