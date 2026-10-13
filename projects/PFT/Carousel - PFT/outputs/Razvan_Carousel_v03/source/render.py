"""Editable PFT carousel source. Run with Python + Pillow + NumPy.
All coordinates are in 1080x1350 design pixels; PNGs render at 2x then downsample.
Text and chart geometry remain editable separately from photographic ImageGen plates.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
import numpy as np
import base64, html, json, hashlib, zipfile

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'assets'
FONTS = ROOT / 'source' / 'fonts'
S = 2
GREEN = '#37FE03'  # dominant bright green sampled from Design Ref headline
PALE = '#B0FF88'
WHITE = '#F5F6F4'
GREY = '#C6CBC6'
FONT_FILES = {'regular':'Poppins-Regular.ttf','medium':'Poppins-Medium.ttf',
              'semi':'Poppins-SemiBold.ttf','bold':'Poppins-Bold.ttf','serif':'PPEiko-Thin.otf'}
FONT_NAMES = {k:'PFT'+k.title() for k in FONT_FILES}
def rgb(c): return tuple(int(c[i:i+2],16) for i in (1,3,5))
def font(size, kind='regular'): return ImageFont.truetype(str(FONTS/FONT_FILES[kind]),round(size*S))
def width(t,size,kind='regular'): return font(size,kind).getlength(t)/S

class Canvas:
    def __init__(self, background='education'):
        self.im=Image.new('RGBA',(1080*S,1350*S),(9,11,10,255))
        self.svg=[]; self.text_boxes=[]
        if background == 'minimal':
            yy,xx=np.mgrid[0:1350*S,0:1080*S]
            glow=np.maximum(0,1-np.sqrt(((xx/S-920)/1050)**2+((yy/S-960)/1100)**2))*.12
            plate=np.zeros((1350*S,1080*S,4),dtype=np.uint8)
            for k,v in enumerate(rgb(GREEN)): plate[:,:,k]=9*(1-glow)+v*glow
            plate[:,:,3]=255
            self.im=Image.fromarray(plate)
            self.svg.append('<defs><radialGradient id="subtleGreen" cx="85%" cy="71%" r="90%"><stop offset="0" stop-color="#37FE03" stop-opacity="0.12"/><stop offset="1" stop-color="#37FE03" stop-opacity="0"/></radialGradient></defs><rect width="1080" height="1350" fill="#090909"/><rect width="1080" height="1350" fill="url(#subtleGreen)"/>')
        else:
            self.image(ASSETS/(background+'.png'),0,0,1080,1350)
        if background in ('education','analysis'):
            self.rect(0,0,1080,1240,'#080808',opacity=.12)
    def image(self,path,x,y,w,h):
        im=Image.open(path).convert('RGBA').resize((round(w*S),round(h*S)),Image.Resampling.LANCZOS)
        self.im.alpha_composite(im,(round(x*S),round(y*S)))
        ext='jpeg' if Path(path).suffix.lower() in ('.jpg','.jpeg') else 'png'
        uri='data:image/'+ext+';base64,'+base64.b64encode(Path(path).read_bytes()).decode()
        self.svg.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="none" href="{uri}"/>')
    def rect(self,x,y,w,h,fill='#111814',outline=None,r=0,opacity=1):
        # Warm charcoal glass replaces the green-tinted V01 surfaces.
        neutral_fills={'#111814':'#171615','#101712':'#191817',
            '#18231A':'#252321','#080E09':'#131211','#0B130E':'#141413',
            '#101912':'#171615','#11200E':'#191816','#0D1710':'#161514',
            '#0A100C':'#141312','#243E19':'#30312A','#234B14':'#30312A'}
        neutral_lines={'#4B6146':'#706B62','#42583D':'#69665F','#40503B':'#69665F',
            '#436537':'#706B62','#425D3D':'#69665F','#496B3A':'#706B62',
            '#3C5135':'#706B62','#4B6047':'#706B62','#73806E':'#706B62'}
        fill=neutral_fills.get(fill,fill); outline=neutral_lines.get(outline,outline)
        layer=Image.new('RGBA',self.im.size); d=ImageDraw.Draw(layer)
        fc=(*rgb(fill),round(255*opacity)) if fill else None
        d.rounded_rectangle((x*S,y*S,(x+w)*S,(y+h)*S),radius=r*S,fill=fc,
                            outline=(*rgb(outline),255) if outline else None,width=2*S)
        self.im.alpha_composite(layer)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill or "none"}" fill-opacity="{opacity}" stroke="{outline or "none"}" stroke-width="2"/>')
    def soft_shade(self,x,y,w,h,opacity=.6):
        layer=Image.new('RGBA',self.im.size)
        ImageDraw.Draw(layer).rounded_rectangle((x*S,y*S,(x+w)*S,(y+h)*S),radius=30*S,fill=(9,9,9,round(255*opacity)))
        layer=layer.filter(ImageFilter.GaussianBlur(25*S))
        self.im.alpha_composite(layer)
        self.svg.append(f'<defs><filter id="softShade"><feGaussianBlur stdDeviation="25"/></filter></defs><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="30" fill="#090909" fill-opacity="{opacity}" filter="url(#softShade)"/>')
    def line(self,pts,color='#465147',weight=1,dash=False):
        d=ImageDraw.Draw(self.im)
        if dash and len(pts)==2:
            a,b=pts; dist=((a[0]-b[0])**2+(a[1]-b[1])**2)**.5
            for t in np.arange(0,dist,16):
                q1=(a[0]+(b[0]-a[0])*t/dist,a[1]+(b[1]-a[1])*t/dist)
                tt=min(t+8,dist); q2=(a[0]+(b[0]-a[0])*tt/dist,a[1]+(b[1]-a[1])*tt/dist)
                d.line([(q1[0]*S,q1[1]*S),(q2[0]*S,q2[1]*S)],fill=color,width=max(1,round(weight*S)))
        else: d.line([(x*S,y*S) for x,y in pts],fill=color,width=max(1,round(weight*S)),joint='curve')
        p=' '.join(f'{x},{y}' for x,y in pts)
        self.svg.append(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{weight}" stroke-dasharray="{"8 8" if dash else "none"}"/>')
    def text(self,t,x,y,size=32,kind='regular',color=WHITE,center=False,gradient=False):
        f=font(size,kind); w=f.getlength(t)/S
        if center: x-=w/2
        bbox=f.getbbox(t,anchor='lt'); h=(bbox[3]-bbox[1])/S
        self.text_boxes.append({'text':t,'x':round(x,2),'y':y,'width':round(w,2),'height':round(h,2),'size':size})
        assert x>=0 and x+w<=1080.5 and y>=0 and y+h<=1350, f'Overflow: {t} {x} {w}'
        if gradient:
            mask=Image.new('L',self.im.size); ImageDraw.Draw(mask).text((x*S,y*S),t,font=f,fill=255,anchor='lt')
            # No neon glow: keep a restrained typographic gradient only.
            colors=np.zeros((1350*S,1,3),dtype=np.uint8)
            for yy in range(1350*S):
                a=max(0,min(1,(yy/S-y)/max(1,h)))
                colors[yy,0]=np.array(rgb(PALE))*(1-a)+np.array(rgb(GREEN))*a
            grad=Image.fromarray(colors).resize(self.im.size); self.im.paste(grad,(0,0),mask)
        else: ImageDraw.Draw(self.im).text((x*S,y*S),t,font=f,fill=color,anchor='lt')
        baseline=y-f.getbbox(t,anchor='ls')[1]/S
        self.svg.append(f'<text x="{x:.3f}" y="{baseline:.3f}" font-family="{FONT_NAMES[kind]}" font-size="{size}" fill="{"url(#lime)" if gradient else color}">{html.escape(t)}</text>')
    def paragraph(self,t,x,y,w,size=32,kind='regular',color=WHITE,leading=None,center=False):
        leading=leading or size*1.4; rows=[]
        for para in t.split('\n'):
            line=''
            for word in para.split():
                trial=(line+' '+word).strip()
                if width(trial,size,kind)>w and line: rows.append(line); line=word
                else: line=trial
            rows.append(line)
        for i,line in enumerate(rows): self.text(line,x+w/2 if center else x,y+i*leading,size,kind,color,center)
        return y+len(rows)*leading
    def badge(self,n,x,y):
        self.rect(x,y,38,38,GREEN,r=19)
        self.text(str(n),x+19,y+6,25,'semi','#071005',True)
    def footer(self,swipe=True):
        self.rect(0,1240,1080,110,'#070A08',opacity=.80)
        self.image(ASSETS/'logo.png',72,1261,28,42)
        self.text('PropFirmTrader',112,1272,25,'medium')
        self.line([(360,1285),(853 if swipe else 1008,1285)],'#616A60',1)
        if swipe:
            self.rect(883,1264,125,38,'#101712','#73806E',19)
            self.text('SWIPE',897,1271,22,'medium')
            self.line([(979,1277),(985,1283),(979,1289)],WHITE,2)
    def step(self,n):
        self.rect(72,72,126,43,'#18231A','#4B6047',21)
        self.text(f'STEP {n}',135,82,24,'medium',WHITE,True)
    def save(self,n):
        p=ROOT/'slides'/f'{n:02d}.png'; self.im.convert('RGB').resize((1080,1350),Image.Resampling.LANCZOS).save(p,compress_level=6)
        styles=''.join(f'@font-face{{font-family:{FONT_NAMES[k]};src:url(data:font/{"otf" if v.endswith("otf") else "ttf"};base64,{base64.b64encode((FONTS/v).read_bytes()).decode()});}}' for k,v in FONT_FILES.items())
        svg='<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350"><defs><linearGradient id="lime" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="'+PALE+'"/><stop offset="1" stop-color="'+GREEN+'"/></linearGradient><style>'+styles+'</style></defs>'+''.join(self.svg)+'</svg>'
        (ROOT/'source'/f'{n:02d}_editable.svg').write_text(svg,encoding='utf-8')
        return {'file':p.name,'dimensions':[1080,1350],'text_boxes':self.text_boxes,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}

def candle(c,x,o,close,high,low,w=16):
    col=GREEN if close<o else '#C4CBC4'
    c.line([(x,high),(x,low)],col,2)
    c.rect(x-w/2,min(o,close),w,max(3,abs(o-close)),col,r=1)

def grid(c,x,y,w,h):
    for yy in np.linspace(y,y+h,5): c.line([(x,yy),(x+w,yy)],'#263128',1)
    for xx in np.linspace(x,x+w,8): c.line([(xx,y),(xx,y+h)],'#1D271F',1)

def prepare():
    # Extract the authentic green logo from the supplied episode still.
    im=Image.open(ASSETS/'logo_crop.png').convert('RGBA'); ar=np.array(im)
    ar[:,:,3]=np.where((ar[:,:,1]>ar[:,:,0]*1.15)&(ar[:,:,1]>ar[:,:,2]*1.5)&(ar[:,:,1]>40),255,0)
    Image.fromarray(ar).save(ASSETS/'logo.png')

def build():
    prepare(); records=[]
    c=Canvas('hero_candle')
    c.text('THE STRATEGY BEHIND A',540,64,34,'medium',WHITE,True)
    c.text('$158,000',540,126,144,'semi',GREEN,True,True)
    c.text('Payout',540,285,91,'serif',WHITE,True)
    c.rect(72,1045,936,126,'#080E09','#4B6146',24,.92)
    c.text('Razvan made a $158K prop firm payout',540,1065,34,'regular',WHITE,True)
    c.text('in just two weeks.',540,1116,34,'semi',GREEN,True)
    c.text('Here’s the strategy behind it.',540,1191,32,'regular',WHITE,True)
    c.footer(); records.append(c.save(1))

    c=Canvas('levels_portrait'); c.step(1)
    c.text('Mark the',72,151,72,'serif',WHITE)
    c.text('KEY LEVELS',72,233,86,'semi',GREEN,gradient=True)
    c.text('before the New York open.',72,337,38,'regular')
    c.text('Razvan maps out:',72,415,32,'medium')
    for i,t in enumerate(['Previous day highs and lows','Previous week highs and lows','Session highs and lows','Value area highs and lows']):
        yy=465+i*48; c.rect(75,yy+10,9,9,GREEN,r=4); c.text(t,104,yy,32)
    c.rect(72,692,936,355,'#0B130E','#42583D',24,.97)
    c.text('KEY LEVEL CONFLUENCE',100,716,23,'medium',GREY)
    grid(c,103,780,871,211)
    c.rect(103,790,871,85,GREEN,r=6,opacity=.10)
    for yy,label in [(801,'SESSION HIGH'),(832,'PDH'),(863,'VAH')]:
        c.line([(105,yy),(698,yy)],GREEN,2,True)
        c.text(label,728,yy-8,22,'medium',GREEN)
    vals=[970,952,959,924,906,914,872,853,861,830,815,832,810,836]
    for i in range(len(vals)-1):
        o,cl=vals[i],vals[i+1]; candle(c,127+i*40,o,cl,min(o,cl)-9,max(o,cl)+12,18)
    c.rect(715,921,257,43,'#243E19','#639950',20)
    c.text('OVERLAP ZONE',843,932,22,'medium',GREEN,True)
    c.text('Illustrative chart • not a trade result',540,1010,21,'regular',GREY,True)
    c.rect(72,1081,936,132,'#171615','#706B62',22,.86)
    c.paragraph('His favourite opportunities appear when multiple key levels overlap in the same area.',147,1101,786,32,center=True,leading=44)
    c.footer(); records.append(c.save(2))

    c=Canvas('reactions_portrait'); c.step(2)
    c.text('Watch how price',72,151,67,'regular')
    c.text('Reacts',72,231,107,'serif',WHITE)
    c.text('Reaching a key level isn’t Razvan’s entry.',72,367,32)
    c.text('He waits to see what price does there.',72,415,32)
    reactions=[('DISPLACEMENT','Price moves aggressively\nthrough the level.',[.82,.72,.67,.52,.17,.12,.04]),
               ('CONSOLIDATION','Price starts chopping\naround the area.',[.82,.70,.56,.48,.53,.46,.54,.47,.52]),
               ('REVERSAL','Price starts rejecting\nthe level.',[.82,.73,.55,.48,.56,.68,.76])]
    for i,(head,body,vals) in enumerate(reactions):
        yy=493+i*211; c.rect(72,yy,936,191,'#101912','#40503B',24,.95)
        c.text(head,104,yy+28,29,'semi',WHITE)
        c.paragraph(body,104,yy+82,460,28,leading=39)
        x0=616; y0=yy+31; grid(c,x0,y0,347,133)
        lev=y0+66; c.line([(x0,lev),(963,lev)],PALE,2,True)
        for j in range(len(vals)-1):
            o=y0+vals[j]*125; cl=y0+vals[j+1]*125
            candle(c,x0+20+j*(308/(len(vals)-1)),o,cl,min(o,cl)-7,max(o,cl)+7,16)
    c.rect(72,1124,936,108,'#171615',r=22,opacity=.88)
    c.text('Illustrative reactions at the same key level',540,1141,21,'regular',GREY,True)
    c.text('The reaction determines what Razvan looks for next.',540,1192,30,'medium',WHITE,True)
    c.footer(); records.append(c.save(3))

    c=Canvas('minimal'); c.step(3)
    c.text('Wait for a reversal',72,151,70,'serif',WHITE)
    c.text('CONFIRMATION',72,237,74,'semi')
    c.paragraph('Razvan prefers reversals for higher reward-to-risk ratios and clearer targets.',72,339,790,30,leading=42)
    c.text('A rejection alone isn’t enough.',72,438,32,'medium',GREEN)
    steps=['Price reaches a key level','A fair value gap forms through it','The fair value gap is inverted','Price closes back through the level','Razvan enters on confirmation']
    for i,t in enumerate(steps):
        yy=515+i*111; c.badge(i+1,72,yy+3)
        c.paragraph(t,131,yy,367,29,leading=38)
        if i<4:
            c.line([(90,yy+64),(90,yy+93)],'#819779',2)
            c.line([(83,yy+85),(90,yy+93),(97,yy+85)],'#819779',2)
    c.rect(538,510,470,576,'#EBEEEE','#64785B',18)
    c.image(ASSETS/'episode_chart_crop.png',551,523,444,555)
    # Numbered markers point to the real candle/zone sequence in the episode screenshot.
    markers=[(1,644,642),(2,755,655),(3,672,595),(4,686,724),(5,700,760)]
    for n,x,y in markers: c.badge(n,x,y)
    c.text('ACTUAL EPISODE • NASDAQ 5M',773,1098,20,'medium',GREY,True)
    c.rect(72,1140,936,96,'#11200E','#436537',20,.96)
    c.text('His preferred Nasdaq setup at the New York open:',540,1157,27,'medium',WHITE,True)
    c.text('5-minute inversion; execution refined on the 1-minute chart.',540,1198,26,'regular',GREEN,True)
    c.footer(); records.append(c.save(4))

    c=Canvas('trailing_overhead'); c.step(4)
    c.text('Let the',72,151,86,'serif',WHITE)
    c.text('WINNERS RUN',72,248,80,'semi',GREEN,gradient=True)
    c.paragraph('Razvan uses logical levels, such as session highs and lows, as targets.',72,355,760,32,leading=45)
    c.rect(72,484,936,383,'#0D1710','#425D3D',24,.96)
    c.text('AFTER THE TARGET • 1-MINUTE SHORT EXAMPLE',100,508,22,'medium',GREY)
    grid(c,105,559,870,230)
    vals=[573,588,603,588,615,634,627,655,673,690,716,731,760,774]
    target=657; c.line([(105,target),(975,target)],GREEN,2,True)
    c.rect(118,665,258,38,'#234B14',r=17)
    c.text('LONDON LOW TARGET',247,673,20,'medium',PALE,True)
    for i in range(len(vals)-1):
        o,cl=vals[i],vals[i+1]; candle(c,130+i*61,o,cl,min(o,cl)-8,max(o,cl)+7,23)
    pts=[]
    for i in range(7,13):
        xx=130+i*61; yy=min(vals[i],vals[i+1])-18
        if pts: pts.append((xx,pts[-1][1]))
        pts.append((xx,yy)); c.line([(xx-16,yy),(xx+24,yy)],WHITE,3)
    c.line(pts,WHITE,2)
    c.text('TRAILING STOP',790,566,22,'medium')
    c.line([(839,598),(851,702)],WHITE,1)
    c.text('Illustrative chart • target hit, then trail above new candles',540,821,21,'regular',GREY,True)
    c.rect(72,896,936,175,'#171615',r=22,opacity=.88)
    c.paragraph('Once price reaches the target, he switches to the 1-minute chart and trails his stop above each new candle as the move continues.',96,922,888,32,leading=45)
    c.rect(72,1105,936,119,'#11200E','#496B3A',22,.96)
    c.paragraph('Razvan says this simple rule can sometimes make enough P&L to make up for the entire week.',104,1130,872,29,leading=42,center=True)
    c.footer(); records.append(c.save(5))

    c=Canvas('outro_close')
    c.text('The full',72,103,110,'serif',WHITE)
    c.text('PROCESS',72,229,94,'semi')
    items=['Mark the key levels','Wait for price\nto reach them','Read the reaction','Wait for confirmation','Enter with\ndefined risk','Target the next\nlogical level']
    ys=[394,465,578,650,722,835]
    for i,(t,y) in enumerate(zip(items,ys)):
        c.badge(i+1,72,y+2); c.paragraph(t,128,y,427,30,leading=41)
    c.rect(72,964,936,131,'#0A100C','#3C5135',22,.92)
    c.paragraph('In the full breakdown, Razvan opens his charts and walks through his trades, explaining the thought process behind them.',103,984,874,30,leading=40)
    c.rect(72,1122,936,77,WHITE,GREEN,r=24)
    c.text('WATCH THE $158K STRATEGY BREAKDOWN',540,1147,31,'semi','#061004',True)
    c.text('Full episode — link in bio.',540,1214,28,'regular',WHITE,True)
    c.footer(False); records.append(c.save(6))

    (ROOT/'source'/'layout_verification.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    sheet=Image.new('RGB',(1080,944),'#171B17')
    for i in range(6):
        im=Image.open(ROOT/'slides'/f'{i+1:02d}.png').resize((344,430),Image.Resampling.LANCZOS)
        x=12+(i%3)*356; y=12+(i//3)*472; sheet.paste(im,(x,y))
        ImageDraw.Draw(sheet).text((x+5,y+440),f'SLIDE {i+1}',font=ImageFont.truetype(str(FONTS/'Poppins-Medium.ttf'),17),fill='#DCE4D9')
    sheet.save(ROOT/'apercu_global.png')
    mobile=Image.new('RGB',(1080,900),'#171B17')
    for i in range(6):
        im=Image.open(ROOT/'slides'/f'{i+1:02d}.png').resize((360,450),Image.Resampling.LANCZOS)
        mobile.paste(im,((i%3)*360,(i//3)*450))
    mobile.save(ROOT/'source'/'qa_mobile_360.png')
    (ROOT/'source'/'preview.html').write_text('<!doctype html><meta charset="utf-8"><title>PFT — Razvan carousel</title><style>body{background:#141814;color:white;font:18px sans-serif;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:24px}img{width:100%;border-radius:12px}a{color:#8dff61}</style><h1>PFT — Razvan</h1><main>'+''.join(f'<div><a href="{i:02d}_editable.svg">Editable slide {i}</a><img src="../slides/{i:02d}.png"></div>' for i in range(1,7))+'</main>',encoding='utf-8')
    with zipfile.ZipFile(ROOT.parent/'Razvan_Carousel_v03_PNG.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted((ROOT/'slides').glob('*.png')): z.write(p,p.name)
    print(json.dumps({'png_count':len(records),'dimensions':[1080,1350],'source':'source/render.py','text_overflows':0}))

if __name__=='__main__': build()
