extends Node2D
const BALL = preload("res://scenes/ball.tscn")
const TIMBER = preload("res://scenes/timber.tscn")
const GOAL = preload("res://scenes/goal.tscn")
const BOOST = preload("res://scenes/boost.tscn")
var ball: RigidBody2D
var goal: Area2D
var boost: Area2D
var shots = 0
var won = false
var paused = false
var aiming = false
var drag_start = Vector2.ZERO
var pull = Vector2.ZERO
var hud: Label
var message: Label
var power: ProgressBar
var panel: PanelContainer
var camera: Camera2D
var best = 0
const FLOOR = 628.13632

func pdf(x: float, y: float) -> Vector2:
	return Vector2(52 + (x-50)*1.6, 92 + (y-84)*1.6)

func _ready():
	var save = ConfigFile.new()
	if save.load("user://progress.cfg") == OK: best = save.get_value("level14", "best", 0)
	var background = Sprite2D.new()
	background.texture = preload("res://assets/park.webp")
	background.position = Vector2(640,360)
	background.scale = Vector2(1280.0/1672,720.0/941)
	add_child(background)
	camera = Camera2D.new()
	camera.position = Vector2(640,360)
	add_child(camera)
	var outline = PackedVector2Array([pdf(53.4429,419.0852),pdf(53.4429,282.2),pdf(120,215.3793),pdf(419.63,84.61),pdf(700.2021,351.8)])
	for i in range(outline.size()-1): beam(outline[i],outline[i+1],10.4)
	beam(Vector2(outline[0].x,FLOOR),Vector2(1226.44,FLOOR),10.4,true)
	var ramp = TIMBER.instantiate()
	add_child(ramp)
	ramp.setup(PackedVector2Array([pdf(370,419),pdf(490,345),pdf(490,419)]))
	var grass = Line2D.new()
	grass.points = PackedVector2Array([pdf(370,419),pdf(490,345)])
	grass.width = 7
	grass.default_color = Color("74ad38")
	add_child(grass)
	ball = BALL.instantiate()
	ball.position = Vector2(112,FLOOR-22)
	add_child(ball)
	boost = BOOST.instantiate()
	boost.ball = ball
	boost.position = Vector2(pdf(180,0).x+92,FLOOR-10)
	add_child(boost)
	goal = GOAL.instantiate()
	goal.ball = ball
	goal.position = Vector2(1091.0176,FLOOR)
	goal.scored.connect(complete)
	add_child(goal)
	beam(goal.position+Vector2(0,-107.66),goal.position+Vector2(79.54,-107.66),10.4,false,false)
	beam(goal.position+Vector2(79.54,-107.66),goal.position+Vector2(135.49,0),10.4,false,false)
	build_hud()
	refresh()

func beam(a: Vector2,b: Vector2,width: float,grass = false,visible_art = true):
	var body = TIMBER.instantiate()
	add_child(body)
	var n = (b-a).normalized().orthogonal()*width/2
	body.setup(PackedVector2Array([a+n,b+n,b-n,a-n]))
	if not visible_art:
		for child in body.get_children():
			if child is CanvasItem: child.hide()
	if grass:
		var edge = Line2D.new()
		edge.points = PackedVector2Array([a-Vector2(0,5),b-Vector2(0,5)])
		edge.width = 7
		edge.default_color = Color("73ad3e")
		add_child(edge)

func wood_style() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = preload("res://assets/wood.webp")
	style.set_content_margin_all(12)
	return style

