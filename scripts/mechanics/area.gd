@tool
extends Area2D
## Shared single-football sensor. Dimensions are local pixels; rotate the node to orient it.
@export var dimensions: Vector2 = Vector2(120,24):
	set(value):
		dimensions = value.max(Vector2(8,8))
		queue_redraw()
		if is_inside_tree(): _sync_shape.call_deferred()
var ball: RigidBody2D
var game: Node
var active = false
var sensor: CollisionShape2D

func _ready():
	collision_layer = 0
	collision_mask = 2
	_sync_shape()
	body_entered.connect(_entered)
	body_exited.connect(_exited)

func bind_game(runtime: Node):
	game = runtime
	ball = runtime.ball

func _sync_shape():
	if not is_instance_valid(sensor):
		sensor = CollisionShape2D.new()
		sensor.shape = RectangleShape2D.new()
		add_child(sensor)
	sensor.shape.size = dimensions

func _entered(body: Node):
	if Engine.is_editor_hint() or body != ball or active: return
	active = true
	activate()

func _exited(body: Node):
	if body != ball: return
	active = false
	deactivate()

func activate():
	pass

func deactivate():
	pass

func reset_contact():
	active = false
	deactivate()

func feedback(kind: String):
	if is_instance_valid(game) and game.has_method("mechanic_feedback"):
		game.mechanic_feedback(kind,global_position)

func plate(rect: Rect2, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("354451")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	draw_style_box(style,rect)
