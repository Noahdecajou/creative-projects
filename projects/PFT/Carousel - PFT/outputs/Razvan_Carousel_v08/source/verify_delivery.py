from pathlib import Path
from PIL import Image
import json, zipfile, io, hashlib, xml.etree.ElementTree as ET

root=Path(__file__).resolve().parent.parent
previous=root.parent/'Razvan_Carousel_v07'
previous_manifest=json.loads((previous/'source'/'layout_verification.json').read_text())
current_manifest=json.loads((root/'source'/'layout_verification.json').read_text())
# The approved photo plates and their SVG placement are immutable in this revision.
for p in (previous/'assets').iterdir():
    if p.is_file(): assert p.read_bytes()==(root/'assets'/p.name).read_bytes(),p.name
namespace={'svg':'http://www.w3.org/2000/svg'}
for i in range(1,7):
    old=ET.parse(previous/'source'/f'{i:02d}_editable.svg').findall('.//svg:image',namespace)
    new=ET.parse(root/'source'/f'{i:02d}_editable.svg').findall('.//svg:image',namespace)
    assert [im.attrib for im in old]==[im.attrib for im in new],f'Image change on slide {i}'
for old,new in zip(previous_manifest,current_manifest):
    old_text=' '.join(t['text'] for t in old['text_boxes'])
    new_text=' '.join(t['text'] for t in new['text_boxes'])
    assert ' '.join(old_text.split())==' '.join(new_text.split()),'Copy changed'
for i,box in [(1,(440,430,740,880)),(2,(610,210,932,630)),
              (3,(750,100,1070,480)),(6,(560,305,960,700))]:
    with Image.open(previous/'slides'/f'{i:02d}.png') as old, Image.open(root/'slides'/f'{i:02d}.png') as new:
        assert old.crop(box).tobytes()==new.crop(box).tobytes(),f'Portrait pixels changed on slide {i}'
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
slides_zip=root.parent/'Razvan_Carousel_v08_PNG.zip'
with zipfile.ZipFile(slides_zip) as z:
    assert z.namelist()==[p.name for p in pngs]
    assert z.testzip() is None
    for p in pngs: assert z.read(p.name)==p.read_bytes()
copy=[]
for i,item in enumerate(manifest,1):
    copy.append(f'SLIDE {i}\n'+'\n'.join(t['text'] for t in item['text_boxes'])+'\n')
(root/'source'/'copy_rendered.txt').write_text('\n'.join(copy),encoding='utf-8')
result={'slide_count':6,'size_px':[1080,1350],'format':'RGB PNG','svg_count':6,
        'approved_photo_assets':'byte-identical to V07',
        'image_placement':'identical to V07 in all six editable SVGs',
        'portrait_pixel_regions':'identical to V07 on slides 1, 2, 3, 6',
        'copy':'unchanged from V07, whitespace normalized',
        'text_bounds':'passed','ordered_png_zip':'passed','checksums':'passed',
        'visual_review':'Six slides individually and overview; mobile preview at 360 px width',
        'source_claims':'Checked against supplied local episode transcript; payout stated in episode introduction'}
(root/'source'/'delivery_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
kit=root.parent/'Razvan_Carousel_v08_COMPLETE.zip'
with zipfile.ZipFile(kit,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file(): z.write(p,str(Path(root.name)/p.relative_to(root)))
with zipfile.ZipFile(kit) as z:
    assert z.testzip() is None
    result['complete_zip_file_count']=len(z.namelist())
    result['complete_zip_size_bytes']=kit.stat().st_size
print(json.dumps(result,indent=2))
