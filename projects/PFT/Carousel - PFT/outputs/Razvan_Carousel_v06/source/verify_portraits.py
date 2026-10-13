from pathlib import Path
from PIL import Image
import numpy as np, json, hashlib

root=Path(__file__).resolve().parent.parent
manifest=json.loads((root/'source'/'portrait_sources.json').read_text())
for name,item in manifest['originals'].items():
    assert hashlib.sha256((root/'assets'/name).read_bytes()).hexdigest()==item['sha256']
plans=[
    (1,'portrait_front_source.jpg',(200,0,2945,2160),0,385,1080,(470,475,690,800)),
    (2,'Razvan_22_00-11-08-00.jpg',(550,0,2400,2160),460,0,620,(700,130,895,405)),
    (3,'Razvan_05_00-07-12-00.jpg',(620,0,2380,2160),480,0,600,(735,140,890,440)),
    (6,'portrait_gesture_source.jpg',(800,0,2200,2160),400,0,680,(625,130,905,555)),
]
results=[]
for n,name,box,x,y,w,roi in plans:
    im=Image.open(root/'assets'/name).convert('RGBA')
    h=w*(box[3]-box[1])/(box[2]-box[0])
    assert w*2/(box[2]-box[0])<=1
    expected=im.crop(box).resize((round(w*2),round(h*2)),Image.Resampling.LANCZOS).convert('RGB')
    region=tuple(round(t*2) for t in roi)
    relative=(region[0]-x*2,region[1]-y*2,region[2]-x*2,region[3]-y*2)
    a=np.asarray(expected.crop(relative)).astype(np.int16)
    b=np.asarray(Image.open(root/'slides_2x'/f'{n:02d}.png').crop(region)).astype(np.int16)
    diff=np.abs(a-b)
    result={'slide':n,'source':name,'face_roi_design_px':roi,'max_channel_difference':int(diff.max()),'mean_channel_difference':float(diff.mean()),'no_source_upscale':True}
    assert diff.max()<=1, f'Face modified: {result}'
    results.append(result)
(root/'source'/'portrait_pixel_verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(json.dumps(results,indent=2))
sheet=Image.new('RGB',(1120,850),'#181818')
for column,n in enumerate((1,6)):
    region=next(p[6] for p in plans if p[0]==n)
    patch=Image.open(root/'slides_2x'/f'{n:02d}.png').crop(tuple(v*2 for v in region))
    sheet.paste(patch,(column*560,0))
sheet.save(root/'source'/'qa_faces_native.png')
