@tool
extends StyleBox
## Native StyleBox, same mirrored 256 px timber density as the reference CSS.
var tint = Color.WHITE
var edge = Color("63300f")
var radius = 17.0
var screws = false
var image = preload("res://assets/wood.webp")
func _init():
	set_content_margin_all(8)
func outline(rect: Rect2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var r = minf(radius,minf(rect.size.x,rect.size.y)/2)
	for i in 4:
		var center = [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),rect.end-Vector2(r,r),Vector2(rect.position.x+r,rect.end.y-r)][i]
		for j in 9: points.append(center+Vector2.from_angle(PI+i*PI/2+j*PI/16)*r)
	return points
func _draw(canvas: RID, rect: Rect2):
	var points = outline(rect)
	var uv = PackedVector2Array()
	for point in points: uv.append((point-rect.position)/256.0)
	var shadow = points.duplicate()
	for i in shadow.size(): shadow[i] += Vector2(0,3)
	RenderingServer.canvas_item_add_polygon(canvas,shadow,PackedColorArray([Color("482512")]))
	RenderingServer.canvas_item_add_polygon(canvas,points,PackedColorArray([tint]),uv,image.get_rid())
	var shade = PackedColorArray()
	for point in points:
		shade.append(Color("8d401d66").lerp(Color("622b0e99"),clampf((point.y-rect.position.y)/maxf(rect.size.y,1),0,1)))
	RenderingServer.canvas_item_add_polygon(canvas,points,shade)
	points.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas,points,PackedColorArray([edge]),3,true)
	var inset = outline(rect.grow(-3))
	inset.append(inset[0])
	RenderingServer.canvas_item_add_polyline(canvas,inset,PackedColorArray([Color("ffe5a780")]),1,true)
	if screws and rect.size.x>120 and rect.size.y>60:
		for at in [rect.position+Vector2(9,9),Vector2(rect.end.x-9,rect.position.y+9),rect.end-Vector2(9,9),Vector2(rect.position.x+9,rect.end.y-9)]:
			RenderingServer.canvas_item_add_circle(canvas,at,3,Color("573721"))
			RenderingServer.canvas_item_add_line(canvas,at-Vector2(1.5,0),at+Vector2(1.5,0),Color("e1ac67"),1,true)
