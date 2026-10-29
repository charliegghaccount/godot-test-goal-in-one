// Run with the reference checkout's tsx; the reference game is never changed.
import {writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.REFERENCE_REPO||'/workspace/goal-in-one-test';
const {levels}=await import(pathToFileURL(resolve(source,'src/levels.ts')).href);
const out=resolve('comparison/levels');mkdirSync(out,{recursive:true});
for(const l of levels.slice(0,20)){
 const draft={format:'goal-in-one-level',version:1,draftId:`comparison-L${String(l.id).padStart(2,'0')}`,modified:'2026-10-29T00:00:00Z',difficulty:2,tags:['comparison'],level:l};
 writeFileSync(resolve(out,`L${String(l.id).padStart(2,'0')}.json`),JSON.stringify(draft,null,2));
 console.log(l.id,l.name,'movers',l.movers.length,'mechanics',JSON.stringify(l.mechanics||{}));
}
