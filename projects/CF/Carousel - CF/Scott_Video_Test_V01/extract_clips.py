from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parent
cfg=json.loads((R/'private_streams.json').read_text())
for name,start,dur in [('03_Gamma',5258.14,50),('04_Algos',5491.12,23.04)]:
    cmd=['ffmpeg','-hide_banner','-loglevel','error','-y','-ss',str(start),'-i',cfg['video'],'-ss',str(start),'-i',cfg['audio'],'-t',str(dur),'-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','fast','-crf','18','-c:a','aac','-b:a','192k','-movflags','+faststart',str(R/(name+'_source.mp4'))]
    p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if p.returncode: print(name,'Extraction failed; code',p.returncode);raise SystemExit(1)
    print(name,'extracted',dur,flush=True)
