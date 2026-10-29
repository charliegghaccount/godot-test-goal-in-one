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
var scoring = false
var sound: Node
var trail = PackedVector2Array()
var score_time = 0.0
var paused = false
var aiming = false
var drag_start = Vector2.ZERO
var pull = Vector2.ZERO
var hud: Label
var message: Label
var rating_view: Control
var panel: PanelContainer
var camera: Camera2D
var best = 0
var studio_test = false
const FLOOR = 628.13632

var level_override: Node2D
var level: Node2D
var level_paths: PackedStringArray = []
var level_picker: OptionButton
var exploring = false
var explore_button: Button
var controls_hint: Label
var camera_drag = false
var spawn_point = Vector2.ZERO
var active_path = "res://comparison/levels/L01.json"

func _ready():
	if StudioBridge.active and not studio_test:
		StudioBridge.waiting(self)
		return
	level_paths = discover_levels()
	if is_instance_valid(level_override):
		level = level_override
		if not level.scene_file_path.is_empty(): active_path = level.scene_file_path
	else:
		active_path = get_meta("level_path", active_path)
		if OS.has_feature("web") and not has_meta("level_path"):
			var requested = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('level') || ''"))
			if requested.is_valid_int() and int(requested)>=1 and int(requested)<=20: active_path="res://comparison/levels/L%02d.json"%int(requested)
		if active_path.ends_with(".json"):
			var result = preload("res://scripts/studio_import.gd").new().parse(FileAccess.get_file_as_string(active_path))
			if not result.errors.is_empty(): push_error(str(result.errors)); return
			level = result.level
		else: level = load(active_path).instantiate()
		add_child(level)
	var errors = level.problems()
	if not errors.is_empty():
		push_error("Invalid level: " + str(errors))
		return
	spawn_point = level.get_node("Spawn").global_position
	var save = ConfigFile.new()
	if not studio_test and save.load("user://progress.cfg") == OK: best = save.get_value(level.level_id,"best",0)
	camera = Camera2D.new()
	add_child(camera)
	ball = BALL.instantiate()
	ball.position = spawn_point
	ball.gravity_scale = level.gravity/1100.0
	add_child(ball)
	goal = level.get_node("Goal")
	goal.ball = ball
	goal.scored.connect(begin_scoring)
	for object in level.find_children("*", "Node2D", true, false):
		if object.has_method("bind_game"):
			object.bind_game(self)
			if object.get_script() == preload("res://scripts/boost.gd"): boost = object
	sound = preload("res://scripts/game_audio.gd").new()
	add_child(sound)
	ball.hit.connect(func(): mechanic_feedback("hit",ball.position))
	ball.kicked.connect(func(): mechanic_feedback("shot",ball.position))
	build_hud()
	frame_camera()
	var backdrop = CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var park = preload("res://scripts/park_background.gd").new()
	park.camera = camera
	park.reference = camera.position
	backdrop.add_child(park)
	refresh()

func discover_levels() -> PackedStringArray:
	var paths = PackedStringArray()
	for filename in ResourceLoader.list_directory("res://levels"):
		if filename.ends_with(".tscn"): paths.append("res://levels/"+filename)
	paths.sort()
	var comparison = PackedStringArray()
	for filename in ResourceLoader.list_directory("res://comparison/levels"):
		if filename.ends_with(".json"): comparison.append("res://comparison/levels/"+filename)
	comparison.sort()
	return comparison+paths

func load_level(path: String):
	var next = load("res://scenes/main.tscn").instantiate()
	next.set_meta("level_path",path)
	get_tree().root.add_child(next)
	if is_instance_valid(level_override): level_override.queue_free()
	queue_free()

func frame_camera():
	if level.camera_mode == 0:
		var screen = get_viewport_rect().size
		camera.zoom = Vector2.ONE * minf(screen.x/level.level_size.x,screen.y/level.level_size.y)
		camera.position = level.camera_origin+level.level_size/2
	else:
		camera.zoom = Vector2.ONE * level.follow_zoom
		camera.position = bounded_camera(ball.position)

func bounded_camera(at: Vector2) -> Vector2:
	var half = get_viewport_rect().size / camera.zoom / 2
	var size = level.level_size
	var origin = level.camera_origin
	if not level.follow_vertical: at.y = spawn_point.y
	return Vector2(origin.x+size.x/2 if size.x<half.x*2 else clampf(at.x,origin.x+half.x,origin.x+size.x-half.x),origin.y+size.y/2 if size.y<half.y*2 else clampf(at.y,origin.y+half.y,origin.y+size.y-half.y))

