@tool
extends "res://scripts/mechanics/area.gd"
## The local UP axis launches the ball; rotate this node to aim.
@export var local_launch_direction: Vector2 = Vector2.UP
@export var visual_height: float = 0.0
@export_range(100,1440,10) var launch_speed: float = 1200.0
@export_range(0,1,0.05) var momentum_retention: float = 0.2
@export_range(0.05,1,0.01) var retrigger_delay: float = 0.18
var cooldown = 0.0
var compression = 0.0

func activate():
	if cooldown > 0 or not is_instance_valid(ball): return
	cooldown = retrigger_delay
	compression = 1.0
	ball.sleeping = false
	ball.linear_velocity = ball.linear_velocity*momentum_retention + local_launch_direction.normalized().rotated(global_rotation)*launch_speed
	feedback("spring")

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	cooldown = maxf(0,cooldown-dt)
	compression = maxf(0,compression-dt*5)
	queue_redraw()

func _draw():
	var w = dimensions.x
	var h = maxf(dimensions.y,visual_height)
	plate(Rect2(-w/2,h/2-7,w,7),Color("525c67"))
	var top = -h/2+compression*(h-14)
	var coil = PackedVector2Array()
	for i in range(9):
		coil.append(Vector2((-1 if i%2 else 1)*w*0.28,lerpf(top+5,h/2-6,i/8.0)))
	draw_polyline(coil,Color("263645"),6,true)
	draw_polyline(coil,Color("e3edf0"),3,true)
	plate(Rect2(-w/2,top,w,8),Color("f64c3d"))
	draw_line(Vector2(-w/2+5,top+2),Vector2(w/2-5,top+2),Color("ff9771"),2,true)
