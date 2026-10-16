from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import zipfile, hashlib, json, html

root = Path(__file__).resolve().parents[2]
masters = root / 'Masters' / 'V02'
out = root / 'Stories_V02'
preview = root / 'Apercus' / 'V02'
files = sorted(masters.glob('*.png'))
assert len(files) == 8, len(files)
records = []
sheet = Image.new('RGB', (1200, 1160), '#181818')
draw = ImageDraw.Draw(sheet)
cards = []
for i, src in enumerate(files):
    with Image.open(src) as im:
        im.load()
        native = im.size
        final = ImageOps.fit(im.convert('RGB'), (1080,1920), method=Image.Resampling.LANCZOS)
    dest = out / src.name
    final.save(dest)
    with Image.open(dest) as check:
        check.load()
        assert check.size == (1080,1920)
    sha = hashlib.sha256(dest.read_bytes()).hexdigest()
    source = root / 'Sources' / 'Thumbnails_V14' / (src.stem + '_3840x2160.png')
    records.append(dict(file=src.name,native_dimensions=native,export_dimensions=[1080,1920],sha256=sha,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest()))
    x,y = 15+(i%4)*300,15+(i//4)*580
    tile = final.resize((270,480),Image.Resampling.LANCZOS)
    sheet.paste(tile,(x,y))
    draw.text((x,y+488),src.stem.replace('_',' ')[:36],fill='white')
    thumb = preview / (src.stem+'.jpg')
    final.resize((360,640),Image.Resampling.LANCZOS).save(thumb,quality=92)
    cards.append('<a href="../../Stories_V02/'+src.name+'"><img src="'+thumb.name+'"><p>'+html.escape(src.stem.replace('_',' '))+'</p></a>')
sheet.save(preview/'Apercu_8_Stories_V02.jpg',quality=94)
(preview/'Galerie_V02.html').write_text('<!doctype html><meta charset="utf-8"><title>Imre Gams - 8 Stories V02</title><style>body{background:#161616;color:white;font-family:Arial;margin:24px}main{display:grid;grid-template-columns:repeat(4,minmax(180px,1fr));gap:20px}img{width:100%}a{color:white;text-decoration:none}p{font-size:14px}@media(max-width:900px){main{grid-template-columns:repeat(2,1fr)}}</style><h1>Imre Gams - 8 Stories V02</h1><p>Adaptations des thumbnails V14 - 1080 x 1920</p><main>'+''.join(cards)+'</main>',encoding='utf-8')
archive = root/'Imre_Gams_8_Stories_V02_1080x1920.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for src in files: z.write(out/src.name,src.name)
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist())==8
    assert z.testzip() is None
    for rec in records:
        data=z.read(rec['file'])
        assert hashlib.sha256(data).hexdigest()==rec['sha256']
        with z.open(rec['file']) as f, Image.open(f) as im:
            im.load(); assert im.size==(1080,1920)
(root/'Suivi'/'V02'/'Verification.json').write_text(json.dumps(dict(images=records,zip=archive.name,zip_count=8,zip_integrity='verified',zip_sha256=hashlib.sha256(archive.read_bytes()).hexdigest()),indent=2),encoding='utf-8')
print(json.dumps(dict(count=8,dimensions=[1080,1920],zip=str(archive),integrity='verified'),indent=2))

