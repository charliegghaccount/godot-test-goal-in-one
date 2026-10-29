extends RigidBody2D
var net_capture = false
var ice_contacts = {}
var incoming_velocity = Vector2.ZERO
signal hit
signal kicked
var hit_cooldown = 0.0
var support_remaining = 0.0
var support_normal = Vector2.UP
var support_velocity = Vector2.ZERO

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
	var art = preload("res://scripts/ball_art.gd").new()
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
	support_remaining = 0.0
	linear_velocity = shot_velocity(pull)
	angular_velocity = clampf(angular_velocity * 0.2 - pull.limit_length(140).x * 0.03, -21, 21)
	incoming_velocity = linear_velocity
	kicked.emit()
	return true

func _integrate_forces(state: PhysicsDirectBodyState2D):
	hit_cooldown = maxf(0,hit_cooldown-state.step)
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		if is_instance_valid(collider) and collider.has_method("impact"):
			collider.impact(absf((incoming_velocity-state.get_contact_collider_velocity_at_position(i)).dot(state.get_contact_local_normal(i))))
		if state.get_contact_impulse(i).length()>50 and hit_cooldown==0:
			hit.emit.call_deferred()
			hit_cooldown = 0.09
	if not net_capture:
		support_remaining = maxf(0,support_remaining-state.step)
		for i in state.get_contact_count():
			var normal = state.get_contact_local_normal(i)
			var surface_velocity = state.get_contact_collider_velocity_at_position(i)
			if normal.y < -0.65 and absf((state.linear_velocity-surface_velocity).dot(normal)) < 60:
				support_normal = normal
				support_velocity = surface_velocity
				support_remaining = 0.08
		var relative = state.linear_velocity-support_velocity
		var supported = support_remaining > 0 and absf(relative.dot(support_normal)) < 60
		physics_material_override.bounce = 0.0 if supported else 0.76
		physics_material_override.friction = (0.35 if absf(relative.x)<320 else 0.04) if supported else 0.003
		var ice_scale = 1.0
		for value in ice_contacts.values(): ice_scale = minf(ice_scale,float(value)/0.003)
		if ice_scale<1: physics_material_override.friction = 0.003*ice_scale
		# Suppress the long low-speed tail without changing flight or high-speed shots.
		# Brief support hysteresis avoids re-enabling bounce between resting contacts.
		if supported:
			var tangent = Vector2(-support_normal.y,support_normal.x)
			var speed = relative.dot(tangent)
			if absf(speed) < 320:
				state.linear_velocity += tangent*(move_toward(speed,0,110*ice_scale*state.step)-speed)
	if net_capture:
		state.linear_velocity *= Vector2(pow(0.95,state.step*120),pow(0.97,state.step*120))
		physics_material_override.bounce = 0.08

	incoming_velocity = state.linear_velocity
