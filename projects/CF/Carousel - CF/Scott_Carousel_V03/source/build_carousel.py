from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter
import numpy as np
import json, zipfile, math

ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'source/assets'; F=ROOT/'source/fonts'; OUT=ROOT/'PNG'
W,H=1080,1350
GREEN='#20f000'; RED='#ff242b'; WHITE='#ffffff'; MUTED='#c4c7c4'
records=[]; bounds=[]; last_text=0
def font(size,weight='Regular'): return ImageFont.truetype(str(F/f'Poppins-{weight}.ttf'),size)
def bg():
    yy,xx=np.mgrid[0:H,0:W]
    arr=np.zeros((H,W,3),dtype=float)+7
    for x,y,c,s in [(1090,-100,(105,8,9),420),(-60,1330,(23,65,0),490),(100,-100,(25,27,30),440)]:
        v=np.exp(-((xx-x)**2+(yy-y)**2)/(2*s*s))
        arr+=v[:,:,None]*np.array(c)
    return Image.fromarray(np.uint8(np.clip(arr,0,255)))
def text(im,s,y,size=38,weight='Regular',color=WHITE,x=None,center=True):
    d=ImageDraw.Draw(im); f=font(size,weight); b=d.textbbox((0,0),s,font=f)
    width=d.textlength(s,font=f)
    if x is None: x=(W-width)/2 if center else 64
    assert x>=40 and x+width<=1040,(s,x,width)
    if weight=='SemiBold':
        from PIL import ImageColor
        tw=int(math.ceil(width))+4;th=b[3]-b[1]+4
        mask=Image.new('L',(tw,th));ImageDraw.Draw(mask).text((0,-b[1]),s,font=f,fill=255)
        rgb=np.array(ImageColor.getrgb(color))
        end=np.array((211,218,224)) if color==WHITE else np.array((31,38,36)) if color in ['#070707','#090909','#080808'] else rgb
        arr=np.repeat(np.linspace(rgb,end,th,dtype=np.uint8)[:,None,:],tw,axis=1)
        if color==WHITE:
            im.paste(Image.new('RGB',(tw,th),'#000000'),(int(x)+1,y+2),mask)
        im.paste(Image.fromarray(arr),(int(x),y),mask)
    else:d.text((x,y-b[1]),s,font=f,fill=color)
    bounds.append({'text':s,'box':[round(x),y,round(x+width),y+b[3]-b[1]],'size':size})
    return b[3]-b[1]
def lines(im,ss,y,size=38,weight='Regular',color=WHITE,leading=56,x=None):
    for n,s in enumerate(ss): text(im,s,y+n*leading,size,weight,color,x)
def pill(im,s,y,size=48,fill=GREEN,color='#070707',weight='SemiBold',x=None):
    d=ImageDraw.Draw(im); f=font(size,weight); tw=d.textlength(s,font=f); bb=d.textbbox((0,0),s,font=f)
    h=bb[3]-bb[1]+32; w=int(tw+48)
    if x is None:x=(W-w)/2
    x=int(x); mask=Image.new('L',(W,H));md=ImageDraw.Draw(mask)
    md.rounded_rectangle((x,y,x+w,y+h),radius=16,fill=95)
    glow=Image.new('RGB',(W,H),fill); im.paste(glow,(0,0),mask.filter(ImageFilter.GaussianBlur(17)))
    from PIL import ImageColor
    rgb=np.array(ImageColor.getrgb(fill)); top=np.minimum(255,rgb*.86+34); bottom=rgb*.87
    arr=np.repeat(np.linspace(top,bottom,h+1,dtype=np.uint8)[:,None,:],w+1,axis=1)
    tile=Image.fromarray(arr); m=Image.new('L',tile.size);ImageDraw.Draw(m).rounded_rectangle((0,0,w,h),radius=16,fill=255)
    im.paste(tile,(x,y),m)
    ImageDraw.Draw(im).rounded_rectangle((x+1,y+1,x+w-1,y+h-1),radius=15,outline=tuple(np.uint8(top)),width=2)
    text(im,s,y+16,size,weight,color,x=x+24)
    return h
def single_candle(im,name,x,y,width):
    src=Image.open(A/name).convert('RGBA');src=src.crop(src.getbbox())
    src=src.resize((width,round(width*src.height/src.width)),Image.Resampling.LANCZOS)
    im.paste(src,(x,y),src)
def candle_pair(im):
    single_candle(im,'candle_red.png',-35,130,180)
    single_candle(im,'candle_green.png',956,960,190)
