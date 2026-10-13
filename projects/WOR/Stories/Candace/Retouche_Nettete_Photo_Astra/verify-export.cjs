const fs=require('fs'),path=require('path');
const sharp=require('C:/Users/notti/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.join(__dirname,'Export_Corrige_V2');
(async()=>{
 const results=[];
 for(const name of fs.readdirSync(path.join(root,'Images')).filter(n=>n.endsWith('.png'))){
   const expected=await sharp(path.join(root,'Images',name)).removeAlpha().raw().toBuffer();
   for(const [folder,width,height] of [['Stories_1080',1080,1920],['Exports_2160',2160,3840]]){
     const file=path.join(root,folder,name);const meta=await sharp(file).metadata();
     if(meta.width!==width||meta.height!==height)throw Error('Dimensions incorrectes: '+file);
     const actual=await sharp(file).resize(941,1672).removeAlpha().raw().toBuffer();
     const start=Math.floor(1672*.65)*941*3; let diff=0;
     for(let k=start;k<expected.length;k++)diff+=Math.abs(expected[k]-actual[k]);
     const mae=diff/(expected.length-start);
     if(mae>4)throw Error('Le bas de l’export differe de la composition: '+file+' / '+mae);
     results.push({file,width,height,lower35PercentMeanPixelDifference:+mae.toFixed(4)});
   }
 }
 if(results.length!==10)throw Error('Exports manquants');
 fs.writeFileSync(path.join(root,'Verification.json'),JSON.stringify(results,null,2));
 console.log(JSON.stringify({verified:results.length,maxLowerAreaDifference:Math.max(...results.map(r=>r.lower35PercentMeanPixelDifference))}));
})();
