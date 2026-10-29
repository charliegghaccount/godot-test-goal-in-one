extends SceneTree
var checks = 0
var failures = 0
var save_path = "user://v6-flow-%d.cfg"%Time.get_ticks_usec()
func check(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func settle():
	for i in 4: await process_frame
func buttons_fit(node: Node, viewport: Vector2i):
	if node is Button and node.is_visible_in_tree():
		var rect = node.get_global_rect()
		check(rect.size.x>=44 and rect.size.y>=44,"button retains touch target: "+node.text)
		check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=viewport.x+1 and rect.end.y<=viewport.y+1,"button fits screen: "+node.text)
	for child in node.get_children(): buttons_fit(child,viewport)
func _initialize(): call_deferred("run")
func run():
	var menu = load("res://scenes/menu.tscn").instantiate()
	menu.progress_path = save_path
	root.add_child(menu)
	await settle()
	check(menu.screen_name=="home" and menu.play_button.visible,"default boot is main menu")
	var campaign = menu.campaign
	check(campaign.entries.size()==20,"only twenty official campaign entries")
	check(campaign.next_path("res://levels/green_runway.tscn")=="","samples excluded from campaign")
	check(campaign.continue_path()==campaign.entries[0].path,"fresh PLAY starts at first official level")
	# Legacy V5 scores have only best; derive stars with current thresholds.
	var legacy = ConfigFile.new()
	legacy.set_value(campaign.entries[0].id,"best",2)
	legacy.save(save_path)
	check(campaign.stars(campaign.entries[0])==2,"legacy best derives stars")
	check(campaign.continue_path()==campaign.entries[1].path,"PLAY finds first unfinished")
	menu.play_button.pressed.emit()
	await settle()
	check(menu.game.active_path==campaign.entries[1].path,"PLAY button launches continuation")
	menu.game.toggle_pause()
	check(menu.game.paused and menu.game.ball.freeze,"pause still freezes ball")
	menu.game.primary_action.pressed.emit()
	check(not menu.game.paused,"resume button resumes play")
	menu.game.back_to_levels()
	await settle()
	check(menu.screen_name=="levels" and menu.tiles.size()==25,"chapter grid has 25 slots")
	check(menu.tiles[19].disabled==false and menu.tiles[20].disabled,"only actual courses available")
	check(menu.chapter_total.text.contains("2 / 75"),"chapter total derives saved stars")
	menu.tiles[0].pressed.emit()
	await settle()
	check(menu.game.active_path==campaign.entries[0].path,"level tile launches requested course")
	menu.game.shots=1
	menu.game.complete()
	menu.game.complete()
	check(campaign.best(campaign.entries[0])==1,"completion updates best once")
	menu.game.replay_action.pressed.emit()
	await settle()
	check(menu.game.active_path==campaign.entries[0].path and menu.game.shots==0,"replay retains level and resets shots")
	menu.game.shots=1
	menu.game.complete()
	menu.game.primary_action.pressed.emit()
	await settle()
	check(menu.game.active_path==campaign.entries[1].path,"NEXT LEVEL loads official level two")
	menu.launch(campaign.entries[19].path)
	await settle()
	menu.game.shots=2
	menu.game.complete()
	check(menu.game.primary_action.text=="ALL LEVELS","last campaign course offers ALL LEVELS")
	menu.game.primary_action.pressed.emit()
	await settle()
	check(menu.screen_name=="levels" and not is_instance_valid(menu.game),"ALL LEVELS returns to grid")
	campaign.set_sound(false)
	var restored = preload("res://scripts/campaign.gd").new()
	restored.progress_path=save_path
	check(restored.stars(restored.entries[0])==3,"new progress instance retains stars")
	check(not restored.sound_enabled(),"sound settings persist")
	# UI tests use actual Control sizes after containers finish layout.
	for size in [Vector2i(1280,720),Vector2i(960,540),Vector2i(932,430),Vector2i(844,390),Vector2i(740,360)]:
		root.size=size
		menu.open_levels()
		await settle()
		check(menu.back_button.get_global_rect().size.y>=44,"navigation touch target at %s"%size)
		for tile in menu.tiles:
			check(tile.size.y>=44 and tile.size.x>=44,"tile touch target at %s"%size)
		check(menu.tiles[4].get_global_rect().end.x<=size.x,"five columns fit at %s"%size)
		if size.y>=430: check(menu.tiles[24].get_global_rect().end.y<=size.y-56,"all 25 tiles fit when height permits")
		menu.show_home()
		await settle()
		buttons_fit(menu.screen,size)
		check(menu.play_button.get_global_rect().position.y>=0 and menu.play_button.get_global_rect().end.y<=size.y,"PLAY fits %s"%size)
		menu.launch(campaign.entries[0].path)
		await settle()
		var g = menu.game
		buttons_fit(g,size)
		g.toggle_tools()
		await settle()
		check(g.tools_panel.get_global_rect().end.y<=size.y,"drawer remains inside mobile viewport")
		g.toggle_tools()
		g.shots=1
		g.complete()
		await settle()
		check(g.panel.get_global_rect().position.y>=0 and g.panel.get_global_rect().end.y<=size.y,"completion fits %s"%size)
		buttons_fit(g,size)
		check(g.primary_action.size.y>=44,"completion touch target %s"%size)
		menu.open_levels()
		await settle()
	# Additional official entries automatically expose new chapters; restore real list afterward.
	var original = campaign.entries.duplicate()
	for i in 40: campaign.entries.append(original[0].duplicate())
	check(campaign.chapter_count()==3,"campaign can grow to sixty without UI changes")
	menu.change_chapter(1)
	await settle()
	check(menu.chapter==1 and not menu.tiles[0].disabled,"chapter navigation shows additional entries")
	campaign.entries.assign(original)
	menu.queue_free()
	await settle()
	# Test draft with the same identity as campaign to detect accidental writes.
	var bridge = root.get_node("StudioBridge")
	var before = FileAccess.get_file_as_string(save_path)
	bridge.receive([FileAccess.get_file_as_string(campaign.entries[0].path)])
	await settle()
	var draft_game = bridge.current_game
	draft_game.progress_path=save_path
	draft_game.campaign.progress_path=save_path
	check(draft_game.studio_test and draft_game.next_level_path().is_empty(),"Studio bypasses campaign progression")
	draft_game.shots=1
	draft_game.complete()
	draft_game.toggle_sound()
	check(FileAccess.get_file_as_string(save_path)==before,"Studio completion/settings never write campaign progress")
	check(draft_game.primary_action.text=="RETURN TO EDITOR","Studio completion returns to editor")
	for size in [Vector2i(1280,720),Vector2i(740,360)]:
		root.size=size
		await settle()
		buttons_fit(draft_game,size)
	draft_game.restart()
	await settle()
	check(bridge.current_game.shots==0 and bridge.current_game.studio_test,"restart test preserves draft mode")
	check(not bridge.last_json.is_empty(),"restart retains editor draft payload")
	bridge.current_game.queue_free()
	bridge.current_level.queue_free()
	await settle()
	DirAccess.remove_absolute(save_path)
	print("GAME FLOW RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
