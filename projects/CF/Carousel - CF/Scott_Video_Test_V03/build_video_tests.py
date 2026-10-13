from pathlib import Path
from PIL import Image, ImageDraw
import subprocess,json,zipfile
R=Path(__file__).resolve().parent
BASE=R.parent/'Scott_Carousel_V03/PNG'
SOURCES=R.parent/'Scott_Video_Test_V01'
items=[('03_Gamma','03_Options_Flow_Gamma.png',(60,696,1020,1236),50),('04_Algos','04_Algos.png',(60,696,1020,1236),23.04)]
results=[]
for name,base,box,dur in items:
    plate=Image.open(BASE/base).convert('RGB')
    x,y,r,b=box;w=r-x;h=b-y
    ImageDraw.Draw(plate).rounded_rectangle(box,radius=24,fill='#111716',outline='#5b625e',width=2)
    plate.save(R/(name+'_plate.png'))
    mask=Image.new('L',(w,h),0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,w-1,h-1),radius=22,fill=255)
    mask.save(R/(name+'_mask.png'))
    filt=f'[1:v]scale={w}:{h}:force_original_aspect_ratio=decrease,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2:color=0x111716,setsar=1,format=rgba[clip];[2:v]format=gray[mask];[clip][mask]alphamerge[rounded];[0:v][rounded]overlay={x}:{y}:shortest=1,format=yuv420p[out]'
    cmd=['ffmpeg','-hide_banner','-loglevel','error','-y','-loop','1','-framerate','25','-i',str(R/(name+'_plate.png')),'-i',str(SOURCES/(name+'_source.mp4')),'-loop','1','-i',str(R/(name+'_mask.png')),'-filter_complex',filt,'-map','[out]','-map','1:a:0','-t',str(dur),'-r','25','-c:v','libx264','-preset','fast','-crf','18','-c:a','aac','-b:a','192k','-movflags','+faststart',str(R/(name+'_Slide_Video.mp4'))]
    subprocess.run(cmd,check=True)
    p=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration:stream=codec_name,width,height,avg_frame_rate','-of','json',str(R/(name+'_Slide_Video.mp4'))],check=True,capture_output=True,text=True)
    metadata=json.loads(p.stdout);assert float(metadata['format']['duration'])<=55
    v=next(s for s in metadata['streams'] if s['codec_name']=='h264');assert (v['width'],v['height'])==(1080,1350)
    for t in [0.5,dur/2,dur-0.5]:
        subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-ss',str(t),'-i',str(R/(name+'_Slide_Video.mp4')),'-frames:v','1',str(R/(name+f'_QA_{t:.1f}.png'))],check=True)
    results.append({'file':name+'_Slide_Video.mp4','metadata':metadata,'clip_box':list(box)})
    print(name,'rendered and verified',flush=True)
(R/'verification.json').write_text(json.dumps(results,indent=2))
with zipfile.ZipFile(R/'Scott_Slides_3_4_Video_Test_V03.zip','w',zipfile.ZIP_DEFLATED) as z:
    for i in results:z.write(R/i['file'],i['file'])
with zipfile.ZipFile(R/'Scott_Slides_3_4_Video_Test_V03.zip') as z:assert len(z.namelist())==2 and z.testzip() is None
