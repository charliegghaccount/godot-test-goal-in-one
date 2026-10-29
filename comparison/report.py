import json,math,pathlib
root=pathlib.Path(__file__).parent
m=json.loads((root/'traces/matter.json').read_text());g={x['name']:x['trace'] for x in json.loads((root/'traces/godot.json').read_text())}
def metrics(t,rolling=False):
 landing=next((i for i,r in enumerate(t[1:],1) if r[1]>960 and t[i-1][3]>0 and r[3]<=0),None)
 rebound=next((r for i,r in enumerate(t[1:],1) if t[i-1][3]>100 and r[3]<-50),[0,0,0,0])
 resting=next((i for i,r in enumerate(t) if i>120 and abs(r[2])<8.4 and abs(r[3])<8.4),None)
 return {'x_1s':round(t[119][0]-200,2),'rise':round((978.8 if rolling else 800)-min(r[1] for r in t),2),'landing_s':None if landing is None else round(landing/120,3),'rebound_speed':round(math.hypot(*rebound[2:]),2),'rebound_angle':round(math.degrees(math.atan2(rebound[3],rebound[2])),2),'distance_10s':round(t[-1][0]-200,2),'rest_s':None if resting is None else round(resting/120,2)}
rows=[]
for case in m:
 a=metrics(case['trace'],case['rolling']);b=metrics(g[case['name']],case['rolling']);rows.append({'case':case['name'],'matter':a,'godot':b})
(root/'metrics.json').write_text(json.dumps(rows,indent=2))
lines=['# Measured physics comparison','', '120 Hz, fixed benchmark geometry, 10-second traces. Horizontal distance at 1 s, rise from y=800, landing at floor contact, rebound velocity, 10 s travel. Rolling begins at y=978.8. No reference physics changed.','', '| Shot | x@1s Matter / Godot | Rise Matter / Godot | Land s Matter / Godot | Travel@10s Matter / Godot |','|---|---:|---:|---:|---:|']
for r in rows:
 a=r['matter'];b=r['godot'];lines.append(f"| {r['case']} | {a['x_1s']} / {b['x_1s']} | {a['rise']} / {b['rise']} | {a['landing_s']} / {b['landing_s']} | {a['distance_10s']} / {b['distance_10s']} |")
(root/'PHYSICS.md').write_text('\n'.join(lines)+'\n');print('\n'.join(lines))
