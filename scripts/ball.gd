class_name PinBall
extends RigidBody2D
## Die Kugel. "is_carry" = die pinke Carry-Kugel (zaehlt im Multiball x10).

const RADIUS := 11.0
const MAX_SPEED := 2400.0

var is_carry := false


func _ready() -> void:
	add_to_group("balls")
	mass = 1.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp = 0.06
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.32
	pm.friction = 0.08
	physics_material_override = pm
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	cs.shape = shape
	add_child(cs)
	z_index = 10


var _still := 0.0


func _physics_process(delta: float) -> void:
	# Anti-Klemm: Ball, der irgendwo laenger festhaengt, bekommt einen Schubs.
	if freeze or global_position.x > 470.0:
		_still = 0.0
		return
	if linear_velocity.length() < 8.0:
		_still += delta
		if _still > 12.0:
			_still = 0.0
			apply_central_impulse(Vector2(randf_range(-140, 140), -280))
	else:
		_still = 0.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var v := state.linear_velocity
	if v.length() > MAX_SPEED:
		state.linear_velocity = v.normalized() * MAX_SPEED


func _draw() -> void:
	if is_carry:
		draw_circle(Vector2.ZERO, RADIUS + 6.0, Color(1.6, 0.2, 0.9, 0.25))
		draw_circle(Vector2.ZERO, RADIUS, Color(1.8, 0.25, 1.0))
		draw_circle(Vector2(-3, -3), 3.5, Color(2.0, 1.4, 1.8))
	else:
		draw_circle(Vector2.ZERO, RADIUS, Color(0.75, 0.78, 0.85))
		draw_circle(Vector2(-3, -3), 3.5, Color(1.2, 1.25, 1.4))


func set_carry(v: bool) -> void:
	is_carry = v
	queue_redraw()
