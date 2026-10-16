from pathlib import Path
import json, html, base64
root=Path.cwd(); dest=root/'outputs/Design_Ref_Analyse_V01'
records=json.loads((dest/'mesures_pixels.json').read_text(encoding='utf-8'))
notes={
0:[
('Couverture','Candace','Titre en capitales sur trois lignes à gauche ; portrait à droite et micro au premier plan. Carte sombre à gauche : le payout vert est le point focal ; CTA rouge bas droit.'),
('Explication','Candace','Titre centré haut, taux de réussite dans un cartouche rouge ; texte et trois petites cartes à gauche ; portrait à droite. Carte de synthèse sous les trois chiffres.'),
('Explication','Candace','Deux lignes de titre centrées ; quatre groupes de lecture à gauche ; visage bas droit avec main et stylo ; ordinateur traverse le bas. Accent rouge dans la headline, pas dans les paragraphes.'),
('Explication','Candace','Titre haut ; perte limite soulignée par un cartouche rouge ; lecture à gauche, portrait à droite ; scène assombrie. Rouge et gras isolent les règles de trading dans le texte.'),
('Calcul','Candace','Headline haute sur deux lignes ; gros payout rouge ; carte verte de cible à gauche, deux groupes de calcul dessous ; portrait pensif à droite. Filets verticaux fins organisent les étapes.'),
('Conclusion','Candace','Logo centré en haut ; deux lignes chiffres rouge/vert ; explication centrale ; deux portraits bas ; CTA au niveau du torse. Footer centré, pas de capsule Swipe.'),
('Conclusion autre marque','Fredy','Plan large du plateau, lumière ambre forte en haut ; dégradé noir sous la table ; promesse et CTA centrés ; halo vert en bas. Footer ChartFanatics : exception à ne pas importer dans WOR.')],
1:[
('Couverture','Clement','Titre centré haut ; $1M surdimensionné à gauche de la qualification rouge ; trait rouge sous le titre ; flèche blanche vers le visage ; ordinateur couvre le bas.'),
('Explication','Clement','Titre haut ; deuxième phrase sur rouge ; deux cartes comparatives vert/rouge à gauche avec pictogrammes circulaires ; portrait à droite ; conclusion en deux bandes blanches légèrement inclinées.'),
('Explication','Clement','Titre centré et cartouche rouge sur la force relative ; portrait à gauche ; carte sombre de lecture à droite ; conclusion en bandes blanches inclinées sous la carte.'),
('Exemple','Clement','Titre haut sur trois lignes avec rouge ; portrait à gauche ; lecture et petit chart à droite. Le chart est un insert bordé ; mots clés en gras dans les paragraphes.'),
('Leçon','Clement','Titre centré sur trois lignes ; feedback en rouge ; portrait central ; deux petits groupes de lecture de chaque côté, fond presque noir. Composition dense, à adapter avec peu de texte.'),
('Conclusion','Clement','Logo haut ; histoire et résultats au centre ; 2024/2025 en blanc et performances vertes ; deux portraits bas ; bouton vidéo noir bordé rouge et petite capsule lien.'),
('Conclusion','Connor','Plan large clair du plateau ; grand panneau rouge au-dessous ; ligne Link in Bio blanche sous le panneau et soulignement manuscrit. Identité différente de Clement.')],
2:[
('Couverture','Matteo','Headline haut gauche ; accent rouge sur AI can test ; phrase de contexte dessous ; écran et robot à gauche ; portrait bas droit ; flèche courbe descendante vers la scène.'),
('Explication','Matteo','Titre haut ; phrase soulignée rouge ; chiffre 90–95% noir sur blanc à gauche ; backtest et carte sombre bord rouge en dessous ; personnage de dos à droite.'),
('Processus','Matteo','Titre haut gauche ; étapes verticales IDEA → RULES → BACKTEST → VALIDATE → LIVE dans cinq cadres ; paragraphes bas gauche ; grand portrait à droite.'),
('Processus','Matteo','Titre sur trois lignes ; Don’t ask rouge ; scène de travail derrière ; quatre rangées sombres à droite, libellé à gauche et Test it à droite ; explication courte sous le tableau.'),
('Comparaison','Matteo','Headline haute décalée à droite ; portrait pensif à gauche ; deux feuilles déchirées 3 RULES / 15 RULES au centre/droite ; phrase de synthèse et deux cartes à filet rouge en bas.'),
('Conclusion','Matteo','Logo haut gauche, biographie en colonne supérieure ; deux cartes de distinction au centre ; portraits gauche/droite bas ; bouton vidéo sur la jointure et footer centré.'),
('Conclusion','Connor','Plan large de l’entretien ; CTA blanc centré sous la table ; nom CONNOR rouge ; soulignement manuscrit sous full episode ; footer centré. Identité différente de Matteo.')],
3:[
('Couverture','Fredy','Portrait haut droite ; profil de volume vert/rouge haut gauche ; titre au milieu/bas, Gamma Levels en rouge ; phrase d’opposition sous le titre ; dégradé bas.'),
('Présentation','Fredy','Question sur une grande bande rouge haute ; expérience dans une petite carte blanche à gauche ; flèches courbes ; portrait central ; grand bloc blanc biographique en bas.'),
('Définition','Fredy','Titre haut centré avec Gamma rouge ; petit schéma manuscrit gauche ; lecture gauche, portrait droite ; carte blanche de conséquence sous le paragraphe.'),
('Schéma','Fredy','Titre centré haut ; graphique horizontal large au centre, niveaux rouges/bleus/verts ; texte centré sous le chart ; pas de portrait. Fond noir et halo discret.'),
('Comparaison','Fredy','Deux colonnes Positive GEX vert et Negative GEX rouge ; sous-titres et charts en miroir ; portrait central bas. Le contraste des labels suffit à hiérarchiser.'),
('Leçon','Fredy','Titre dans une capsule noire à bord fin avec vert ; carte de contraste rouge/vert à gauche ; portrait grand à droite ; décor chaud conservé derrière la tête.')],
4:[
('Couverture','Darrell','Portrait haut/droite et micro gauche ; headline centrée au tiers inférieur ; $800M+ rouge ; bande blanche d’identité en dessous ; flèche blanche vers le sujet.'),
('Présentation','Darrell','Portrait grande échelle ; nom dans une bande rouge à gauche ; flèche vers la tête ; grande carte blanche biographique au milieu/bas ; plateau chaud.'),
('Leçon','Darrell','Headline haute centrée et Ignore rouge ; visage central mains aux tempes ; carte blanche centrale sur le torse avec formule courte ; table visible en bas.'),
('Leçon','Darrell','Titre haut $800M+ rouge ; trois validations vertes à gauche, flèche blanche ; portrait penché écrivant à droite ; table et documents en bas.'),
('Conclusion','Darrell','Plan large deux intervenants ; titre centré sous la table, Professional rouge ; CTA comment Darrell rouge ; soulignement manuscrit ; marque centrée.'),
('Leçon','Connor','Titre haut Risk First rouge ; contraste Not rouge barré / But vert ; portrait central avec doigt à la tempe ; carte sombre d’explication en bas. Invité différent de Darrell.')],
5:[
('Couverture','Connor','Titre haut centré avec Never Track rouge ; grand portrait frontal ; flèches blanches haut gauche et sur épaule ; deux bandes blanches basses, $50M rouge.'),
('Présentation','Connor','Question rouge haut gauche ; sujet à droite regard latéral ; flèche rouge vers le visage ; carte biographique sombre basse ; phrase contextuelle sous la carte.'),
('Explication','Connor','Titre sur fond blanc en haut, noir et rouge ; chart montant derrière ; portrait à droite ; carte d’exemple gauche ; bande translucide de conséquence en bas.'),
('Calcul','Connor','Headline gauche, nom rouge ; sujet à droite avec bureau ; carte sombre de quatre trades à gauche ; flèche vers le total rouge ; phrase de conseil sous le total.'),
('Comparaison','Sans portrait','Deux situations empilées : baisse/alertes en haut, hausse/validations en bas ; charts sur noir ; injonctions sur deux longues bandes rouges. Grande flèche de baisse.'),
('Conclusion','Jim','Plan large entretien avec Jim ; promesse centrée sous la table ; 4,200% dans le rouge ; CTA JIM rouge ; footer centré. Invité différent de Connor.')],
6:[
('Couverture','Connor','Titre haut sur deux lignes, $50+ Million rouge ; tête frontale très grande ; flèches blanches ; accroche basse et carte blanche Repeatable System ; footer stable.'),
('Présentation','Connor','Même scène latérale que la famille (5) ; question rouge haut gauche ; carte noire biographique centrée en bas ; un groupe de contexte supplémentaire dessous.'),
('Leçon','Connor','Headline noire sur deux bandes blanches hautes ; Stay Consistent rouge ; portrait central et chart montant derrière ; formule blanche centrale au torse.'),
('Leçon','Connor','Scène bureau sombre ; personne droite ; titre au milieu/bas $50M+ rouge ; trois validations vertes dessous ; flèche blanche près du micro.'),
('Conclusion','Connor','Plan large du plateau ; promesse et Top 1% Of Traders rouge dans le tiers inférieur ; consigne comment CONNOR rouge ; footer centré.')],
7:[
('Couverture','John','Portrait plein cadre ; rendement sur capsule verte, titre bas centré avec capsule rouge ; phrase de contexte légère dessous ; fond bas presque noir.'),
('Présentation','Connor','Question rouge et flèche rouge ; portrait Connor latéral ; biographie sombre en bas et contexte dessous. Ne pas l’utiliser pour présenter John.'),
('Leçon','John','Portrait de profil à droite avec micro ; slogan blanc sur capsule rouge médiane ; bande blanche avec deux objections ; courte conséquence blanche dessous.'),
('Leçon','John','Grand portrait frontal ; capsule rouge médiane ; sous-titre avec contour/ombre marquée et NOT rouge ; conclusion centrée sur deux lignes.'),
('Conclusion','John','Panneau blanc/rouge de contexte en haut ; deux intervenants sur plateau ; Full breakdown bas, consigne JOHN rouge ; soulignement rouge ; footer centré.')],
8:[
('Couverture','Gala','Portrait frontal plein cadre ; headline médiane ; $5M+ In Trading Profits en longue bande rouge ; sous-titre centré dessous ; footer bas gauche.'),
('Présentation','John','Question sur panneau rouge haut gauche avec filet blanc ; flèche pointillée ; visage John à droite ; grande carte blanche biographique en bas. Invité différent de Gala.'),
('Leçon','Gala','Capsule rouge haute ; portrait central ; quatre bandes blanches courtes en escalier dans la moitié basse ; traits soulignent certains groupes.'),
('Leçon','Gala','Capsule rouge haute ; portrait dominant ; quatre bandes blanches de liste au milieu/bas ; fond ambre encore visible sur les côtés.'),
('Conclusion','Gala','Promesse centrée haute avec capsule rouge ; deux portraits bas ; Full breakdown et CTA GALA au torse ; soulignement rouge et footer centré.')],
9:[
('Couverture','Jim','Portrait frontal blanc/ambre avec fond bleu ; headline basse rendement sur rouge, puis World Records blanc ; phrase de contexte dessous ; flèche blanche pointillée.'),
('Présentation','Gala','Question sur panneau rouge haut gauche ; flèche pointillée ; grand portrait Gala ; biographie sur blanc dans le tiers inférieur. Invité différent de Jim.'),
('Leçon','Jim','Titre haut sur deux bandes rouges ; portrait droite ; flèche blanche descendante et trois croix rouges à gauche ; leçon noire sur bandes blanches en bas.'),
('Leçon','Jim','Portrait à droite ; flèche blanche pointillée à gauche ; headline médiane #1 Investing Rule rouge ; trois validations vertes dessous.'),
('Couverture variante','Jim','Titre haut WARNING rouge avec pictogramme jaune ; portrait plus petit au centre ; chart baissier rouge dans un cadre ; Market Crash rouge/blanc en bas et contexte dessous.')],
10:[
('Présentation variante','Jim','Question noire/rouge dans un grand panneau blanc haut gauche ; grand point d’interrogation blanc ; portrait droite et flèche jaune ; grande carte translucide biographique basse.'),
('Leçon variante','Jim','Reprise du portrait et de la flèche pointillée ; #1 Investing Rule rouge médian ; trois validations vertes ; liste différente de Slide-4 (9).')],
11:[('Présentation variante','Jim','Variante très proche de Slide-2 (10), question sans point d’interrogation après le nom dans le cartouche ; grand symbole ? décoratif conservé ; même carte biographique.')]
}
for r in records:
 idx=r['slide']-1
 if r['group']==10: idx=0 if r['slide']==2 else 1
 if r['group']==11: idx=0
 role,guest,note=notes[r['group']][idx]; r.update(role=role,guest_visible=guest,observation=note)
