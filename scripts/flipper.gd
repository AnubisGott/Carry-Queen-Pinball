class_name Flipper
extends AnimatableBody2D
## Flipperfinger, kinematisch rotiert (sync_to_physics schiebt die Kugel).
##
## Optik nach dem Vorbild des Referenzprojekts: dunkler Koerper mit pinker
## Kante, cyanfarbene Linie auf der Oberseite, Nieten und ein gruener
## Lagerring am Drehpunkt.  Die Kollisionsform bleibt davon unberuehrt.

const SPEED := 22.0
const METAL := Color(0.78, 0.83, 0.92)
const TIP_X := 78.0

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
	var col := CollisionPolygon2D.new()
	col.polygon = _shape_points()
	add_child(col)

	# Grafik als eigener Knoten - dreht sich mit dem Koerper mit.
	var art := Node2D.new()
	art.draw.connect(_draw_art.bind(art))
	add_child(art)
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


func _draw_art(c: Node2D) -> void:
	var pts := _shape_points()
	var tip := Vector2(TIP_X if is_left else -TIP_X, 0.0)
	var up := Vector2(0, -1)

	# Schlagschatten
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(3, 5))
	c.draw_colored_polygon(shadow, Color(0, 0, 0, 0.65))

	# Koerper: sehr dunkel, innen eine Spur heller
	c.draw_colored_polygon(pts, Color(0.015, 0.020, 0.030))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(Vector2(p.x * 0.88, p.y * 0.52))
	c.draw_colored_polygon(inner, Color(0.080, 0.090, 0.120))

	# pinke Aussenkante
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, Table.NEON_PINK, 3.0, true)

	# cyanfarbene Linie auf der Oberseite
	c.draw_line(Vector2.ZERO.lerp(tip, 0.16) + up * 8.0,
			Vector2.ZERO.lerp(tip, 0.92) + up * 3.5, Table.NEON_CYAN, 2.0, true)

	# Nieten laengs der Oberseite
	for f in [0.30, 0.52, 0.74]:
		c.draw_circle(Vector2.ZERO.lerp(tip, f) + up * 3.0, 2.0, METAL)

	# Lager: dunkler Kreis, gruener Ring, pinker Kern
	c.draw_circle(Vector2.ZERO, 13.0, Color(0.03, 0.04, 0.05))
	c.draw_arc(Vector2.ZERO, 13.0, 0, TAU, 28, Table.NEON_GREEN, 3.0, true)
	c.draw_circle(Vector2.ZERO, 3.0, Table.NEON_PINK)


func set_pressed(on: bool) -> void:
	var new_target := deg_to_rad(pressed_deg if on else rest_deg)
	if on and new_target != _target:
		Sfx.play("flip", -8.0)
	_target = new_target


func _physics_process(delta: float) -> void:
	rotation = move_toward(rotation, _target, SPEED * delta)
