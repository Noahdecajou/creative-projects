$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$grainCode = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class SampsaGrain3 {
    public static void Render(string input, string png, string jpg, int seed) {
        using (Bitmap bitmap = new Bitmap(input)) {
            Rectangle bounds = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            BitmapData data = bitmap.LockBits(bounds, ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb);
            byte[] pixels = new byte[data.Stride * data.Height];
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
            Random rng = new Random(seed);
            for (int y = 0; y < data.Height; y++) {
                for (int x = 0; x < data.Width; x++) {
                    int noise = (int)Math.Round((rng.NextDouble() * 2.0 - 1.0) * 255.0 * 0.03, MidpointRounding.AwayFromZero);
                    int offset = y * data.Stride + x * 3;
                    for (int c = 0; c < 3; c++) pixels[offset + c] = (byte)Math.Max(0, Math.Min(255, pixels[offset + c] + noise));
                }
            }
            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
            bitmap.UnlockBits(data);
            bitmap.Save(png, ImageFormat.Png);
            ImageCodecInfo jpeg = null;
            foreach (ImageCodecInfo codec in ImageCodecInfo.GetImageEncoders()) if (codec.MimeType == "image/jpeg") jpeg = codec;
            using (EncoderParameters options = new EncoderParameters(1)) {
                options.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 96L);
                bitmap.Save(jpg, jpeg, options);
            }
        }
    }
    public static double[] Verify(string source, string export, int seed) {
        using (Bitmap a = new Bitmap(source)) using (Bitmap b = new Bitmap(export)) {
            if (a.Width != b.Width || a.Height != b.Height) throw new Exception("Dimensions changed");
            Rectangle bounds = new Rectangle(0, 0, a.Width, a.Height);
            BitmapData da = a.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
            BitmapData db = b.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
            byte[] pa = new byte[da.Stride * da.Height];
            byte[] pb = new byte[db.Stride * db.Height];
            Marshal.Copy(da.Scan0, pa, 0, pa.Length); Marshal.Copy(db.Scan0, pb, 0, pb.Length);
            Random rng = new Random(seed);
            long mismatch = 0, changed = 0; int maximum = 0; double sum = 0, squares = 0;
            for (int y = 0; y < da.Height; y++) for (int x = 0; x < da.Width; x++) {
                int noise = (int)Math.Round((rng.NextDouble() * 2.0 - 1.0) * 255.0 * 0.03, MidpointRounding.AwayFromZero);
                sum += noise; squares += noise * noise; bool different = false;
                for (int c = 0; c < 3; c++) {
                    int original = pa[y * da.Stride + x * 3 + c];
                    int actual = pb[y * db.Stride + x * 3 + c];
                    int expected = Math.Max(0, Math.Min(255, original + noise));
                    if (actual != expected) mismatch++;
                    int diff = Math.Abs(actual - original); if (diff > maximum) maximum = diff;
                    if (diff != 0) different = true;
                }
                if (different) changed++;
            }
            a.UnlockBits(da); b.UnlockBits(db);
            double count = a.Width * a.Height, mean = sum / count;
            if (mismatch != 0) throw new Exception("Unexpected pixel changes: " + mismatch);
            return new double[] { maximum, changed / count, mean, Math.Sqrt(squares / count - mean * mean), mismatch };
        }
    }
}
'@
Add-Type -TypeDefinition $grainCode -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Private.Windows.GdiPlus','System.Private.Windows.Core','System.Runtime.InteropServices','System.Runtime')

