@tool
extends Marker2D
func _draw():
	if Engine.is_editor_hint():
		draw_texture_rect(preload("res://assets/football.svg"),Rect2(-16,-16,32,32),false)
