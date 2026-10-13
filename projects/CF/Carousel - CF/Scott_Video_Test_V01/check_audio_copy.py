import subprocess,json
from pathlib import Path
from PIL import Image
import numpy as np
R=Path(__file__).resolve().parent
checks=[('03_Gamma','03_Options_Flow_Gamma.png',(64,579,1017,974)),('04_Algos','04_Algos.png',(64,627,1017,961))]
results=[]
for name,base,box in checks:
    p=subprocess.run(['ffmpeg','-hide_banner','-i',str(R/(name+'_Slide_Video.mp4')),'-af','volumedetect','-vn','-f','null','-'],capture_output=True,text=True)
    levels=[s.strip() for s in p.stderr.splitlines() if 'mean_volume:' in s or 'max_volume:' in s]
    assert len(levels)==2 and all('-inf' not in s for s in levels)
    a=np.array(Image.open(R/(name+'_plate.png')));b=np.array(Image.open(R.parent/'Scott_Carousel_V01/PNG'/base))
    mask=np.ones(a.shape[:2],bool);x,y,right,bottom=box;mask[y:bottom,x:right]=False
    exact=bool(np.array_equal(a[mask],b[mask]));assert exact
    results.append({'slide':name,'editorial_pixels_preserved':exact,'audio_levels':levels})
print(json.dumps(results,indent=2))
(R/'audio_copy_verification.json').write_text(json.dumps(results,indent=2))