(dest/'fiches_references.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
guide=(dest/'Connaissance_Design_WOR.txt').read_text(encoding='utf-8')
cards=[]
for idx,r in enumerate(records):
 assetdir=dest/'pixels_sources'; assetdir.mkdir(exist_ok=True)
 datauri='data:image/jpeg;base64,'+base64.b64encode((root/'Design REF'/r['file']).read_bytes()).decode('ascii')
 (assetdir/f'ref_{idx:02d}.js').write_text('window.designPixelSource='+json.dumps(datauri)+';',encoding='utf-8')
 src='../../Design%20REF/'+__import__('urllib.parse',fromlist=['quote']).quote(r['file'])
 colors=[]
 for cat in ['rouge_sature','vert_vif','blanc_neutre','sombre']:
  p=r['palette_mesuree'][cat]; colors.append(f'<p>{cat} : {p["percent"]}% du raster — '+''.join(f'<span class="swatch" style="background:{c["hex"]}"></span><code>{c["hex"]}</code> ' for c in p['top_rgb'][:3])+'</p>')
 cards.append(f'''<article data-role="{html.escape(r['role'])}" data-guest="{html.escape(r['guest_visible'])}"><button class="imageButton" onclick="inspect({idx})"><img loading="lazy" src="{src}" alt="{html.escape(r['file'])}"></button><div class="text"><h3>{html.escape(r['file'])}</h3><p class="badge">{r['width']} × {r['height']} · {html.escape(r['role'])} · {html.escape(r['guest_visible'])}</p><p>{html.escape(r['observation'])}</p><details><summary>Couleurs et mesures raster</summary>{''.join(colors)}<p>Composantes de rouge saturé ≥800 px (elles peuvent inclure lettres, reflets ou charts) :</p><pre>{html.escape(json.dumps(r['composants_rouges'],ensure_ascii=False,indent=2))}</pre><p>Bandes blanches candidates en haut : {r['bandes_blanches_haut_candidates']}. Ce masque peut détecter la photo ou une carte blanche.</p><code>SHA256 {r['sha256']}</code></details><button onclick="inspect({idx})">Inspecter les pixels et la grille</button></div></article>''')
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Atlas du design des carrousels WOR</title><style>
*{box-sizing:border-box}body{margin:0;background:#111;color:#eee;font:16px/1.55 system-ui,sans-serif}header,main{max-width:1500px;margin:auto;padding:28px}h1{font-size:36px;line-height:1.15}h2{font-size:26px}a{color:#ff7777}button,select,input{font:inherit;background:#222;color:#fff;border:1px solid #666;border-radius:7px;padding:8px 12px;cursor:pointer}button:hover{background:#393939}.toolbar{position:sticky;top:0;background:#181818ed;padding:14px;z-index:2;display:flex;gap:12px;flex-wrap:wrap}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:22px}article{background:#202020;border:1px solid #444;border-radius:12px;overflow:hidden}.imageButton{display:block;width:100%;padding:0;border:0;border-radius:0}.imageButton img{display:block;width:100%;height:auto}.text{padding:20px}.badge{color:#bbb;font-size:14px}h3{margin-top:0}.swatch{display:inline-block;width:17px;height:17px;vertical-align:middle;border:1px solid #777;margin:0 4px}code{font-size:12px;overflow-wrap:anywhere}pre{white-space:pre-wrap;font-size:12px}summary{cursor:pointer;color:#ffaaa5}details{margin-bottom:16px}.guide{background:#181818;border:1px solid #444;padding:24px;border-radius:12px}.guide pre{font:16px/1.65 system-ui,sans-serif;white-space:pre-wrap;max-width:950px;margin:auto}dialog{background:#151515;color:#fff;border:1px solid #777;border-radius:12px;width:min(1280px,98vw);height:95vh;padding:16px}dialog::backdrop{background:#000c}.inspectorTools{display:flex;gap:14px;align-items:center;flex-wrap:wrap;position:sticky;top:0;background:#151515;z-index:3;padding-bottom:10px}.canvasWrap{overflow:auto;height:calc(100% - 120px);background:#333}canvas{display:block;max-width:100%;height:auto;cursor:crosshair}.pixel{font-family:monospace;background:#252525;padding:10px}.notice{border-left:4px solid #ff3333;padding:12px 20px;background:#222}nav{display:flex;gap:20px;flex-wrap:wrap}.count{color:#bbb}
</style><header><h1>Atlas du design des carrousels WOR</h1><p>62 références examinées · 44 images en 1080 × 1350 · 18 en 1080 × 1440 · 13 octobre 2026</p><p>Portraits, hiérarchie, typographie visible, traitement des images, couleurs et composition. Chaque fiche est rattachée à un fichier précis ; les suffixes ne prouvent pas l’appartenance à un épisode.</p><nav><a href="#atlas">Fiches individuelles</a><a href="#guide">Guide de production complet</a><a href="Connaissance_Design_WOR.txt">Guide texte</a><a href="mesures_pixels.json">Mesures brutes</a><a href="fiches_references.json">Fiches JSON</a></nav><p class="notice">Les dimensions et pixels sont mesurés. La fonte exacte et les paramètres des calques ne sont pas récupérables avec certitude depuis les JPEG. Les masques colorés repèrent des composantes raster ; ils ne segmentent pas automatiquement les blocs de texte.</p><details><summary>12 planches de comparaison</summary>'''+''.join(f'<p><a href="serie_{g:02d}.jpg">Planche du suffixe {g if g else "sans suffixe"}</a></p>' for g in range(12))+'''</details></header><main><h2 id="atlas">Fiches individuelles</h2><div class="toolbar"><input id="search" placeholder="Fichier, invité, description…" oninput="filter()"><select id="role" onchange="filter()"><option value="">Toutes les fonctions</option>'''+''.join(f'<option>{html.escape(x)}</option>' for x in sorted({r['role'] for r in records}))+'''</select><span class="count" id="count">62 références</span></div><section class="cards">'''+''.join(cards)+'''</section><h2 id="guide">Guide de production complet</h2><section class="guide"><pre>'''+html.escape(guide)+'''</pre></section></main><dialog id="modal"><div class="inspectorTools"><strong id="filename"></strong><button onclick="document.getElementById('modal').close()">Fermer</button><label><input type="checkbox" id="grid" onchange="paint()"> Grille 50 px</label><label><input type="checkbox" id="regions" onchange="paint()"> Boîtes rouge / vert</label><button onclick="nativeSize()">100 % / ajusté</button></div><p class="pixel" id="pixel">Cliquer un pixel pour lire ses coordonnées et son RGB original.</p><div class="canvasWrap"><canvas id="canvas"></canvas></div></dialog><script>
const refs=DATA;let current=null,original=new Image(),isNative=false;const canvas=document.getElementById('canvas'),ctx=canvas.getContext('2d');const raw=document.createElement('canvas'),rawctx=raw.getContext('2d',{willReadFrequently:true});
function filter(){const q=document.getElementById('search').value.toLowerCase(),role=document.getElementById('role').value;let n=0;document.querySelectorAll('article').forEach(a=>{let show=a.textContent.toLowerCase().includes(q)&&(!role||a.dataset.role===role);a.hidden=!show;if(show)n++});document.getElementById('count').textContent=n+' références'}
function inspect(i){current=refs[i];document.getElementById('filename').textContent=current.file+' · '+current.width+' × '+current.height;document.getElementById('pixel').textContent='Chargement du JPEG original…';original.onload=()=>{raw.width=canvas.width=original.naturalWidth;raw.height=canvas.height=original.naturalHeight;rawctx.drawImage(original,0,0);paint();document.getElementById('pixel').textContent='Cliquer un pixel pour lire ses coordonnées et son RGB original.'};let loader=document.createElement('script');loader.src='pixels_sources/ref_'+String(i).padStart(2,'0')+'.js';loader.onload=()=>{original.src=window.designPixelSource;loader.remove()};loader.onerror=()=>{document.getElementById('pixel').textContent='Source embarquée introuvable. Conserver le dossier pixels_sources à côté de cet atlas.'};document.head.appendChild(loader);document.getElementById('modal').showModal()}
function paint(){if(!current||!original.complete)return;ctx.drawImage(original,0,0);if(document.getElementById('grid').checked){ctx.lineWidth=1;ctx.strokeStyle='#00ccffaa';ctx.font='15px monospace';ctx.fillStyle='#00ccff';for(let x=0;x<canvas.width;x+=50){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,canvas.height);ctx.stroke();if(x%100===0)ctx.fillText(x,x+2,20)}for(let y=0;y<canvas.height;y+=50){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(canvas.width,y);ctx.stroke();if(y%100===0)ctx.fillText(y,3,y+18)}}if(document.getElementById('regions').checked){for(const [key,color]of [['composants_rouges','#00ccff'],['composants_verts','#ffff00']]){ctx.strokeStyle=color;ctx.lineWidth=3;ctx.fillStyle=color;ctx.font='17px monospace';current[key].forEach(r=>{const b=r.bbox_xyxy_inclusive;ctx.strokeRect(b[0],b[1],b[2]-b[0]+1,b[3]-b[1]+1);ctx.fillText(b[0]+','+b[1],b[0],Math.max(20,b[1]-5))})}}}
function nativeSize(){isNative=!isNative;canvas.style.maxWidth=isNative?'none':'100%'}
canvas.addEventListener('click',e=>{const rect=canvas.getBoundingClientRect(),x=Math.min(canvas.width-1,Math.max(0,Math.floor((e.clientX-rect.left)*canvas.width/rect.width))),y=Math.min(canvas.height-1,Math.max(0,Math.floor((e.clientY-rect.top)*canvas.height/rect.height))),rgb=Array.from(rawctx.getImageData(x,y,1,1).data).slice(0,3),hex='#'+rgb.map(v=>v.toString(16).padStart(2,'0')).join('').toUpperCase();document.getElementById('pixel').textContent='x='+x+' y='+y+' | RGB('+rgb.join(', ')+') | '+hex+' | coordonnées natives, couleur sans grille';});
</script></html>'''
page=page.replace('const refs=DATA;', 'const refs='+json.dumps(records,ensure_ascii=False).replace('</','<\\/')+';')
(dest/'Atlas_Design_WOR.html').write_text(page,encoding='utf-8')
print('Atlas :',len(cards),'fiches, guide :',len(guide.split()),'mots')
