extends SceneTree
var failures = 0
var checks = 0
var game: Node
var ball: RigidBody2D

func check(ok: bool, label: String):
	checks += 1
	if ok: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)

func _initialize():
	call_deferred("run")

func ticks(count: int):
	for i in count: await physics_frame

func place(at: Vector2, velocity = Vector2.ZERO):
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,at))
	ball.linear_velocity = velocity
	ball.sleeping = false

func add_mechanic(scene: String, at: Vector2) -> Node2D:
	var object = load("res://scenes/"+scene+".tscn").instantiate()
	object.position = at
	game.level.add_child(object)
	object.bind_game(game)
	return object

func roundtrip(scene: String, properties: Dictionary):
	var object = load("res://scenes/"+scene+".tscn").instantiate()
	for key in properties: object.set(key,properties[key])
	var packed = PackedScene.new()
	check(packed.pack(object)==OK,"pack "+scene)
	var path = "user://mechanic_"+scene+".tscn"
	check(ResourceSaver.save(packed,path)==OK,"save "+scene)
	var saved = load(path).instantiate()
	for key in properties:
		var expected = properties[key]
		var actual = saved.get(key)
		var same = is_equal_approx(actual,expected) if expected is float else actual==expected
		check(same,"reopen "+scene+" / "+key)
	saved.free()
	object.free()

