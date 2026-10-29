extends RigidBody2D
var net_capture = false
signal hit
signal kicked
var hit_cooldown = 0.0

func _ready():
	# Layer 1 is solid architecture; layer 2 identifies the football for sensors.
	collision_layer = 2
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 8
	mass = 1.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.09
	angular_damp = -log(0.92)*60
	var material = PhysicsMaterial.new()
	material.bounce = 0.76
	material.friction = 0.003
	material.rough = true
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
	kicked.emit()
	return true

func _integrate_forces(state: PhysicsDirectBodyState2D):
	hit_cooldown = maxf(0,hit_cooldown-state.step)
	for i in state.get_contact_count():
		if state.get_contact_impulse(i).length()>50 and hit_cooldown==0:
			hit.emit.call_deferred()
			hit_cooldown = 0.09
	if not net_capture:
		physics_material_override.bounce = 0.76
		physics_material_override.friction = 0.003
		for i in state.get_contact_count():
			if absf(state.linear_velocity.dot(state.get_contact_local_normal(i)))<60:
				physics_material_override.bounce = 0.0
				physics_material_override.friction = 0.35 if absf(state.linear_velocity.x)<300 else 0.04
	if net_capture:
		state.linear_velocity *= Vector2(pow(0.95,state.step*120),pow(0.97,state.step*120))
		physics_material_override.bounce = 0.08