func reset_ball():
	if won:
		restart()
		return
	aiming = false
	scoring = false
	score_time = 0
	ball.net_capture = false
	goal.scored_once = false
	for object in level.find_children("*", "Area2D", true, false):
		if object.has_method("reset_contact"): object.reset_contact()
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,spawn_point))
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.sleeping = false
	goal.initialized = false
	queue_redraw()

func toggle_explore():
	exploring = not exploring
	aiming = false
	camera_drag = false
	explore_button.text = "Return" if exploring else "Explore"
	controls_hint.text = "EXPLORE • Drag to pan • Wheel to zoom • Return to aim" if exploring else "Drag anywhere to kick • Explore: drag to pan / wheel to zoom • R restart"
	if not exploring: frame_camera()
	queue_redraw()

func wood_style() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = preload("res://assets/wood.webp")
	style.set_content_margin_all(12)
	return style

func button(text: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(90,48)
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
	row.add_theme_constant_override("separation",10)
	top.add_child(row)
	hud = Label.new()
	hud.clip_text = true
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_theme_font_size_override("font_size",19)
	hud.add_theme_color_override("font_color",Color("fff3cf"))
	row.add_child(hud)
	if studio_test: row.add_child(button("Return",StudioBridge.return_to_editor))
	row.add_child(button("Restart",restart))
	row.add_child(button("Pause",toggle_pause))
	var mute = button("Mute",func(): sound.toggle())
	mute.pressed.connect(func(): mute.text="Sound off" if sound.muted else "Mute")
	row.add_child(mute)
	row.add_child(button("Reset ball",reset_ball))
	explore_button = button("Explore",toggle_explore)
	row.add_child(explore_button)
	level_picker = OptionButton.new()
	level_picker.custom_minimum_size = Vector2(190,42)
	level_picker.fit_to_longest_item = false
	level_picker.clip_text = true
	level_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	level_picker.position = Vector2(24,660)
	for path in level_paths:
		level_picker.add_item(path.get_file().get_basename().capitalize())
		if path == active_path: level_picker.select(level_picker.item_count-1)
	level_picker.item_selected.connect(func(index): load_level(level_paths[index]))
	layer.add_child(level_picker)
	level_picker.visible = not studio_test
	var tip = Label.new()
	controls_hint = tip
	tip.text = "Drag anywhere to kick • Explore: drag to pan / wheel to zoom • R restart"
	tip.position = Vector2(235,668)
	tip.add_theme_font_size_override("font_size",19)
	tip.add_theme_color_override("font_color",Color("fff5dc"))
	tip.add_theme_color_override("font_shadow_color",Color("26422b"))
	tip.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(tip)
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
	rating_view = preload("res://scripts/rating_stars.gd").new()
	rating_view.custom_minimum_size = Vector2(0,55)
	column.add_child(rating_view)
	column.add_child(button("Continue / Play again",func():
		if won: restart()
		else: toggle_pause()))
	panel.hide()

func refresh():
	hud.text = "%s   •   SHOTS %d   /   PAR %d   /   BEST %s" % [level.level_name,shots,level.par,str(best) if best else "—"]

func restart():
	if studio_test:
		StudioBridge.receive([StudioBridge.last_json])
		return
	load_level(active_path)

func toggle_pause():
	if won: return
	paused = not paused
	ball.freeze = paused
	goal.set_physics_process(not paused)
	# Stop actuators, never remove CollisionObject2D bodies from the physics world.
	for object in level.find_children("*","Node2D",true,false):
		if object.has_method("bind_game"): object.set_physics_process(not paused)
	aiming = false
	message.text = "HALF TIME
Ready for another shot?"
	rating_view.visible = false
	panel.visible = paused
	queue_redraw()

func begin_scoring():
	if won or scoring or shots==0: return
	scoring = true
	score_time = 0
	aiming = false
	ball.net_capture = true
	mechanic_feedback("net",ball.position)

func _physics_process(dt):
	if scoring and not paused:
		score_time += dt
		if score_time >= 0.65:
			scoring = false
			complete()

func complete():
	if won or shots == 0: return
	won = true
	# Stop actuators, never remove CollisionObject2D bodies from the physics world.
	for object in level.find_children("*","Node2D",true,false):
		if object.has_method("bind_game"): object.set_physics_process(false)
	aiming = false
	var stars = 3 if shots <= level.star_shots.x else (2 if shots <= level.star_shots.y else 1)
	best = shots if best == 0 else mini(best,shots)
	var save = ConfigFile.new()
	save.set_value(level.level_id,"best",best)
	if not studio_test: save.save("user://progress.cfg")
	message.text = ("GOAL IN ONE!   " if shots==1 else "GOAL!   ") + "
%d %s  •  Par %d" % [shots,"shot" if shots==1 else "shots",level.par]
	rating_view.visible = true
	rating_view.count = stars
	rating_view.queue_redraw()
	panel.show()
	sound.announce(shots,level.par,level.star_shots)
	refresh()
	queue_redraw()

func _input(event):
	# Finish a drag even if the pointer crosses a HUD control before release.
	if event is InputEventMouseMotion and aiming:
		pull = ((event.position-drag_start)/get_viewport_rect().size.y*720).limit_length(140)
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		camera_drag = false
		if aiming and not paused and not won and not scoring:
			aiming = false
			if ball.kick(pull): shots += 1
			refresh()
			queue_redraw()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R: restart()
		if event.keycode == KEY_ESCAPE: toggle_pause()
		if event.keycode == KEY_E: toggle_explore()
	if paused or won or scoring: return
	if exploring:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: camera_drag = event.pressed
			if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
				camera.zoom = (camera.zoom * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9)).clamp(Vector2(0.3,0.3),Vector2(2,2))
		if event is InputEventMouseMotion and camera_drag:
			camera.position = bounded_camera(camera.position-event.relative/camera.zoom)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			aiming = true
			drag_start = event.position
			pull = Vector2.ZERO
		elif aiming:
			aiming = false
			if ball.kick(pull): shots += 1
			refresh()
	if event is InputEventMouseMotion and aiming:
		# Screen-space pull remains consistent even while the camera follows the ball.
		pull = ((event.position-drag_start)/get_viewport_rect().size.y*720).limit_length(140)
	queue_redraw()

