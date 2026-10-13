// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1500}
const base="C:\\Users\\notti\\Documents\\ChatGPT\\Thumbnail - CF\\Casper_SMC\\Masters\\V01\\";
const jobs=[
 {name:"Casper_conversation_clean_generated",file:"Casper_00-20-00_cutout.png",shirt:"Keep his black shirt, white undershirt, tattoos, watch and rings exactly."},
 {name:"Casper_explain_clean_generated",file:"Casper_00-16-00_cutout.png",shirt:"Change only his black open shirt to an off-white cotton shirt, keeping the same open collar, sleeves, seams, folds and texture. Keep the white undershirt, tattoos, green marker and both hands exactly."},
 {name:"Riz_front_clean_generated",file:"Riz_01-16-00_cutout.png",shirt:"Keep his beige polo shirt, exact color, collar, buttons and folds."},
 {name:"Riz_conversation_clean_generated",file:"Riz_01-34-00_cutout.png",shirt:"Keep his beige polo shirt, exact color, collar, buttons and folds. Keep his crossed arms, watch, fingers and ring."}
];
store('clean_jobs',jobs);
for(const j of jobs) {
j.prompt="Precise photographic cutout edit on the supplied image. Preserve exact 16:9 full canvas and the EXACT subject position, scale and silhouette. Remove only the microphone, vertical microphone stand, any support and its cables; reconstruct the small hidden area of clothing. "+j.shirt+" All facial and head pixels must remain as close to the source as possible, original expression, eyes, hair, beard, skin tone, neck, no enhanced texture or sharpening. Do not move, recrop, zoom, relight, change pose, alter expression, invent jewelry or change body proportions. Keep the background fully transparent. It will be composited into a thumbnail. Do not add text, watermark or graphics.";
}
const results=await Promise.allSettled(jobs.map(async j=>({name:j.name,result:await tools.image_gen__imagegen({prompt:j.prompt,referenced_image_paths:[base+j.file],transparent_background:true})})));
store('clean_jobs',jobs);store('clean_results',results);
for(const r of results){if(r.status==='fulfilled'){text(r.value.name);generatedImage(r.value.result);}else text({error:String(r.reason)});}

