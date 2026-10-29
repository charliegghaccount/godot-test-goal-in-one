extends SceneTree
func _initialize():call_deferred("run")
func run():
	var rows=[]
	for id in [1,2,5,6,9,10,14,18,19,20,"mechanics","studio-library"]:
		for angle in [-15,-35,-55]:
			var level=load("res://scripts/studio_import.gd").new().parse(FileAccess.get_file_as_string("res://comparison/levels/L%02d.json"%id if id is int else "res://tests/fixtures/"+id+".json")).level
			var holder=Node.new();root.add_child(holder);holder.add_child(level)
			var game=load("res://scenes/main.tscn").instantiate();game.level_override=level;game.studio_test=true;root.add_child(game)
			await physics_frame
			game.shots=1;game.ball.kick(-Vector2.from_angle(deg_to_rad(angle))*140)
			var trace=[]
			for i in 360:
				await physics_frame
				if i%40==39:trace.append([game.ball.position.x,game.ball.position.y])
			rows.append({"level":id,"angle":angle,"trace":trace,"won":game.won})
			game.queue_free();holder.queue_free();await process_frame
	FileAccess.open("res://comparison/routes-godot.json",FileAccess.WRITE).store_string(JSON.stringify(rows))
	quit()