func _process(dt):
	if not is_instance_valid(ball): return
	if level.camera_mode == 1 and not exploring:
		camera.position = camera.position.lerp(bounded_camera(ball.position),1-exp(-dt*level.camera_speed))
	elif level.camera_mode == 0 and not exploring: frame_camera()
	if ball.linear_velocity.length()>100:
		trail.append(ball.position)
		if trail.size()>18: trail.remove_at(0)
	elif not trail.is_empty(): trail.remove_at(0)
	queue_redraw()
	if ball.position.y > level.camera_origin.y+level.level_size.y+150 and not paused: reset_ball()

func _draw():
	for i in range(1,trail.size()):
		draw_line(trail[i-1],trail[i],Color(1,1,1,float(i)/trail.size()*0.18),3,true)
	if not aiming or not is_instance_valid(ball) or pull.length()<6: return
	var pos = ball.position
	var velocity = ball.shot_velocity(pull)
	var space = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = 16
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.exclude = [ball.get_rid()]
	query.collision_mask = 1
	var spacing = 14.0/camera.zoom.x
	var next_dot = spacing
	var distance = 0.0
	var dots = 0
	for i in range(100):
		var before = pos
		var step = velocity / 120.0
		query.transform = Transform2D(0,pos)
		query.motion = step
		var fraction = space.cast_motion(query)
		if fraction[0] < 1.0:
			pos += step*fraction[0]
			query.transform.origin = before+step*fraction[1]
			query.motion = Vector2.ZERO
			var rest = space.get_rest_info(query)
			if rest.is_empty(): break
			velocity = velocity.bounce(rest.normal)*0.76
			pos += rest.normal*0.3
		else: pos += step
		var length = before.distance_to(pos)
		while distance+length>=next_dot and dots<50:
			var at = before.lerp(pos,(next_dot-distance)/maxf(length,0.001))
			draw_circle(at,2.7/camera.zoom.x,Color(1,0.97,0.75,0.85*(1.0-dots/52.0)))
			next_dot += spacing
			dots += 1
		distance += length
		velocity *= 0.99925
		velocity.y += level.gravity/120.0
		if dots>=50: break

func mechanic_feedback(kind: String, at: Vector2):
	var ring = Node2D.new()
	ring.position = at
	add_child(ring)
	var circle = Line2D.new()
	circle.width = 3
	circle.default_color = Color("ff6b67") if kind == "reset" else Color("fff0a1")
	for i in range(33): circle.add_point(Vector2.from_angle(i*TAU/32)*24)
	ring.add_child(circle)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ring,"scale",Vector2(2,2),0.35)
	tween.tween_property(ring,"modulate:a",0.0,0.35)
	tween.chain().tween_callback(ring.queue_free)
	if is_instance_valid(sound): sound.effect(kind)
