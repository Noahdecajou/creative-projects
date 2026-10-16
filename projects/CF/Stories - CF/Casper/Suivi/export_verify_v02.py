from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, zipfile, hashlib, io

root = Path(__file__).resolve().parents[1]
sources = sorted((root/'Masters'/'V02').glob('*.png'))
assert len(sources) == 8, f'Expected 8 masters, found {len(sources)}'
records=[]
for src in sources:
    with Image.open(src) as im:
        im.load()
        native=im.size
        final=ImageOps.fit(im.convert('RGB'),(1080,1920),method=Image.Resampling.LANCZOS)
        dest=root/'Stories_V02'/src.name
        final.save(dest)
    with Image.open(dest) as check:
        check.load()
        assert check.size==(1080,1920)
    records.append(dict(file=src.name,native_dimensions=native,export_dimensions=[1080,1920],sha256=hashlib.sha256(dest.read_bytes()).hexdigest()))
sheet=Image.new('RGB',(1120,1040),'#171717')
d=ImageDraw.Draw(sheet)
for i,src in enumerate(sources):
    with Image.open(root/'Stories_V02'/src.name) as im:
        tile=im.resize((270,480),Image.Resampling.LANCZOS)
    x=10+(i%4)*280;y=10+(i//4)*520
    sheet.paste(tile,(x,y));d.text((x,y+487),src.stem[:36],fill='white')
sheet.save(root/'Apercus'/'Casper_8_Stories_V02.jpg',quality=94)
archive=root/'Casper_8_Stories_V02_1080x1920.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for src in sources:z.write(root/'Stories_V02'/src.name,src.name)
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist())==8 and z.testzip() is None
    for rec in records:
        data=z.read(rec['file'])
        assert hashlib.sha256(data).hexdigest()==rec['sha256']
        with Image.open(io.BytesIO(data)) as im:
            im.load();assert im.size==(1080,1920)
(root/'Suivi'/'Verification_V02.json').write_text(json.dumps(dict(stories=records,zip=archive.name,count=8,integrity='verified'),indent=2),encoding='utf-8')
print(json.dumps(dict(count=8,dimensions=[1080,1920],zip=str(archive),integrity='verified')))

