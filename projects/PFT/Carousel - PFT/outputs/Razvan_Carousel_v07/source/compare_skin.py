"""QA contact sheet only: show native pixel crops; no processing of delivered photographs."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parent.parent
before=root.parent/'Razvan_Carousel_v05'/'assets'
after=root/'assets'
font=ImageFont.truetype(str(root/'source'/'fonts'/'Poppins-Medium.ttf'),20)
sheet=Image.new('RGB',(900,1260),'#191919')
d=ImageDraw.Draw(sheet)
plans=[('Slide 1','hero_candle_natural.png','hero_photo_grain.png',(.388,.29,.695,.665)),
       ('Slide 6','outro_close_daylight.png','outro_photo_grain.png',(.517,.143,.900,.577))]
for row,(label,old,new,box) in enumerate(plans):
    y=row*630
    for col,(folder,file,version) in enumerate([(before,old,'V05'),(after,new,'V07')]):
        im=Image.open(folder/file).convert('RGB')
        crop=im.crop(tuple(round(v*(im.width if i%2==0 else im.height)) for i,v in enumerate(box)))
        assert crop.width<=440 and crop.height<=610
        d.text((10+col*450,y+5),label+' / '+version+' / native pixels',font=font,fill='white')
        sheet.paste(crop,(10+col*450,y+40))
sheet.save(root/'source'/'comparison_skin_native.png')