def action_card(im,x,ss):
    w=470;h=98;y=576
    mask=Image.new('L',(1080,1350));ImageDraw.Draw(mask).rounded_rectangle((x,y,x+w,y+h),radius=16,fill=85)
    im.paste(Image.new('RGB',im.size,'white'),(0,0),mask.filter(ImageFilter.GaussianBlur(14)))
    a=np.repeat(np.linspace((255,255,255),(222,225,226),h+1,dtype=np.uint8)[:,None,:],w+1,axis=1)
    tile=Image.fromarray(a);m=Image.new('L',tile.size);ImageDraw.Draw(m).rounded_rectangle((0,0,w,h),radius=16,fill=255)
    im.paste(tile,(x,y),m)
    for i,t in enumerate(ss):
        tw=ImageDraw.Draw(im).textlength(t,font=font(38,'SemiBold'))
        text(im,t,y+12+i*42,38,'SemiBold','#090909',x=x+(w-tw)/2)
def panel(im,box): ImageDraw.Draw(im).rounded_rectangle(box,radius=24,fill='#111716',outline='#5b625e',width=2)
def paste_round(im,asset,box,radius=22):
    x,y,r,b=box; p=ImageOps.fit(asset,(r-x,b-y),method=Image.Resampling.LANCZOS)
    mask=Image.new('L',p.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,p.width-1,p.height-1),radius=radius,fill=255)
    im.paste(p,(x,y),mask)
def logo(im,x=64,y=46,width=330):
    src=Image.open(A/'logo.png').convert('RGBA');src=src.crop(src.getbbox())
    src=src.resize((width,round(width*src.height/src.width)),Image.Resampling.LANCZOS)
    im.paste(src,(x,y),src)
def footer(im,swipe=True):
    text(im,'chartfanatics.com',1269,30,color='#9eb09a',x=64)
    if swipe:
        ImageDraw.Draw(im).rounded_rectangle((814,1257,1016,1310),radius=27,outline='#b7c9b1',width=1)
        text(im,'Swipe',1270,30,x=837)
        arrow(ImageDraw.Draw(im),[(940,1283),(990,1283)],'#ffffff',2)
def header(im,a,b=None):
    logo(im)
    text(im,a,149,82,'SemiBold')
    if b:pill(im,b,249,82)
def save(im,name):
    global last_text
    footer(im,name[:2]!='07')
    p=OUT/name; im.save(p)
    records.append({'file':name,'dimensions':[W,H],'copy':[b['text'] for b in bounds[last_text:]]})
    last_text=len(bounds)
def arrow(d,xy,color=GREEN,width=4):
    d.line(xy,fill=color,width=width)
    (x0,y0),(x1,y1)=xy[-2:];a=math.atan2(y1-y0,x1-x0)
    d.polygon([(x1,y1),(x1-17*math.cos(a-.5),y1-17*math.sin(a-.5)),(x1-17*math.cos(a+.5),y1-17*math.sin(a+.5))],fill=color)
def chart(im,box,vals,level=None):
    panel(im,box); x,y,r,b=box;d=ImageDraw.Draw(im)
    for gy in range(y+70,b-45,60):d.line((x+25,gy,r-25,gy),fill='#26312c',width=1)
    left=x+35;right=r-35;top=y+90;bottom=b-55
    lo=min(vals)-8;hi=max(vals)+8
    def py(v):return bottom-(v-lo)/(hi-lo)*(bottom-top)
    step=(right-left)/len(vals)
    for i in range(1,len(vals)):
        op=vals[i-1];cl=vals[i];px=left+i*step;c=GREEN if cl>=op else RED
        d.line((px,py(max(op,cl)+3),px,py(min(op,cl)-3)),fill=c,width=2)
        d.rectangle((px-step*.24,py(max(op,cl)),px+step*.24,max(py(min(op,cl)),py(max(op,cl))+3)),fill=c)
    if level is not None:d.line((left,py(level),right,py(level)),fill=GREEN,width=3)
    return left,right,py,step

