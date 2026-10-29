extends RefCounted
static func box(color: Color, edge: Color = Color("573721")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0.12,0.17,0.07,0.35)
	style.shadow_size = 4
	return style
static func wood() -> StyleBox:
	var style = preload("res://scripts/ui/wood_style.gd").new()
	style.screws = true
	style.set_content_margin_all(12)
	return style
static func theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 19
	t.default_font = preload("res://assets/fonts/LiberationSans-Bold.ttf")
	t.set_color("font_color","Label",Color("fff1cf"))
	t.set_color("font_shadow_color","Label",Color("483021"))
	t.set_constant("shadow_offset_y","Label",2)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var color = {"normal":"a96730","hover":"c5873b","pressed":"754821","focus":"a96730","disabled":"665745"}[state]
		var style = preload("res://scripts/ui/wood_style.gd").new()
		style.tint = Color("ffffff") if state in ["normal","focus"] else (Color("ffedcf") if state=="hover" else Color("a69c8b") if state=="disabled" else Color("d8c1a0"))
		style.edge = Color("ffcf65") if state=="focus" else Color("63300f")
		t.set_stylebox(state,"Button",style)
	t.set_color("font_color","Button",Color("fff1cf"))
	t.set_color("font_disabled_color","Button",Color("b4a28a"))
	t.set_stylebox("panel","PanelContainer",wood())
	t.set_constant("separation","VBoxContainer",8)
	t.set_constant("separation","HBoxContainer",8)
	return t
static func button(text: String, action: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	b.text = text
	b.custom_minimum_size = Vector2(44,44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	if primary:
		var primary_style = wood()
		primary_style.edge = Color("ffd15c")
		b.add_theme_stylebox_override("normal",primary_style)
		var hover_style = wood()
		hover_style.edge = Color("ffe69b")
		b.add_theme_stylebox_override("hover",hover_style)
	return b
static func label(text: String, font_size: int = 20) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	return l

static func icon(kind: String) -> Texture2D:
	var paths = {"sound":"M4 9h4l5-5v16l-5-5H4z M16 8q6 4 0 8", "mute":"M4 9h4l5-5v16l-5-5H4z M17 9l5 6m0-6l-5 6", "restart":"M5 8a8 8 0 1 1-1 8 M5 3v6h6", "pause":"M8 5v14M16 5v14", "tools":"M10 4a6 6 0 1 0 0 12a6 6 0 1 0 0-12 M15 15l6 6"}
	var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="%s" fill="none" stroke="#fff1cf" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'%paths.get(kind,paths.tools)
	var image = Image.new()
	image.load_svg_from_string(svg)
	return ImageTexture.create_from_image(image)
static func icon_button(kind: String, action: Callable, hint: String) -> Button:
	var b = button("",action)
	b.icon = icon(kind)
	b.tooltip_text = hint
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style = wood()
		style.radius = 99
		b.add_theme_stylebox_override(state,style)
	return b
