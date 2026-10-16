from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,zipfile,hashlib,io
root=Path(__file__).resolve().parents[2]
files=sorted((root/'Stories_V03').glob('*.png'))
assert len(files)==8
records=[]
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
sheet=Image.new('RGB',(1120,1060),'#171717');draw=ImageDraw.Draw(sheet)
for i,f in enumerate(files):
    with Image.open(f) as im:
        im.load();assert im.size==(1080,1920)
        tile=im.resize((270,480),Image.Resampling.LANCZOS)
    x=10+i%4*280;y=10+i//4*530
    sheet.paste(tile,(x,y));draw.text((x,y+490),f.stem[:2]+' - Casper / V03',fill='white',font=font)
    inherited=f.name[:2] not in ('02','06')
    if inherited:assert f.read_bytes()==(root/'Stories_V02'/f.name).read_bytes()
    else:
        with Image.open(root/'Stories_V02'/f.name) as old,Image.open(f) as new:
            assert old.crop((0,0,1080,550)).tobytes()==new.crop((0,0,1080,550)).tobytes()
            assert old.crop((0,1540,1080,1920)).tobytes()==new.crop((0,1540,1080,1920)).tobytes()
    records.append(dict(file=f.name,sha256=hashlib.sha256(f.read_bytes()).hexdigest(),dimensions=[1080,1920],inherited_identically=inherited))
sheet.save(root/'Apercus'/'Casper_8_Stories_V03.jpg',quality=95)
compare=Image.new('RGB',(1480,1390),'#171717');d=ImageDraw.Draw(compare)
for row,prefix in enumerate(('02','06')):
    f=next(f for f in files if f.name.startswith(prefix))
    for col,ver in enumerate(('V02','V03')):
        with Image.open(root/f'Stories_{ver}'/f.name) as im:tile=im.resize((360,640),Image.Resampling.LANCZOS)
        x=col*370;y=row*695+35
        compare.paste(tile,(x,y));d.text((x+8,y-27),f'{prefix} - '+('AVANT' if col==0 else 'APRES'),font=font,fill='white')
    # Enlarge original vs final face crops separately for visual review, no sharpening.
    with Image.open(root/'Stories_V02'/f.name) as old,Image.open(f) as new:
        oldbox=(620,640,1060,1160) if prefix=='02' else (310,590,770,1140)
        newbox=(735,722,1025,1080) if prefix=='02' else (390,670,700,1050)
        for col,(im,box) in enumerate(((old,oldbox),(new,newbox))):
            crop=im.crop(box);crop.thumbnail((350,590),Image.Resampling.LANCZOS)
            compare.paste(crop,(750+col*365,row*695+110))
            d.text((758+col*365,row*695+45),'VISAGE '+('AVANT' if col==0 else 'PHOTO ORIGINALE'),font=font,fill='white')
compare.save(root/'Apercus'/'Comparatif_02_06_V02_V03.jpg',quality=96)
archive=root/'Casper_8_Stories_V03_Sans_Grain_1080x1920.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for f in files:z.write(f,f.name)
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist())==8 and z.testzip() is None
    for r in records:
        data=z.read(r['file']);assert hashlib.sha256(data).hexdigest()==r['sha256']
        with Image.open(io.BytesIO(data)) as im:im.load();assert im.size==(1080,1920)
result=dict(count=8,grain_added=False,changed=['02','06'],other_six_byte_identical=True,zip_integrity='verified',files=records)
(root/'Suivi'/'V03'/'Verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='files'}))
