extends Node2D
const UI = preload("res://scripts/ui/timber_ui.gd")
var campaign = preload("res://scripts/campaign.gd").new()
var progress_path = "user://progress.cfg"
var screen: Control
var content: Control
var game: Node
var chapter = 0
var screen_name = "home"
var tiles: Array[Button] = []
var play_button: Button
var back_button: Button
var chapter_total: Label
var backdrop: CanvasLayer
func _ready():
	campaign.progress_path = progress_path
	if StudioBridge.active:
		var waiting = load("res://scenes/main.tscn").instantiate()
		add_child(waiting)
		return
	backdrop = CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	backdrop.add_child(preload("res://scripts/park_background.gd").new())
	var layer = CanvasLayer.new()
	add_child(layer)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = UI.theme()
	layer.add_child(screen)
	get_viewport().size_changed.connect(reflow)
	show_home()
	if OS.has_feature("web"):
		var requested = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('level') || ''"))
		if requested.is_valid_int() and int(requested)>0 and int(requested)<=campaign.entries.size(): launch(campaign.entries[int(requested)-1].path)
func clear_screen(name: String):
	screen_name = name
	for child in screen.get_children():
		screen.remove_child(child)
		child.queue_free()
	tiles.clear()
	screen.show()
	backdrop.show()
func card(width: float = 420) -> VBoxContainer:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = minf(width,get_viewport_rect().size.x-32)
	center.add_child(panel)
	var column = VBoxContainer.new()
	panel.add_child(column)
	return column
func show_home():
	clear_screen("home")
	var column = card()
	column.add_child(UI.label("GOAL IN ONE",38))
	column.add_child(UI.label("GRASS PARKS • YOUR KICK. YOUR ANGLE.",15))
	var ball = TextureRect.new()
	ball.texture = preload("res://assets/football.svg")
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.custom_minimum_size.y = 54
	column.add_child(ball)
	play_button = UI.button("PLAY",func(): launch(campaign.continue_path()),true)
	play_button.disabled = campaign.entries.is_empty()
	column.add_child(play_button)
	column.add_child(UI.button("LEVEL SELECT",open_levels))
	column.add_child(UI.button("SETTINGS",show_settings))
	column.add_child(UI.label("%d official courses • Unlimited kicks"%campaign.entries.size(),15))
func open_levels(path: String = ""):
	if not path.is_empty(): chapter = maxi(0,campaign.index_of(path))/25
	stop_game()
	clear_screen("levels")
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	screen.add_child(margin)
	var column = VBoxContainer.new()
	margin.add_child(column)
	var heading = HBoxContainer.new()
	column.add_child(heading)
	back_button = UI.button("HOME",show_home)
	heading.add_child(back_button)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sign = UI.label("GRASS PARKS\nCHAPTER %d  •  %d–%d"%[chapter+1,chapter*25+1,(chapter+1)*25],19)
	var sign_panel = PanelContainer.new()
	sign_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sign_panel.add_child(sign)
	heading.add_child(sign_panel)
	chapter_total = UI.label("STARS %d / 75"%campaign.chapter_stars(chapter))
	heading.add_child(chapter_total)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",6)
	scroll.add_child(grid)
	for slot in 25:
		var index = chapter*25+slot
		var available = index < campaign.entries.size()
		var entry = campaign.entries[index] if available else {}
		var stars = campaign.stars(entry) if available else 0
		var text = str(index+1)
		var tile = UI.button(text,launch.bind(entry.get("path","")))
		tile.name = "Level%d"%(index+1)
		tile.disabled = not available
		tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_theme_font_size_override("font_size",18)
		tile.text = ""
		var number_label = UI.label(text,18)
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(number_label)
		number_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		number_label.offset_top = 2
		number_label.offset_bottom = 26
		if not available: number_label.modulate = Color("b4a28a")
		var marker: Control
		if available:
			marker = preload("res://scripts/rating_stars.gd").new()
			marker.radius = 6.0
			marker.spacing = 16.0
			marker.center_y = 10.0
			marker.count = stars
		else:
			marker = UI.label("SOON",11)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(marker)
		marker.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		marker.offset_top = -20
		marker.offset_bottom = 0
		tile.tooltip_text = entry.get("name","Not yet available")
		if available and entry.path==campaign.continue_path(): tile.add_theme_stylebox_override("normal",UI.box(Color("ab7834"),Color("ffe16e")))
		grid.add_child(tile)
		tiles.append(tile)
	var nav = HBoxContainer.new()
	column.add_child(nav)
	var previous = UI.button("< CHAPTER",change_chapter.bind(-1))
	previous.disabled = chapter==0
	nav.add_child(previous)
	var next = UI.button("CHAPTER >",change_chapter.bind(1))
	next.disabled = chapter+1>=campaign.chapter_count()
	nav.add_child(next)
	reflow()
func reflow():
	if screen_name=="levels":
		var h = maxf(44,minf(92,(get_viewport_rect().size.y-188)/5))
		for tile in tiles: tile.custom_minimum_size.y = h
func change_chapter(delta: int):
	chapter = clampi(chapter+delta,0,campaign.chapter_count()-1)
	open_levels()
func show_settings():
	clear_screen("settings")
	var column = card()
	column.add_child(UI.label("SETTINGS",30))
	var sound = UI.button("",func(): pass)
	sound.text = "SOUND: ON" if campaign.sound_enabled() else "SOUND: OFF"
	sound.pressed.connect(func():
		campaign.set_sound(not campaign.sound_enabled())
		sound.text = "SOUND: ON" if campaign.sound_enabled() else "SOUND: OFF")
	column.add_child(sound)
	column.add_child(UI.label("Drag back and release to kick.\nKick again while moving. Unlimited shots.",18))
	column.add_child(UI.button("BACK",show_home))
func stop_game():
	if is_instance_valid(game):
		game.queue_free()
		game = null
func launch(path: String):
	if campaign.index_of(path)<0: return
	stop_game()
	screen.hide()
	backdrop.hide()
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("level_path",path)
	game.progress_path = progress_path
	game.flow = self
	add_child(game)
