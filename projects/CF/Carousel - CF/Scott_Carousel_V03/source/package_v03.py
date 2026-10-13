from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import zipfile,json
R=Path(__file__).resolve().parents[1];V=R.parent/'Scott_Video_Test_V03'
f=ImageFont.truetype(str(R/'source/fonts/Poppins-Regular.ttf'),18)
sheet=Image.new('RGB',(1080,1450),'#171717')
for i,(prefix,dur) in enumerate([('03_Gamma',50),('04_Algos',23.04)]):
    for j,t in enumerate([.5,dur/2,dur-.5]):
        im=Image.open(V/(prefix+f'_QA_{t:.1f}.png')).resize((350,438),Image.Resampling.LANCZOS)
        x=j*360+5;y=i*480+5;sheet.paste(im,(x,y))
        ImageDraw.Draw(sheet).text((x,y+444),f'{prefix} - {t:.1f}s',font=f,fill='white')
sheet=sheet.crop((0,0,1080,960));sheet.save(V/'Apercu_Video_Test_V03.jpg',quality=94)
with zipfile.ZipFile(R/'Scott_Carousel_V03_Complet.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted((R/'PNG').glob('*.png')):z.write(p,'PNG/'+p.name)
    for p in sorted(V.glob('*_Slide_Video.mp4')):z.write(p,'Video/'+p.name)
    z.write(R/'Apercu_7_Slides.jpg','Apercu_7_Slides.jpg')
    z.write(V/'Apercu_Video_Test_V03.jpg','Apercu_Video_Test_V03.jpg')
    z.write(R/'source/READ_ME.txt','READ_ME.txt')
with zipfile.ZipFile(R/'Scott_Carousel_V03_Sources.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in (R/'source').rglob('*'):
        if p.is_file() and p.name not in ['revise.py']:
            z.write(p,'Scott_Carousel_V03/source/'+str(p.relative_to(R/'source')))
    for n in ['build_video_tests.py','check_audio_copy.py','verification.json','audio_copy_verification.json']:
        z.write(V/n,'Scott_Video_Test_V03/'+n)
    for n in ['03_Gamma_source.mp4','04_Algos_source.mp4']:
        z.write(R.parent/'Scott_Video_Test_V01'/n,'Scott_Video_Test_V01/'+n)
for n in ['Scott_Carousel_V03_Complet.zip','Scott_Carousel_V03_Sources.zip','Scott_Carousel_V03_7_Slides.zip']:
    with zipfile.ZipFile(R/n) as z:
        assert z.testzip() is None
        print(n,len(z.namelist()),'files; integrity verified')
print('7 static slides, 2 video slides, previews, and rebuild sources packaged.')
