@tool
extends "res://scripts/mechanics/area.gd"
@export var direction = Vector2.RIGHT
@export var acceleration = 3600.0
var time = 0.0
func _physics_process(dt):
	if Engine.is_editor_hint(): return
	time += dt
	# Reference wind checks the center, not a circle touching the region edge.
	if is_instance_valid(ball) and Rect2(-dimensions/2,dimensions).has_point(to_local(ball.global_position)):
		var axis = direction.rotated(global_rotation).normalized()
		var fade = maxf(0,1-maxf(0,ball.linear_velocity.dot(axis))/1440)
		ball.sleeping = false
		ball.linear_velocity += axis*acceleration*fade*dt
	queue_redraw()
func _draw():
	var rect = Rect2(-dimensions/2,dimensions)
	draw_rect(rect,Color("83e5ff28"))
	draw_rect(rect,Color("a4eaffaa"),false,2)
	var axis = direction.normalized()
	var normal = axis.orthogonal()
	for row in 5:
		for col in 5:
			var at = rect.position+Vector2(fposmod(col*60+time*axis.x*36,dimensions.x),fposmod(row*45+time*axis.y*36,dimensions.y))
			if rect.grow(-16).has_point(at):
				draw_line(at-axis*13,at+axis*13,Color("efffffbb"),1.5,true)
				draw_polyline(PackedVector2Array([at+axis*7+normal*5,at+axis*13,at+axis*7-normal*5]),Color("efffffbb"),1.5,true)
	var reach = minf(dimensions.x/(2*maxf(absf(axis.x),0.0001)),dimensions.y/(2*maxf(absf(axis.y),0.0001)))
	var size = maxf(6,minf(46,minf(dimensions.x*0.55,dimensions.y*0.65)))
	var fan_at = -axis*maxf(0,reach-size*0.5)
	draw_set_transform(fan_at,axis.angle()+PI/2,Vector2.ONE*size/46)
	draw_style_box(preload("res://scripts/ui/timber_ui.gd").box(Color("455365"),Color("202a34")),Rect2(-21,-16,42,31))
	draw_rect(Rect2(-23,-21,46,8),Color("a1adba"))
	draw_rect(Rect2(-23,16,46,7),Color("414d5b"))
	for i in 4:
		var v = Vector2.from_angle(time*9+i*PI/2)*11
		draw_line(Vector2(0,1),v+Vector2(0,1),Color("90a6ba"),5,true)
	draw_circle(Vector2(0,1),3,Color("e0edf8"))
	draw_set_transform(Vector2.ZERO)
