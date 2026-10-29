import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const source=process.env.REFERENCE_REPO||'/workspace/goal-in-one-test';
const {FootballSimulation}=await import(pathToFileURL(resolve(source,'src/simulation.ts')).href);
const {default:Matter}=await import(pathToFileURL(resolve(source,'node_modules/matter-js/build/matter.js')).href);
import {writeFileSync} from 'node:fs';
const cases=[...[-15,-40,-70].flatMap(a=>[40,90,140].map(power=>({name:`a${a}-p${power}`,angle:a,power,rolling:false,second:false}))),{name:'correction',angle:-40,power:140,second:true,rolling:false},{name:'rolling',angle:0,power:0,second:false,rolling:true}];
const result=[];
for(const c of cases){
 const l={id:1,name:'benchmark',tip:'',par:1,starShots:[1,3],width:20000,start:{x:200,y:c.rolling?978.8:800},goal:{placement:'free',x:19000,y:1000,w:150,h:150,roof:80},boundary:[{x:-10000,y:1000},{x:-10000,y:-10000},{x:20000,y:-10000},{x:20000,y:1000}],outline:[],obstacles:[],surfaces:[],movers:[]};
 const sim=new FootballSimulation(l as any);const a=c.angle*Math.PI/180;
 if(c.rolling)Matter.Body.setVelocity(sim.ball,{x:7,y:0});else sim.shoot({x:-Math.cos(a)*c.power,y:-Math.sin(a)*c.power});
 const trace=[];for(let i=0;i<1200;i++){if(c.second&&i===72)sim.shoot({x:100,y:-30});sim.step();trace.push([sim.ball.position.x,sim.ball.position.y,sim.ball.velocity.x*60,sim.ball.velocity.y*60]);}
 result.push({...c,trace});sim.destroy();
}
writeFileSync('comparison/traces/matter.json',JSON.stringify(result));
writeFileSync('comparison/cases.json',JSON.stringify(cases));
