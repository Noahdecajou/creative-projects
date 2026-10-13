$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$generated = 'C:\Users\notti\.codex\generated_images\01a11aa5-67de-7dd2-9ca7-5b8158198691'
$jobs = @(
    @{ Id='01'; File='exec-d7ce1591-463b-4ce1-8236-e5b0895a3cae.png'; Slug='What_Candles_Dont_Show'; Still='01-10-00'; Crop=@(163,279,1312,632); Dest=@(134,320,781,484); Poly=@(134,320,915,320,915,752,832,804,134,804); Arrow=@(860,558,58,115) },
    @{ Id='02'; File='exec-47e6dd2e-ecde-403e-a48a-27352ae11d2a.png'; Slug='Hidden_Orders_Moving_Price'; Still='01-07-30'; Crop=@(170,269,1310,642); Dest=@(134,322,781,481); Poly=@(134,322,915,322,915,781,885,803,134,803); Arrow=@(866,550,51,120) },
    @{ Id='04'; File='exec-fea7c288-bab9-40ee-97d9-8899bf90e685.png'; Slug='Stop_Trading_Blind'; Still='01-04-00'; Crop=@(148,274,1364,637); Dest=@(486,127,753,493); Poly=@(486,127,1239,127,1239,575,1207,620,486,620); Arrow=@(730,125,147,104) }
)
foreach ($job in $jobs) {
    $original = New-Object System.Drawing.Bitmap((Join-Path $generated $job.File))
    $result = New-Object System.Drawing.Bitmap($original)
    $still = [System.Drawing.Image]::FromFile((Join-Path $root ('Sources_HD\Scott_OrderFlow\Scott_OrderFlow_' + $job.Still + '.jpg')))
    $g = [System.Drawing.Graphics]::FromImage($result)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
    for ($i=0; $i -lt $job.Poly.Count; $i+=2) { $pts.Add((New-Object System.Drawing.Point($job.Poly[$i], $job.Poly[$i+1]))) }
    $clip.AddPolygon($pts.ToArray())
    $g.SetClip($clip)
    $d = $job.Dest; $c = $job.Crop
    $dest = New-Object System.Drawing.Rectangle($d[0],$d[1],$d[2],$d[3])
    $g.DrawImage($still,$dest,[single]$c[0],[single]$c[1],[single]$c[2],[single]$c[3],[System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $clip.Dispose(); $still.Dispose()
    # Retain the approved yellow arrow over the direct still insertion.
    $a = $job.Arrow
    for ($y=$a[1]; $y -lt ($a[1]+$a[3]); $y++) {
        for ($x=$a[0]; $x -lt ($a[0]+$a[2]); $x++) {
            $pixel = $original.GetPixel($x,$y)
            if ($pixel.R -gt 170 -and $pixel.G -gt 145 -and $pixel.B -lt 165 -and $pixel.R -gt ($pixel.B+65)) { $result.SetPixel($x,$y,$pixel) }
        }
    }
    $path = Join-Path $root ('Masters\Scott_Pulcini_Thumbnails_V02\' + $job.Id + '_' + $job.Slug + '_master.png')
    $result.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $result.Dispose(); $original.Dispose()
    Write-Output $path
}
$jobs | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $root 'Suivi\Scott_Pulcini_Thumbnails_V02\Direct_screen_composites.json')
