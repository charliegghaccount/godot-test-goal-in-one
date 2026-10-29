@tool
extends "res://scripts/mechanics/area.gd"
@export_range(0,0.04,0.0001) var friction = 0.0005
func activate():
	if is_instance_valid(ball): ball.ice_contacts[get_instance_id()] = friction
func deactivate():
	if is_instance_valid(ball): ball.ice_contacts.erase(get_instance_id())
func _exit_tree(): deactivate()
func _draw():
	draw_line(Vector2(-dimensions.x/2,0),Vector2(dimensions.x/2,0),Color("398fbb"),10,true)
	draw_line(Vector2(-dimensions.x/2,0),Vector2(dimensions.x/2,0),Color("b7f1ff"),7,true)
	for x in range(-int(dimensions.x/2)+10,int(dimensions.x/2)-10,27):
		draw_line(Vector2(x,-2),Vector2(x+9,2),Color("ffffffdd"),1.5,true)
