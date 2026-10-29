extends Node2D
## Standalone comparison scene, exported separately; never replaces the game's menu.
func _ready(): call_deferred("run")
func run():
	var params = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify(Object.fromEntries(new URLSearchParams(location.search)))"))) if OS.has_feature("web") else {}
	var id = str(params.get("level","1"))
	var path = "res://comparison/levels/L%02d.json"%int(id) if id.is_valid_int() else "res://tests/fixtures/"+id+".json"
	var game = load("res://scenes/main.tscn").instantiate()
	game.studio_test = true
	game.set_meta("level_path",path)
	add_child(game)
	for child in game.get_children():
		if child is CanvasLayer and child.layer>=0: child.hide()
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	var ticks = int(params.get("ticks",0))
	if params.has("angle"):
		game.shots=1
		game.ball.kick(-Vector2.from_angle(deg_to_rad(float(params.angle)))*float(params.get("power",140)))
	if ticks==0:
		game.ball.freeze = true
		for object in game.level.get_children(): object.set_physics_process(false)
	for i in ticks: await get_tree().physics_frame
	await get_tree().process_frame
	game.ball.freeze = true
	game.set_physics_process(false)
	game.set_process(false)
	for object in game.level.get_children(): object.set_physics_process(false)
	if params.get("state","")=="aim":
		game.aiming = true
		game.pull = Vector2(-110,50)
	if params.has("zoom"):
		game.exploring = true
		game.camera.zoom *= float(params.zoom)
		game.camera.position = game.bounded_camera(game.camera.position+Vector2(float(params.get("panx",0)),float(params.get("pany",0))))
	game.queue_redraw()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parityState="+JSON.stringify({"ticks":ticks,"ball":[game.ball.position.x,game.ball.position.y],"camera":[game.camera.position.x,game.camera.position.y,game.camera.zoom.x],"won":game.won})+";window.parityReady=true")
