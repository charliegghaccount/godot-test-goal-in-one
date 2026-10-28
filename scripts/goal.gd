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
	if initialized and valid_crossing(previous,current,radius): scored.emit()
	previous = current
	initialized = true

func _draw():
	var w = goal_size.x
	var h = goal_size.y
	var roof = w*roof_ratio
	# No polygon fill, fourth frame edge, or net strand along x=0: entrance stays open.
	for y in range(-int(h)+12,-5,12):
		var right = roof + (y+h)/h*(w-roof)
		draw_line(Vector2(12,y),Vector2(right,y),Color(1,1,1,0.45),1,true)
	for x in range(12,int(w)-5,12):
		var top = -h if x < roof else -(w-x)/(w-roof)*h
		draw_line(Vector2(x,top),Vector2(x,-5),Color(1,1,1,0.45),1,true)
	draw_polyline(frame_points(),Color("54636c"),11,true)
	draw_polyline(frame_points(),Color("f7fcff"),7,true)
