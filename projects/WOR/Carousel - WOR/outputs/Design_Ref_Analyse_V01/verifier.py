from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote
import json,hashlib,re
root=Path.cwd(); dest=root/'outputs/Design_Ref_Analyse_V01'; refs=json.loads((dest/'fiches_references.json').read_text(encoding='utf-8')); page=(dest/'Atlas_Design_WOR.html').read_text(encoding='utf-8')
class Links(HTMLParser):
 def __init__(self): super().__init__(); self.links=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ('src','href') and v and not v.startswith('#'): self.links.append(v)
p=Links(); p.feed(page); missing=[x for x in p.links if not (dest/unquote(x)).resolve().exists()]
assert not missing,missing
assert len(refs)==62 and len({r['file'] for r in refs})==62
for r in refs:
 assert hashlib.sha256((root/'Design REF'/r['file']).read_bytes()).hexdigest()==r['sha256']
 assert r['observation'] and r['role'] and r['guest_visible']
assert page.count('<article ')==62
scripts=re.findall(r'<script>(.*?)</script>',page,re.S); (dest/'atlas_verification.js').write_text('\n'.join(scripts),encoding='utf-8')
report={'reference_count':62,'fiches_count':62,'local_links_checked':len(p.links),'missing_links':missing,'original_hashes_unchanged':True,'dimensions':{'1080x1350':sum(r['height']==1350 for r in refs),'1080x1440':sum(r['height']==1440 for r in refs)},'browser_visual_preview':'not_verified_browser_timed_out','guide_words':len((dest/'Connaissance_Design_WOR.txt').read_text(encoding='utf-8').split())}
(dest/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8'); print(json.dumps(report))
