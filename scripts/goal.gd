@tool
extends Area2D
signal scored
@export var goal_size: Vector2 = Vector2(135.49,107.66):
	set(value):
		goal_size = value.max(Vector2(65,65))
		_rebuild()
@export_range(0.2,0.85) var roof_ratio: float = 0.587:
	set(value):
		roof_ratio = value
		_rebuild()
var ball: RigidBody2D
var previous = Vector2.ZERO
var initialized = false
var scored_once = false
var net_flash = 0.0
var net_time = -10.0
var frame_body: StaticBody2D

func _ready():
	_rebuild()

func frame_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0,-goal_size.y),Vector2(goal_size.x*roof_ratio,-goal_size.y),Vector2(goal_size.x,0),Vector2.ZERO])

func _rebuild():
	queue_redraw()
	if not is_inside_tree(): return
	if is_instance_valid(frame_body):
		remove_child(frame_body)
		frame_body.queue_free()
	frame_body = StaticBody2D.new()
	frame_body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	frame_body.collision_layer = 1
	frame_body.collision_mask = 2
	add_child(frame_body)
	var points = frame_points()
	for i in range(3):
		var shape = CollisionShape2D.new()
		var rectangle = RectangleShape2D.new()
		rectangle.size = Vector2(points[i].distance_to(points[i+1]),10.4)
		shape.shape = rectangle
		shape.position = (points[i]+points[i+1])/2
		shape.rotation = (points[i+1]-points[i]).angle()
		frame_body.add_child(shape)

func valid_crossing(before: Vector2, current: Vector2, radius: float = 16.0) -> bool:
	# Work in local coordinates so moving, resizing and rotating the whole goal stays coherent.
	if before.x > radius or current.x <= radius or current.x <= before.x: return false
	var y = lerpf(before.y,current.y,(radius-before.x)/(current.x-before.x))
	return y-radius > -goal_size.y+5.2 and y+radius < -4.2

func _physics_process(_dt):
	if Engine.is_editor_hint() or not is_instance_valid(ball): return
	var current = to_local(ball.global_position)
	var radius = 16.0 / maxf(absf(global_scale.x),0.01)
	net_flash = maxf(0,net_flash-_dt*1.5)
	if net_time>=0: net_time += _dt
	if initialized and not scored_once and valid_crossing(previous,current,radius):
		scored_once = true
		net_flash = 1.0
		net_time = 0.0
		scored.emit()
	queue_redraw()
	previous = current
	initialized = true

func mesh_line(points: PackedVector2Array):
	draw_polyline(points,Color("40586944"),2,true)
	draw_polyline(points,Color("fffffff0"),1.15,true)
func _draw():
	var w = goal_size.x
	var h = goal_size.y
	var roof = w*roof_ratio
	var ripple = sin(net_time*24)*exp(-net_time*3)*2 if net_time>=0 and net_time<1.4 else 0.0
	for y in range(-int(h)+13,-1,13):
		var right = roof+(y+h)/h*(w-roof)
		mesh_line(PackedVector2Array([Vector2(5,y),Vector2((5+right)/2,y+ripple),Vector2(right,y)]))
	for x in range(13,int(w),13):
		var top = -h if x<roof else -(w-x)/(w-roof)*h
		mesh_line(PackedVector2Array([Vector2(x,top),Vector2(x+ripple,top/2),Vector2(x,0)]))
		for y in range(-int(h)+13,-1,13):
			if y>top: draw_circle(Vector2(x,y),0.95,Color("ffffffdd"))
	var points = frame_points()
	for i in 3:
		var a = points[i]
		var b = points[i+1]
		var normal = (b-a).normalized().orthogonal()
		draw_line(a,b,Color("465360"),10.4,true)
		draw_line(a,b,Color("f4f7fa"),7.9,true)
		draw_line(a-normal*2.4,b-normal*2.4,Color.WHITE,1.25,true)
		for at in [a,b]:
			draw_circle(at,5.2,Color("465360"))
			draw_circle(at,3.95,Color("f4f7fa"))
	for at in [points[1],points[2]]:
		draw_circle(at,3.5,Color("9aa9b5"))
		draw_circle(at,2.8,Color("eaf0f5"))
		draw_circle(at-Vector2.ONE*0.9,1.2,Color.WHITE)
