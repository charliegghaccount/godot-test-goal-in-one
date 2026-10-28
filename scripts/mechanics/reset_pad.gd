@tool
extends "res://scripts/mechanics/area.gd"
@export_range(0.1,2,0.05) var cooldown_seconds: float = 0.5
var cooldown = 0.0
var flash = 0.0
var pending = false

func activate():
	if cooldown > 0 or pending: return
	pending = true
	cooldown = cooldown_seconds
	flash = 1.0
	feedback("reset")
	# Do not teleport a physics body inside a collision signal/physics query flush.
	reset_football.call_deferred()

func reset_football():
	pending = false
	if is_instance_valid(game) and not game.won:
		game.reset_ball()

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	cooldown = maxf(0,cooldown-dt)
	flash = maxf(0,flash-dt*3)
	queue_redraw()

func _draw():
	plate(Rect2(-dimensions/2,dimensions),Color("47515d"))
	plate(Rect2(-dimensions/2+Vector2(3,3),dimensions-Vector2(6,6)),Color("dd3545").lightened(flash*0.6))
	for x in range(-int(dimensions.x/2)+10,int(dimensions.x/2)-8,20):
		draw_line(Vector2(x,-dimensions.y/2+4),Vector2(x+8,dimensions.y/2-4),Color("ffb3a3"),3,true)
	if flash > 0: draw_arc(Vector2.ZERO,dimensions.x/2+flash*18,0,TAU,32,Color(1,0.3,0.2,flash),3,true)