func button(text: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(130,48)
	b.add_theme_font_size_override("font_size",20)
	b.add_theme_stylebox_override("normal",wood_style())
	b.add_theme_color_override("font_color",Color("fff1cf"))
	b.pressed.connect(action)
	return b

func build_hud():
	var layer = CanvasLayer.new()
	add_child(layer)
	var top = PanelContainer.new()
	top.position = Vector2(24,18)
	top.size = Vector2(1232,70)
	top.add_theme_stylebox_override("panel",wood_style())
	layer.add_child(top)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	top.add_child(row)
	hud = Label.new()
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_theme_font_size_override("font_size",24)
	hud.add_theme_color_override("font_color",Color("fff3cf"))
	row.add_child(hud)
	row.add_child(button("Restart",restart))
	row.add_child(button("Pause",toggle_pause))
	var tip = Label.new()
	tip.text = "GREEN RUNWAY   •   Drag back from the ball and release   •   Kick again in mid-flight"
	tip.position = Vector2(110,665)
	tip.add_theme_font_size_override("font_size",21)
	tip.add_theme_color_override("font_color",Color("fff5dc"))
	tip.add_theme_color_override("font_shadow_color",Color("26422b"))
	tip.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(tip)
	power = ProgressBar.new()
	power.position = Vector2(440,108)
	power.size = Vector2(400,14)
	power.show_percentage = false
	power.visible = false
	layer.add_child(power)
	panel = PanelContainer.new()
	panel.position = Vector2(390,225)
	panel.size = Vector2(500,230)
	panel.add_theme_stylebox_override("panel",wood_style())
	layer.add_child(panel)
	var column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",30)
	column.add_child(message)
	column.add_child(button("Continue / Play again",func():
		if won: restart()
		else: toggle_pause()))
	panel.hide()

func refresh():
	hud.text = "GOAL IN ONE   /   14     •     SHOTS %d     /     PAR 1     /     BEST %s" % [shots,str(best) if best else "—"]

func restart():
	get_tree().reload_current_scene()

func toggle_pause():
	if won: return
	paused = not paused
	ball.freeze = paused
	boost.set_physics_process(not paused)
	aiming = false
	power.hide()
	message.text = "HALF TIME
Ready for another shot?"
	panel.visible = paused
	queue_redraw()

func complete():
	if won or shots == 0: return
	won = true
	aiming = false
	power.hide()
	var stars = 3 if shots <= 1 else (2 if shots <= 3 else 1)
	best = shots if best == 0 else mini(best,shots)
	var save = ConfigFile.new()
	save.set_value("level14","best",best)
	save.save("user://progress.cfg")
	message.text = "GOAL!   " + "★".repeat(stars) + "☆".repeat(3-stars) + "
%d shots  •  Par 1" % shots
	panel.show()
	refresh()
	queue_redraw()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R: restart()
		if event.keycode == KEY_ESCAPE: toggle_pause()
	if paused or won: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_mouse_position().distance_to(ball.position) < 75:
			aiming = true
			drag_start = get_global_mouse_position()
			pull = Vector2.ZERO
			power.show()
		elif not event.pressed and aiming:
			aiming = false
			if ball.kick(pull): shots += 1
			power.hide()
			refresh()
	if event is InputEventMouseMotion and aiming:
		pull = (get_global_mouse_position()-drag_start).limit_length(140)
		power.value = pull.length()/140*100
	queue_redraw()

func _process(_dt):
	if aiming: queue_redraw()
	if ball.position.y > 900 and not paused:
		PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(112,FLOOR-22)))
		ball.linear_velocity = Vector2.ZERO

func _draw():
	if not aiming or not is_instance_valid(ball): return
	var pos = ball.position
	var velocity = ball.shot_velocity(pull)
	draw_line(pos,pos+pull,Color(1,1,1,0.7),3,true)
	for i in range(32):
		var next = pos + velocity * 0.025
		var query = PhysicsRayQueryParameters2D.create(pos,next,1,[ball.get_rid()])
		var hit = get_world_2d().direct_space_state.intersect_ray(query)
		if hit:
			pos = hit.position
			velocity = velocity.bounce(hit.normal)*0.76
		else: pos = next
		velocity.y += 1100 * 0.025
		velocity *= 0.99775
		draw_circle(pos,3.5,Color(1,0.95,0.65,1.0-i/36.0))