func run():
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("level_path","res://levels/starter.tscn")
	root.add_child(game)
	await ticks(2)
	ball = game.ball
	var pad = add_mechanic("boost",Vector2(400,570))
	pad.acceleration = 6000
	place(Vector2(400,570))
	await ticks(8)
	check(pad.active and ball.linear_velocity.x > 100,"forward pad activates physically")
	check(pad.sensor.shape.size == pad.dimensions,"boost sensor matches Inspector dimensions")
	pad.queue_free()
	await ticks(2)
	pad = add_mechanic("backward_boost",Vector2(400,570))
	place(Vector2(400,570))
	await ticks(8)
	check(ball.linear_velocity.x < -100,"backward pad accelerates left")
	pad.rotation = PI/2
	place(Vector2(400,570))
	await ticks(4)
	check(ball.linear_velocity.y < 0,"rotated boost accelerates along local direction")
	pad.queue_free()
	await ticks(2)
	var spring = add_mechanic("spring",Vector2(400,570))
	spring.launch_speed = 1300
	place(Vector2(400,570))
	await ticks(4)
	check(ball.linear_velocity.y < -1100,"spring launches on actual contact")
	check(spring.compression > 0 and spring.cooldown > 0,"spring activated/compressed state")
	var cooldown = spring.cooldown
	spring.activate()
	check(spring.cooldown == cooldown,"spring debounce ignores repeated activation")
	place(Vector2(650,350))
	await ticks(35)
	check(spring.compression == 0,"spring returns to extended state")
	spring.rotation = PI/2
	place(Vector2(400,570))
	await ticks(4)
	check(ball.linear_velocity.x > 1100,"spring launch orientation follows rotation")
	spring.queue_free()
	await ticks(2)
	var fan = add_mechanic("fan",Vector2(400,600))
	fan.airflow_acceleration = 5000
	place(Vector2(400,500))
	await ticks(15)
	check(fan.active and ball.linear_velocity.y < -100,"updraft overcomes gravity in range")
	check(fan.sensor.shape.size.y == fan.airflow_range+fan.dimensions.y,"fan sensor matches range plus housing")
	fan.rotation = PI/2
	place(Vector2(500,600))
	await ticks(10)
	check(ball.linear_velocity.x > 100,"fan rotated airflow pushes right")
	place(Vector2(200,300))
	await ticks(4)
	check(not fan.active,"fan stops applying airflow outside range")
	fan.queue_free()
	await ticks(2)
	var hazard = add_mechanic("reset_pad",Vector2(500,570))
	game.shots = 4
	place(Vector2(500,570))
	await ticks(8)
	check(ball.position.distance_to(game.spawn_point) < 20,"red pad resets ball to level spawn")
	check(game.shots == 4,"red reset preserves shots")
	check(hazard.cooldown > 0 and hazard.flash > 0,"red pad feedback and cooldown")
	place(Vector2(500,570))
	await ticks(4)
	check(ball.position.x > 450,"red pad ignores immediate retrigger")
	hazard.queue_free()
	await ticks(2)
	var gate = add_mechanic("gate",Vector2(700,520))
	gate.name = "TestGate"
	gate.movement_speed = 240
	gate.travel_distance = 120
	var switch = add_mechanic("pressure_switch",Vector2(400,610))
	switch.linked_gate = switch.get_path_to(gate)
	place(Vector2(400,600))
	await ticks(10)
	check(switch.active and gate.target_open,"physical switch contact opens linked gate")
	check(gate.progress > 0 and gate.position.y < 520,"linked gate moves along configured track")
	check(switch.pressed_amount > 0,"switch pressed animation")
	var progress = gate.progress
	game.toggle_pause()
	await ticks(12)
	check(gate.progress == progress,"pause freezes moving mechanisms")
	game.toggle_pause()
	place(Vector2(200,350))
	await ticks(80)
	check(gate.progress == 1,"gate reaches exact open endpoint")
	place(Vector2(400,600))
	await ticks(8)
	check(not gate.target_open,"toggle switch reverses target on next contact")
	place(Vector2(200,350))
	await ticks(80)
	switch.activation_mode = 1
	switch.open_seconds = 0.25
	place(Vector2(400,600))
	await ticks(6)
	check(gate.target_open,"timed switch opens gate")
	await ticks(40)
	check(not gate.target_open,"timed switch closes after expiry")
	place(Vector2(200,350))
	await ticks(10)
	switch.activation_mode = 2
	place(Vector2(400,600))
	await ticks(6)
	check(gate.target_open,"hold switch opens while pressed")
	place(Vector2(200,350))
	await ticks(6)
	check(not gate.target_open,"hold switch closes on release")
	switch.queue_free()
	gate.queue_free()
	await ticks(3)
	gate = add_mechanic("gate",Vector2(700,500))
	gate.movement_direction = Vector2.RIGHT
	gate.travel_distance = 100
	gate.movement_speed = 600
	gate.set_open(true)
	place(Vector2(750,500))
	await ticks(10)
	check(gate.progress < 0.2,"gate sweep stops before crushing football")
	place(Vector2(200,350))
	await ticks(35)
	check(gate.progress == 1,"gate resumes once path is clear")
	gate.automatic = true
	gate.endpoint_wait = 0.05
	await ticks(70)
	check(gate.progress < 1,"automatic gate cycles without a switch")
	check(gate.collision.shape.size == gate.dimensions,"gate collision matches visible dimensions")
	gate.queue_free()
	await ticks(2)
	# Real boost→spring interaction in the authored demo, not a direct callback.
	var runway = add_mechanic("boost",Vector2(350,610))
	runway.dimensions = Vector2(180,30)
	var launcher = add_mechanic("spring",Vector2(480,610))
	place(Vector2(290,604),Vector2(150,0))
	var launched = false
	for i in range(90):
		await physics_frame
		if ball.linear_velocity.y < -800: launched = true
	check(launched,"boost carries ball into spring and launches it")
	runway.queue_free()
	launcher.queue_free()
	# Serialize exported Inspector settings for every reusable scene.
	roundtrip("boost",{"direction":Vector2(0,-1),"dimensions":Vector2(210,18),"acceleration":3300.0,"maximum_speed":900.0})
	roundtrip("backward_boost",{"direction":Vector2.LEFT,"acceleration":2800.0})
	roundtrip("spring",{"launch_speed":1350.0,"momentum_retention":0.3,"rotation":0.4,"dimensions":Vector2(140,42)})
	roundtrip("fan",{"airflow_range":410.0,"airflow_acceleration":2800.0,"rotation":-0.3,"dimensions":Vector2(110,40)})
	roundtrip("reset_pad",{"cooldown_seconds":0.8,"dimensions":Vector2(190,18)})
	roundtrip("pressure_switch",{"linked_gate":NodePath("../MyGate"),"activation_mode":1,"open_seconds":4.0,"dimensions":Vector2(100,18)})
	roundtrip("gate",{"dimensions":Vector2(45,210),"movement_direction":Vector2.LEFT,"travel_distance":220.0,"movement_speed":180.0,"automatic":true,"endpoint_wait":0.3})
	var demo = load("res://levels/experiment_switch_gate.tscn").instantiate()
	var scene = PackedScene.new()
	check(scene.pack(demo)==OK,"pack linked demonstration level")
	check(ResourceSaver.save(scene,"user://linked_demo.tscn")==OK,"save linked demonstration level")
	var restored = load("user://linked_demo.tscn").instantiate()
	check(restored.get_node("FloorSwitch").gate()==restored.get_node("Gate"),"switch resolves gate after whole-level save/reopen")
	var duplicate = restored.duplicate()
	check(duplicate.get_node("FloorSwitch").gate()==duplicate.get_node("Gate"),"duplicate level links to its own gate")
	duplicate.free()
	restored.free()
	demo.free()
	game.queue_free()
	await process_frame
	print("MECHANICS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
