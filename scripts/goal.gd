extends Area2D
signal scored
var ball: RigidBody2D
var previous = Vector2.ZERO
var initialized = false

func _ready():
	var collision = CollisionShape2D.new()
	collision.position = Vector2(17, -54)
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(2, 75)
	add_child(collision)

func _physics_process(_dt):
	var current = ball.global_position - global_position
	if initialized and previous.x <= 16 and current.x > 16 and current.x > previous.x:
		var y = lerpf(previous.y,current.y,(16-previous.x)/(current.x-previous.x))
		if y - 16 > -107.66 + 5.2 and y + 16 < -4.2: scored.emit()
	previous = current
	initialized = true

func _draw():
	var net = PackedVector2Array([Vector2(0,-107.66),Vector2(79.54,-107.66),Vector2(135.49,0),Vector2.ZERO])
	draw_colored_polygon(net,Color(0.92,0.98,1,0.2))
	for y in range(-100, 0, 12):
		var right = 79.54 + (y+107.66)/107.66*55.95
		draw_line(Vector2(0,y),Vector2(right,y),Color(1,1,1,0.5),1)
	for x in range(0, 130, 12):
		var top = -107.66 if x < 80 else -(135.49-x)/55.95*107.66
		draw_line(Vector2(x,top),Vector2(x,0),Color(1,1,1,0.5),1)
	var frame = PackedVector2Array([Vector2(0,-107.66),Vector2(79.54,-107.66),Vector2(135.49,0),Vector2.ZERO])
	draw_polyline(frame,Color("54636c"),11,true)
	draw_polyline(frame,Color("f7fcff"),7,true)
