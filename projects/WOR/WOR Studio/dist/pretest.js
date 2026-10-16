'use strict';
const WORPretest=(()=>{
 const count=l=>l.topCount===5?5:3;
 const current=()=>{const r=WORLab.currentReport(),l=WORLab.getLab();return r&&r.change===l.change&&JSON.stringify(r.audience)===JSON.stringify(WORLab.audience())?r:null};
 function tabs(active){return `<div class="pretest-tabs" aria-label="Type de prétest"><button class="${active==='ab'?'active':''}" id="pretest-images">Miniatures</button><button class="${active==='titles'?'active':''}" id="pretest-titles">Titres</button><button class="${active==='youtube'?'active':''}" id="pretest-youtube">Dans YouTube</button><span>Présélection IA · choix final libre</span></div>`}
 function wireTabs(){on('pretest-images',()=>navigate('ab'));on('pretest-titles',()=>navigate('titles'));on('pretest-youtube',()=>WORFeed.open());WORReport.wire()}
 function strip(c){const rows=current()?.job.result.ranking,row=rows?.find(r=>r.id===c.id);return `<div class="single-score"><span>${row?'Note de présélection':'Prêt pour le prétest'}</span><strong>${row?row.score+'<small>/100</small>':'—'}</strong>${row?`<span class="badge">Rang ${rows.findIndex(r=>r.score===row.score)+1}</span>`:''}</div>`}
 function panel(){const l=WORLab.getLab(),n=l.candidates.length;return `<section class="pretest-action panel"><div><span class="meta-caps">02 · PRÉSÉLECTIONNER</span><h2>Fais émerger les meilleures idées.</h2><p>Un classement argumenté de tes miniatures. Tu peux ensuite ajuster la sélection librement.</p><p class="muted">Analyse via ton compte Codex : les images, titres et contexte sont envoyés à OpenAI. Une aide au choix, pas un résultat de spectateurs.</p></div><div class="pretest-controls"><label class="field">Ma présélection<select id="pretest-count"><option value="3" ${count(l)===3?'selected':''}>Top 3</option><option value="5" ${count(l)===5?'selected':''}>Top 5</option></select></label><button class="button primary" id="lab-analyze" ${l.pending||n<2?'disabled':''}>${l.pending?'Analyse en cours…':current()?'Revoir le classement':'Lancer le prétest →'}</button></div></section>`}
 function refresh(){if(view!=='ab')return;$$('[data-score]').forEach(el=>{const c=WORLab.getLab().candidates.find(c=>c.id===el.dataset.score);if(c)el.innerHTML=strip(c)});const host=$('#pretest-report');if(host&&!current())host.innerHTML='<div class="lab-empty-report"><h3>Le classement est à actualiser.</h3><p>Les propositions ont changé. Relance le prétest pour les comparer.</p></div>';const b=$('#lab-analyze');if(b&&!WORLab.getLab().pending)b.textContent='Lancer le prétest →'}
 function wire(){wireTabs();const select=$('#pretest-count');if(select)select.onchange=async e=>{WORLab.getLab().topCount=Number(e.target.value);await persist();render()};on('lab-show-all',async()=>{const l=WORLab.getLab();l.showAll=!l.showAll;await persist();render()})}
 return {count,current,tabs,wireTabs,strip,panel,refresh,wire};
})();

