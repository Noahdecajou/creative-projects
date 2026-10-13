$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$master = Join-Path $root 'Masters\Scott_Pulcini_Thumbnails_V03\04_Stop_Trading_Blind_master.png'
$archive = Join-Path $root 'Masters\Scott_Pulcini_Thumbnails_V03\Intermediaires'
New-Item -ItemType Directory -Force -Path $archive | Out-Null
$backup = Join-Path $archive '04_avant_correction_contours.png'
if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $master -Destination $backup }
$source = New-Object System.Drawing.Bitmap('C:\Users\notti\.codex\generated_images\01a11aa5-67de-7dd2-9ca7-5b8158198691\exec-fea7c288-bab9-40ee-97d9-8899bf90e685.png')
$original = New-Object System.Drawing.Bitmap($master)
$result = New-Object System.Drawing.Bitmap($original)
$original.Dispose()
$right = @(@(65,1300),@(85,1264),@(100,1245),@(115,1230),@(130,1218),@(145,1210),@(160,1207),@(175,1202),@(195,1201),@(210,1203),@(230,1207),@(245,1211),@(260,1216),@(275,1220),@(290,1225),@(310,1229),@(330,1231),@(360,1236),@(390,1242),@(430,1252))
$left = @(@(120,456),@(145,468),@(180,481),@(210,486),@(240,488),@(260,486),@(280,481),@(300,477),@(320,472),@(340,469),@(380,466),@(410,459))
function Boundary-X($points, [int]$y) {
    for ($k=0; $k -lt ($points.Count-1); $k++) {
        if ($y -ge $points[$k][0] -and $y -le $points[$k+1][0]) {
            $fraction = ($y-$points[$k][0]) / [double]($points[$k+1][0]-$points[$k][0])
            return $points[$k][1] + $fraction*($points[$k+1][1]-$points[$k][1])
        }
    }
}
foreach ($side in @('right','left')) {
    $points = if ($side -eq 'right') { $right } else { $left }
    for ($y=$points[0][0]; $y -le $points[-1][0]; $y++) {
        $edge = Boundary-X $points $y
        $xmin = if ($side -eq 'right') { 1188 } else { 450 }
        $xmax = if ($side -eq 'right') { 1270 } else { 496 }
        for ($x=$xmin; $x -le $xmax; $x++) {
            $alpha = if ($side -eq 'right') { [Math]::Max(0,[Math]::Min(1,($x-$edge+5)/3)) } else { [Math]::Max(0,[Math]::Min(1,($edge-$x+5)/3)) }
            if ($alpha -eq 0) { continue }
            $a=$result.GetPixel($x,$y); $b=$source.GetPixel($x,$y)
            $r=[int][Math]::Round($a.R*(1-$alpha)+$b.R*$alpha)
            $g=[int][Math]::Round($a.G*(1-$alpha)+$b.G*$alpha)
            $blue=[int][Math]::Round($a.B*(1-$alpha)+$b.B*$alpha)
            $result.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,$r,$g,$blue))
        }
    }
}
# Keep the complete accepted white label and its natural shadow in the clothing edit.
$white = New-Object System.Drawing.Bitmap('C:\Users\notti\.codex\generated_images\01a11aa5-67de-7dd2-9ca7-5b8158198691\exec-3d708031-692a-4c66-8654-f67745a21004.png')
$g = [System.Drawing.Graphics]::FromImage($result)
$r = New-Object System.Drawing.Rectangle(548,758,566,183)
$g.DrawImage($white,$r,$r,[System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $white.Dispose()
$result.Save($master,[System.Drawing.Imaging.ImageFormat]::Png)
$result.Dispose(); $source.Dispose()
Write-Output '04: original foreground hair and facial contours restored over the native monitor insert.'
