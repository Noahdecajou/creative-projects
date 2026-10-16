from PIL import Image
from pathlib import Path
from collections import Counter
import numpy as np,json
root=Path.cwd(); dest=root/'outputs/Design_Ref_Analyse_V01'; records=json.loads((dest/'inventaire.json').read_text())
def components(mask):
 runs=[]; parent=[]; prev=[]
 def find(a):
  while parent[a]!=a: parent[a]=parent[parent[a]]; a=parent[a]
  return a
 for y,row in enumerate(mask):
  z=np.r_[False,row,False].astype(np.int8); starts=np.flatnonzero(np.diff(z)==1); ends=np.flatnonzero(np.diff(z)==-1)-1; curr=[]; pi=0
  for x0,x1 in zip(starts,ends):
   idx=len(runs); runs.append((int(x0),int(x1),y)); parent.append(idx); curr.append(idx)
   while pi<len(prev) and runs[prev[pi]][1]<x0-1: pi+=1
   j=pi
   while j<len(prev) and runs[prev[j]][0]<=x1+1:
    a=find(idx); b=find(prev[j]); parent[a]=b; j+=1
  prev=curr
 result={}
 for idx,(x0,x1,y) in enumerate(runs):
  k=find(idx)
  if k not in result: result[k]=[x0,y,x1,y,x1-x0+1]
  else:
   b=result[k]; b[0]=min(b[0],x0); b[2]=max(b[2],x1); b[3]=y; b[4]+=x1-x0+1
 return [{'bbox_xyxy_inclusive':b[:4],'pixels':b[4]} for b in result.values() if b[4]>=800 and b[2]-b[0]>=35 and b[3]-b[1]>=15]
def rows(mask,x0,x1,y0,y1,threshold):
 counts=mask[y0:y1,x0:x1].sum(axis=1); active=counts>=threshold; z=np.r_[False,active,False].astype(np.int8); starts=np.flatnonzero(np.diff(z)==1); ends=np.flatnonzero(np.diff(z)==-1)-1
 return [[int(a+y0),int(b+y0)] for a,b in zip(starts,ends) if b-a>=4]
for r in records:
 im=np.asarray(Image.open(root/'Design REF'/r['file']).convert('RGB')); a=im.astype(np.int16); R,G,B=a[:,:,0],a[:,:,1],a[:,:,2]
 masks={'rouge_sature':(R>180)&(G<85)&(B<85)&(R-G>115),'vert_vif':(G>150)&(R<115)&(B<115)&(G-R>70),'blanc_neutre':(a.min(2)>232)&((a.max(2)-a.min(2))<20),'sombre':a.max(2)<35}
 palette={}
 for name,m in masks.items():
  colors,counts=np.unique(im[m],axis=0,return_counts=True); ix=np.argsort(counts)[-5:][::-1]; palette[name]={'pixel_count':int(m.sum()),'percent':round(float(m.mean()*100),3),'top_rgb':[{'hex':'#'+''.join(f'{v:02X}' for v in colors[j]),'pixels':int(counts[j])} for j in ix]}
 r['palette_mesuree']=palette; r['composants_rouges']=components(masks['rouge_sature']); r['composants_verts']=components(masks['vert_vif']); r['bandes_blanches_haut_candidates']=rows(masks['blanc_neutre'],30,1050,0,340,35); r['bandes_blanches_footer_candidates']=rows(masks['blanc_neutre'],30,800,r['height']-125,r['height'],20)
(dest/'mesures_pixels.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print(Counter(r['height'] for r in records))
for name in ['Slide-1 (6).jpg','Slide-3.jpg','Slide-2 (10).jpg','Slide-5 (2).jpg']:
 r=next(r for r in records if r['file']==name); print(name,json.dumps({k:r[k] for k in ['composants_rouges','composants_verts','bandes_blanches_haut_candidates','bandes_blanches_footer_candidates','palette_mesuree']}))
