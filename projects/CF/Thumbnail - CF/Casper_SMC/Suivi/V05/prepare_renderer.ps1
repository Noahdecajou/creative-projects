$ErrorActionPreference='Stop'
$p=Join-Path $PSScriptRoot 'render_v05.ps1'
$s=Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V04\render_v04.ps1') -Raw
$s=$s.Replace('V04','V05').Replace('V4Grain','V5Grain')
$s=$s.Replace(". (Join-Path (Split-Path $PSScriptRoot) 'drawing_functions.ps1')",". (Join-Path $PSScriptRoot 'drawing_functions.ps1')")
$a=$s.IndexOf('function Glow {}');$b=$s.IndexOf('function LaptopPlate',$a)
$s=$s.Substring(0,$a)+". (Join-Path "+'$PSScriptRoot'+" 'style_v05.ps1')"+[Environment]::NewLine+$s.Substring($b)
$s=$s.Replace('Rounded $x $y 37 37 $YellowColor 7','Panel $x $y 37 37 $YellowColor $true 7')
$s=$s.Replace('Rect ($left+$a.Width+14) 20 ($b.Width+24) 88 $YellowColor','Panel ($left+$a.Width+14) 20 ($b.Width+24) 88 $YellowColor $true 2')
$s=$s.Replace("for("+ '$i=1;$i -le 8;$i++){',("RenderScreens"+[Environment]::NewLine+"for("+ '$i=1;$i -le 8;$i++){'))
$a=$s.IndexOf(' switch($i){');$b=$s.IndexOf('  $g.Dispose();',$a)
$new=@'
 switch($i){
 1 {LaptopPlate;Photo 'screen_01.png' 93 247 609 363;Person 'Casper_front_photo.png' 1030 24 485;Ink 'TRADE WITH' 27 28 95 $WhiteColor 'SemiBold' 746 $true;$null=Badge 'A SYSTEM' 27 118 109 $WhiteColor $BlackColor 'Bold' 15 10;$null=Badge 'Condition - Zones - Trigger' 210 639 42 $YellowColor $BlackColor 'Medium' 16 11 715;Arrow 758 625 779 554 732 502 676 471 $YellowColor 7}
 2 {LaptopPlate;Photo 'screen_02.png' 93 247 609 363;Person 'Casper_front_photo.png' 1030 24 485;Ink "WHO'S IN" 28 25 102 $WhiteColor 'SemiBold' 734 $true;$null=Badge 'CONTROL?' 28 126 104 $WhiteColor $BlackColor 'Bold' 15 10 735;$null=Badge 'Read the Volume Profile' 231 639 44 $YellowColor $BlackColor 'Medium' 16 11 711;Arrow 758 625 779 554 732 502 676 471 $YellowColor 7}
 3 {Photo '03_scene_retouch.png';Gradient 0 0 1280 112 (C 115 0 0 0) (C 0 0 0 0);CompactRow 'TRADING' 'IN' 32 8 90 $WhiteColor $BlackColor $true 1216 $true 18;Panel 427 104 427 109 $YellowColor $true 10;Fit '3' 443 115 81 87 128 $BlackColor 'Bold';Fit 'DECISIONS' 542 132 295 53 61 $BlackColor 'Bold';Panel 789 452 458 56 $GreenColor $true 9;Fit 'A CLEAR TRADING SYSTEM' 801 465 434 29 33 $WhiteColor 'Medium';Arrow 629 238 568 326 563 498 614 625 $YellowColor 7}
 4 {Gradient 0 0 1280 720 (C 255 34 42 48) (C 255 4 10 15);Panel 319 132 646 405 (C 255 98 105 113) $false 9;Board 'Tableau_00-23-00.jpg' 327 141 630 388;Person 'Casper_front_photo.png' 238 23 442;Person 'Riz_front_photo.png' 1040 21 445 $true;$null=Badge 'CONDITION / ZONES / TRIGGER' 425 28 29 $YellowColor $BlackColor 'SemiBold' 15 11 438;Arrow 644 91 630 113 650 144 680 162 $YellowColor 6;Gradient 0 420 1280 300 (C 0 0 0 0) (C 255 0 0 0);CompactRow 'STOP' 'OVERTHINKING' 45 598 92 $WhiteColor $BlackColor $true 1190 $true 23}
 5 {Photo '05_scene_photo_test.png';Gradient 0 0 1280 106 (C 130 0 0 0) (C 0 0 0 0);Headline05;Panel 47 220 288 108 (C 217 12 17 22) $false 10;Fit '3 CLEAR' 61 232 260 33 40 $WhiteColor 'SemiBold';Fit 'DECISIONS' 61 281 260 34 40 $WhiteColor 'SemiBold';Arrow 276 346 274 379 355 402 419 368 $YellowColor 6;Panel 995 412 238 56 (C 224 12 17 22) $false 23;Fit 'CASPER' 1006 424 216 33 43 $WhiteColor 'Medium';Panel 462 518 365 62 (C 228 12 17 22) $false 10;Fit 'STEP BY STEP' 476 532 337 34 39 $WhiteColor 'SemiBold';Arrow 901 584 888 557 862 548 831 548 $YellowColor 6}
 6 {LightBoard}
 7 {Photo '07_scene_photo_test.png';Gradient 0 0 1280 160 (C 120 0 0 0) (C 0 0 0 0);CenterBadge 'LET YOUR WINNERS RUN' 23 66 $RedColor $WhiteColor 'Bold' 1100;$null=Badge 'RIZ' 34 113 29 $WhiteColor $BlackColor 'Bold' 14 9;$null=Badge 'CASPER' 1088 107 29 $WhiteColor $BlackColor 'Bold' 14 9 161;Arrow 75 162 87 189 153 211 208 194 $WhiteColor 3;Arrow 1177 157 1179 181 1102 207 1040 188 $WhiteColor 3;Youtube 569 281 139}
 8 {Photo '08_scene_photo_test.png';Gradient 0 0 1280 132 (C 130 0 0 0) (C 0 0 0 0);Pixelate 222 143 142 144;BehindCasperArrow08;Header08;ElectricPanel 20 198 184 52 10;Fit 'CONDITION' 29 211 165 26 28 $WhiteColor 'Medium';ElectricPanel 441 249 170 55 10;Fit 'ZONES' 454 261 144 30 31 $WhiteColor 'Medium';ElectricPanel 682 172 184 53 10;Fit 'TRIGGER' 692 184 164 29 31 $WhiteColor 'Medium';Arrow 614 276 657 311 717 279 750 231 $WhiteColor 3 $true;Youtube 576 369 137}
 }
'@
$s=$s.Substring(0,$a)+$new+[Environment]::NewLine+$s.Substring($b)
Set-Content -LiteralPath $p -Value $s -Encoding utf8

