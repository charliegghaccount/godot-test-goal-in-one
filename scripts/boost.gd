@tool
extends Area2D
var ball: RigidBody2D
var active = false

func _ready():
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(184, 30)
	add_child(collision)
	body_entered.connect(func(body):
		if body == ball: active = true)
	body_exited.connect(func(body):
		if body == ball: active = false)
	queue_redraw()

func _physics_process(dt):
	if not Engine.is_editor_hint() and active and is_instance_valid(ball):
		ball.sleeping = false
		ball.linear_velocity.x += 7200 * maxf(0, 1 - ball.linear_velocity.x / 1080) * dt

func _draw():
	draw_style_box(_panel(), Rect2(-92, 1, 184, 12))
	for x in range(-78, 80, 25):
		draw_polyline(PackedVector2Array([Vector2(x,3),Vector2(x+8,7),Vector2(x,11)]), Color("e1ffae"), 3, true)

func _panel():
	var s = StyleBoxFlat.new()
	s.bg_color = Color("4c9b38")
	s.set_corner_radius_all(5)
	return s
