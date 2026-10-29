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
static func wood() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = preload("res://assets/wood.webp")
	style.set_content_margin_all(12)
	return style
static func theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 19
	t.set_color("font_color","Label",Color("fff1cf"))
	t.set_color("font_shadow_color","Label",Color("483021"))
	t.set_constant("shadow_offset_y","Label",2)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var color = {"normal":"a96730","hover":"c5873b","pressed":"754821","focus":"a96730","disabled":"665745"}[state]
		t.set_stylebox(state,"Button",box(Color(color),Color("ffcf65") if state=="focus" else Color("573721")))
	t.set_color("font_color","Button",Color("fff1cf"))
	t.set_color("font_disabled_color","Button",Color("b4a28a"))
	t.set_stylebox("panel","PanelContainer",wood())
	t.set_constant("separation","VBoxContainer",8)
	t.set_constant("separation","HBoxContainer",8)
	return t
static func button(text: String, action: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44,44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	if primary:
		b.add_theme_stylebox_override("normal",box(Color("477b35"),Color("ffd15c")))
		b.add_theme_stylebox_override("hover",box(Color("639843"),Color("ffe69b")))
	return b
static func label(text: String, font_size: int = 20) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	return l
