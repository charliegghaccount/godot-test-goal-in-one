extends Node2D
func patch(center: Vector2, radius: float, angle: float, circle: PackedVector2Array):
	var points = PackedVector2Array()
	for i in 5: points.append(center+Vector2.from_angle(angle+i*TAU/5)*radius)
	for polygon in Geometry2D.intersect_polygons(points,circle): draw_colored_polygon(polygon,Color("183247"))
func _draw():
	draw_circle(Vector2(0,2),17,Color("15344922"))
	draw_circle(Vector2.ZERO,16.75,Color("173449"))
	for i in range(32,0,-1):
		var t = float(i)/32
		draw_circle(Vector2(-3,-4)*(1-t),t*16,Color("ffffff").lerp(Color("b7c7d2"),pow(t,3)*0.8))
	var circle = PackedVector2Array()
	for i in 64: circle.append(Vector2.from_angle(i*TAU/64)*15.5)
	patch(Vector2.ZERO,4.5,-PI/2,circle)
	for i in 5:
		var a = i*TAU/5-PI/2
		var at = Vector2.from_angle(a)*12
		draw_line(Vector2.from_angle(a)*4,at,Color("9aa9b2"),0.65,true)
		patch(at,4.4,a,circle)
	draw_circle(Vector2(-4,-5),2,Color("ffffff8c"))
