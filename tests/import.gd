extends SceneTree
var checks = 0
var failures = 0
func check(ok,label):
	checks+=1
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func _initialize(): call_deferred("run")
func run():
	var parser = preload("res://scripts/studio_import.gd").new()
	for name in ["basic","mechanics","wide"]:
		var text = FileAccess.get_file_as_string("res://tests/fixtures/"+name+".json")
		var result = parser.parse(text)
		check(result.errors.is_empty(),name+" imports: "+str(result.errors))
		if not result.has("level"):continue
		var holder = Node.new()
		root.add_child(holder)
		var level = result.level
		holder.add_child(level)
		check(level.get_node("Spawn").position == Vector2(130,618),"exact spawn")
		check(level.get_node("Goal").goal_size == Vector2(107,100),"exact goal dimensions")
		check(level.get_meta("studio_draft").draftId.begins_with("bridge-"),"metadata preserved")
		var game = load("res://scenes/main.tscn").instantiate()
		game.level_override = level
		game.studio_test = true
		root.add_child(game)
		await physics_frame
		check(is_instance_valid(game.ball),"native football created")
		check(game.ball.kick(Vector2(-100,30)),"native shot accepted")
		for i in range(30):await physics_frame
		check(game.ball.position.x>130,"actual physics advances shot")
		if name=="wide":check(game.level.camera_mode==1 and game.level.level_size.x>2500,"wide level follow camera")
		if name=="mechanics":
			check(is_instance_valid(game.boost),"native boost bound")
			check(game.boost.acceleration==7200,"boost unit conversion")
			PhysicsServer2D.body_set_state(game.ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(180,618)))
			game.ball.linear_velocity = Vector2(250,0)
			var activated = false
			for i in range(180):
				await physics_frame
				if game.ball.linear_velocity.y < -900: activated = true
			check(activated,"imported boost carries football into imported spring: actual launch")
		var before = FileAccess.get_file_as_string("user://progress.cfg") if FileAccess.file_exists("user://progress.cfg") else ""
		game.shots = 1
		PhysicsServer2D.body_set_state(game.ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,level.get_node("Goal").position+Vector2(-35,-55)))
		game.ball.linear_velocity = Vector2(400,0)
		for i in range(115): await physics_frame
		check(game.won,"imported goal detects real native crossing")
		var after = FileAccess.get_file_as_string("user://progress.cfg") if FileAccess.file_exists("user://progress.cfg") else ""
		check(before==after,"Godot preview does not write progression")
		game.queue_free();holder.queue_free()
		await process_frame
	for bad in ['{}','{"format":"goal-in-one-level","version":99,"level":{}}']:
		check(not parser.parse(bad).errors.is_empty(),"invalid envelope rejected")
	var draft = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/basic.json"))
	draft.level.mechanics={"rotors":[{"x":10}]}
	check("Unsupported mechanic: rotors" in parser.parse(JSON.stringify(draft)).errors,"unsupported objects explicitly rejected")
	draft.level.mechanics={}
	draft.level.start.x="bad"
	check(not parser.parse(JSON.stringify(draft)).errors.is_empty(),"invalid coordinate rejected")
	print("IMPORT RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