const WORReport=(()=>{
 let busy=false;
 function button(){return `<button class="button" data-director-report aria-label="Exporter le rapport PDF en anglais">${busy?'Rapport en préparation…':'↓ Rapport PDF · EN'}</button>`}
 function wire(){$$('[data-director-report]').forEach(b=>b.onclick=open)}
 function message(value){const box=$('#director-status');if(box)box.textContent=value}
 async function api(path,body){const response=await fetch(path,body===undefined?{}:{method:'POST',headers:{'Content-Type':'application/json','X-WOR-Token':token},body:JSON.stringify(body)});if(!response.ok){const error=await response.json();throw Error(error.error||'Le rapport n’a pas pu être créé.')}return response}
 function open(){
  if(busy)return toast('Le rapport est en préparation. Tu peux continuer à parcourir le studio.');
  const current=WORPretest.current(),l=WORLab.getLab();
  if(!server)return toast('Ouvre le studio avec son lanceur local pour exporter le PDF.');
  if(!current||l.pending){form('<div class="dialog-top"><h2>Un rapport à jour</h2><button class="icon-button" id="close-form" aria-label="Fermer">×</button></div><p>Termine ou relance le prétest des miniatures avant l’export. Le PDF doit reprendre les notes correspondant aux images et au contexte actuels.</p><button class="button primary full" id="director-back">Ouvrir le prétest</button>');on('director-back',()=>{$('#form-dialog').close();navigate('ab')});return}
  const rows=current.job.result.ranking,chosen=l.selection.length?l.selection:rows.slice(0,WORPretest.count(l)).map(r=>r.id);
  form(`<div class="dialog-top"><h2>Le rapport pour ta direction.</h2><button class="icon-button" id="close-form" aria-label="Fermer">×</button></div><p>Un PDF en anglais avec la synthèse, le classement complet, les notes et explications de ta sélection, puis une mise en situation YouTube par miniature.</p><div class="report-choices">${rows.map(r=>{const c=l.candidates.find(c=>c.id===r.id);return `<label class="candidate-choice"><input type="checkbox" name="director-choice" value="${esc(r.id)}" ${chosen.includes(r.id)?'checked':''}><img src="${esc(c.image)}" alt="Variante ${esc(c.variantLabel)}"><span><strong>Variante ${esc(c.variantLabel)} · ${r.score}/100</strong><small>${esc(WORLab.title(c))}</small></span></label>`}).join('')}</div><p class="muted" id="director-count">${chosen.length}/5 miniatures retenues pour le rapport.</p><p class="muted">Les explications sont traduites via ton compte Codex, sans renoter les images. Le PDF est assemblé localement. La grille exportée est au format ordinateur, avec la position et les voisins actuels.</p><button class="button primary full" id="director-generate">Créer le PDF en anglais →</button><p class="report-status" id="director-status" role="status" aria-live="polite"></p>`);
  $$('input[name=director-choice]').forEach(box=>box.onchange=()=>{const checked=$$('input[name=director-choice]:checked');if(checked.length>5){box.checked=false;return toast('Cinq miniatures maximum dans un rapport.')}$('#director-count').textContent=`${checked.length}/5 miniatures retenues pour le rapport.`;$('#director-generate').disabled=!checked.length});
  on('director-generate',generate);
 }
 async function generate(){
  if(busy)return;const selectedIds=$$('input[name=director-choice]:checked').map(x=>x.value);if(!selectedIds.length)return;
  const episode=ep(),l=WORLab.getLab(),report=WORPretest.current();if(!report)return toast('Le prétest doit être actualisé.');const f=WORFeed.settings(),request={episodeId:episode.id,reportId:report.job.id,change:l.change,selectedIds,feed:{position:f.position,order:[...f.order]}};
  busy=true;$('#director-generate').disabled=true;$$('input[name=director-choice]').forEach(b=>b.disabled=true);$$('[data-director-report]').forEach(b=>b.textContent='Rapport en préparation…');
  try{
   message('1/3 · Vérification du rapport et des images…');await persist();const prepared=await(await api('/api/report/source',request)).json(),key=JSON.stringify(prepared.strings);let job;
   if(l.englishReport?.key===key){try{job=await(await api('/api/lab/job?id='+encodeURIComponent(l.englishReport.jobId))).json();if(!['running','complete'].includes(job.status))job=null}catch{}}
   if(!job){job=await(await api('/api/lab/report-english',{strings:prepared.strings})).json();l.englishReport={key,jobId:job.id};await persist()}
   message('2/3 · Traduction des explications en anglais via Codex…');
   while(job.status==='running'){await new Promise(r=>setTimeout(r,1800));job=await(await api('/api/lab/job?id='+encodeURIComponent(job.id))).json()}
   if(job.status!=='complete')throw Error(job.error||'Traduction interrompue. Tu peux réessayer.');
   message('3/3 · Mise en page du PDF et des aperçus YouTube…');const response=await api('/api/report/pdf',{...request,translationJobId:job.id}),blob=await response.blob();if(blob.type!=='application/pdf')throw Error('Le serveur n’a pas renvoyé un PDF.');
   download(blob,`${projectFor(episode).code}_${safe(episode.name)}_Pretest_Report_EN.pdf`);message('Le PDF en anglais est prêt et son téléchargement a été lancé.');toast('Rapport PDF en anglais créé.');
  }catch(e){message(e.message);toast(e.message)}finally{busy=false;$$('input[name=director-choice]').forEach(b=>b.disabled=false);const b=$('#director-generate');if(b){b.disabled=false;b.textContent='Télécharger le PDF en anglais →'}$$('[data-director-report]').forEach(b=>b.textContent='↓ Rapport PDF · EN')}
 }
 return {button,wire,open};
})();
