const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await page.goto(process.env.GAME_URL || 'http://127.0.0.1:8063');await page.waitForTimeout(9000);
 await page.mouse.click(100,680);await page.waitForTimeout(300);await page.screenshot({path:'/tmp/v3picker.png'});
 await page.mouse.click(100,570);await page.waitForTimeout(1800);await page.screenshot({path:'/tmp/v3spring.png'});
 await page.mouse.move(400,300);await page.mouse.down();await page.mouse.move(280,300,{steps:12});await page.mouse.up();await page.waitForTimeout(700);await page.screenshot({path:'/tmp/v3spring-active.png'});
 await page.mouse.click(100,680);await page.waitForTimeout(300);await page.mouse.click(100,595);await page.waitForTimeout(1600);await page.screenshot({path:'/tmp/v3fan.png'});
 await page.mouse.move(400,300);await page.mouse.down();await page.mouse.move(340,300,{steps:12});await page.mouse.up();await page.waitForTimeout(2500);await page.screenshot({path:'/tmp/v3fan-active.png'});
 await page.mouse.click(100,680);await page.waitForTimeout(300);await page.mouse.click(100,622);await page.waitForTimeout(1600);await page.screenshot({path:'/tmp/v3gate.png'});
 await page.mouse.move(400,300);await page.mouse.down();await page.mouse.move(340,300,{steps:12});await page.mouse.up();await page.waitForTimeout(1300);await page.screenshot({path:'/tmp/v3gate-active.png'});
 await browser.close();if(errors.length)throw Error(errors.join('\n'));console.log('Three lab browser flows completed without console errors; inspect screenshots.');
})().catch(e=>{console.error(e);process.exit(1)})