# Cover: photographic asset stays separate from all typeset copy.
im=bg(); cover=ImageOps.fit(Image.open(A/'cover.png'),(W,H),method=Image.Resampling.LANCZOS)
im.paste(cover,(0,0));logo(im)
pill(im,'Scott Pulcini',46,29,WHITE,'#090909',x=748)
text(im,'4 THINGS',138,96,'SemiBold')
lines(im,['THAT CAN MAKE YOUR TRADING'],239,42)
pill(im,'“100X BETTER”',290,80,RED,WHITE)
overlay=Image.new('RGBA',(W,H));od=ImageDraw.Draw(overlay)
for yy in range(1175,H):od.line((0,yy,W,yy),fill=(0,0,0,min(245,int((yy-1175)*1.9))))
im=Image.alpha_composite(im.convert('RGBA'),overlay).convert('RGB')
pill(im,'$15M IN 3 YEARS',1080,46,WHITE,'#090909')
lines(im,['From a trader who says he made $15M','for himself and his trading firm.'],1162,38,leading=56)
save(im,'01_100X_Better.png')

im=bg();header(im,'ICEBERGS','+ STOP RUNS')
lines(im,['A big green candle doesn’t always','mean buyers are entering.'],381,38,leading=56)
text(im,'It could be traders getting stopped out.',488,38)
ice=Image.open(A/'iceberg.png')
panel(im,(64,576,1016,899))
ice=ImageOps.contain(ice,(550,321),method=Image.Resampling.LANCZOS)
paste_round(im,ice,(65,577,65+ice.width,577+ice.height),22)
pill(im,'100 contracts visible',594,30,WHITE,'#080808',x=578)
pill(im,'900 hidden below',769,34,GREEN,'#080808',x=591)
text(im,'Illustrative order size',856,23,color=MUTED,x=698)
lines(im,['Scott watches iceberg orders to spot hidden size','and stop runs to separate forced exits','from genuine buying or selling.'],948,38,leading=56)
pill(im,'SAME CANDLE. DIFFERENT STORY.',1144,38,WHITE,'#080808')
save(im,'02_Icebergs_Stop_Runs.png')

im=bg();header(im,'OPTIONS FLOW','+ GAMMA')
text(im,'Scott trades futures. He watches options daily.',380,38)
lines(im,['Options dealers hedge in the underlying market.','That activity can help drive the futures market.'],448,38,leading=56)
box=(60,696,1020,1236)
vals=[30,34,31,37,39,35,43,46,42,51,54,50,60,64,60,69,74,70,79,84,79,89,91]
left,right,py,step=chart(im,box,vals,level=92)
text(im,'GAMMA LEVEL',722,30,'SemiBold',GREEN,x=89)
text(im,'Magnet • Target • S/R',768,29,x=90)
d=ImageDraw.Draw(im);arrow(d,[(590,1120),(710,1030),(865,py(92)+5)])
pill(im,'Order flow aligns here',1118,29,WHITE,'#090909',x=545)
text(im,'Concept illustration',1197,23,color=MUTED,x=90)
lines(im,['When gamma + order flow align at the same level,','Scott says that confluence gives him an edge.'],565,38,leading=56)
candle_pair(im)
save(im,'03_Options_Flow_Gamma.png')

im=bg();logo(im)
text(im,'ALGOS',135,82,'SemiBold')
pill(im,'Trade the rotation',218,51)
lines(im,['In a range, when price moves too far, too fast,','algorithms can snap it back.'],310,38,leading=56)
lines(im,['Scott uses the 5-minute Price Change Algo','to alert him when price becomes extended.'],417,38,leading=56)
text(im,'He trades around an existing position:',529,38)
action_card(im,60,['Price extends:','takes size off'])
action_card(im,550,['Price rotates back:','adds size back'])
vals=[50,56,63,72,80,75,67,59,51,45,39,45,54,65,75,82,76,65,53,44,37,44,51,62,72,80]
left,right,py,step=chart(im,(60,696,1020,1236),vals)
text(im,'LONG POSITION EXAMPLE',722,27,'SemiBold',MUTED,x=89)
pill(im,'SELL SOME',808,27,RED,WHITE,x=150)
pill(im,'ADD BACK',1070,27,GREEN,'#090909',x=533)
arrow(ImageDraw.Draw(im),[(281,850),(left+5*step,py(80))],RED)
arrow(ImageDraw.Draw(im),[(604,1070),(left+20*step,py(37))])
text(im,'Concept illustration',1197,23,color=MUTED,x=90)
save(im,'04_Algos.png')

