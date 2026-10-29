"""Summarize original, unwarped renderer captures. Requires Pillow."""
import json, pathlib, math
from PIL import Image, ImageDraw, ImageChops, ImageStat
root=pathlib.Path(__file__).resolve().parents[1]
evidence=root/'build/v7-evidence'; out=root/'comparison/v7';out.mkdir(exist_ok=True)
rows=json.loads((evidence/'paired-states.json').read_text())
metrics=[]
for row in rows:
 a=Image.open(evidence/row['images']['vite']).convert('RGB');b=Image.open(evidence/row['images']['godot']).convert('RGB')
 d=ImageStat.Stat(ImageChops.difference(a,b))
 metrics.append({**{k:v for k,v in row.items() if k not in ('images',)},'mean_absolute_rgb_error':round(sum(d.mean)/3,3),'camera_component_max_error':round(max(abs(x-y) for x,y in zip(row['states']['vite']['camera'],row['states']['godot']['camera'])),5)})
(out/'visual-metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
def sheet(name,records):
 width=1000; gap=16; item_height=300
 result=Image.new('RGB',(width,item_height*len(records)+40),'#eae6d5');draw=ImageDraw.Draw(result)
 draw.text((16,10),'VITE / MATTER (LEFT)                          GODOT V7 (RIGHT) — actual captures, same viewport',fill='black')
 for i,(label,a,b) in enumerate(records):
  y=40+i*item_height
  draw.text((16,y),label,fill='black')
  for j,filename in enumerate((a,b)):
   im=Image.open(filename).convert('RGB');im.thumbnail((480,265))
   result.paste(im,(16+j*500,y+22))
 result.save(out/name,quality=88)
for width in (1280,960,844):
 selected=[r for r in rows if r['width']==width]
 sheet(f'world-{width}.jpg',[(f"Level {r['level']} / {width}x{r['height']} / {r['ticks']} ticks / {r.get('state','idle')}", evidence/r['images']['vite'],evidence/r['images']['godot']) for r in selected])
 ui=[]
 for stage in ('home','levels','hud','pause','complete'):
  a=evidence/f'ui-vite-{stage}-{width}.png';b=evidence/f'ui-godot-{stage}-{width}.png'
  if a.exists() and b.exists():ui.append((f'{stage} / {width}px',a,b))
 if ui:sheet(f'ui-{width}.jpg',ui)
print('Wrote contact sheets and',len(rows),'paired visual metrics')
