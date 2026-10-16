from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import json, shutil, hashlib

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'Sources'/'V03'
photo=Image.open(SRC/'Casper_00-12-00.jpg').convert('RGB')
portrait=Image.open(SRC/'Casper_front_photo.png').convert('RGBA')
cut=Image.open(SRC/'Casper_00-12-00_cutout.png').convert('RGBA')
assert photo.size==portrait.size==cut.size==(3840,2160)
# Restore the actual camera pixels across the head, ears, face and neck.
# Only the existing shirt repair remains from the approved thumbnail layer.
head=[(0,0),(1280,0),(1280,282),(816,282),(774,303),(750,317),(744,356),(737,403),(730,443),(725,469),(705,471),(676,462),(658,432),(643,399),(631,364),(623,327),(619,298),(618,282),(0,282)]
hm=Image.new('L',photo.size);ImageDraw.Draw(hm).polygon([(x*3,y*3) for x,y in head],fill=255)
rgb=Image.composite(photo,portrait.convert('RGB'),hm)
alpha=portrait.getchannel('A')
alpha=Image.composite(cut.getchannel('A'),alpha,hm)
# Trim a single source-pixel boundary of the existing cutout, not the face.
alpha=alpha.filter(ImageFilter.MinFilter(3))
alpha=alpha.point(lambda v:255 if v>=240 else v)
portrait=rgb.convert('RGBA');portrait.putalpha(alpha)
portrait.save(SRC/'Casper_original_face_composite.png')
raw=np.asarray(photo);restored=np.asarray(portrait)
face_box=(1830,330,2290,810)
x1,y1,x2,y2=face_box
assert np.array_equal(raw[y1:y2,x1:x2],restored[y1:y2,x1:x2,:3])

def poly_mask(points,size=(1080,1920),feather=0):
    m=Image.new('L',size);ImageDraw.Draw(m).polygon(points,fill=255)
    m=m.filter(ImageFilter.MaxFilter(31))
    return m.filter(ImageFilter.GaussianBlur(feather)) if feather else m

def subject_at(center,top,scale):
    p=portrait.resize((round(3840*scale),round(2160*scale)),Image.Resampling.LANCZOS)
    ox=round(center-2061*scale);oy=round(top-108*scale)
    layer=Image.new('RGBA',(1080,1920));layer.alpha_composite(p,(ox,oy))
    return layer,dict(scale_uniform=scale,offset=[ox,oy],source_face_box=face_box)

def restore_footer(out,old,y):
    # Fade only the body at the lower join, then reapply the original exact badge pixels.
    a=np.zeros((1920,1080),dtype=np.uint8)
    for row in range(1315,1550):a[row,:]=round(255*min(1,max(0,(row-1315)/170)))
    a[1550:]=255
    out=Image.composite(Image.new('RGB',old.size,(10,10,10)),out,Image.fromarray(a))
    box=(89,1361,991,1471) if y==1360 else (76,1372,1005,1483)
    band=Image.new('L',old.size);ImageDraw.Draw(band).rounded_rectangle(box,radius=20,fill=255)
    glow=band.filter(ImageFilter.GaussianBlur(17)).point(lambda v:round(v*.30))
    color=(240,223,0) if y==1360 else (0,126,255)
    out=Image.composite(Image.new('RGB',old.size,color),out,glow)
    out=Image.composite(old,out,band)
    a=np.zeros((1920,1080),dtype=np.uint8)
    for row in range(1510,1920):a[row,:]=round(255*min(1,(row-1510)/20))
    return Image.composite(old,out,Image.fromarray(a))

