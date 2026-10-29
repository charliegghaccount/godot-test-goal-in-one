import json,pathlib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
p=pathlib.Path(__file__).parent
m={x['name']:x['trace'] for x in json.loads((p/'traces/matter.json').read_text())}
g={x['name']:x['trace'] for x in json.loads((p/'traces/godot.json').read_text())}
fig,axes=plt.subplots(1,2,figsize=(12,4))
for name,color in [('a-40-p140','#286cb5'),('a-70-p90','#bf7620')]:
 for data,style,label in [(m,'-', 'Matter'),(g,'--','Godot')]:
  t=data[name][:140];axes[0].plot([x[0] for x in t],[800-x[1] for x in t],style,color=color,label=f'{label} {name}')
axes[0].set(xlabel='Horizontal position (px)',ylabel='Height above launch (px)',title='Equivalent predefined shots')
for data,style,label in [(m,'-','Matter'),(g,'--','Godot')]:
 t=data['rolling'];axes[1].plot([i/120 for i in range(len(t))],[x[2] for x in t],style,label=label)
axes[1].set(xlabel='Time (seconds)',ylabel='Horizontal velocity (px/s)',title='Rolling: remaining mismatch')
for ax in axes:ax.legend();ax.grid(alpha=.2)
fig.tight_layout();fig.savefig(p/'physics-comparison.png',dpi=160)
