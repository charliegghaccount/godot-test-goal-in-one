@tool
extends AnimatableBody2D
@export var dimensions = Vector2(140,24)
@export var speed = 1.0
@export var phase = 0.0
@export var swinging = false
@export var amplitude = 0.5
@export var period = 5.0
@export var use_pivot = false
@export var pivot = Vector2.ZERO
@export var grass_edging = false
var origin = Vector2.ZERO
var time = 0.0
var ball: RigidBody2D
var collision: CollisionShape2D
func pose_angle(at: float) -> float:
	return phase+sin(at*TAU/maxf(period,0.1))*amplitude if swinging else phase+at*speed
func pose_position(angle: float) -> Vector2:
	return pivot+Vector2(-sin(angle),cos(angle))*dimensions.y/2 if use_pivot else origin
func _ready():
	origin = position
	collision_mask = 2
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = dimensions
	add_child(collision)
	var material = PhysicsMaterial.new()
	material.friction = 0.003
	material.bounce = 0.04 # Godot adds restitution; ball 0.76 + paddle 0.04 = reference 0.8.
	physics_material_override = material
	transform = Transform2D(phase,pose_position(phase))
func bind_game(game: Node): ball = game.ball
func _physics_process(dt):
	if Engine.is_editor_hint(): return
	time += dt
	var angle = rotation+clampf(pose_angle(time)-rotation,-3*dt,3*dt)
	var at = pose_position(angle)
	if is_instance_valid(ball):
		var supported = false
		for body in ball.get_colliding_bodies():
			if body!=self: supported = true
		if supported:
			var query = PhysicsShapeQueryParameters2D.new()
			query.shape = collision.shape
			query.transform = get_parent().global_transform*Transform2D(angle,at)
			query.collision_mask = 2
			if not get_world_2d().direct_space_state.intersect_shape(query).is_empty(): return
	transform = Transform2D(angle,at)
	queue_redraw()
func _draw():
	if use_pivot:
		var local_pivot = (pivot-position).rotated(-rotation)
		draw_line(local_pivot,Vector2.ZERO,Color("455d65"),4,true)
		preload("res://scripts/game_art.gd").bolt(self,local_pivot,6)
	preload("res://scripts/game_art.gd").rectangle(self,dimensions,grass_edging)
	preload("res://scripts/game_art.gd").bolt(self,Vector2.ZERO,7)
