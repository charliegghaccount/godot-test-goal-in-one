extends SceneTree
var failures = 0
var checks = 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
	else: print("PASS: ",label)
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("level_path","res://levels/green_runway.tscn")
	root.add_child(game)
	await physics_frame
	var ball = game.ball
	check(ball.kick(Vector2(-140,0)),"full kick accepted")
	check(absf(ball.linear_velocity.x-1050)<1,"Matter velocity conversion")
	check(ball.kick(Vector2(100,0)),"moving ball can kick again")
	check(ball.linear_velocity.x < 0,"opposing momentum projection clamp")
	check(not ball.kick(Vector2(2,0)),"small drag ignored")
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(112,570)))
	ball.linear_velocity = Vector2.ZERO
	for i in range(120): await physics_frame
	check(ball.position.y < 620 and ball.position.y > 520,"floor collision and bounce retain ball")
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(340,609)))
	ball.linear_velocity = Vector2.ZERO
	for i in range(20): await physics_frame
	check(ball.linear_velocity.x > 100,"green runway accelerates ball")
	game.toggle_pause()
	check(ball.freeze and game.paused,"pause freezes gameplay")
	game.toggle_pause()
	check(not ball.freeze,"resume releases ball")
	game.shots = 2
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(1060,580)))
	ball.linear_velocity = Vector2(500,0)
	for i in range(115): await physics_frame
	check(game.won,"physical goal entry completes level")
	check(game.best > 0,"best score saved")
	# Anywhere aiming, dead zone, screen pan separation.
	game.won = false
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(700,300)
	game._unhandled_input(press)
	check(game.aiming,"aim starts far from football")
	var move = InputEventMouseMotion.new()
	move.position = Vector2(600,350)
	game._unhandled_input(move)
	var release = press.duplicate()
	release.pressed = false
	var before_shots = game.shots
	game._unhandled_input(release)
	check(game.shots == before_shots+1,"anywhere release records kick")
	game.toggle_explore()
	game._unhandled_input(press)
	game._unhandled_input(move)
	game._unhandled_input(release)
	check(not game.aiming and game.shots == before_shots+1,"explore drag never shoots")
	game.toggle_explore()
	var ids = []
	for path in game.discover_levels():
		if path.ends_with(".json"): continue
		var level = preload("res://scripts/studio_import.gd").new().parse(FileAccess.get_file_as_string(path)).level if path.ends_with(".json") else load(path).instantiate()
		game.add_child(level)
		check(not level.level_id in ids,"unique stable ID")
		ids.append(level.level_id)
		check(level.problems().is_empty(),"valid level: "+path)
		for object in level.find_children("*", "Polygon2D",true,false):
			check(object.polygon == object.collision.polygon,"visual/collision vertices: "+str(object.name))
			check(object.global_transform == object.collision.global_transform,"visual/collision transforms: "+str(object.name))
		level.get_node("Goal").goal_size = Vector2(220,180)
		var g = level.get_node("Goal")
		check(g.valid_crossing(Vector2(-20,-80),Vector2(40,-80)),"resized goal accepts forward crossing")
		check(not g.valid_crossing(Vector2(40,-80),Vector2(-20,-80)),"goal rejects reverse crossing")
		check(not g.valid_crossing(Vector2(-20,-2),Vector2(40,-2)),"goal rejects clipped crossing")
		check(g.frame_body.get_child_count()==3,"goal has exactly three physical bars")
		var packed = PackedScene.new()
		check(packed.pack(level)==OK,"pack editable level")
		check(ResourceSaver.save(packed,"user://roundtrip.tscn")==OK,"save editable level")
		var reopened = load("user://roundtrip.tscn").instantiate()
		check(reopened.level_id == level.level_id and reopened.get_node("Goal").goal_size==Vector2(220,180),"reopen retains identity and goal edits")
		reopened.free()
		level.queue_free()
	# Validate transformed goal coordinates and both horizontal/vertical camera bounds.
	game.goal.position = Vector2(900,500)
	game.goal.rotation = 0.15
	var world = game.goal.to_global(Vector2(40,-70))
	check(game.goal.to_local(world).is_equal_approx(Vector2(40,-70)),"goal coordinates follow transform")
	game.level.level_size = Vector2(2100,1100)
	check(game.bounded_camera(Vector2(9999,9999)).x < 2100 and game.bounded_camera(Vector2(9999,9999)).y < 1100,"camera clamps both axes")
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
