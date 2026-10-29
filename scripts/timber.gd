@tool
extends Polygon2D
## Use Godot's polygon toolbar to draw and move vertices. Collision uses this exact polygon.
@export var grass_edging: bool = false:
	set(value):
		grass_edging = value
		queue_redraw()
@export var seam_points: PackedVector2Array = []
@export var grain_angle = 0.0
var last_grain = 0.0
var body: StaticBody2D
var collision: CollisionPolygon2D
var last_polygon = PackedVector2Array()

func _ready():
	texture = preload("res://assets/wood.webp")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_sync()

func _process(_dt):
	if polygon != last_polygon or grain_angle!=last_grain: _sync()

func _sync():
	last_polygon = polygon.duplicate()
	last_grain = grain_angle
	var coordinates = PackedVector2Array()
	var local = PackedVector2Array()
	var origin = Vector2(INF,INF)
	for point in polygon:
		var at = point.rotated(-grain_angle)
		local.append(at)
		origin = origin.min(at)
	for point in local: coordinates.append((point-origin)*texture.get_width()/256.0)
	uv = coordinates
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
	if polygon.size()<3: return
	if seam_points.size()==2:
		var a = seam_points[0]
		var b = seam_points[1]
		var axis = (b-a).normalized()
		var normal = axis.orthogonal()
		draw_line(a,b,Color("6b3b1e"),10.4,true)
		for end in [a,b]: draw_circle(end,5.2,Color("6b3b1e"))
		var surface = PackedVector2Array([a-normal*4.16,b-normal*4.16,b+normal*4.16,a+normal*4.16])
		var beam_uv = PackedVector2Array()
		for point in surface: beam_uv.append((point-a).rotated(-axis.angle())/256.0)
		draw_polygon(surface,PackedColorArray([Color.WHITE]),beam_uv,texture)
		draw_line(a+normal*2.9,b+normal*2.9,Color("ffe6ad99"),1.2,true)
		draw_line(a-normal*2.9,b-normal*2.9,Color("65331966"),1.2,true)
		for at in seam_points:
			draw_rect(Rect2(at-Vector2.ONE*4.8,Vector2.ONE*9.6),Color("34454c"))
			preload("res://scripts/game_art.gd").bolt(self,at,1.56)
		if grass_edging:
			var start = a if a.x<b.x else b
			var end = b if a.x<b.x else a
			draw_line(start-Vector2(0,3.5),end-Vector2(0,3.5),Color("47ab32"),3,true)
			for x in range(int(start.x)+3,int(end.x)-2,9):
				draw_polyline(PackedVector2Array([Vector2(x,start.y-2),Vector2(x+2,start.y-5),Vector2(x+4,start.y-2)]),Color("b4ed59"),1.5,true)
	else: preload("res://scripts/game_art.gd").timber(self,polygon,grass_edging,grain_angle)
