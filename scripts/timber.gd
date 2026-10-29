@tool
extends Polygon2D
## Use Godot's polygon toolbar to draw and move vertices. Collision uses this exact polygon.
@export var grass_edging: bool = false:
	set(value):
		grass_edging = value
		queue_redraw()
@export var seam_points: PackedVector2Array = []
var body: StaticBody2D
var collision: CollisionPolygon2D
var last_polygon = PackedVector2Array()

func _ready():
	texture = preload("res://assets/wood.webp")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_sync()

func _process(_dt):
	if polygon != last_polygon: _sync()

func _sync():
	last_polygon = polygon.duplicate()
	uv = PackedVector2Array()
	for point in polygon: uv.append(point*texture.get_width()/256.0)
	if not is_instance_valid(body):
		body = StaticBody2D.new()
		add_child(body)
		collision = CollisionPolygon2D.new()
		body.add_child(collision)
		for at in seam_points:
			var cap = CollisionShape2D.new()
			cap.shape = CircleShape2D.new()
			cap.shape.radius = 5.2
			cap.position = at
			body.add_child(cap)
		var material = PhysicsMaterial.new()
		material.friction = 0.003
		body.physics_material_override = material
	collision.polygon = polygon
	queue_redraw()

func setup(points: PackedVector2Array):
	polygon = points
	_sync()

func _draw():
	if polygon.size() < 3: return
	var border = polygon.duplicate()
	border.append(polygon[0])
	draw_polyline(border,Color("5f3a22"),3,true)
	for at in seam_points:
		draw_circle(at,5.2,Color("425863"))
		draw_circle(at+Vector2(-1,-1),1.5,Color("d8e0df"))
	var area = 0.0
	for i in polygon.size(): area += polygon[i].cross(polygon[(i+1)%polygon.size()])
	if grass_edging:
		for i in polygon.size():
			var a = polygon[i]
			var b = polygon[(i+1)%polygon.size()]
			var normal = Vector2((b-a).y,-(b-a).x).normalized() * signf(area)
			if normal.y < -0.2:
				draw_line(a,b,Color("6ba238"),7,true)
				var count = int(a.distance_to(b)/12)
				for j in count:
					var at = a.lerp(b,float(j)/maxi(count,1))
					draw_line(at,at+normal*8+Vector2(3,0),Color("9ac94b"),2,true)
