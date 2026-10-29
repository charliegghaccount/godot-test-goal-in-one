extends SceneTree
var failures = 0
var checks = 0
func check(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize(): call_deferred("run")
func run():
	for speed in [60.0,120.0,420.0]:
		var world = Node2D.new()
		root.add_child(world)
		var floor_body = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(10000,10.4)
		shape.position = Vector2(2000,1000)
		floor_body.add_child(shape)
		var material = PhysicsMaterial.new()
		material.friction = 0.003
		floor_body.physics_material_override = material
		world.add_child(floor_body)
		var ball = load("res://scenes/ball.tscn").instantiate()
		ball.position = Vector2(200,978.8)
		world.add_child(ball)
		ball.linear_velocity = Vector2(speed,0)
		var distance_at_one = 0.0
		for i in 1200:
			await physics_frame
			if i==119: distance_at_one = ball.position.x-200
			if i==359: check(absf(ball.linear_velocity.x)<8.4,"slow rolling reaches reference rest threshold by 3 seconds")
		var travel = ball.position.x-200
		check(travel>0,"rolling moves forward")
		check(absf(ball.linear_velocity.x)<0.1,"rolling settles without persistent creep")
		if speed==420:
			check(absf(travel-617.34)<61.734,"rolling travel within 10 percent of recorded TypeScript reference")
			check(absf(distance_at_one-376.85)<20,"initial low-friction travel preserved")
		else: check(travel<speed,"low-speed ball stops within one second of initial-speed distance")
		check(ball.kick(Vector2(-80,60)),"settled ball accepts new shot")
		await physics_frame
		check(ball.linear_velocity.y < -400,"ground support does not suppress upward kicks")
		world.queue_free()
		await process_frame
	print("ROLLING RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
