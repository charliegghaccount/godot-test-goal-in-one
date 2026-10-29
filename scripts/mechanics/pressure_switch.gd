@tool
extends "res://scripts/mechanics/area.gd"
## Assign a sibling gate with the Inspector node picker. Default matches the reference toggle.
@export_node_path("AnimatableBody2D") var linked_gate: NodePath:
	set(value):
		linked_gate = value
		if is_inside_tree(): update_configuration_warnings()
@export_enum("Toggle", "Timed", "Hold") var activation_mode: int = 0
@export_range(0.2,30,0.1) var open_seconds: float = 6.0
@export var circular_sensor = false
var remaining = 0.0
var pressed_amount = 0.0

func gate() -> Node:
	return get_node_or_null(linked_gate) if not linked_gate.is_empty() else null

func activate():
	var target = gate()
	if not is_instance_valid(target) or not target.has_method("set_open"): return
	if activation_mode == 0: target.set_open(not target.target_open)
	else:
		target.set_open(true)
		if activation_mode == 1: remaining = open_seconds
	feedback("switch")

func deactivate():
	if activation_mode == 2:
		var target = gate()
		if is_instance_valid(target) and target.has_method("set_open"): target.set_open(false)

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	pressed_amount = move_toward(pressed_amount,1.0 if active else 0.0,dt*12)
	if remaining > 0:
		remaining = maxf(0,remaining-dt)
		if remaining == 0:
			var target = gate()
			if is_instance_valid(target) and target.has_method("set_open"): target.set_open(false)
	queue_redraw()

func _get_configuration_warnings() -> PackedStringArray:
	var target = gate()
	if not is_instance_valid(target) or not target.has_method("set_open"):
		return PackedStringArray(["Assign Linked Gate using the Inspector node picker."])
	return PackedStringArray()

func _draw():
	plate(Rect2(-dimensions/2,dimensions),Color("45535e"))
	var top = -dimensions.y/2+pressed_amount*5
	plate(Rect2(-dimensions.x/2+5,top,dimensions.x-10,6),Color("65dc65") if active else Color("f2b846"))
	draw_circle(Vector2(0,top+3),2,Color("fff6c7"))

func _sync_shape():
	if not circular_sensor:
		super._sync_shape()
		return
	if not is_instance_valid(sensor):
		sensor = CollisionShape2D.new()
		add_child(sensor)
	sensor.shape = CircleShape2D.new()
	sensor.shape.radius = 18