$workspace = (Get-Location).Path
$sourceDir = Join-Path $workspace 'outputs\Sampsa-Jeppez-Carousel-V02'
$outputDir = Join-Path $workspace 'outputs\Sampsa-Jeppez-Carousel-V03-Grain3'
if (Test-Path -LiteralPath $outputDir) { throw 'Output already exists; preserve versions.' }
New-Item -ItemType Directory -Path $outputDir | Out-Null
foreach ($name in @('PNG','JPEG','Production')) { New-Item -ItemType Directory -Path (Join-Path $outputDir $name) | Out-Null }
$sourceVerification = Get-Content -LiteralPath (Join-Path $sourceDir 'Production\Verification.json') -Raw | ConvertFrom-Json
$checks = @()
foreach ($number in 1..7) {
    $name = 'Slide-{0:00}' -f $number
    $source = Join-Path $sourceDir ('PNG\' + $name + '.png')
    $png = Join-Path $outputDir ('PNG\' + $name + '.png')
    $jpg = Join-Path $outputDir ('JPEG\' + $name + '.jpg')
    $seed = 20261013 + $number
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHash -ne $sourceVerification.slides[$number-1].png_sha256) { throw "Source differs from approved V02: $name" }
    [SampsaGrain3]::Render($source, $png, $jpg, $seed)
    $pixelCheck = [SampsaGrain3]::Verify($source, $png, $seed)
    if ($pixelCheck[0] -gt 8) { throw 'Grain exceeds expected 8-bit rounding bound' }
    $image = [System.Drawing.Image]::FromFile($png)
    if ($image.Width -ne 1080 -or $image.Height -ne 1440) { throw 'Unexpected export dimensions' }
    $image.Dispose()
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sourceHash) { throw 'Source changed' }
    $checks += [ordered]@{ slide=$number; source=$source; source_sha256=$sourceHash; png=('PNG/' + $name + '.png'); png_sha256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash.ToLowerInvariant(); seed=$seed; grain_percent=3; method='Uniform monochrome noise +/-3% of 255, rounded to 8-bit; one pass at final dimensions'; dimensions=@(1080,1440); max_channel_change=$pixelCheck[0]; changed_pixel_fraction=$pixelCheck[1]; noise_mean=$pixelCheck[2]; noise_stddev=$pixelCheck[3]; unexpected_pixel_changes=$pixelCheck[4]; source_unchanged=$true }
}

# Presentation previews are composed only from the verified final exports.
$preview = New-Object System.Drawing.Bitmap 1516,1044
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.Clear([System.Drawing.Color]::FromArgb(20,20,20))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font 'Arial',14
for ($i=0; $i -lt 7; $i++) {
    $x = 12 + ($i % 4) * 376
    if ($i -ge 4) { $x += 188 }
    $y = 12 + [math]::Floor($i / 4) * 516
    $graphics.DrawString(('{0:00}' -f ($i+1)), $font, [System.Drawing.Brushes]::LightGray, [float]$x, [float]$y)
    $image = [System.Drawing.Image]::FromFile((Join-Path $outputDir ('PNG\Slide-{0:00}.png' -f ($i+1))))
    $graphics.DrawImage($image, [int]$x, [int]($y+24), 360,480)
    $image.Dispose()
}
$preview.Save((Join-Path $outputDir 'Apercu_7_slides.jpg'), [System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics.Dispose(); $preview.Dispose(); $font.Dispose()

$detail = New-Object System.Drawing.Bitmap 1248,680
$graphics = [System.Drawing.Graphics]::FromImage($detail)
$graphics.Clear([System.Drawing.Color]::FromArgb(20,20,20))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = New-Object System.Drawing.Font 'Arial',16
foreach ($side in 0..1) {
    $folder = if ($side -eq 0) { $sourceDir } else { $outputDir }
    $label = if ($side -eq 0) { 'V02 - avant grain' } else { 'V03 - grain monochrome 3 %' }
    $x = 12 + 624*$side
    $graphics.DrawString($label,$font,[System.Drawing.Brushes]::White,[float]$x,[float]12)
    $image = [System.Drawing.Image]::FromFile((Join-Path $folder 'PNG\Slide-01.png'))
    $destination = New-Object System.Drawing.Rectangle $x,52,600,600
    $crop = New-Object System.Drawing.Rectangle 670,350,300,300
    $graphics.DrawImage($image,$destination,$crop,[System.Drawing.GraphicsUnit]::Pixel)
    $image.Dispose()
}
$detail.Save((Join-Path $outputDir 'Detail_grain_200pct.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $detail.Dispose(); $font.Dispose()

$utf8 = New-Object System.Text.UTF8Encoding $false
$copy = (Get-Content -LiteralPath (Join-Path $sourceDir 'Production\Texte_final.txt') -Raw -Encoding UTF8).Replace('CAROUSEL V02','CAROUSEL V03 - GRAIN 3 %')
[System.IO.File]::WriteAllText((Join-Path $outputDir 'Production\Texte_final.txt'),$copy,$utf8)
$notes = @'
SAMPSA JEPPEZ - V03 - GRAIN 3 % - 13 octobre 2026

Les sept PNG approuves de V02 ont recu une seule passe de grain monochrome fin a leur dimension finale 1080 x 1440.
Methode : bruit uniforme independant par pixel, amplitude +/-3 % de 255 (+/-7,65 niveaux), arrondi a 8 bits ; le meme ajout est applique aux trois canaux RGB, puis borne entre 0 et 255. La quantification peut produire un ecart maximal de 8 niveaux. Seeds reproductibles : 20261014 a 20261020.
Le traitement est une operation numerique locale, sans regeneration, redimensionnement, deplacement, lissage ou nettete supplementaire. Chaque pixel du PNG final a ete compare au resultat attendu de la formule : zero autre modification.
Les sept JPEG sont derives des memes images avec grain, qualite 96. Le bruit n'est pas applique a nouveau lors de cet export.
Les SHA-256 des sept sources V02 correspondent au manifeste approuve et restent identiques apres le traitement. Les versions V01 et V02 ainsi que leurs sources et masters sont conservees.
Le ZIP final contient exactement sept PNG. L'apercu est une planche reduite ; Detail_grain_200pct.png montre le grain a 200 %.
Les sources, prompts imagegen initiaux, notes editoriales et references de transcription restent dans le dossier V02. La V03 n'utilise aucune nouvelle generation d'image.
'@
[System.IO.File]::WriteAllText((Join-Path $outputDir 'Production\Notes_grain.txt'),$notes,$utf8)
Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $outputDir 'Production\apply_grain.ps1')
$cards = foreach ($number in 1..7) {
    $name = 'Slide-{0:00}' -f $number
    '<section><h2>Slide '+$number+'</h2><a href="PNG/'+$name+'.png"><img src="PNG/'+$name+'.png" alt="Sampsa Jeppez slide '+$number+'"></a><p><a href="PNG/'+$name+'.png" download>PNG</a> · <a href="JPEG/'+$name+'.jpg" download>JPEG</a></p></section>'
}
$gallery = @'
<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sampsa Jeppez - V03 - Grain 3 %</title><style>*{box-sizing:border-box}body{margin:0;padding:28px;background:#101010;color:#eee;font:16px/1.5 system-ui,sans-serif}header{max-width:1200px;margin:0 auto 30px}h1{font-size:30px}a{color:#ff706b}main{max-width:1600px;margin:auto;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:24px}section{background:#181818;padding:14px;border:1px solid #333;border-radius:12px}h2{font-size:16px;color:#ccc}img{width:100%;height:auto;display:block}</style><header><h1>Sampsa Jeppez — V03 finale</h1><p>Sept slides · 1080 × 1440 · Grain monochrome 3 %</p><p><a href="../Sampsa-Jeppez-Carousel-V03-Grain3-PNG.zip">Télécharger les sept PNG</a> · <a href="Apercu_7_slides.jpg">Aperçu complet</a> · <a href="Detail_grain_200pct.png">Détail du grain à 200 %</a> · <a href="Production/Notes_grain.txt">Traitement</a> · <a href="../Sampsa-Jeppez-Carousel-V02/Galerie.html">Version précédente</a></p></header><main>
'@
$gallery += ($cards -join '') + '</main></html>'
[System.IO.File]::WriteAllText((Join-Path $outputDir 'Galerie.html'),$gallery,$utf8)

$archivePath = Join-Path $workspace 'outputs\Sampsa-Jeppez-Carousel-V03-Grain3-PNG.zip'
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists' }
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $outputDir 'PNG'),$archivePath,[System.IO.Compression.CompressionLevel]::Optimal,$false)
$zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    if ($zip.Entries.Count -ne 7) { throw 'Expected seven PNG entries' }
    foreach ($entry in $zip.Entries) {
        $stream = $entry.Open()
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        try { $archiveHash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
        finally { $stream.Dispose(); $hasher.Dispose() }
        $exportHash = (Get-FileHash -LiteralPath (Join-Path (Join-Path $outputDir 'PNG') $entry.Name) -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($archiveHash -ne $exportHash) { throw 'Archive mismatch' }
    }
} finally { $zip.Dispose() }
foreach ($match in [regex]::Matches($gallery,'(?:href|src)="([^"]+)"')) {
    if (-not (Test-Path -LiteralPath (Join-Path $outputDir $match.Groups[1].Value))) { throw ('Missing gallery asset: '+$match.Groups[1].Value) }
}
$report = [ordered]@{ slides=$checks; png_count=7; jpeg_count=7; dimensions=@(1080,1440); grain_percent=3; grain_passes=1; unexpected_pixel_changes=0; source_V02_unchanged=$true; zip_entries=7; zip_integrity_and_hashes_verified=$true; all_gallery_links_exist=$true; zip_sha256=(Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant() }
[System.IO.File]::WriteAllText((Join-Path $outputDir 'Production\Verification.json'),($report | ConvertTo-Json -Depth 8),$utf8)
[ordered]@{ output=$outputDir; archive=$archivePath; png_count=7; jpeg_count=7; grain_percent=3; grain_passes=1; dimensions=@(1080,1440); unexpected_pixel_changes=0; zip_verified=$true } | ConvertTo-Json -Compress
