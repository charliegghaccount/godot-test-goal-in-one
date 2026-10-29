@tool
extends "res://scripts/mechanics/area.gd"
@export_range(0.1,2,0.05) var cooldown_seconds: float = 0.5
var cooldown = 0.0
var flash = 0.0
var pending = false

func activate():
	if cooldown > 0 or pending: return
	pending = true
	cooldown = cooldown_seconds
	flash = 1.0
	feedback("reset")
	# Do not teleport a physics body inside a collision signal/physics query flush.
	reset_football.call_deferred()

func reset_football():
	pending = false
	if is_instance_valid(game) and not game.won:
		game.reset_ball()

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	cooldown = maxf(0,cooldown-dt)
	flash = maxf(0,flash-dt*3)
	queue_redraw()

func _draw():
	preload("res://scripts/pad_art.gd").draw_pad(self,dimensions,"delete",flash)
