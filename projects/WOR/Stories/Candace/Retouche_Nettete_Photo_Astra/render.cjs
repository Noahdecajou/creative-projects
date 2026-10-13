const fs=require('fs'), path=require('path');
const {chromium}=require('C:/Users/notti/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root=__dirname;
const exportRoot=path.join(root,'Export_Corrige_V2');
const meta=JSON.parse(fs.readFileSync(path.join(root,'crop-metadata.json'),'utf8'));
const files=JSON.parse(fs.readFileSync(path.join(root,'selected-portraits.json'),'utf8'));
const data=p=>'data:image/png;base64,'+fs.readFileSync(p).toString('base64');
const plaques=[[302,1208,338,63],[316,1226,309,60],[315,1259,311,61],[314,1285,312,61],[314,1261,313,63]];
const limits=[1299,1233,1330,1238,1345];
function body(j){
  const orig=data(path.join('C:/Users/notti/Downloads',j.f));
  const pic=data(files[j.i]); const p0=plaques[j.i]; const p=[p0[0]-16,p0[1]-16,p0[2]+32,p0[3]+32];
  const clip=Math.min(j.crop_height,limits[j.i]-j.crop_y);
  const left=j.crop_x===0?0:14, right=j.crop_x+j.crop_width>=938?0:14;
  return `<img class="original" src="${orig}"><div class="portrait-clip" style="left:${j.crop_x}px;top:${j.crop_y}px;width:${j.crop_width}px;height:${clip}px;mask-image:linear-gradient(to bottom,transparent ${j.i===3?18:0}px,black ${j.i===3?50:16}px,black calc(100% - 95px),transparent),linear-gradient(to right,transparent,black ${left}px,black calc(100% - ${right}px),transparent);mask-composite:intersect"><img style="width:${j.crop_width}px;height:${j.crop_height}px" src="${pic}"></div><div class="protected-text" style="left:${p[0]}px;top:${p[1]}px;width:${p[2]}px;height:${p[3]}px;mask-image:linear-gradient(to right,transparent,black 14px,black calc(100% - 14px),transparent),linear-gradient(to bottom,transparent,black 14px,black calc(100% - 14px),transparent);mask-composite:intersect"><img src="${orig}" style="left:${-p[0]}px;top:${-p[1]}px"></div>${j.i===3?`<div class="protected-text" style="left:0;top:0;width:941px;height:444px"><img src="${orig}" style="left:0;top:0"></div>`:''}`;
}
const css=`*{box-sizing:border-box}html,body{width:100%;height:100%;margin:0;padding:0;background:#000;overflow:hidden}.story{position:absolute;left:0;top:0;width:941px;height:1672px;transform-origin:top left}.original{position:absolute;left:0;top:0;width:941px;height:1672px}.portrait-clip{position:absolute;overflow:hidden}.portrait-clip img{display:block}.protected-text{position:absolute;overflow:hidden}.protected-text img{position:absolute;width:941px;height:1672px}`;
(async()=>{
  const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
  const manifest=[];
  for(const j of meta){if(!files[j.i])continue;
    for(const [folder,w,h] of [['Images',941,1672],['Stories_1080',1080,1920],['Exports_2160',2160,3840]]){
      fs.mkdirSync(path.join(exportRoot,folder),{recursive:true});
      const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});
      const html=`<!doctype html><meta charset="utf-8"><style>${css}.story{transform:scale(${w/941},${h/1672})}</style><main class="story">${body(j)}</main>`;
      await page.setContent(html); await page.locator('img').evaluateAll(es=>Promise.all(es.map(e=>e.decode())));
      const output=path.join(exportRoot,folder,j.n+'.png'); await page.screenshot({path:output});
      manifest.push({name:j.n,output,width:w,height:h,original:path.join('C:/Users/notti/Downloads',j.f),portrait:files[j.i],note:folder==='Exports_2160'?'Export agrandi; ne constitue pas une prise de vue native 4K.':'Retouche photographique generative puis reintegration locale; textes originaux preserves.'});
      if(folder==='Images'){fs.mkdirSync(path.join(exportRoot,'Editable'),{recursive:true});fs.writeFileSync(path.join(exportRoot,'Editable',j.n+'.html'),html);}
      await page.close();
    }
  }
  await browser.close();fs.writeFileSync(path.join(exportRoot,'manifest.json'),JSON.stringify(manifest,null,2));console.log(JSON.stringify({count:manifest.length,destination:exportRoot},null,2));
})();

