"""A locally rendered animated 3D chess scene, with no paid generation service."""
from pathlib import Path
import math, shutil, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
W,H,FPS,DURATION=720,1280,30,12
poster=Image.open(ROOT/'Designs - Reference'/'NT - Practice Your Next Move.png').convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
N=FPS*DURATION
route=[(-2,-2),(-1,0),(1,1),(0,-1),(-2,-2)]

def lathe(profile,pos,color,sides=20):
    pts=[]
    for z,r in profile:
        pts.extend([(pos[0]+r*math.cos(i*2*math.pi/sides),pos[1]+r*math.sin(i*2*math.pi/sides),z+pos[2]) for i in range(sides)])
    faces=[]
    for j in range(len(profile)-1):
        for i in range(sides):
            k=j*sides+i; nxt=j*sides+(i+1)%sides
            faces.append(([pts[k],pts[nxt],pts[nxt+sides],pts[k+sides]],color))
    faces.append(([pts[(len(profile)-1)*sides+i] for i in range(sides)],color))
    return faces

base_profile=[(0,.47),(.10,.50),(.20,.46),(.25,.36),(.32,.33),(.42,.39),(.48,.30),(.62,.27)]
pawn_profile=base_profile+[(.80,.18),(1.10,.12),(1.18,.23),(1.28,.24),(1.38,.17),(1.42,.04)]
# Horse side profile; extruded geometry gives real depth as the camera moves.
horse=[(-.36,.52),(.32,.52),(.39,.76),(.33,1.08),(.24,1.43),(.11,1.72),
       (-.01,1.93),(-.16,2.16),(-.23,1.91),(-.43,1.86),(-.59,1.67),
       (-.84,1.46),(-.82,1.23),(-.59,1.19),(-.47,1.38),(-.24,1.47),
       (-.19,1.27),(-.34,1.00),(-.43,.72)]

def knight(pos):
    faces=lathe(base_profile,pos,(94,43,20))
    sides=[]
    for width in [-.19,.19]:
        sides.append([(pos[0]+hx,pos[1]+width,pos[2]+hz) for hx,hz in horse])
    faces.append((sides[0],(126,60,24)))
    faces.append((sides[1],(170,80,24)))
    for i in range(len(horse)):
        j=(i+1)%len(horse)
        faces.append(([sides[0][i],sides[0][j],sides[1][j],sides[1][i]],(210,99,26)))
    return faces

def render(i):
    t=i/FPS; theta=2*math.pi*t/DURATION
    yaw=.24+.24*math.sin(theta)
    cam=np.array([12*math.sin(yaw),-12*math.cos(yaw),10.0])
    target=np.array([0.,0.,.45]); forward=(target-cam);forward/=np.linalg.norm(forward)
    right=np.cross(forward,[0,0,1]);right/=np.linalg.norm(right)
    up=np.cross(right,forward)
    def project(p):
        q=np.array(p)-cam; depth=np.dot(q,forward)
        return (W*.50+760*np.dot(q,right)/depth,H*.568-760*np.dot(q,up)/depth)
    def depth(points):return float(np.mean([np.dot(np.array(p)-cam,forward) for p in points]))
    scene=Image.new('RGB',(W,H),(8,7,7));draw=ImageDraw.Draw(scene)
    faces=[]
    for bx in range(-4,4):
        for by in range(-4,4):
            col=(35,29,26) if (bx+by)%2 else (72,55,43)
            faces.append(([(bx,by,0),(bx+1,by,0),(bx+1,by+1,0),(bx,by+1,0)],col))
    faces.append(([(-4,-4,0),(4,-4,0),(4,-4,-.32),(-4,-4,-.32)],(28,17,12)))
    progress=t/3; step=min(int(progress),3); u=progress-step
    ease=u*u*(3-2*u)
    start,end=route[step],route[step+1]
    # Every three seconds the knight visibly hops to its next L-shaped destination.
    current=(start[0]+(end[0]-start[0])*ease,start[1]+(end[1]-start[1])*ease)
    hop=.85*math.sin(math.pi*u)**2
    for px,py in [(-3,1),(3,2),(2,-3),(-3,-3)]:
        faces+=lathe(pawn_profile,(px,py,0),(35,32,30))
    faces+=knight((current[0],current[1],hop))
    light=np.array([-.45,-.6,.65]);light/=np.linalg.norm(light)
    for verts,color in sorted(faces,key=lambda f:depth(f[0]),reverse=True):
        v=np.array(verts,dtype=float)
        normal=np.cross(v[1]-v[0],v[2]-v[0]);norm=np.linalg.norm(normal)
        if norm>0:normal/=norm
        illumination=.55+.65*abs(float(np.dot(normal,light)))
        shaded=tuple(min(255,int(c*illumination)) for c in color)
        screen=[project(p) for p in verts]
        draw.polygon(screen,fill=shaded)
        if color[0]>90:
            draw.line(screen+[screen[0]],fill=(133,65,24),width=1)
    # L-shaped trails light up progressively, reinforcing the actual chess move.
    glow=Image.new('RGB',(W,H));g=ImageDraw.Draw(glow)
    for j in range(4):
        a,b=route[j],route[j+1]
        elbow=(b[0],a[1])
        points=[a,elbow,b]
        strength=.25+.75*(j==step)
        coords=[project((px,py,.025)) for px,py in points]
        g.line(coords,fill=(int(255*strength),int(90*strength),int(10*strength)),width=3)
        for q in (coords[0],coords[-1]):g.ellipse((q[0]-3,q[1]-3,q[0]+3,q[1]+3),fill=(255,118,24))
    arr=np.asarray(scene,dtype=np.float32)
    arr+=np.asarray(glow.filter(ImageFilter.GaussianBlur(8)),dtype=np.float32)*1.2
    arr+=np.asarray(glow,dtype=np.float32)*.7
    scene=Image.fromarray(np.clip(arr,0,255).astype(np.uint8))
    # Feather into the approved layout; keep headline, branding and CTA unchanged.
    mask=Image.new('L',(W,H));m=ImageDraw.Draw(mask)
    m.rectangle((0,int(H*.396),W,int(H*.735)),fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(9))
    final=Image.composite(scene,poster,mask)
    return final

video=OUT/'NT - Knight in Motion - Loop 12s.mp4'
command=[shutil.which('ffmpeg'),'-hide_banner','-loglevel','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-an','-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-crf','18','-preset','fast','-pix_fmt','yuv420p','-movflags','+faststart',str(video)]
proc=subprocess.Popen(command,stdin=subprocess.PIPE)
for i in range(N):
    img=render(i)
    proc.stdin.write(img.tobytes())
    if i in [0,45,90,135,180,270]:img.save(OUT/f'action-preview-{i:03d}.jpg',quality=93)
    if i%90==0:print(f'Rendered {i}/{N}',flush=True)
proc.stdin.close()
if proc.wait():raise RuntimeError('Encoding failed')
print(video,flush=True)
