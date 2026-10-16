from PIL import Image,ImageOps,ImageDraw
from pathlib import Path
import re,json,hashlib
root=Path.cwd(); dest=root/'outputs/Design_Ref_Analyse_V01'; files=list((root/'Design REF').glob('*.jpg'))
groups={}
records=[]
for p in files:
 m=re.fullmatch(r'Slide-(\d+)(?: \((\d+)\))?\.jpg',p.name); n=int(m[1]); g=int(m[2] or 0)
 im=Image.open(p); groups.setdefault(g,[]).append((n,p)); records.append({'file':p.name,'group':g,'slide':n,'width':im.width,'height':im.height,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for g,items in sorted(groups.items()):
 items.sort(); cols=4; rows=(len(items)+cols-1)//cols; sheet=Image.new('RGB',(cols*360,rows*490),(35,35,35)); d=ImageDraw.Draw(sheet)
 for k,(n,p) in enumerate(items):
  im=Image.open(p); im.thumbnail((350,450)); x=(k%cols)*360; y=(k//cols)*490; sheet.paste(im,(x,y+25)); d.text((x+8,y+7),p.name,fill='white')
 sheet.save(dest/f'serie_{g:02d}.jpg',quality=92)
(dest/'inventaire.json').write_text(json.dumps(sorted(records,key=lambda r:(r['group'],r['slide'])),indent=2),encoding='utf-8')
print(len(records), 'references',len(groups),'groups'); print(sorted(set((r['width'],r['height']) for r in records)))
