@tool
extends StaticBody2D
@export var dimensions = Vector2(80,120)
@export var threshold = 540.0
@export var grass_edging = false
var damage = 0.0
var broken = false
var game: Node
var collision: CollisionShape2D
func _ready():
	collision_mask = 2
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = dimensions
	add_child(collision)
	var material = PhysicsMaterial.new()
	material.friction = 0.003
	material.bounce = 0.0 # Retain ball restitution (Matter takes max, Godot adds).
	physics_material_override = material
func bind_game(runtime: Node): game = runtime
func impact(speed: float):
	if broken: return
	damage = maxf(damage,minf(1,speed/maxf(threshold,1)))
	queue_redraw()
	if speed<threshold: return
	broken = true
	shatter.call_deferred()
func shatter():
	collision.disabled = true
	hide()
	if is_instance_valid(game): game.mechanic_feedback("break",global_position)
func _draw():
	preload("res://scripts/game_art.gd").rectangle(self,dimensions,grass_edging)
	draw_polyline(PackedVector2Array([Vector2(-6,-dimensions.y/2+8),Vector2(5,-8),Vector2(-4,2),Vector2(6,dimensions.y/2-8)]),Color("704024"),2,true)
	draw_rect(Rect2(-dimensions/2+Vector2.ONE*4,dimensions-Vector2.ONE*8),Color("fff1b3") if damage>0.4 else Color("f4cb85"),false,1.5)
