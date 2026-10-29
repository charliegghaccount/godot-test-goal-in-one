extends Node2D
func _process(_dt): queue_redraw()
func wood(points: PackedVector2Array, angle: float = 0, grass: bool = false):
	var uv = PackedVector2Array()
	var origin = Vector2(INF,INF)
	for point in points: origin = origin.min(point.rotated(-angle))
	for point in points: uv.append((point.rotated(-angle)-origin)/256.0)
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,preload("res://assets/wood.webp"))
	preload("res://scripts/game_art.gd").timber(self,points,grass,angle)
func _draw():
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	var screen = get_viewport_rect().size
	var scale = maxf(screen.x/1600,screen.y/900)
	draw_set_transform((screen-Vector2(1600,900)*scale)/2,0,Vector2.ONE*scale)
	wood(PackedVector2Array([Vector2(-30,510),Vector2(250,510),Vector2(250,595),Vector2(-30,595)]),0,true)
	wood(PackedVector2Array([Vector2(240,550),Vector2(430,655),Vector2(412,691),Vector2(222,586)]),atan2(105,190))
	wood(PackedVector2Array([Vector2(-30,690),Vector2(430,690),Vector2(430,785),Vector2(-30,785)]),0,true)
	wood(PackedVector2Array([Vector2(1260,700),Vector2(1630,700),Vector2(1630,800),Vector2(1260,800)]),0,true)
	draw_texture_rect(preload("res://assets/football.svg"),Rect2(125,435,75,75),false)
	var points = PackedVector2Array([Vector2(1320,532),Vector2(1445,532),Vector2(1540,697),Vector2(1320,697)])
	for x in range(1333,1540,13):
		var top = 532 if x<1445 else 697-(1540-x)*165.0/95
		draw_line(Vector2(x,top),Vector2(x,697),Color("fffffff0"),1.15,true)
	for y in range(545,697,13): draw_line(Vector2(1325,y),Vector2(1445+(y-532)*95.0/165,y),Color("fffffff0"),1.15,true)
	draw_polyline(points,Color("465360"),14,true)
	draw_polyline(points,Color("f4f7fa"),10.6,true)
	draw_set_transform(Vector2.ZERO)
