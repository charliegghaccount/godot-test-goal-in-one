@tool
extends "res://scripts/mechanics/area.gd"
## Origin is the ground-mounted fan. The force region extends along local UP.
@export_range(40,1000,10) var airflow_range: float = 300.0:
	set(value):
		airflow_range = value
		if is_inside_tree(): _sync_shape.call_deferred()
		queue_redraw()
@export_range(0,12000,50) var airflow_acceleration: float = 2500.0
@export_range(100,2500,10) var maximum_air_speed: float = 1440.0
var phase = 0.0

func _sync_shape():
	super._sync_shape()
	sensor.shape.size = Vector2(dimensions.x,airflow_range+dimensions.y)
	sensor.position = Vector2(0,-airflow_range/2)

func _physics_process(dt):
	if Engine.is_editor_hint(): return
	phase += dt*12
	if active and is_instance_valid(ball):
		var axis = Vector2.UP.rotated(global_rotation)
		var fade = maxf(0,1-maxf(0,ball.linear_velocity.dot(axis))/maximum_air_speed)
		ball.sleeping = false
		ball.linear_velocity += axis*airflow_acceleration*fade*dt
	queue_redraw()

func _draw():
	# Light flow guides remain visible in the editor and animate in play.
	var shade = Color(0.8,0.95,1,0.12)
	draw_rect(Rect2(-dimensions.x/2,-airflow_range-dimensions.y/2,dimensions.x,airflow_range),shade)
	for i in range(4):
		var y = -dimensions.y/2-fposmod(i*airflow_range/4+phase*10,airflow_range)
		draw_polyline(PackedVector2Array([Vector2(-9,y+5),Vector2(0,y),Vector2(9,y+5)]),Color(0.85,0.98,1,0.55),2,true)
	plate(Rect2(-dimensions/2,dimensions),Color("647b8a"))
	var center = Vector2.ZERO
	for i in range(4):
		var a = phase+i*TAU/4
		var tip = center+Vector2.from_angle(a)*minf(dimensions.x*0.3,dimensions.y*0.35)
		draw_line(center,tip,Color("d8edf0"),5,true)
	draw_circle(center,4,Color("344754"))
	for x in range(-int(dimensions.x/2)+8,int(dimensions.x/2)-4,9):
		draw_line(Vector2(x,-dimensions.y/2+4),Vector2(x,dimensions.y/2-4),Color(0.1,0.2,0.25,0.5),1,true)
