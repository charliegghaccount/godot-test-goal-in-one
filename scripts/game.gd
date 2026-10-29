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
var best_stars = 0
var progress_path = "user://progress.cfg"
var flow: Node
var campaign = preload("res://scripts/campaign.gd").new()
var tools_panel: PanelContainer
var modal_root: Control
var mute_button: Button
var primary_action: Button
var replay_action: Button
var selection_action: Button
var level_selection: PanelContainer
var transition_pending = false
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
	campaign.progress_path = progress_path
	level_paths = discover_levels()
	if is_instance_valid(level_override):
		level = level_override
		if not level.scene_file_path.is_empty(): active_path = level.scene_file_path
	else:
		active_path = get_meta("level_path", active_path)
		if OS.has_feature("web") and not has_meta("level_path"):
			var requested = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('level') || ''"))
			var requested_path = "res://comparison/levels/L%02d.json"%int(requested) if requested.is_valid_int() else ""
			if requested_path in level_paths: active_path = requested_path
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
	if not studio_test and save.load(progress_path) == OK:
		best = save.get_value(level.level_id,"best",0)
		best_stars = campaign.rating(best,level.star_shots)
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
	sound.muted = not campaign.sound_enabled()
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
	paths = natural_order(paths)
	var comparison = PackedStringArray()
	for filename in ResourceLoader.list_directory("res://comparison/levels"):
		if filename.ends_with(".json"): comparison.append("res://comparison/levels/"+filename)
	comparison = natural_order(comparison)
	return comparison+paths

func natural_order(paths: PackedStringArray) -> PackedStringArray:
	var ordered = Array(paths)
	ordered.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	return PackedStringArray(ordered)

func load_level(path: String):
	if transition_pending or not path in level_paths: return
	transition_pending = true
	var next = load("res://scenes/main.tscn").instantiate()
	next.set_meta("level_path",path)
	next.studio_test = studio_test
	next.progress_path = progress_path
	next.flow = flow
	if is_instance_valid(flow): flow.game = next
	get_parent().add_child(next)
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

func build_hud():
	preload("res://scripts/ui/game_hud.gd").build(self)

func next_level_path() -> String:
	return "" if studio_test else campaign.next_path(active_path)

func primary_pressed():
	if not won: toggle_pause()
	elif studio_test: StudioBridge.return_to_editor()
	elif next_level_path().is_empty(): back_to_levels()
	else: load_level(next_level_path())

func back_to_levels():
	if studio_test:
		StudioBridge.return_to_editor()
		return
	if is_instance_valid(level_override): level_override.queue_free()
	if is_instance_valid(flow): flow.open_levels(active_path)
	else:
		var menu = load("res://scenes/menu.tscn").instantiate()
		menu.progress_path = progress_path
		get_parent().add_child(menu)
		menu.open_levels(active_path)
		queue_free()

func toggle_sound():
	sound.toggle()
	if not studio_test: campaign.set_sound(not sound.muted)
	mute_button.text = "OFF" if sound.muted else "SND"

func toggle_tools():
	tools_panel.visible = not tools_panel.visible
	aiming = false

func return_to_ball():
	exploring = false
	camera_drag = false
	frame_camera()
	explore_button.text = "EXPLORE / PAN"
	tools_panel.hide()

func zoom_camera(factor: float):
	exploring = true
	camera.zoom = (camera.zoom*factor).clamp(Vector2(0.3,0.3),Vector2(2,2))
	explore_button.text = "RETURN TO AIM"

func refresh():
	hud.text = "SHOTS %d  /  PAR %d" % [shots,level.par]
	mute_button.text = "OFF" if sound.muted else "SND"

func restart():
	if studio_test and not StudioBridge.last_json.is_empty():
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
	primary_action.text = "RESUME"
	replay_action.show()
	selection_action.show()
	tools_panel.hide()
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
	best_stars = campaign.rating(best,level.star_shots)
	if not studio_test:
		var error = campaign.record(level.level_id,shots,level.star_shots)
		if error!=OK: push_warning("Progress could not be saved: "+error_string(error))
	var heading = "GOAL IN ONE!" if shots==1 else ("GREAT GOAL!" if stars==3 else ("NICE FINISH!" if stars==2 else "LEVEL COMPLETE!"))
	message.text = "%s\nSHOTS %d  •  PAR %d"%[heading,shots,level.par]
	rating_view.visible = true
	rating_view.count = stars
	rating_view.queue_redraw()
	primary_action.text = "RETURN TO EDITOR" if studio_test else ("NEXT LEVEL" if not next_level_path().is_empty() else "ALL LEVELS")
	if next_level_path().is_empty() and not studio_test and campaign.index_of(active_path)>=0:
		message.text += "\nAll levels complete!"
	replay_action.show()
	selection_action.visible = not studio_test
	panel.show()
	tools_panel.hide()
	var reveal = create_tween()
	rating_view.modulate.a = 0.0
	reveal.tween_property(rating_view,"modulate:a",1.0,0.25)
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
			tools_panel.hide()
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
