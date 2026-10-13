import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomBytes} from 'node:crypto';
import {createLab} from './lab.mjs';
const root=path.dirname(fileURLToPath(import.meta.url)),dist=path.join(root,'dist'),dataDir=path.join(root,'data');
const port=Number(process.env.WOR_PORT||8765),host='127.0.0.1',token=randomBytes(24).toString('hex');
const origin=`http://${host}:${port}`;
await fs.mkdir(dataDir,{recursive:true});
let revision=0,saved=null,writing=false;
try{const raw=JSON.parse(await fs.readFile(path.join(dataDir,'session.json'),'utf8'));saved=raw.state;revision=raw.revision||0}catch(e){if(e.code!=='ENOENT'){console.error('Session illisible. Le fichier existant a été préservé.');process.exit(1)}}
function reply(res,status,body,type='application/json; charset=utf-8'){res.writeHead(status,{'Content-Type':type,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer'});res.end(typeof body==='string'?body:JSON.stringify(body))}
function feedback(state){const lines=['WOR STUDIO — RETOURS À REPRENDRE','Enregistré le '+new Date().toISOString(),'Aucun traitement IA automatique. Lire la session et les sources avant toute retouche.','Règles : portraits originaux, titres exacts, versions conservées, grain final 3 %, Spotify sans micros.'];for(const e of state.episodes){lines.push('\nÉPISODE : '+e.name,'Sujet : '+(e.subject||''),'Frame.io : '+(e.frameio||''));for(const a of e.assets)for(const [i,v] of a.versions.entries())for(const c of v.comments){lines.push(`\n[${c.resolved?'TRAITÉ':'À TRAITER'}] ${a.kind} / ${a.name} / V${i+1}`,`Version ID : ${v.id}`,`${c.category} — ${c.x==null?'général':`repère ${c.number}, x=${(c.x*100).toFixed(1)} %, y=${(c.y*100).toFixed(1)} %`}`,c.text)}}return lines.join('\n')}
const lab=createLab({origin,token,reply,dataDir});
const allowed=new Set(['index.html','style.css','app.js','seed.js','extras.css','lab.js','lab.css','titles.js','pretest.js','studio.css','feed.js','feed.css','feed-catalog.js','feed-assets/6lyl7flPOOU.jpg','feed-assets/ANbO-i3-GxY.jpg','feed-assets/UWDFkMaJXNw.jpg','feed-assets/i5dUXg_t1nw.jpg','feed-assets/bIi6YzPt9bE.jpg','feed-assets/Mqi_g9UpbDk.jpg','feed-assets/zfW1-0dQEGo.jpg','feed-assets/FJIx4aNF49o.jpg','feed-assets/HloJo5zyq7k.jpg','feed-assets/yUvzHeoJO3I.jpg','feed-assets/CvRwUoDZiog.jpg','feed-assets/MsuB2-J8t-E.jpg','feed-assets/Di8Xq8n234w.jpg','feed-assets/jntQftWtdKI.jpg','feed-assets/XF1usbFkA2w.jpg','history-candace-2026-10-10.png']);
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.jpg':'image/jpeg'};
const srv=http.createServer(async(req,res)=>{try{
 if(req.headers.host!==`${host}:${port}`&&req.headers.host!==`localhost:${port}`)return reply(res,403,{error:'Host denied'});
 const url=new URL(req.url,origin);
 if(req.method==='GET'&&url.pathname==='/api/health')return reply(res,200,{app:'WOR Studio',version:7});
 if(await lab(req,res,url))return;
 if(req.method==='GET'&&url.pathname==='/api/state')return reply(res,200,{state:saved,revision,token});
 if(req.method==='POST'&&url.pathname==='/api/state'){
  if(![origin,`http://localhost:${port}`].includes(req.headers.origin)||req.headers['x-wor-token']!==token)return reply(res,403,{error:'Origin or session invalid'});
  if(writing)return reply(res,409,{error:'Save in progress'});
  let chunks=[],size=0;for await(const chunk of req){size+=chunk.length;if(size>100*1024*1024)return reply(res,413,{error:'Session too large'});chunks.push(chunk)}
  let payload;try{payload=JSON.parse(Buffer.concat(chunks).toString())}catch{return reply(res,400,{error:'Invalid JSON'})}
  if(payload.revision!==revision)return reply(res,409,{error:'Session changed in another tab'});
  if(payload.state?.schema!==1||!Array.isArray(payload.state.episodes)||!payload.state.episodes.every(e=>typeof e.name==='string'&&Array.isArray(e.assets)&&e.assets.every(a=>Array.isArray(a.versions)&&a.versions.every(v=>Array.isArray(v.comments)))))return reply(res,400,{error:'Invalid state'});
  writing=true;try{const next=revision+1;const feedbackText=feedback(payload.state);await fs.writeFile(path.join(dataDir,'session.tmp'),JSON.stringify({revision:next,state:payload.state}));await fs.rename(path.join(dataDir,'session.tmp'),path.join(dataDir,'session.json'));saved=payload.state;revision=next;await fs.writeFile(path.join(dataDir,'retours-a-traiter.txt'),feedbackText,'utf8');reply(res,200,{revision})}finally{writing=false}return;
 }
 if(req.method!=='GET'&&req.method!=='HEAD')return reply(res,405,{error:'Method not allowed'});
 const file=url.pathname==='/'?'index.html':url.pathname.slice(1);if(!allowed.has(file))return reply(res,404,{error:'Not found'});
 const content=await fs.readFile(path.join(dist,file));res.writeHead(200,{'Content-Type':types[path.extname(file)],'Cache-Control':'no-cache','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"});res.end(req.method==='HEAD'?undefined:content);
}catch(e){console.error(e.message);if(!res.headersSent)reply(res,500,{error:'Local operation failed'});else res.end()}});
srv.on('error',e=>{console.error(e.code==='EADDRINUSE'?`Le port ${port} est déjà utilisé.`:e.message);process.exit(1)});
srv.listen(port,host,()=>console.log(`WOR Studio: ${origin}`));
