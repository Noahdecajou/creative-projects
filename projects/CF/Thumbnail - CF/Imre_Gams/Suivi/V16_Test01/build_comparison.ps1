$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot)
$preview=Join-Path $root 'Apercus\V16_Test01'
$previous=Get-Content -LiteralPath (Join-Path $root 'Apercus\V15_Test01\Comparatif_V15.html') -Raw
$head=$previous.Substring(0,$previous.IndexOf('</head>')+7).Replace('Essai de relief V15','Ombre et lueurs V16')
$js=$previous.Substring($previous.IndexOf('<script>'))
$body=@'
<body><main><div class="eyebrow">CHARTFANATICS · IMRE GAMS · 01 · V16 TEST · 14 OCTOBRE 2026</div>
<h1>Boxes lumineuses et ombre portée.</h1>
<p>La référence rouge est transposée en blanc et en jaune : une lumière diffuse autour de la box, avec des bords nets. Une ombre douce détache Imre du fond.</p>
<div class="toolbar"><button id="before" aria-pressed="false">Avant · V15</button><button id="split" aria-pressed="true">Comparer</button><button id="after" aria-pressed="false">Essai · V16</button><a class="download" href="../../Exports/V16_Test01/01_Price_Is_Not_Value_V16_Test_3840x2160.png" download>PNG 3840 × 2160</a><a class="download" href="../../Exports/V16_Test01/01_Price_Is_Not_Value_V16_Test_1280x720.jpg" download>JPEG 1280 × 720</a></div>
<div class="viewer"><img src="../V15_Test01/01_1280.jpg" alt="Avant V15"><img id="afterImage" class="after" src="01_1280.jpg" alt="V16 avec ombre portée et lueurs renforcées"><div id="divider" class="divider"></div><span id="beforeLabel" class="badge beforeLabel">AVANT · V15</span><span id="afterLabel" class="badge afterLabel">ESSAI · V16</span></div>
<div class="controls"><label for="wipe">Séparation avant/après</label><input id="wipe" type="range" min="0" max="100" value="50" aria-label="Position du comparatif avant et après"></div>
<div class="notes"><p><strong>Ombre derrière Imre</strong><br>Une ombre neutre suit sa silhouette, légèrement vers la gauche et le bas. Le portrait et ses proportions sont conservés.</p><p><strong>Lueurs des boxes</strong><br>Un halo blanc derrière VALUE et un halo jaune derrière Auction Market Theory. Les lueurs restent centrées autour des boxes, sans décalage.</p><p><strong>Seller et Buyer</strong><br>Les couleurs des lettres sont conservées. Le visage, la typographie et les bougies ne reçoivent aucune nouvelle retouche.</p></div>
<h2>À taille mobile</h2><div class="mobile"><figure><img src="../V15_Test01/01_320.jpg" alt="Avant V15 à 320 pixels"><figcaption>Avant · V15 · 320 px</figcaption></figure><figure><img src="01_320.jpg" alt="Essai V16 à 320 pixels"><figcaption>Essai · V16 · 320 px</figcaption></figure></div>
<h2>Référence de lumière</h2><figure><img src="../../Suivi/V16_Test01/Reference_glow.png" alt="Référence rouge fournie par l’utilisateur" style="width:420px;max-width:100%;height:auto"><figcaption>Référence fournie : intensité et diffusion de la lumière autour de la box.</figcaption></figure>
<footer><p class="small">Essai limité à la miniature 01. Aucun grain ajouté. Export 3840 × 2160 avec portrait agrandi. Ajustements réalisés dans les calques éditables de la composition ; aucun nouveau portrait généré. <a href="../../Suivi/V16_Test01/Verification.csv">Vérifications</a> · <a href="../../Suivi/V16_Test01/Pixel_preservation.csv">Contrôle des pixels du visage et des couleurs Seller / Buyer</a>.</p></footer></main>
'@
[IO.File]::WriteAllText((Join-Path $preview 'Comparatif_V16.html'),$head+$body+$js)
$package=Get-Content -LiteralPath (Join-Path $root 'Suivi\V15_Test01\package_test.ps1') -Raw
$package=$package.Replace('V15_Test01','V16_Test01').Replace('V15_Test','V16_Test').Replace('Apercus\V14\','Apercus\V15_Test01\').Replace('AVANT - V14','AVANT - V15').Replace('ESSAI RELIEF - V15','OMBRE ET LUEURS - V16').Replace('Comparatif_01_V14_V15.png','Comparatif_01_V15_V16.png').Replace('Comparatif_V15.html','Comparatif_V16.html').Replace('Imre_Gams_01_Test_Relief_V15.zip','Imre_Gams_01_Ombre_Lueurs_V16.zip')
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'package_test.ps1'),$package)
& (Join-Path $PSScriptRoot 'package_test.ps1')
