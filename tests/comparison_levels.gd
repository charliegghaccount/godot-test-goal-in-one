extends SceneTree
var failures=0
var checks=0
func check(ok,label):
	checks+=1
	if not ok: failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
	for index in range(1,21):
		var path="res://comparison/levels/L%02d.json"%index
		var imported=load("res://scripts/studio_import.gd").new().parse(FileAccess.get_file_as_string(path))
		check(imported.errors.is_empty(),"canonical import %d: %s"%[index,imported.errors])
		if not imported.has("level"):continue
		var holder=Node.new();root.add_child(holder);holder.add_child(imported.level)
		var game=load("res://scenes/main.tscn").instantiate();game.studio_test=true;game.level_override=imported.level;root.add_child(game)
		await physics_frame
		check(game.level.problems().is_empty(),"canonical geometry valid")
		var draft=game.level.get_meta("studio_draft").level
		check(game.ball.position.distance_to(Vector2(draft.start.x,draft.start.y))<2,"spawn retained")
		var movers=[]
		for object in game.level.get_children():
			if object.get_script()==load("res://scripts/mechanics/mover.gd"):movers.append(object)
		game.ball.kick(Vector2(-110,60))
		for i in range(120):await physics_frame
		check(is_finite(game.ball.position.x) and is_finite(game.ball.position.y),"shot remains finite")
		for mover in movers:
			var expected=mover.rest_position+(Vector2.RIGHT if mover.axis==1 else Vector2.DOWN)*cos(mover.time*TAU/mover.period)*mover.travel
			check(mover.position.distance_to(expected)<3,"canonical mover follows sinusoidal track")
		game.queue_free();holder.queue_free();await process_frame
	var audio=load("res://scripts/game_audio.gd")
	check(audio.announcement_for(1,1,Vector2i(1,3))=="goal-in-one","one shot voice")
	check(audio.announcement_for(2,1,Vector2i(1,3))=="goal","two star voice")
	check(audio.announcement_for(4,5,Vector2i(1,3))=="solid-effort","one star under par voice")
	check(audio.announcement_for(7,5,Vector2i(1,3))=="should-have-done-better","over par voice")
	check(audio.announcement_for(2,3,Vector2i(3,5))=="","three stars multiple shots no recording")
	print("COMPARISON RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
