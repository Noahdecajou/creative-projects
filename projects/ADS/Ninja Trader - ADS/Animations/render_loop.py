"""Local, credit-free motion treatment of the approved NinjaTrader artwork."""
from pathlib import Path
import math
import shutil
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / 'Designs - Reference' / 'NT - Practice Your Next Move.png'
W, H, FPS, SECONDS = 1080, 1920, 30, 12
base = Image.open(SOURCE).convert('RGB').resize((W, H), Image.Resampling.LANCZOS)
original = np.asarray(base, dtype=np.float32)
y, x = np.mgrid[0:H, 0:W].astype(np.float32)
x /= W
y /= H

def smooth(a, b, values):
    t = np.clip((values-a)/(b-a), 0, 1)
    return t*t*(3-2*t)

# Keep the supplied headline and CTA completely still and legible.
photo_mask = smooth(.376, .411, y) * (1-smooth(.724, .745, y))
bottom_mask = smooth(.881, .925, y)
motion_mask = np.maximum(photo_mask, bottom_mask)[..., None]
warm = np.array([1.0, .40, .095], np.float32)
edge_mask = (1-smooth(.11, .25, x)) + smooth(.78, .95, x)
rng = np.random.default_rng(19)
particles = [(float(rng.uniform(.08,.92)),float(rng.uniform(.42,.70)),
              float(rng.uniform(0,2*math.pi)),float(rng.uniform(1,2.6))) for _ in range(15)]

def frame(t):
    phase = 2*math.pi*t/SECONDS
    breath = .5-.5*math.cos(phase)
    scale = 1.012 + .038*breath
    dx = 8*math.sin(phase)
    dy = 4*math.sin(phase)
    cx, cy = W*.50, H*.57
    inv = 1/scale
    moved = base.transform((W,H), Image.Transform.AFFINE,
        (inv,0,cx-cx*inv+dx,0,inv,cy-cy*inv+dy), Image.Resampling.BICUBIC)
    arr = original*(1-motion_mask) + np.asarray(moved,dtype=np.float32)*motion_mask

    # Broad moving softbox and a warmer rim light; no strobing.
    light_x = .63 + .15*math.sin(phase)
    softbox = np.exp(-((x-light_x)/.23)**2-((y-.55)/.22)**2)
    rim = np.exp(-((x-(.59+.025*math.sin(phase)))/.045)**2-((y-.54)/.12)**2)
    reflected = np.exp(-((x-(.49+.10*math.sin(phase)))/.28)**2-((y-.69)/.037)**2)
    lighting = photo_mask*(softbox*(5+11*breath)+rim*(3+8*breath)+reflected*8*breath)
    arr += lighting[...,None]*warm

    # Sparse, soft dust catches the light at the edges of the chess scene.
    dust = Image.new('RGB',(W,H))
    draw = ImageDraw.Draw(dust)
    for px,py,p,radius in particles:
        opacity = (.5+.5*math.sin(phase+p))**3
        sx = W*(px+.010*math.sin(phase+p))
        sy = H*(py+.012*math.cos(phase+p))
        rr = radius
        draw.ellipse((sx-rr,sy-rr,sx+rr,sy+rr),fill=(int(105*opacity),int(55*opacity),int(18*opacity)))
    dust = np.asarray(dust.filter(ImageFilter.GaussianBlur(1.4)),dtype=np.float32)
    arr += dust*photo_mask[...,None]

    # Gentle glow around the existing red call-to-action.
    halo = np.exp(-((x-.5)/.40)**8-((y-.807)/.032)**2)
    outside_button = 1-(smooth(.10,.15,x)*(1-smooth(.85,.90,x))*smooth(.775,.789,y)*(1-smooth(.831,.846,y)))
    arr += (halo*outside_button*(3+5*breath))[...,None]*np.array([1,.08,.02],np.float32)
    return np.clip(arr,0,255).astype(np.uint8)

OUT.mkdir(exist_ok=True)
video = OUT / 'NT - Practice Your Next Move - Loop 12s.mp4'
ffmpeg = shutil.which('ffmpeg')
if not ffmpeg:
    raise RuntimeError('FFmpeg is required')
command = [ffmpeg,'-hide_banner','-loglevel','error','-y','-f','rawvideo','-pix_fmt','rgb24',
           '-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-an','-c:v','libx264',
           '-preset','fast','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(video)]
proc = subprocess.Popen(command,stdin=subprocess.PIPE)
try:
    for i in range(FPS*SECONDS):
        pixels = frame(i/FPS)
        proc.stdin.write(pixels.tobytes())
        if i in (0,90,180,270):
            Image.fromarray(pixels).save(OUT / f'preview-{i:03d}.jpg',quality=92)
        if i%60 == 0:
            print(f'Rendered {i}/{FPS*SECONDS} frames',flush=True)
finally:
    proc.stdin.close()
if proc.wait() != 0:
    raise RuntimeError('Video encoding failed')
first, last, wrap = frame(0),frame(SECONDS-1/FPS),frame(SECONDS)
assert np.array_equal(first,wrap), 'Loop must return exactly to its starting state'
print(f'Loop boundary mean pixel change: {np.abs(first.astype(float)-last).mean():.4f}',flush=True)
print(video,flush=True)
