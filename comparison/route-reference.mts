import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.REFERENCE_REPO||'/workspace/goal-in-one-test';
const {FootballSimulation}=await import(pathToFileURL(resolve(source,'src/simulation.ts')).href);
const {levels}=await import(pathToFileURL(resolve(source,'src/levels.ts')).href);
import {writeFileSync} from 'node:fs';
const rows=[];
for(const id of [1,5,9,14])for(const angle of [-15,-35,-55]){
 const s=new FootballSimulation(levels[id-1]);const a=angle*Math.PI/180;s.shoot({x:-140*Math.cos(a),y:-140*Math.sin(a)});
 const trace=[];for(let i=0;i<360;i++){s.step();if(i%40===39)trace.push([s.ball.position.x,s.ball.position.y]);}
 rows.push({level:id,angle,trace,won:s.phase==='won'});s.destroy();
}writeFileSync('comparison/routes-matter.json',JSON.stringify(rows,null,2));
