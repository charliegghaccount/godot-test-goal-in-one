extends RefCounted
const UI = preload("res://scripts/ui/timber_ui.gd")
static func build(game: Node):
	var layer = CanvasLayer.new()
	game.add_child(layer)
	var root = Control.new()
	root.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	root.theme = UI.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.offset_left = 12
	margin.offset_top = 10
	margin.offset_right = -12
	root.add_child(margin)
	var row = HBoxContainer.new()
	margin.add_child(row)
	row.add_child(UI.button("RETURN TO EDITOR" if game.studio_test else "LEVELS",game.back_to_levels))
	var level_sign = PanelContainer.new()
	row.add_child(level_sign)
	var index = game.campaign.index_of(game.active_path)
	level_sign.add_child(UI.label("TEST" if game.studio_test else ("LEVEL %d"%(index+1) if index>=0 else "SAMPLE"),18))
	var space = Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	var stats = PanelContainer.new()
	row.add_child(stats)
	game.hud = UI.label("",18)
	stats.add_child(game.hud)
	var mute = UI.icon_button("sound",game.toggle_sound,"Toggle sound")
	mute.tooltip_text = "Toggle sound"
	game.mute_button = mute
	row.add_child(mute)
	row.add_child(UI.icon_button("restart",game.restart,"Restart (R)"))
	row.add_child(UI.icon_button("pause",game.toggle_pause,"Pause (Esc)"))
	var drawer_button = UI.icon_button("tools",game.toggle_tools,"Camera tools")
	drawer_button.tooltip_text = "Camera, reset and settings"
	row.add_child(drawer_button)
	for control in row.get_children():
		if control is Button: control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var drawer = PanelContainer.new()
	game.tools_panel = drawer
	drawer.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	drawer.offset_left = -310
	drawer.offset_right = -12
	drawer.offset_top = 70
	drawer.anchor_bottom = 1.0
	drawer.offset_bottom = -12
	root.add_child(drawer)
	var drawer_scroll = ScrollContainer.new()
	drawer.add_child(drawer_scroll)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_scroll.add_child(column)
	game.explore_button = UI.button("EXPLORE / PAN",game.toggle_explore)
	column.add_child(game.explore_button)
	column.add_child(UI.button("RETURN TO BALL",game.return_to_ball))
	var zoom = HBoxContainer.new()
	column.add_child(zoom)
	zoom.add_child(UI.button("ZOOM −",game.zoom_camera.bind(0.85)))
	zoom.add_child(UI.button("ZOOM +",game.zoom_camera.bind(1.15)))
	column.add_child(UI.button("RESET BALL",game.reset_ball))
	column.add_child(UI.button("SOUND SETTINGS",game.toggle_sound))
	game.controls_hint = UI.label("Drag back to kick. Unlimited shots.\nR: restart • E: explore • Esc: pause",15)
	column.add_child(game.controls_hint)
	game.level_picker = OptionButton.new()
	game.level_picker.custom_minimum_size.y = 44
	game.level_picker.add_item("EXPERIMENTAL SCENES")
	for path in game.level_paths:
		if path.ends_with(".tscn"): game.level_picker.add_item(path.get_file().get_basename().capitalize())
	game.level_picker.item_selected.connect(func(index):
		var paths = []
		for path in game.level_paths:
			if path.ends_with(".tscn"): paths.append(path)
		if index>0: game.load_level(paths[index-1]))
	column.add_child(game.level_picker)
	game.level_picker.visible = not game.studio_test
	drawer.hide()
	var modal = Control.new()
	game.modal_root = modal
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var dim = ColorRect.new()
	dim.color = Color(0.05,0.12,0.05,0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	game.panel = PanelContainer.new()
	game.panel.custom_minimum_size.x = minf(460,game.get_viewport_rect().size.x-24)
	center.add_child(game.panel)
	var result = VBoxContainer.new()
	game.panel.add_child(result)
	game.message = UI.label("",26)
	result.add_child(game.message)
	game.rating_view = preload("res://scripts/rating_stars.gd").new()
	game.rating_view.custom_minimum_size.y = 55
	result.add_child(game.rating_view)
	game.primary_action = UI.button("CONTINUE",game.primary_pressed,true)
	result.add_child(game.primary_action)
	game.replay_action = UI.button("RESTART TEST" if game.studio_test else "REPLAY LEVEL",game.restart)
	result.add_child(game.replay_action)
	game.selection_action = UI.button("RETURN TO EDITOR" if game.studio_test else "BACK TO LEVELS",game.back_to_levels)
	result.add_child(game.selection_action)
	game.panel.visibility_changed.connect(func(): modal.visible=game.panel.visible)
	game.panel.hide()
	modal.hide()
