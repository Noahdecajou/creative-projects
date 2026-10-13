from pathlib import Path
import math, subprocess, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent
W,H,FPS=720,1280,30
im=Image.open(ROOT/'Designs - Reference'/'NT - Practice Your Next Move.png').convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
outline=[(452,659),(503,677),(549,725),(584,777),(607,831),(616,883),(605,936),(590,989),(584,1045),(592,1085),(619,1137),(613,1168),(591,1196),(521,1210),(397,1215),(348,1206),(330,1188),(335,1160),(342,1140),(353,1124),(363,1092),(369,1068),(356,1045),(350,1015),(367,986),(388,956),(406,919),(420,882),(412,879),(393,894),(373,898),(339,889),(319,870),(317,838),(334,812),(346,792),(381,770),(402,751),(416,721),(435,708),(443,681)]
outline=[(int(x*W/941),int(y*H/1672)) for x,y in outline]
mask=Image.new('L',(W,H));ImageDraw.Draw(mask).polygon(outline,fill=255)
mask=mask.filter(ImageFilter.GaussianBlur(.65))
piece=im.convert('RGBA');piece.putalpha(mask)
box=mask.getbbox();piece=piece.crop(box)
piece=piece.resize((int(piece.width*.86),int(piece.height*.86)),Image.Resampling.LANCZOS)
# Reconstruct the obscured background using neighbouring photographic colours.
source_pixels=np.asarray(im)
arr=source_pixels.copy(); left,right=int(W*.29),int(W*.71)
for yy in range(int(H*.39),int(H*.745)):
    for xx in range(left,right):
        u=(xx-left)/(right-left)
        arr[yy,xx]=(source_pixels[yy,left].astype(float)*(1-u)+source_pixels[yy,right].astype(float)*u).astype(np.uint8)
patch=Image.fromarray(arr).filter(ImageFilter.GaussianBlur(5))
erase=mask.filter(ImageFilter.MaxFilter(61)).filter(ImageFilter.GaussianBlur(5))
bg=Image.composite(patch,im,erase)
route=[(0,0),(60,-18),(90,18),(30,35),(0,0)]
cx=(box[0]+box[2])/2;floor=box[3]

def render(index):
    t=index/FPS;step=min(int(t/3),3);u=t/3-step;e=u*u*(3-2*u)
    a,b=route[step],route[step+1];dx=a[0]+(b[0]-a[0])*e;dy=a[1]+(b[1]-a[1])*e
    jump=45*math.sin(math.pi*u)**2
    canvas=bg.copy().convert('RGBA')
    shadow=Image.new('RGBA',(W,H));d=ImageDraw.Draw(shadow)
    width=105-25*jump/65
    d.ellipse((cx+dx-width,floor+dy-19,cx+dx+width,floor+dy+10),fill=(0,0,0,int(160-50*jump/65)))
    shadow=shadow.filter(ImageFilter.GaussianBlur(10));canvas=Image.alpha_composite(canvas,shadow)
    # An illuminated route emerges under the moving piece.
    glow=Image.new('RGBA',(W,H));g=ImageDraw.Draw(glow)
    pts=[(cx+px,floor+py-4) for px,py in route[:step+1]]+[(cx+dx,floor+dy-4)]
    if len(pts)>1:g.line(pts,fill=(255,99,5,220),width=4)
    for xx,yy in pts:g.ellipse((xx-4,yy-4,xx+4,yy+4),fill=(255,185,76,220))
    halo=glow.filter(ImageFilter.GaussianBlur(10));canvas=Image.alpha_composite(canvas,halo);canvas=Image.alpha_composite(canvas,glow)
    angle=-3*math.sin(2*math.pi*u)*(1 if b[0]>a[0] else -1)
    moving=piece.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    px=int(cx+dx-moving.width/2);py=int(floor+dy-jump-moving.height)
    canvas.alpha_composite(moving,(px,py))
    # Preserve the supplied typography even where the reconstruction mask feathers.
    top=int(H*.389)
    canvas.paste(im.crop((0,0,W,top)),(0,0))
    # Crossfade to the exact original layout around the loop boundary.
    fade=min(1,t/.45,(12-t)/.45)
    canvas=Image.blend(im.convert('RGBA'),canvas,max(0,fade))
    return canvas.convert('RGB')

path=OUT/'NT - Knight in Motion - Loop 12s.mp4'
proc=subprocess.Popen([shutil.which('ffmpeg'),'-hide_banner','-loglevel','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-an','-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(path)],stdin=subprocess.PIPE)
for i in range(360):
    frame=render(i);proc.stdin.write(frame.tobytes())
    if i in [0,45,135,225]:frame.save(OUT/f'motion-preview-{i:03d}.jpg',quality=94)
    if i%90==0:print(f'Rendered {i}/360',flush=True)
proc.stdin.close()
if proc.wait():raise RuntimeError('Encoding failed')
print(path,flush=True)
