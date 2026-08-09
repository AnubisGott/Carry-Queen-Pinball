class_name Flipper
extends AnimatableBody2D
## Flipperfinger, kinematisch rotiert (sync_to_physics schiebt die Kugel).

const SPEED := 22.0

var is_left := true
var rest_deg := 28.0
var pressed_deg := -32.0
var _target := 0.0


func _init(left: bool, pivot: Vector2) -> void:
	is_left = left
	position = pivot
	if left:
		rest_deg = 28.0
		pressed_deg = -32.0
	else:
		rest_deg = -28.0
		pressed_deg = 32.0
	rotation = deg_to_rad(rest_deg)
	_target = rotation


func _ready() -> void:
	sync_to_physics = true
	var pts := _shape_points()
	var col := CollisionPolygon2D.new()
	col.polygon = pts
	add_child(col)
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(0.08, 0.05, 0.12)
	add_child(poly)
	var line := Line2D.new()
	var closed := pts.duplicate()
	closed.append(pts[0])
	line.points = closed
	line.width = 3.0
	line.default_color = Color(1.7, 0.28, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	z_index = 5


func _shape_points() -> PackedVector2Array:
	var base := [Vector2(-14, -13), Vector2(62, -7), Vector2(78, 0), Vector2(62, 7), Vector2(-14, 13), Vector2(-20, 0)]
	if not is_left:
		var mirrored := []
		for p in base:
			mirrored.append(Vector2(-p.x, p.y))
		mirrored.reverse()
		base = mirrored
	return PackedVector2Array(base)


func set_pressed(on: bool) -> void:
	var new_target := deg_to_rad(pressed_deg if on else rest_deg)
	if on and new_target != _target:
		Sfx.play("flip", -8.0)
	_target = new_target


func _physics_process(delta: float) -> void:
	rotation = move_toward(rotation, _target, SPEED * delta)
