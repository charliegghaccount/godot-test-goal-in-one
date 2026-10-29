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
		var screen = get_viewport_rect().size
		if not level.has_meta("studio_draft"):
			camera.zoom = Vector2.ONE*level.follow_zoom
			camera.position = bounded_camera(ball.position)
			return
		var minimum_scale = level.minimum_ball_diameter/32.0
		var width = minf(level.camera_view_size.x,minf(screen.x/minimum_scale,level.level_size.x))
		var height = minf(level.camera_view_size.y,minf(width*screen.y/screen.x,minf(screen.y/minimum_scale,level.level_size.y)))
		camera.zoom = Vector2.ONE*minf(screen.x/width,screen.y/height)
		var initial = level.camera_initial if level.custom_initial else ball.position
		camera.position = bounded_camera(initial+Vector2(width*0.15,-height*0.2))

func follow_target() -> Vector2:
	var extent = get_viewport_rect().size/camera.zoom
	var target = camera.position
	var look = ball.position+Vector2(clampf(ball.linear_velocity.x/12,-extent.x*0.09,extent.x*0.09),clampf(ball.linear_velocity.y/12,-extent.y*0.09,extent.y*0.09))
	var half_dead = level.camera_dead_zone.clamp(Vector2(0.08,0.08),Vector2(0.6,0.6))/2
	target.x += look.x-clampf(look.x,camera.position.x-extent.x*(half_dead.x+0.02),camera.position.x+extent.x*(half_dead.x-0.02))
	if level.follow_vertical: target.y += look.y-clampf(look.y,camera.position.y-extent.y*half_dead.y,camera.position.y+extent.y*half_dead.y)
	var safe = minf(52/camera.zoom.x,extent.y*0.17)
	target.y = clampf(target.y,ball.position.y-extent.y/2+safe,ball.position.y+extent.y/2-safe)
	return bounded_camera(target)

func bounded_camera(at: Vector2) -> Vector2:
	var half = get_viewport_rect().size / camera.zoom / 2
	var size = level.level_size
	var origin = level.camera_origin
	return Vector2(origin.x+size.x/2 if size.x<half.x*2 else clampf(at.x,origin.x+half.x,origin.x+size.x-half.x),origin.y+size.y/2 if size.y<half.y*2 else clampf(at.y,origin.y+half.y,origin.y+size.y-half.y))

func reset_ball():
	trail.clear()
	if won:
		restart()
		return
	aiming = false
	scoring = false
	score_time = 0
	ball.net_capture = false
	ball.ice_contacts.clear()
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
	mute_button.icon = preload("res://scripts/ui/timber_ui.gd").icon("mute" if sound.muted else "sound")

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
	mute_button.icon = preload("res://scripts/ui/timber_ui.gd").icon("mute" if sound.muted else "sound")

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
	mechanic_feedback("win",ball.position)
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
		camera.position = camera.position.lerp(follow_target(),1-exp(-dt*level.camera_speed))
	elif level.camera_mode == 0 and not exploring: frame_camera()
	if ball.linear_velocity.length()>100:
		trail.append(ball.position)
		if trail.size()>13: trail.remove_at(0)
	elif not trail.is_empty(): trail.remove_at(0)
	queue_redraw()
	if ball.position.y > level.camera_origin.y+level.level_size.y+150 and not paused: reset_ball()

func aim_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	var pos = ball.position
	var velocity = ball.shot_velocity(pull)
	for i in 50:
		velocity *= 0.9985
		velocity.y += level.gravity/60.0
		pos += velocity/60.0
		if i%3==0: points.append(pos)
	return points

func goal_indicator() -> Dictionary:
	if not is_instance_valid(goal) or not is_instance_valid(camera): return {}
	var screen = get_viewport_rect().size
	var content = screen
	if level.camera_mode==0: content = level.level_size*minf(screen.x/level.level_size.x,screen.y/level.level_size.y)
	var rect = Rect2((screen-content)/2,content)
	var target = goal.get_global_transform_with_canvas()*Vector2(0,-goal.goal_size.y/2)
	if rect.has_point(target): return {}
	var margin = minf(40,content.y/5)
	var point = target.clamp(rect.position+Vector2.ONE*margin,rect.end-Vector2.ONE*margin)
	return {"point":point,"angle":(target-point).angle()}

func draw_goal_indicator():
	var indicator = goal_indicator()
	if indicator.is_empty(): return
	var at = get_global_transform_with_canvas().affine_inverse()*indicator.point
	draw_set_transform(at,0,Vector2.ONE/camera.zoom.x)
	draw_circle(Vector2.ZERO,19,Color("174c39ee"))
	var axis = Vector2.from_angle(indicator.angle)
	draw_line(-axis*8,axis*8,Color("dcffb0"),3,true)
	draw_polyline(PackedVector2Array([axis*2-axis.orthogonal()*6,axis*8,axis*2+axis.orthogonal()*6]),Color("dcffb0"),3,true)
	draw_string(ThemeDB.fallback_font,Vector2(-24,-25),"GOAL",HORIZONTAL_ALIGNMENT_CENTER,48,10,Color("174c39"))
	draw_set_transform(Vector2.ZERO)

func _draw():
	draw_goal_indicator()
	for i in trail.size(): draw_circle(trail[i],2,Color(0.36,0.51,0.47,float(i)/trail.size()*0.25))
	if not is_instance_valid(ball): return
	if not aiming or pull.length()<6:
		if not won and not scoring: draw_arc(ball.position,25,0,TAU,48,Color("1d827e55"),1.8,true)
		return
	var points = aim_points()
	for i in points.size():
		var fraction = float(i)/points.size()
		draw_circle(points[i],3.7-fraction*2,Color(1,1,1,(1-fraction)*0.95))
	var b = ball.position
	var ratio = minf(1,140/maxf(pull.length(),1))
	draw_dashed_line(b,b+pull*ratio,Color("163b5b66"),2,5)
	var axis = -pull.normalized()
	var end = b+axis*(minf(90,pull.length())*0.7+20)
	draw_line(b+axis*20,end,Color("edff74"),5,true)
	draw_polyline(PackedVector2Array([end-axis.rotated(-0.5)*11,end,end-axis.rotated(0.5)*11]),Color("edff74"),5,true)
	draw_arc(b,23,-PI/2,-PI/2+TAU*minf(1,pull.length()/140),48,Color("edff74"),3,true)
	draw_circle(b+pull*ratio,5,Color.WHITE)
	var font = ThemeDB.fallback_font
	var text = "%d%% POWER"%roundi(minf(1,pull.length()/140)*100)
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+24
	draw_style_box(preload("res://scripts/ui/timber_ui.gd").box(Color("17364c"),Color("17364c")),Rect2(b+Vector2(-width/2,-75),Vector2(width,26)))
	draw_string(font,b+Vector2(-width/2,-58),text,HORIZONTAL_ALIGNMENT_CENTER,width,10,Color("edff74"))

func mechanic_feedback(kind: String, at: Vector2):
	var particles = preload("res://scripts/feedback_particles.gd").new()
	particles.position = at
	particles.setup(kind)
	add_child(particles)
	if is_instance_valid(sound): sound.effect(kind)
