extends SceneTree
var checks = 0
var failures = 0
var parser = preload("res://scripts/studio_import.gd").new()
var base = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/basic.json"))
func check(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func game_for(mechanics: Dictionary):
	var draft = base.duplicate(true)
	draft.level.mechanics = mechanics
	draft.level.surfaces = []
	draft.level.obstacles = []
	var parsed = parser.parse(JSON.stringify(draft))
	check(parsed.errors.is_empty(),"new mechanic imports: "+str(parsed.errors))
	var holder = Node.new()
	root.add_child(holder)
	holder.add_child(parsed.level)
	var game = load("res://scenes/main.tscn").instantiate()
	game.level_override = parsed.level
	game.studio_test = true
	root.add_child(game)
	return game
func dispose(game):
	game.level.get_parent().queue_free()
	game.queue_free()
func place(ball,at: Vector2,velocity: Vector2):
	PhysicsServer2D.body_set_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,at))
	ball.sleeping = false
	ball.gravity_scale = 0
	ball.linear_velocity = velocity
func objects(game,kind: String):
	return game.level.get_children().filter(func(n): return n.get_script()==load("res://scripts/mechanics/"+kind+".gd"))
func _initialize(): call_deferred("run")
func run():
	var ramp = load("res://scenes/timber.tscn").instantiate()
	ramp.polygon = PackedVector2Array([Vector2(20,10),Vector2(220,10),Vector2(220,110),Vector2(20,110)])
	root.add_child(ramp)
	check(ramp.uv.size()==ramp.polygon.size(),"timber UV buffer is retained, not modified as a temporary property copy")
	check(absf(ramp.uv[0].distance_to(ramp.uv[1])/200-2)<0.01,"timber uses exact 512-texture / 256-world density")
	ramp.grain_angle = PI/4
	ramp._sync()
	check((ramp.uv[1]-ramp.uv[0]).distance_to(Vector2(200,0).rotated(-PI/4)*2)<0.01,"grain rotation maps actual polygon vertices once")
	ramp.queue_free()
	var canonical = parser.parse(FileAccess.get_file_as_string("res://comparison/levels/L02.json"))
	check(canonical.level.camera_origin.x==25 and canonical.level.level_size.x==1250,"legacy framing retains original 1250-unit camera")
	canonical.level.free()
	var mover = load("res://scenes/mover.tscn").instantiate()
	mover.use_path = true
	mover.path_start = Vector2(100,200)
	mover.path_end = Vector2(300,200)
	mover.phase = 0.25
	root.add_child(mover)
	await physics_frame
	await process_frame
	var expected_path = mover.path_start.lerp(mover.path_end,(1-cos((mover.time/mover.period+0.25)*TAU))/2)
	check(mover.position.distance_to(expected_path)<2,"path mover retains phase after physics synchronization")
	mover.queue_free()
	var library = parser.parse(FileAccess.get_file_as_string("res://tests/fixtures/studio-library.json"))
	check(library.errors.is_empty(),"unmodified original Studio library envelope imports")
	if library.has("level"): library.level.free()
	var rotor = {"x":600,"y":350,"w":200,"h":24,"speed":0.35,"phase":0.2}
	var game = game_for({"rotors":[rotor]})
	for i in 120: await physics_frame
	var actor = objects(game,"rotor")[0]
	check(absf(actor.rotation-(0.2+0.35*actor.time))<0.01,"rotor follows original radians/second")
	game.toggle_pause()
	var angle = actor.rotation
	for i in 20: await physics_frame
	check(actor.rotation==angle,"rotor respects pause")
	game.toggle_pause()
	for i in 20: await physics_frame
	check(actor.rotation>angle,"rotor resumes")
	# High-speed physical impact against a rotating collision body.
	await physics_frame
	place(game.ball,Vector2(600,250),Vector2(0,700))
	var hit = false
	for i in 35:
		await physics_frame
		if game.ball.linear_velocity.y<0: hit = true
	check(hit,"rotating paddle produces native ball rebound")
	dispose(game);await process_frame
	rotor.merge({"pivot":{"x":600,"y":270},"amplitude":0.65,"period":5},true)
	game = game_for({"rotors":[rotor]})
	for i in 90: await physics_frame
	actor = objects(game,"rotor")[0]
	var expected = 0.2+sin(actor.time*TAU/5)*0.65
	check(absf(actor.rotation-expected)<0.02,"swing matches original sine angle")
	check(actor.position.distance_to(Vector2(600,270)+Vector2(-sin(actor.rotation),cos(actor.rotation))*12)<1,"swing retains pivot-length geometry")
	dispose(game);await process_frame
	for speed in [120.0,800.0]:
		game = game_for({"breakables":[{"id":"wood","x":600,"y":400,"w":48,"h":120,"threshold":5}]})
		actor = objects(game,"breakable")[0]
		await physics_frame
		place(game.ball,Vector2(530,400),Vector2(speed,0))
		for i in 90: await physics_frame
		check(actor.broken==(speed>300),"break threshold uses incoming normal speed, not tangential motion")
		if speed>300:
			check(actor.collision.disabled and not actor.visible,"broken timber removes collision and art")
		else: check(actor.damage>0 and not actor.collision.disabled,"weak impact keeps solid damaged wood")
		dispose(game);await process_frame
	var travel = []
	for icy in [false,true]:
		game = game_for({"ice":[{"x":80,"y":640,"w":850,"angle":0,"friction":0.00015}]} if icy else {})
		game.ball.gravity_scale=1
		PhysicsServer2D.body_set_state(game.ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,Vector2(150,618.8)))
		game.ball.linear_velocity=Vector2(120,0)
		for i in 180: await physics_frame
		travel.append(game.ball.position.x-150)
		if icy:
			check(not game.ball.ice_contacts.is_empty(),"ice sensor applies friction to actual ball contact")
			check(game.ball.physics_material_override.friction<=0.000151,"ice material uses declared coefficient")
			game.reset_ball()
			check(game.ball.ice_contacts.is_empty(),"reset clears stale ice contact")
		dispose(game);await process_frame
	check(travel[1]>travel[0]*1.5,"ice physically preserves more travel than ordinary floor")
	game = game_for({"winds":[{"x":400,"y":200,"w":200,"h":200,"angle":0,"strength":1.3}]})
	await physics_frame
	place(game.ball,Vector2(450,300),Vector2.ZERO)
	for i in 10: await physics_frame
	check(game.ball.linear_velocity.x>100 and absf(game.ball.linear_velocity.y)<1,"wind converts strength to reference force units")
	await physics_frame
	place(game.ball,Vector2(390,300),Vector2.ZERO)
	for i in 2: await physics_frame
	game.ball.linear_velocity = Vector2.ZERO
	for i in 5: await physics_frame
	check(absf(game.ball.linear_velocity.x)<1,"wind uses center-in-rectangle, not overlapping ball radius")
	dispose(game);await process_frame
	var draft = base.duplicate(true)
	draft.level.camera={"mode":"follow-xy","viewWidth":900,"viewHeight":500,"initial":{"x":400,"y":300},"deadZone":{"x":0.3,"y":0.2},"minimumBallDiameterPx":20}
	var parsed = parser.parse(JSON.stringify(draft))
	check(parsed.errors.is_empty() and parsed.level.custom_initial,"custom camera initial and dead-zone import")
	parsed.level.free()
	draft.level.mechanics={"portal":[{}]}
	check(not parser.parse(JSON.stringify(draft)).errors.is_empty(),"unknown mechanics still fail explicitly")
	print("V7 MECHANICS RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
