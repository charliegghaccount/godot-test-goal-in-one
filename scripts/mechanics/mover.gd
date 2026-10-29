@tool
extends "res://scripts/mechanics/gate.gd"
@export var travel: float = 89.0
@export var period: float = 8.0
@export_enum("Vertical", "Horizontal") var axis: int = 0
@export var use_path: bool = false
@export var path_start: Vector2
@export var path_end: Vector2
@export var once: bool = false
@export var phase: float = 0.0
var time = 0.0
func _ready():
	super._ready()
	if not Engine.is_editor_hint():
		position = path_start if use_path else rest_position+(Vector2.RIGHT if axis==1 else Vector2.DOWN)*travel

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	time += dt
	if use_path:
		var u = (1-cos(PI*minf(1,(time/maxf(period,0.1)+phase)*2)))/2 if once else (1-cos((time/maxf(period,0.1)+phase)*TAU))/2
		position = path_start.lerp(path_end,u)
	else:
		position = rest_position + (Vector2.RIGHT if axis==1 else Vector2.DOWN)*cos(time*TAU/maxf(period,0.1))*travel
