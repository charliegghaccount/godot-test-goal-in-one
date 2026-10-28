@tool
extends Polygon2D
## Use Godot's polygon toolbar to draw and move vertices. Collision uses this exact polygon.
@export var grass_edging: bool = false:
	set(value):
		grass_edging = value
		queue_redraw()
var body: StaticBody2D
var collision: CollisionPolygon2D
var last_polygon = PackedVector2Array()

func _ready():
	texture = preload("res://assets/wood.webp")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_sync()

func _process(_dt):
	if polygon != last_polygon: _sync()

func _sync():
	last_polygon = polygon.duplicate()
	uv = polygon
	if not is_instance_valid(body):
		body = StaticBody2D.new()
		add_child(body)
		collision = CollisionPolygon2D.new()
		body.add_child(collision)
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
	draw_polyline(border,Color("624027"),3,true)
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
