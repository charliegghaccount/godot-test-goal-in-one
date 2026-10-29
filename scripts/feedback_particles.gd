extends Node2D
var particles: Array[Dictionary] = []
func setup(kind: String):
	var palette = {"win":["d9f688","ffffff","5bbf93","f6b269"],"break":["b37a40","f1c789","775027"],"spring":["d0a2ff","f7ddff"],"switch":["56cfff","ffffff"],"reset":["fb7369","ffb1aa"],"boost":["adf177","f9c36a"]}.get(kind,["c5a36b","a6d44b"])
	for i in (65 if kind=="win" else 25 if kind=="break" else 12):
		particles.append({"p":Vector2.ZERO,"v":Vector2(randf_range(-0.5,0.5)*(330 if kind=="win" else 100),-randf()*(300 if kind=="win" else 100)),"life":2.0 if kind=="win" else 0.55,"size":randf_range(2,5),"color":Color(palette[i%palette.size()])})
func _process(dt):
	if get_parent().paused: return
	for particle in particles:
		particle.life -= dt
		particle.p += particle.v*dt
		particle.v.y += 250*dt
	particles = particles.filter(func(p): return p.life>0)
	if particles.is_empty(): queue_free()
	queue_redraw()
func _draw():
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(1,particle.life*2)
		draw_rect(Rect2(particle.p,Vector2.ONE*particle.size),color)