records=[]
for src in sorted((ROOT/'Stories_V02').glob('*.png')):
    dest=ROOT/'Stories_V03'/src.name
    if src.name[:2] not in ('02','06'):
        shutil.copy2(src,dest)
        records.append(dict(file=src.name,unchanged=True,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()))
        continue
    old=Image.open(src).convert('RGB');out=old.copy()
    if src.name.startswith('02'):
        # Clear the former head and shoulders using only adjacent existing background.
        points=[(718,638),(862,633),(992,675),(1050,734),(1080,827),(1080,1500),(393,1500),(399,1356),(432,1295),(494,1239),(580,1182),(655,1100),(632,1030),(613,954),(616,852),(630,776),(661,707)]
        m=poly_mask(points,feather=12)
        bg=Image.new('RGB',old.size,(10,10,10))
        a=np.asarray(old)
        b=np.asarray(bg).copy()
        # Background texture from existing left-side dark space; table from unobstructed wood.
        for yy in range(630,1500):
            if yy<1146:
                sample=a[yy if yy<770 else 680+(yy%65),100:600]
            else:
                sample=a[min(yy,1330),0:350]
            b[yy]=sample[np.arange(1080)%len(sample)]
        out=Image.composite(Image.fromarray(b),out,m)
        layer,geo=subject_at(878,724,.40)
        out=Image.alpha_composite(out.convert('RGBA'),layer).convert('RGB')
        out=restore_footer(out,old,1360)
        out.paste(old.crop((0,0,1080,640)),(0,0))
    else:
        # The occluded panel center contains no text; retain all readable chart columns.
        points=[(455,593),(600,593),(704,625),(760,728),(772,859),(774,969),(738,1057),(737,1174),(823,1230),(930,1288),(998,1380),(1060,1485),(15,1485),(14,1423),(56,1342),(140,1262),(244,1200),(342,1144),(374,1076),(341,1016),(320,939),(315,828),(328,731),(370,657)]
        m=poly_mask(points,feather=3)
        ma=np.asarray(m).copy();ma[:595]=0;m=Image.fromarray(ma)
        bg=Image.new('RGB',old.size,(11,11,11));d=ImageDraw.Draw(bg)
        d.rounded_rectangle((29,593,1051,1278),radius=22,fill=(255,255,255))
        out=Image.composite(bg,out,m)
        ImageDraw.Draw(out).rectangle((435,593,675,601),fill=(255,255,255))
        # Reinstate the untouched teaching columns before placing the smaller portrait.
        for box in [(767,617,1042,1220),(50,617,310,1144),(50,1144,243,1220)]:
            out.paste(old.crop(box),box[:2])
        ImageDraw.Draw(out).rectangle((0,1279,1080,1530),fill=(10,10,10))
        layer,geo=subject_at(540,670,.42)
        out=Image.alpha_composite(out.convert('RGBA'),layer).convert('RGB')
        # Keep the small trigger caption readable above the newly visible shirt.
        caption_box=(54,1157,293,1184)
        out.paste(old.crop(caption_box),caption_box[:2])
        out=restore_footer(out,old,1370)
    out.save(dest)
    # Facial ROI must equal the same uniformly resized photographic layer exactly.
    # It is away from cutout edges, lower fades, text and graphics.
    x0,y0=geo['offset'];s=geo['scale_uniform']
    roi=(round(x0+1870*s),round(y0+410*s),round(x0+2260*s),round(y0+770*s))
    fx,fy,fr,fb=roi
    expected=np.asarray(layer)[fy:fb,fx:fr,:3]
    actual=np.asarray(out)[fy:fb,fx:fr]
    assert np.array_equal(expected,actual),'Photographic facial ROI changed'
    geo['final_face_roi']=roi
    geo['face_pixels_match_resized_original']=True
    out.save(ROOT/'Masters'/'V03'/src.name)
    records.append(dict(file=src.name,unchanged=False,geometry=geo,grain_added=False,face_source='Sources/V03/Casper_00-12-00.jpg',raw_face_restored_identically=True,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()))
    out.resize((540,960),Image.Resampling.LANCZOS).save(ROOT/'Apercus'/('V03_'+src.stem+'.jpg'),quality=96)
(ROOT/'Suivi'/'V03'/'Composition.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('Composed 02/06 from original photo; copied other six unchanged; no added grain.')
