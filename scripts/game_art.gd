@tool
extends RefCounted
## Shared world-unit artwork translated from the reference Canvas helpers.
static func bolt(canvas: CanvasItem, at: Vector2, radius: float = 3.2):
	canvas.draw_circle(at,radius+1,Color("344651"))
	canvas.draw_circle(at-Vector2(0.5,0.5),radius,Color("a4b6bc"))
	canvas.draw_line(at-Vector2(radius*0.5,0),at+Vector2(radius*0.5,0),Color("46545c"),0.8,true)
static func timber(canvas: CanvasItem, points: PackedVector2Array, grass: bool = false, grain: float = 0):
	if points.size()<3: return
	var center = Vector2.ZERO
	var winding = 0.0
	for i in points.size():
		center += points[i]
		winding += points[i].cross(points[(i+1)%points.size()])
	center /= points.size()
	var border = points.duplicate()
	border.append(points[0])
	canvas.draw_polyline(border,Color("613619"),2.5,true)
	for i in points.size():
		var a = points[i]
		var b = points[(i+1)%points.size()]
		var axis = (b-a).normalized()
		var inward = Vector2(-axis.y,axis.x)*signf(winding)
		var light = ((b.y-a.y)*-0.6+(b.x-a.x)*0.8)*signf(winding)/maxf(a.distance_to(b),1)
		canvas.draw_line(a+inward*2,b+inward*2,Color("ffe9b68c") if light>0 else Color("6d351e70"),3 if light>0 else 5,true)
		var at = a.lerp(center,minf(0.35,13/maxf(a.distance_to(center),1)))
		bolt(canvas,at)
		if grass and axis.dot(Vector2.from_angle(grain))*signf(winding)>0.35:
			canvas.draw_line(a,b,Color("47ab32"),3,true)
			for x in range(3,int(a.distance_to(b))-3,9):
				var origin = a+axis*x
				canvas.draw_polyline(PackedVector2Array([origin+inward,origin+axis*2-inward*3.6,origin+axis*4+inward]),Color("b4ed59"),1.2,true)
static func rectangle(canvas: CanvasItem, size: Vector2, grass: bool = false):
	var rect = Rect2(-size/2,size)
	var wood = preload("res://assets/wood.webp")
	canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	canvas.draw_texture_rect_region(wood,rect,Rect2(Vector2.ZERO,size*wood.get_width()/256.0))
	timber(canvas,PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),grass)