im=bg();header(im,'PROGRAM BUYING','+ SELLING')
lines(im,['Scott looks for institutions trading huge','baskets of stocks — and strong directional moves.'],380,38,leading=56)
text(im,'Two major clues:',496,38,'SemiBold')
pill(im,'TICK at sustained extremes',559,39,WHITE,'#090909')
text(im,'+',637,47,'SemiBold',GREEN)
pill(im,'200%+ relative volume',705,42)
vals=[94,95,93,96,91,89,86,77,71,66,67,55,46,39,41,28,19,13,15,6,-2,-8]
left,right,py,step=chart(im,(64,783,1016,1070),vals)
pill(im,'TICK -1000',802,26,RED,WHITE,x=86)
pill(im,'RELATIVE VOLUME 200%',802,26,WHITE,'#090909',x=410)
text(im,'Concept illustration',1032,23,color=MUTED,x=90)
text(im,'When both appear, Scott says:',1090,38)
pill(im,'DON’T FADE THE MOVE.',1140,40,RED,WHITE)
text(im,'It can keep going further than “too far.”',1220,38)
save(im,'05_Program_Buying_Selling.png')

im=bg();logo(im)
lines(im,['HOW DOES SCOTT','ACTUALLY SEE ALL THIS?'],150,64,'SemiBold',leading=84)
pill(im,'Bookmap + order flow',338,50)
text(im,'Bookmap lets Scott look inside the candle.',446,38)
src=Image.open(A/'bookmap_original.jpg');crop=src.crop((164,318,865,779))
paste_round(im,crop,(64,533,1016,1040));d=ImageDraw.Draw(im)
pill(im,'RESTING LIQUIDITY',547,25,WHITE,'#090909',x=85)
arrow(d,[(350,582),(500,667)],WHITE)
pill(im,'MARKET ORDERS',846,25,WHITE,'#090909',x=80)
arrow(d,[(286,839),(191,742)],WHITE)
pill(im,'ICEBERG EVENT',687,25,GREEN,'#090909',x=660)
arrow(d,[(659,724),(129,708)])
text(im,'Actual screenshot from Scott’s episode',1055,25,color=MUTED)
text(im,'With add-ons: stop runs + iceberg orders.',1097,38)
lines(im,['Scott builds rules around what price does next','to decide whether to look for longs or shorts.'],1153,38,leading=56)
candle_pair(im)
save(im,'06_Inside_The_Candle.png')

im=bg();logo(im)
lines(im,['SEE SCOTT BREAK DOWN'],151,64,'SemiBold')
pill(im,'THE FULL STRATEGY',243,64)
lines(im,['Entries, exits, Bookmap, order flow','and real chart examples.'],376,38,leading=56)
photo=Image.open(A/'scott_original.jpg')
paste_round(im,photo,(64,517,1016,1026))
pill(im,'Scott Pulcini',956,31,WHITE,'#090909')
text(im,'Comment',1053,55,'SemiBold')
pill(im,'“SCOTT”',1125,60,RED,WHITE)
text(im,'and we’ll DM you the full episode.',1235,38)
candle_pair(im)
im.save(OUT/'07_Full_Strategy_CTA.png');records.append({'file':'07_Full_Strategy_CTA.png','dimensions':[W,H],'copy':[b['text'] for b in bounds[last_text:]]})

sheet=Image.new('RGB',(4*360,2*482),'#161616')
for i,r in enumerate(records):
    src=Image.open(OUT/r['file']);src.load();assert src.size==(W,H)
    p=src.resize((350,438),Image.Resampling.LANCZOS)
    x=(i%4)*360+5;y=(i//4)*482+5;sheet.paste(p,(x,y))
    ImageDraw.Draw(sheet).text((x+6,y+444),r['file'][:2]+' / '+r['file'][3:-4],font=font(15),fill=WHITE)
    src.resize((360,450),Image.Resampling.LANCZOS).save(ROOT/'QA'/r['file'])
sheet.save(ROOT/'Apercu_7_Slides.jpg',quality=94)
with zipfile.ZipFile(ROOT/'Scott_Carousel_V03_7_Slides.zip','w',zipfile.ZIP_DEFLATED) as z:
    for r in records:z.write(OUT/r['file'],r['file'])
with zipfile.ZipFile(ROOT/'Scott_Carousel_V03_7_Slides.zip') as z:
    assert len(z.namelist())==7 and z.testzip() is None
    for n in z.namelist():
        with z.open(n) as f,Image.open(f) as im:im.load();assert im.size==(W,H)
(ROOT/'QA'/'verification.json').write_text(json.dumps({'files':records,'count':7,'zip_integrity':'verified','text_bounds':bounds},indent=2),encoding='utf-8')
(ROOT/'source'/'Copy_final.txt').write_text('\n\n'.join(r['file']+'\n'+'\n'.join(r['copy']) for r in records),encoding='utf-8')
print('Verified: 7 PNG files at 1080 x 1350; ordered ZIP passed integrity check.')
