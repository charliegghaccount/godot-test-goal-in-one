extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var results = []
	for data in JSON.parse_string(FileAccess.get_file_as_string("res://comparison/cases.json")):
		var world = Node2D.new()
		root.add_child(world)
		var floor = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(30000,10.4)
		shape.position = Vector2(5000,1000)
		floor.add_child(shape)
		var material = PhysicsMaterial.new()
		material.friction = 0.003
		floor.physics_material_override = material
		world.add_child(floor)
		var ball = load("res://scenes/ball.tscn").instantiate()
		ball.position = Vector2(200,978.8 if data.rolling else 800)
		world.add_child(ball)
		if data.rolling: ball.linear_velocity = Vector2(420,0)
		else: ball.kick(-Vector2.from_angle(deg_to_rad(data.angle))*data.power)
		var trace = []
		for i in 1200:
			if data.second and i==72: ball.kick(Vector2(100,-30))
			await physics_frame
			trace.append([ball.position.x,ball.position.y,ball.linear_velocity.x,ball.linear_velocity.y])
		results.append({"name":data.name,"trace":trace})
		world.queue_free()
		await process_frame
	var file = FileAccess.open("res://comparison/traces/godot.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results))
	quit()
