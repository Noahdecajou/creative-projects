from pathlib import Path
R=Path(__file__).resolve().parents[1];p=R/'source/build_carousel.py';s=p.read_text(encoding='utf-8')
start=s.index('def candles(');end=s.index('def panel(',start)
s=s[:start]+'''def single_candle(im,name,x,y,width):
    src=Image.open(A/name).convert('RGBA');src=src.crop(src.getbbox())
    src=src.resize((width,round(width*src.height/src.width)),Image.Resampling.LANCZOS)
    im.paste(src,(x,y),src)
def candle_pair(im):
    single_candle(im,'candle_red.png',-40,160,95)
    single_candle(im,'candle_green.png',1020,990,110)
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
''' +s[end:]
s=s.replace('candles(im,944,10,145)','candle_pair(im)').replace('candles(im,5,788,145)','candle_pair(im)')
a=s.index("im=bg();header(im,'ALGOS')");b=s.index("\nim=bg();header(im,'PROGRAM BUYING'",a)
s=s[:a]+'''im=bg();logo(im)
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
''' +s[b:]
p.write_text(s.replace('Scott_Carousel_V02','Scott_Carousel_V03'),encoding='utf-8')
v=R.parent/'Scott_Video_Test_V03'
p=v/'build_video_tests.py';s=p.read_text().replace('Scott_Carousel_V02','Scott_Carousel_V03').replace('Video_Test_V02','Video_Test_V03').replace('(60,830,1020,1234)','(60,696,1020,1236)');p.write_text(s)
p=v/'check_audio_copy.py';s=p.read_text().replace('Scott_Carousel_V02','Scott_Carousel_V03').replace('(60,830,1021,1235)','(60,696,1021,1237)');p.write_text(s)
p=R/'source/package_v03.py';s=p.read_text().replace('V02','V03').replace('package_v02','package_v03');p.write_text(s)
print('V03 layout ready; waiting for reference-led candle assets.')
