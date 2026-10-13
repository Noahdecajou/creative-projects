from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, zipfile

root = Path(__file__).resolve().parent
records = []
files = sorted((root / 'Masters').glob('*.png'))
for src in files:
    with Image.open(src) as im:
        im.load()
        native = list(im.size)
        final = ImageOps.fit(im.convert('RGB'), (1080, 1920), method=Image.Resampling.LANCZOS)
        dest = root / 'Stories_v1' / src.name
        final.save(dest)
    with Image.open(dest) as check:
        check.load()
        assert check.size == (1080,1920)
    records.append({'file':src.name, 'native_dimensions':native,'export_dimensions':[1080,1920]})
if len(files) == 8:
    sheet = Image.new('RGB', (1120,1080), '#202020')
    draw = ImageDraw.Draw(sheet)
    for idx, src in enumerate(files):
        with Image.open(root / 'Stories_v1' / src.name) as im:
            tile = im.resize((270,480), Image.Resampling.LANCZOS)
        x = 10+(idx%4)*280
        y = 10+(idx//4)*540
        sheet.paste(tile,(x,y))
        draw.text((x,y+487),src.stem[:35],fill='white')
    sheet.save(root / 'Apercu_8_Stories.jpg', quality=92)
    archive = root / 'Scott_Pulcini_8_Stories_V1.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for src in files:
            z.write(root / 'Stories_v1' / src.name, src.name)
    with zipfile.ZipFile(archive) as z:
        assert len(z.namelist()) == 8
        assert z.testzip() is None
        for name in z.namelist():
            with z.open(name) as f, Image.open(f) as im:
                im.load()
                assert im.size == (1080,1920)
    records.append({'zip':archive.name,'count':8,'integrity':'verified'})
(root / 'Suivi' / 'Verification_exports.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print(json.dumps(records,indent=2))
