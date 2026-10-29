extends SceneTree
var checks = 0
var failures = 0
const SAVE = "user://progress-regression.cfg"
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func spawn(path: String):
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress_path = SAVE
	game.set_meta("level_path",path)
	root.add_child(game)
	return game
func _initialize(): call_deferred("run")
func run():
	DirAccess.remove_absolute(SAVE)
	var game = spawn("res://comparison/levels/L01.json")
	await physics_frame
	check(not game.sound.announcements_enabled,"spoken announcer lines disabled")
	check(game.next_level_path().ends_with("L02.json"),"first canonical level advances in order")
	game.shots = 1
	game.complete()
	game.complete()
	check(game.won and game.best==1,"completion is idempotent")
	check(game.primary_action.text=="NEXT LEVEL" and game.replay_action.visible,"completion offers next and replay")
	game.primary_action.pressed.emit()
	await process_frame
	game = root.get_child(root.get_child_count()-1)
	check(game.active_path.ends_with("L02.json"),"next button loads next playable level")
	check(not game.won and game.shots==0 and game.score_time==0,"next level starts fresh")
	game.shots = 2
	game.complete()
	var save = ConfigFile.new()
	save.load(SAVE)
	check(save.get_sections().size()==2,"progress preserves previously completed levels")
	check(save.get_value(game.level.level_id,"stars",0)==2,"stars persisted")
	game.queue_free()
	await process_frame
	game = spawn("res://comparison/levels/L01.json")
	check(game.best==1 and game.best_stars==3,"best result restored")
	game.shots = 4
	game.complete()
	check(game.best==1 and game.best_stars==3,"worse replay preserves best score and stars")
	game.queue_free()
	await process_frame
	game = spawn("res://comparison/levels/L19.json")
	check(game.next_level_path().ends_with("L20.json"),"selector entry retains progression")
	for i in 120: await physics_frame
	game.shots = 5
	game.paused = true
	game.scoring = true
	game.restart()
	game.restart()
	await process_frame
	game = root.get_child(root.get_child_count()-1)
	check(game.active_path.ends_with("L19.json") and game.shots==0,"restart retains selected level and resets shots")
	check(not game.paused and not game.scoring and not game.won and game.score_time==0,"restart resets timers and phases")
	check(game.ball.position.distance_to(game.spawn_point)<2,"restart restores spawn")
	for object in game.level.get_children():
		if object.get_script()==load("res://scripts/mechanics/mover.gd"):
			check(object.time<0.02,"restart resets moving obstacles")
	game.queue_free()
	await process_frame
	game = spawn("res://comparison/levels/L20.json")
	check(game.next_level_path().is_empty(),"campaign ends before native samples")
	game.shots=1
	game.complete()
	check(game.message.text.contains("All levels complete") and game.primary_action.text=="ALL LEVELS","final level offers selection")
	game.primary_action.pressed.emit()
	await process_frame
	var menu = root.get_child(root.get_child_count()-1)
	check(menu.screen_name=="levels","final level opens selection")
	menu.queue_free()
	await process_frame
	DirAccess.remove_absolute(SAVE)
	print("PROGRESSION RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
