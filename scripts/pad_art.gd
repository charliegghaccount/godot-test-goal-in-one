@tool
extends RefCounted
static func draw_pad(canvas: CanvasItem, size: Vector2, kind: String, flash: float = 0):
	var w = size.x
	var colors = [Color("92f442"),Color("35d21c"),Color("169a22")] if kind=="forward" else ([Color("ffc259"),Color("ff8b18"),Color("df5812")] if kind=="backward" else [Color("ff7161"),Color("ff332d"),Color("be1c2d")])
	canvas.draw_rect(Rect2(-w/2,-6,w,12),Color("202a34"))
	for y in 10: canvas.draw_line(Vector2(-w/2+1,-5+y),Vector2(w/2-1,-5+y),Color("7d8c9a").lerp(Color("28313c"),y/9.0),1,true)
	for y in 8: canvas.draw_line(Vector2(-w/2+5,-5+y),Vector2(w/2-5,-5+y),colors[0].lerp(colors[2],y/7.0).lightened(flash*0.3),1,true)
	if kind=="delete":
		for x in range(-int(w/2)+12,int(w/2)-12,20): canvas.draw_line(Vector2(x,-4),Vector2(x-5,1),Color("8f162a80"),4,true)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(6,3),Vector2(-6,3)]),Color("fff5e5"))
		canvas.draw_line(Vector2(0,-3),Vector2(0,0),Color("a51b2b"),1.3,true)
	else:
		var d = 1 if kind=="forward" else -1
		for x in range(-int(w/2)+18,int(w/2)-8,28):
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-d*5,-4),Vector2(x+d*2,-4),Vector2(x+d*7,-1),Vector2(x+d*2,2),Vector2(x-d*5,2),Vector2(x,-1)]),Color("fffef4"))
	for x in [-w/2+2.5,w/2-2.5]: preload("res://scripts/game_art.gd").bolt(canvas,Vector2(x,0),1.4)
