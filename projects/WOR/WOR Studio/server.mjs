import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomBytes} from 'node:crypto';
import {createLab,directorReportSource,renderDirectorPdf,validateStudioState,saveInspirations} from './lab.mjs';
const root=path.dirname(fileURLToPath(import.meta.url)),dist=path.join(root,'dist'),dataDir=path.join(root,'data');
const port=Number(process.env.WOR_PORT||8765),host='127.0.0.1',token=randomBytes(24).toString('hex');
const origin=`http://${host}:${port}`;
await fs.mkdir(dataDir,{recursive:true});
let revision=0,saved=null,writing=false,pdfBusy=false;
try{const raw=JSON.parse(await fs.readFile(path.join(dataDir,'session.json'),'utf8'));saved=raw.state;revision=raw.revision||0}catch(e){if(e.code!=='ENOENT'){console.error('Session illisible. Le fichier existant a été préservé.');process.exit(1)}}
function reply(res,status,body,type='application/json; charset=utf-8'){res.writeHead(status,{'Content-Type':type,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer'});res.end(typeof body==='string'?body:JSON.stringify(body))}
function feedback(state){const lines=['WOR STUDIO — RETOURS À REPRENDRE','Enregistré le '+new Date().toISOString(),'Aucun traitement IA automatique. Lire la session et les sources avant toute retouche.','Règles : portraits originaux, titres exacts, versions conservées, grain final 3 %, Spotify sans micros.'];for(const e of state.episodes){lines.push('\nPROJET : '+(e.projectId||'wor').toUpperCase(),'ÉPISODE : '+e.name,'Sujet : '+(e.subject||''),...(e.frameLinks||[{role:'host',url:e.frameio||''}]).filter(l=>l.url).map(l=>'Frame.io '+l.role+' : '+l.url),'Inspirations : '+(e.inspirations||[]).map(f=>f.name+(f.note?' — '+f.note:'')).join('; '),'Fichiers locaux : data/inspirations/manifest.json');for(const a of e.assets)for(const [i,v] of a.versions.entries())for(const c of v.comments){lines.push(`\n[${c.resolved?'TRAITÉ':'À TRAITER'}] ${a.kind} / ${a.name} / V${i+1}`,`Version ID : ${v.id}`,`${c.category} — ${c.x==null?'général':`repère ${c.number}, x=${(c.x*100).toFixed(1)} %, y=${(c.y*100).toFixed(1)} %`}`,c.text)}}return lines.join('\n')}
const lab=createLab({origin,token,reply,dataDir});
const allowed=new Set(['index.html','style.css','app.js','seed.js','extras.css','lab.js','lab.css','titles.js','pretest.js','studio.css','feed.js','feed.css','feed-catalog.js','feed-assets/6lyl7flPOOU.jpg','feed-assets/ANbO-i3-GxY.jpg','feed-assets/UWDFkMaJXNw.jpg','feed-assets/i5dUXg_t1nw.jpg','feed-assets/bIi6YzPt9bE.jpg','feed-assets/Mqi_g9UpbDk.jpg','feed-assets/zfW1-0dQEGo.jpg','feed-assets/FJIx4aNF49o.jpg','feed-assets/HloJo5zyq7k.jpg','feed-assets/yUvzHeoJO3I.jpg','feed-assets/CvRwUoDZiog.jpg','feed-assets/MsuB2-J8t-E.jpg','feed-assets/Di8Xq8n234w.jpg','feed-assets/jntQftWtdKI.jpg','feed-assets/XF1usbFkA2w.jpg','history-candace-2026-10-10.png']);
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.jpg':'image/jpeg'};
const srv=http.createServer(async(req,res)=>{try{
 if(req.headers.host!==`${host}:${port}`&&req.headers.host!==`localhost:${port}`)return reply(res,403,{error:'Host denied'});
 const url=new URL(req.url,origin);
 if(req.method==='GET'&&url.pathname==='/api/health')return reply(res,200,{app:'WOR Studio',version:9});
 if(await lab(req,res,url))return;
 if(url.pathname.startsWith('/api/report/')){
  if(req.method!=='POST'||![origin,`http://localhost:${port}`].includes(req.headers.origin)||req.headers['x-wor-token']!==token)return reply(res,403,{error:'Demande locale non autorisée.'});
  if(!['/api/report/source','/api/report/pdf'].includes(url.pathname))return reply(res,404,{error:'Action inconnue.'});
  try{
   let size=0,chunks=[];for await(const chunk of req){size+=chunk.length;if(size>65536)return reply(res,413,{error:'Demande trop volumineuse.'});chunks.push(chunk)}
   const request=JSON.parse(Buffer.concat(chunks).toString()),rawCatalog=await fs.readFile(path.join(dist,'feed-catalog.js'),'utf8'),catalog=JSON.parse(rawCatalog.slice(rawCatalog.indexOf('=')+1).trim().replace(/;$/,''));
   const source=directorReportSource(saved,request,catalog);
   if(url.pathname==='/api/report/source')return reply(res,200,{strings:source.strings,selectedCount:source.selected.length,total:source.rows.length});
   if(pdfBusy)return reply(res,409,{error:'Un PDF est déjà en préparation.'});
   if(!/^[\da-f-]{36}$/.test(request.translationJobId||''))throw Error('Traduction manquante. Rouvre l’export.');
   const translation=JSON.parse(await fs.readFile(path.join(dataDir,'analyses',request.translationJobId,'job.json'),'utf8'));
   if(translation.status!=='complete'||translation.input?.mode!=='report-english'||JSON.stringify(translation.input.strings)!==JSON.stringify(source.strings))throw Error('La traduction ne correspond pas à cette sélection. Relance l’export.');
   pdfBusy=true;try{const bytes=await renderDirectorPdf(source,translation.result,dist);const name=source.project.code+'_'+source.episode.normalize('NFKD').replace(/[^a-zA-Z0-9]+/g,'_').slice(0,70)+'_Pretest_Report_EN.pdf';res.writeHead(200,{'Content-Type':'application/pdf','Content-Disposition':`attachment; filename="${name}"`,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(bytes)}finally{pdfBusy=false}return;
  }catch(e){return reply(res,400,{error:e.code==='ERR_MODULE_NOT_FOUND'?'La bibliothèque PDF manque. Lance npm install dans le dossier du studio.':e.code==='ENOENT'?'Une référence locale ou la traduction manque. Restaure les références YouTube puis relance l’export.':e.message})}
 }
 if(req.method==='GET'&&url.pathname==='/api/state')return reply(res,200,{state:saved,revision,token});
 if(req.method==='POST'&&url.pathname==='/api/state'){
  if(![origin,`http://localhost:${port}`].includes(req.headers.origin)||req.headers['x-wor-token']!==token)return reply(res,403,{error:'Origin or session invalid'});
  if(writing)return reply(res,409,{error:'Save in progress'});
  let chunks=[],size=0;for await(const chunk of req){size+=chunk.length;if(size>100*1024*1024)return reply(res,413,{error:'Session too large'});chunks.push(chunk)}
  let payload;try{payload=JSON.parse(Buffer.concat(chunks).toString())}catch{return reply(res,400,{error:'Invalid JSON'})}
  if(payload.revision!==revision)return reply(res,409,{error:'Session changed in another tab'});
  try{validateStudioState(payload.state)}catch(e){return reply(res,400,{error:e.message})}
  writing=true;try{const next=revision+1;const feedbackText=feedback(payload.state);await saveInspirations(payload.state,dataDir);await fs.writeFile(path.join(dataDir,'session.tmp'),JSON.stringify({revision:next,state:payload.state}));await fs.rename(path.join(dataDir,'session.tmp'),path.join(dataDir,'session.json'));saved=payload.state;revision=next;await fs.writeFile(path.join(dataDir,'retours-a-traiter.txt'),feedbackText,'utf8');reply(res,200,{revision})}finally{writing=false}return;
 }
 if(req.method!=='GET'&&req.method!=='HEAD')return reply(res,405,{error:'Method not allowed'});
 const file=url.pathname==='/'?'index.html':url.pathname.slice(1);if(!allowed.has(file))return reply(res,404,{error:'Not found'});
 const content=await fs.readFile(path.join(dist,file));res.writeHead(200,{'Content-Type':types[path.extname(file)],'Cache-Control':'no-cache','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"});res.end(req.method==='HEAD'?undefined:content);
}catch(e){console.error(e.message);if(!res.headersSent)reply(res,500,{error:'Local operation failed'});else res.end()}});
srv.on('error',e=>{console.error(e.code==='EADDRINUSE'?`Le port ${port} est déjà utilisé.`:e.message);process.exit(1)});
srv.listen(port,host,()=>console.log(`WOR Studio: ${origin}`));
