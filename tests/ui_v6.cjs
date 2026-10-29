// Run against the actual Web export: GAME_URL=http://127.0.0.1:8062 node tests/ui_v6.cjs
// Uses installed Playwright/Chromium, Python Pillow and Tesseract for canvas assertions.
const { chromium } = require('playwright');
const { mkdirSync, writeFileSync } = require('node:fs');
const { execFileSync } = require('node:child_process');
const { resolve } = require('node:path');
const assert = require('node:assert/strict');
const sizes = [[1280,720],[960,540],[932,430],[844,390],[740,360]];
const output = resolve(process.env.EVIDENCE_DIR || 'build/v6-evidence');
mkdirSync(output,{recursive:true});
writeFileSync(resolve(output,'.gdignore'),'');
(async()=>{
 const browser = await chromium.launch({executablePath:process.env.CHROMIUM_PATH || '/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try {
 const page = await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const url=process.env.GAME_URL || 'http://127.0.0.1:8062';
 const shot=async(name)=>{const path=resolve(output,name+'.png');await page.screenshot({path});return path};
 const text=path=>{
  // Isolate the cream lettering from wood/park texture before OCR.
  const mask=path+'.ocr.png';
  execFileSync('python3',['-c',`from PIL import Image
import sys
im=Image.open(sys.argv[1]).convert('RGB')
m=Image.new('L',im.size)
m.putdata([0 if r>210 and g>200 and b>160 else 255 for r,g,b in im.getdata()])
m.resize((im.width*2,im.height*2)).save(sys.argv[2])`,path,mask],{stdio:'ignore'});
  return execFileSync(process.env.TESSERACT_PATH || 'tesseract',[mask,'stdout','--psm','11'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}).toUpperCase();
 };
 const captures=async(stage)=>{for(const [width,height] of sizes){await page.setViewportSize({width,height});await page.waitForTimeout(500);await shot(`${stage}-${width}`)}};
 await page.goto(url);await page.waitForTimeout(7000);
 const homeText=text(await shot('home-check'));
 assert.match(homeText,/GOAL/);assert.match(homeText,/LEVEL SELECT/);assert.match(homeText,/SETTINGS/);
 await captures('home');
 // Last capture is 740x360; the centered native menu has a fixed-height card.
 await page.mouse.click(370,238);await page.waitForTimeout(700);
 await page.setViewportSize({width:1280,height:720});await page.waitForTimeout(700);
 assert.match(text(await shot('levels-check')),/GRASS[\s-]+PARKS/);
 await captures('levels');
 // First available tile is always in the top-left of the responsive grid.
 await page.mouse.click(75,112);await page.waitForTimeout(1500);
 await captures('hud');
 await page.setViewportSize({width:1280,height:720});await page.waitForTimeout(500);
 // Real level-one drag; the physics regression also verifies this route natively.
 await page.mouse.move(550,400);await page.mouse.down();await page.mouse.move(415,436,{steps:10});await page.mouse.up();
 let complete=false;
 for(let i=0;i<12;i++){await page.waitForTimeout(2500);if(text(await shot('completion-check')).includes('NEXT LEVEL')){complete=true;break}}
 assert(complete,'real mouse shot should display NEXT LEVEL');
 await captures('completion');
 await page.setViewportSize({width:1280,height:720});await page.waitForTimeout(500);
 // Completion panel is centered; native layout tests verify all touch rectangles.
 await page.mouse.click(640,365);await page.waitForTimeout(2500);
 const nextText=text(await shot('next-level-check'));
 assert.match(nextText,/LEVEL\s*2/,'NEXT LEVEL must display level two');
 assert.match(nextText,/SHOTS\s*0/,'next level must reset shots');
 // Pause, then resume through the actual button.
 await page.keyboard.press('Escape');await page.waitForTimeout(400);
 assert.match(text(await shot('pause-check')),/HALF TIME/);
 await page.mouse.click(640,340);await page.waitForTimeout(400);
 assert(!text(await shot('resume-check')).includes('HALF TIME'),'resume closes pause');
 assert.deepEqual(errors,[],'no browser errors');
 console.log('PASS: menu, chapter grid, real shot completion, NEXT LEVEL -> level 2, pause/resume, and 20 responsive captures.');
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
