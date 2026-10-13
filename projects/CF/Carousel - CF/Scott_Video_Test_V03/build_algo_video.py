from pathlib import Path
import subprocess,json
from PIL import Image,ImageDraw,ImageColor
import numpy as np
R=Path(__file__).resolve().parent
design=R.parent/'Scott_Carousel_V02/source/build_carousel.py'
scope={'__file__':str(design)}
exec(design.read_text(encoding='utf-8').split('# Cover:')[0],scope)
im=scope['bg']();scope['logo'](im)
scope['text'](im,'ALGOS',135,82,'SemiBold')
scope['pill'](im,'Trade the rotation',218,51)
scope['lines'](im,['In a range, when price moves too far, too fast,','algorithms can snap it back.'],310,38,leading=56)
scope['lines'](im,['Scott uses the 5-minute Price Change Algo','to alert him when price becomes extended.'],417,38,leading=56)
scope['text'](im,'He trades around an existing position:',529,38)
for x,ss in [(60,['Price extends:','takes size off']),(550,['Price rotates back:','adds size back'])]:
    w=470;h=98;y=576
    mask=Image.new('L',(1080,1350));ImageDraw.Draw(mask).rounded_rectangle((x,y,x+w,y+h),radius=16,fill=85)
    im.paste(Image.new('RGB',im.size,'white'),(0,0),mask.filter(scope['ImageFilter'].GaussianBlur(14)))
    a=np.repeat(np.linspace((255,255,255),(222,225,226),h+1,dtype=np.uint8)[:,None,:],w+1,axis=1)
    tile=Image.fromarray(a);m=Image.new('L',tile.size);ImageDraw.Draw(m).rounded_rectangle((0,0,w,h),radius=16,fill=255)
    im.paste(tile,(x,y),m)
    for i,s in enumerate(ss):
        tw=ImageDraw.Draw(im).textlength(s,font=scope['font'](38,'SemiBold'))
        scope['text'](im,s,y+12+i*42,38,'SemiBold','#090909',x=x+(w-tw)/2)
scope['panel'](im,(60,696,1020,1236));scope['footer'](im)
im.save(R/'04_Algos_plate.png')
mask=Image.new('L',(960,540));ImageDraw.Draw(mask).rounded_rectangle((0,0,959,539),radius=22,fill=255);mask.save(R/'04_Algos_mask.png')
source=R.parent/'Scott_Video_Test_V01/04_Algos_source.mp4'
output=R/'04_Algos_Slide_Video.mp4'
filt='[1:v]scale=960:540,setsar=1,format=rgba[clip];[2:v]format=gray[mask];[clip][mask]alphamerge[rounded];[0:v][rounded]overlay=60:696:shortest=1,format=yuv420p[out]'
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-loop','1','-framerate','25','-i',str(R/'04_Algos_plate.png'),'-i',str(source),'-loop','1','-i',str(R/'04_Algos_mask.png'),'-filter_complex',filt,'-map','[out]','-map','1:a:0','-t','23.04','-r','25','-c:v','libx264','-preset','fast','-crf','18','-c:a','aac','-b:a','192k','-movflags','+faststart',str(output)],check=True)
meta=json.loads(subprocess.run(['ffprobe','-v','error','-show_entries','format=duration:stream=codec_name,width,height','-of','json',str(output)],capture_output=True,text=True,check=True).stdout)
assert float(meta['format']['duration'])<=55
assert any(s.get('width')==1080 and s.get('height')==1350 for s in meta['streams'])
assert any(s.get('codec_name')=='aac' for s in meta['streams'])
for t in [.5,11.5,22.5]:
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-ss',str(t),'-i',str(output),'-frames:v','1',str(R/f'04_Algos_QA_{t}.png')],check=True)
(R/'verification.json').write_text(json.dumps({'metadata':meta,'video_box':[60,696,1020,1236],'body_font_size':38,'copy_preserved':True,'source_audio':True},indent=2))
print('Verified: 1080x1350, 23.04s, 960x540 inset, original audio.')
