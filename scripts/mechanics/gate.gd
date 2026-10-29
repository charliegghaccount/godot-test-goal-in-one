@tool
extends AnimatableBody2D
## Movement follows local Direction, in pixels, from the saved node position.
@export var dimensions: Vector2 = Vector2(40,160):
	set(value):
		dimensions = value.max(Vector2(12,12))
		if is_inside_tree(): _sync_shape.call_deferred()
		queue_redraw()
@export var movement_direction: Vector2 = Vector2.UP:
	set(value):
		movement_direction = value
		queue_redraw()
@export_range(0,1000,5) var travel_distance: float = 170.0:
	set(value):
		travel_distance = value
		queue_redraw()
@export_range(10,1000,5) var movement_speed: float = 180.0
@export var closing_speed: float = 0.0
@export var automatic: bool = false
@export_range(0,10,0.1) var endpoint_wait: float = 0.8
var target_open = false
var progress = 0.0
var rest_position = Vector2.ZERO
var wait_remaining = 0.0
var collision: CollisionShape2D
var ball: RigidBody2D
var blocked = false

func _ready():
	collision_mask = 2
	sync_to_physics = true
	rest_position = position
	_sync_shape()
	if automatic: target_open = true

func bind_game(runtime: Node):
	ball = runtime.ball

func _sync_shape():
	if not is_instance_valid(collision):
		collision = CollisionShape2D.new()
		collision.shape = RectangleShape2D.new()
		add_child(collision)
	collision.shape.size = dimensions

func set_open(value: bool):
	target_open = value

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	if wait_remaining > 0:
		wait_remaining = maxf(0,wait_remaining-dt)
		return
	var next = move_toward(progress,1.0 if target_open else 0.0,(movement_speed if target_open or closing_speed<=0 else closing_speed)*dt/maxf(travel_distance,1))
	var next_position = rest_position+movement_direction.normalized().rotated(rotation)*travel_distance*next
	blocked = false
	# Stop before crushing the ball. Full-shape sweeps prevent tunnelling even at high speed.
	if is_instance_valid(ball) and next_position != position:
		var query = PhysicsShapeQueryParameters2D.new()
		query.shape = collision.shape
		query.transform = global_transform
		query.motion = get_parent().global_transform.basis_xform(next_position-position)
		query.exclude = [get_rid()]
		query.collision_mask = 2
		var hits = get_world_2d().direct_space_state.intersect_shape(query)
		var ahead = get_world_2d().direct_space_state.cast_motion(query)
		var toward = query.motion.dot(ball.global_position-global_position) > 0
		blocked = ahead[0] < 1.0 or (not hits.is_empty() and toward)
	if not blocked:
		position = next_position
		progress = next
	if automatic and (progress == 0 or progress == 1):
		target_open = not target_open
		wait_remaining = endpoint_wait
	queue_redraw()

func _draw():
	var rect = Rect2(-dimensions/2,dimensions)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	var wood = preload("res://assets/wood.webp")
	var density = wood.get_width()/256.0
	draw_texture_rect_region(wood,rect,Rect2(rect.position*density,rect.size*density))
	draw_rect(rect,Color("634129"),false,3)
	for y in [-dimensions.y/2+10,dimensions.y/2-10]:
		draw_rect(Rect2(-dimensions.x/2,y-4,dimensions.x,8),Color("64727d"))
		for x in [-dimensions.x/2+6,dimensions.x/2-6]:
			draw_circle(Vector2(x,y),2,Color("dde3e2"))
	draw_circle(Vector2(0,0),4,Color("ffbb4a") if blocked else (Color("6cdc6b") if target_open else Color("a6b8be")))
	if Engine.is_editor_hint():
		var end = movement_direction.normalized()*travel_distance
		draw_line(Vector2.ZERO,end,Color(1,0.9,0.4,0.7),2,true)
		draw_rect(Rect2(end-dimensions/2,dimensions),Color(1,0.9,0.4,0.5),false,2)
