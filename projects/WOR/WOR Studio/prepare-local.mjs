import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
await fs.mkdir(path.join(root,'data'),{recursive:true});
try { await fs.copyFile(path.join(root,'dist','seed.example.js'),path.join(root,'dist','seed.js'),fs.constants.COPYFILE_EXCL); }
catch(e) { if(e.code!=='EEXIST') throw e; }
