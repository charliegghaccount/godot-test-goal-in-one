extends StaticBody2D

func setup(points: PackedVector2Array):
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	add_child(collision)
	var face = Polygon2D.new()
	face.polygon = points
	face.texture = preload("res://assets/wood.webp")
	face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uv = PackedVector2Array()
	for point in points: uv.append(point * 0.65)
	face.uv = uv
	add_child(face)
	var border = Line2D.new()
	border.points = points
	border.closed = true
	border.width = 3
	border.default_color = Color("593a24")
	add_child(border)
	var material = PhysicsMaterial.new()
	material.friction = 0.003
	physics_material_override = material
