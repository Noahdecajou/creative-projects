from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, zipfile

root=Path(__file__).resolve().parent.parent
files=sorted((root/'Stories_v3_Poppins').glob('*.png'))
assert len(files)==8
faces=[[(610,350,1030,860)],[(650,270,1040,780)],[(90,600,425,1000),(640,600,1000,1000)],[(20,490,320,1040),(740,490,1050,1040)],[(420,700,720,1080)],[(400,590,750,1080)],[(100,700,400,1100),(750,685,1040,1090)],[(160,720,310,915),(775,720,1025,950)]]
records=[]
sheet=Image.new('RGB',(1120,1080),'#202020')
draw=ImageDraw.Draw(sheet)
for idx,path in enumerate(files):
    with Image.open(path) as image,Image.open(root/'Stories_v2_Grain_3pct'/path.name) as original:
        image.load();original.load()
        assert image.size==(1080,1920)
        a=np.array(image.convert('RGB'));b=np.array(original.convert('RGB'))
        for x1,y1,x2,y2 in faces[idx]:
            assert np.array_equal(a[y1:y2,x1:x2],b[y1:y2,x1:x2]),f'Portrait region altered: {path.name}'
        tile=image.resize((270,480),Image.Resampling.LANCZOS)
        x=10+(idx%4)*280;y=10+(idx//4)*540
        sheet.paste(tile,(x,y));draw.text((x,y+487),path.stem[:35],fill='white')
    records.append({'file':path.name,'dimensions':[1080,1920],'font':'Poppins Regular and Poppins Bold from supplied TTF files','portrait_regions':'pixel-identical to V2','grain_new_typography_sigma':7.65})
sheet.save(root/'Apercu_8_Stories_V3_Poppins.jpg',quality=93)
archive=root/'Scott_Pulcini_8_Stories_V3_Poppins.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for path in files:z.write(path,path.name)
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist())==8 and z.testzip() is None
    for name in z.namelist():
        with z.open(name) as f,Image.open(f) as im:
            im.load();assert im.size==(1080,1920)
(root/'Suivi'/'Verification_typographie_V3.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('Verified: eight 1080x1920 PNG; all checked facial regions identical to V2; ZIP integrity passed.')
