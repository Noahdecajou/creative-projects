from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import zipfile, io, hashlib, json
root=Path(__file__).resolve().parents[1]
files=sorted((root/'Stories_V03_Grain_4pct').glob('*.png'))
assert len(files)==8
archive=root/'Casper_8_Stories_V03_Grain_4pct_1080x1920.zip'
sheet=Image.new('RGB',(1120,1040),'#171717');draw=ImageDraw.Draw(sheet)
records=[]
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist())==8 and z.testzip() is None
    for i,f in enumerate(files):
        with Image.open(f) as im:
            im.load();assert im.size==(1080,1920)
            arr=np.array(im.convert('RGB')).astype(np.int16)
            tile=im.resize((270,480),Image.Resampling.LANCZOS)
        with Image.open(root/'Stories_V02'/f.name) as src:
            original=np.array(src.convert('RGB')).astype(np.int16)
        diff=arr-original
        mask=((original>=40)&(original<=215)&(arr>0)&(arr<255)).all(axis=2)
        values=diff[mask]
        assert len(values)>10000
        assert np.array_equal(values[:,0],values[:,1]) and np.array_equal(values[:,1],values[:,2])
        sigma=float(values[:,0].std())
        assert 9.9<sigma<10.5, sigma
        data=f.read_bytes();digest=hashlib.sha256(data).hexdigest()
        assert hashlib.sha256(z.read(f.name)).hexdigest()==digest
        with Image.open(io.BytesIO(z.read(f.name))) as check:
            check.load();assert check.size==(1080,1920)
        x=10+(i%4)*280;y=10+(i//4)*520
        sheet.paste(tile,(x,y));draw.text((x,y+487),f.stem[:36],fill='white')
        records.append(dict(file=f.name,dimensions=[1080,1920],added_grain_percent=4,measured_sigma=sigma,monochromatic=True,sha256=digest))
sheet.save(root/'Apercus'/'Casper_8_Stories_V03_Grain_4pct.jpg',quality=94)
(root/'Suivi'/'Verification_grain_V03_integrite.json').write_text(json.dumps(dict(count=8,source='Stories_V02',one_added_pass=True,zip_integrity='verified',stories=records),indent=2),encoding='utf-8')
print('Verified: 8 PNG, 1080 x 1920, added monochromatic Gaussian grain 4%, ZIP integrity and hashes match.')
