@tool
extends Node2D
## Each saved scene is one level. Gameplay is shared, never copied into levels.
@export var level_id: String = "new-level"
@export var level_name: String = "New level"
@export_range(1, 99) var par: int = 1
@export var star_shots: Vector2i = Vector2i(1, 3)
@export var level_size: Vector2 = Vector2(1280, 720):
	set(value):
		level_size = value.max(Vector2(320,240))
		queue_redraw()
@export_enum("Fit arena", "Follow ball") var camera_mode: int = 0
@export_range(0.3, 2) var follow_zoom: float = 1.0
@export var camera_origin: Vector2 = Vector2.ZERO
@export var follow_vertical: bool = true
@export var camera_speed: float = 6.0
@export var gravity: float = 1100.0
@export var background: Texture2D = preload("res://assets/park.webp")

func _ready():
	if not Engine.is_editor_hint() and get_parent() == get_tree().root:
		call_deferred("test_level")

func test_level():
	var game = load("res://scenes/main.tscn").instantiate()
	game.level_override = self
	get_tree().root.add_child(game)

func _draw():
	if Engine.is_editor_hint():
		draw_texture_rect(background,Rect2(Vector2.ZERO,level_size),false,Color(1,1,1,0.65))
		draw_rect(Rect2(Vector2.ZERO,level_size),Color("ffc97a"),false,3)

func problems() -> PackedStringArray:
	var errors = PackedStringArray()
	if level_id.strip_edges().is_empty(): errors.append("Set a stable Level ID")
	if not get_node_or_null("Spawn"): errors.append("Add a Marker2D named Spawn")
	if not get_node_or_null("Goal"): errors.append("Add a training goal named Goal")
	if star_shots.x < 1 or star_shots.y < star_shots.x: errors.append("Star thresholds must increase")
	for object in find_children("*", "Polygon2D", true, false):
		if object.polygon.size() < 3 or Geometry2D.triangulate_polygon(object.polygon).is_empty():
			errors.append("Invalid polygon: " + str(object.name))
	return errors

func _get_configuration_warnings() -> PackedStringArray:
	return problems()
