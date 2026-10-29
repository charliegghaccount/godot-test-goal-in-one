extends Control
var count = 0
func _draw():
	for i in range(3):
		var center = Vector2(size.x/2+(i-1)*54,26)
		var points = PackedVector2Array()
		for n in range(10):points.append(center+Vector2.from_angle(-PI/2+n*PI/5)*(21 if n%2==0 else 9))
		draw_colored_polygon(points,Color("ffd15c") if i<count else Color("765238"))
		points.append(points[0])
		draw_polyline(points,Color("59371e"),2,true)
