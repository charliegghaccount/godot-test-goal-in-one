@tool
extends "res://scripts/mechanics/area.gd"
## Direction is in local coordinates (right by default). Acceleration uses px/s².
@export var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		queue_redraw()
@export_range(0,20000,50) var acceleration: float = 7200.0
@export_range(60,2500,10) var maximum_speed: float = 1080.0
var phase = 0.0

func _ready():
	super._ready()

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	phase += dt
	if active and is_instance_valid(ball):
		var axis = direction.normalized().rotated(global_rotation)
		var fade = maxf(0,1-maxf(0,ball.linear_velocity.dot(axis))/maximum_speed)
		ball.sleeping = false
		ball.linear_velocity += axis*acceleration*fade*dt
	queue_redraw()

func _draw():
	preload("res://scripts/pad_art.gd").draw_pad(self,dimensions,"forward" if direction.x>=0 else "backward")

func activate():
	feedback("boost")
