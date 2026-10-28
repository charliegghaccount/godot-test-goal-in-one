extends SceneTree
var failures = 0
func check(ok: bool, label: String):
	if not ok:
		failures += 1
		push_error(label)
	else: print("PASS: ",label)
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
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
	for i in range(30): await physics_frame
	check(game.won,"physical goal entry completes level")
	check(game.best > 0,"best score saved")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
