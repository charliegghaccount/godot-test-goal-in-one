extends SceneTree
var failures=0
var checks=0
func check(ok,label):
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize():call_deferred("run")
func run():
	for size in [Vector2(80,120),Vector2(135,108),Vector2(240,180)]:
		for speed in [500,1100,2200]:
			for slope in [-60,40,999]:
				var holder=Node.new();root.add_child(holder)
				var level=Node2D.new();level.set_script(load("res://scripts/level.gd"));holder.add_child(level)
				level.level_size=Vector2(2000,1200)
				var spawn=Marker2D.new();spawn.name="Spawn";spawn.position=Vector2(300,400);level.add_child(spawn)
				var goal=load("res://scenes/goal.tscn").instantiate();goal.name="Goal";goal.position=Vector2(800,900 if speed==1100 else 600);goal.goal_size=size;level.add_child(goal)
				var game=load("res://scenes/main.tscn").instantiate();game.level_override=level;game.studio_test=true;root.add_child(game)
				await physics_frame
				if slope==999:
					var floor=load("res://scenes/timber.tscn").instantiate()
					level.add_child(floor)
					floor.setup(PackedVector2Array([Vector2(0,goal.position.y-5.2),Vector2(800+size.x,goal.position.y-5.2),Vector2(800+size.x,goal.position.y+30),Vector2(0,goal.position.y+30)]))
				game.shots=1
				PhysicsServer2D.body_set_state(game.ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(0,goal.position+(Vector2(-200,-21) if slope==999 else Vector2(-20,-size.y*0.5))))
				game.ball.linear_velocity=Vector2(speed,0 if slope==999 else slope)
				var entered=false
				var captured=true
				for i in 220:
					await physics_frame
					entered=entered or game.scoring or game.won
					if entered:
						var local=goal.to_local(game.ball.global_position)
						if local.y> -10 or local.x<0:captured=false
				check(entered,"entry size=%s speed=%s slope=%s"%[size,speed,slope])
				check(game.won and game.score_time>=0.65,"full delayed completion")
				check(captured,"ball retained by native goal solids after entry")
				check(goal.frame_body.is_inside_tree() and level.process_mode!=Node.PROCESS_MODE_DISABLED,"goal/level collision bodies remain active")
				game.queue_free();holder.queue_free();await process_frame
	print("GOAL RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
