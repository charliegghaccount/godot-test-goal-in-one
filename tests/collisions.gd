extends SceneTree
var checks=0
var failures=0
func check(ok,label):
	checks+=1
	if not ok: failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
	for angle in [0.0,0.5,-0.7]:
		var world=Node2D.new();root.add_child(world)
		var timber=load("res://scenes/timber.tscn").instantiate();timber.position=Vector2(600,400);timber.rotation=angle;world.add_child(timber)
		timber.setup(PackedVector2Array([Vector2(-5,-220),Vector2(5,-220),Vector2(5,220),Vector2(-5,220)]))
		var ball=load("res://scenes/ball.tscn").instantiate();ball.position=Vector2(350,400);ball.gravity_scale=0;world.add_child(ball)
		ball.linear_velocity=Vector2(2400,0)
		var reflected=false
		for i in range(45):
			await physics_frame
			if ball.linear_velocity.x<0:reflected=true
		check(reflected,"high speed rebound at angle "+str(angle))
		check(ball.position.x<750,"no tunnelling through thin tilted timber")
		world.queue_free();await process_frame
	print("COLLISION RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
