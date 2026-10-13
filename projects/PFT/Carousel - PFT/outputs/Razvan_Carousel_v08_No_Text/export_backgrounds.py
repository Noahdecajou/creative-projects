"""Export approved carousel photo/background layers without typesetting or overlays."""
from pathlib import Path
import importlib.util, hashlib, json, zipfile
from PIL import Image

root=Path(__file__).resolve().parent
approved=root.parent/'Razvan_Carousel_v08'
spec=importlib.util.spec_from_file_location('approved_carousel',approved/'source'/'render.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
backgrounds=['hero_photo_grain','levels_photo_grain','reactions_photo_grain',
             'minimal','trailing_overhead_daylight','outro_photo_grain']
assets={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (approved/'assets').iterdir() if p.is_file()}
records=[]
for i,background in enumerate(backgrounds,1):
    canvas=module.Canvas(background)
    assert not canvas.text_boxes
    im=canvas.im.convert('RGB').resize((1080,1350),Image.Resampling.LANCZOS)
    path=root/f'{i:02d}.png'
    im.save(path,compress_level=6)
    with Image.open(path) as check:
        assert check.size==(1080,1350) and check.mode=='RGB'
        check.verify()
    records.append({'file':path.name,'background':background,'size':[1080,1350],
                    'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert assets=={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (approved/'assets').iterdir() if p.is_file()}
package=root.parent/(root.name+'.zip')
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as archive:
    for item in records: archive.write(root/item['file'],item['file'])
with zipfile.ZipFile(package) as archive:
    assert archive.namelist()==[item['file'] for item in records]
    assert archive.testzip() is None
    for item in records: assert archive.read(item['file'])==(root/item['file']).read_bytes()
sheet=Image.new('RGB',(1080,900),'#181818')
for i,item in enumerate(records):
    with Image.open(root/item['file']) as im:
        sheet.paste(im.resize((360,450),Image.Resampling.LANCZOS),((i%3)*360,(i//3)*450))
sheet.save(root/'preview.png')
(root/'verification.json').write_text(json.dumps({'images':records,'approved_assets':'unchanged',
    'crop_and_scale':'reused approved V08 Canvas constructor',
    'layers':'backgrounds only; no text, charts, highlights, branding or footer overlays',
    'zip_contents':'six ordered PNGs, validated'},indent=2),encoding='utf-8')
print(json.dumps({'count':6,'dimensions':[1080,1350],'zip':str(package),'asset_hashes':'unchanged'}))
