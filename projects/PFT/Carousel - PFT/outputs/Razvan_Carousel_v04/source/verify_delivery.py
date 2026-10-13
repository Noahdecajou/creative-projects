from pathlib import Path
from PIL import Image
import json, zipfile, io, hashlib, xml.etree.ElementTree as ET

root=Path(__file__).resolve().parent.parent
pngs=sorted((root/'slides').glob('*.png'))
assert [p.name for p in pngs]==[f'{i:02d}.png' for i in range(1,7)]
manifest=json.loads((root/'source'/'layout_verification.json').read_text())
for p,item in zip(pngs,manifest):
    with Image.open(p) as im:
        assert im.size==(1080,1350) and im.mode=='RGB'
        im.verify()
    assert hashlib.sha256(p.read_bytes()).hexdigest()==item['sha256']
    ET.parse(root/'source'/f'{p.stem}_editable.svg')
    for t in item['text_boxes']:
        assert 0<=t['x'] and t['x']+t['width']<=1080.5
        assert 0<=t['y'] and t['y']+t['height']<=1350
slides_zip=root.parent/'Razvan_Carousel_v04_PNG.zip'
with zipfile.ZipFile(slides_zip) as z:
    assert z.namelist()==[p.name for p in pngs]
    assert z.testzip() is None
    for p in pngs: assert z.read(p.name)==p.read_bytes()
copy=[]
for i,item in enumerate(manifest,1):
    copy.append(f'SLIDE {i}\n'+'\n'.join(t['text'] for t in item['text_boxes'])+'\n')
(root/'source'/'copy_rendered.txt').write_text('\n'.join(copy),encoding='utf-8')
result={'slide_count':6,'size_px':[1080,1350],'format':'RGB PNG','svg_count':6,
        'text_bounds':'passed','ordered_png_zip':'passed','checksums':'passed',
        'visual_review':'Six slides individually and overview; mobile preview at 360 px width',
        'source_claims':'Checked against supplied local episode transcript; payout stated in episode introduction'}
(root/'source'/'delivery_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
kit=root.parent/'Razvan_Carousel_v04_COMPLETE.zip'
with zipfile.ZipFile(kit,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file(): z.write(p,str(Path(root.name)/p.relative_to(root)))
with zipfile.ZipFile(kit) as z:
    assert z.testzip() is None
    result['complete_zip_file_count']=len(z.namelist())
    result['complete_zip_size_bytes']=kit.stat().st_size
print(json.dumps(result,indent=2))
