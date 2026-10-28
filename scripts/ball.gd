extends RigidBody2D

func _ready():
	mass = 1.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp = 0.09
	angular_damp = 4.8
	var material = PhysicsMaterial.new()
	material.bounce = 0.76
	material.friction = 0.003
	physics_material_override = material
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 16
	add_child(shape)
	var art = Sprite2D.new()
	art.texture = preload("res://assets/football.svg")
	art.scale = Vector2.ONE * 32.0 / art.texture.get_width()
	add_child(art)

func shot_velocity(pull: Vector2) -> Vector2:
	var direction = -pull.normalized()
	var retained = linear_velocity * 0.55
	var power = minf(pull.length(), 140.0) * 7.5
	var projection = retained.dot(direction)
	if projection < -power * 0.25:
		retained += direction * (-power * 0.25 - projection)
	return retained + direction * power

func kick(pull: Vector2):
	if pull.length() < 6:
		return false
	sleeping = false
	linear_velocity = shot_velocity(pull)
	angular_velocity = clampf(angular_velocity * 0.2 - pull.limit_length(140).x * 0.03, -21, 21)
	return true
