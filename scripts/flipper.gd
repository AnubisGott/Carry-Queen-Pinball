class_name Flipper
extends AnimatableBody2D
## Flipperfinger, kinematisch rotiert (sync_to_physics schiebt die Kugel).
##
## Optik nach dem Vorbild des Referenzprojekts: dunkler Koerper mit pinker
## Kante, cyanfarbene Linie auf der Oberseite, Nieten und ein gruener
## Lagerring am Drehpunkt.  Die Kollisionsform bleibt davon unberuehrt.

const SPEED := 22.0
## Zurueck in die Ruhelage geht es deutlich langsamer - wie bei einer echten
## Rueckstellfeder.  Ein schnell wegfallendes Blatt laesst die aufliegende
## Kugel sonst kurz in der Luft stehen und sie kommt als Huepfer wieder auf.
const RETURN_SPEED := 4.0
const METAL := Color(0.78, 0.83, 0.92)
const TIP_X := 78.0
## Schub des "Solenoids": eine aufliegende Kugel bekommt beim Schlag diesen
## Stoss quer zum Blatt mit.  Ohne ihn haette eine am Blattansatz liegende
## Kugel kaum Umfangsgeschwindigkeit und kaeme nicht bis nach oben - aus dem
## Stand muss der Schlag aber bis zu den G-G-E-Z-Gassen (y = 212) reichen.
const FLIP_POWER := 2150.0
## Anteil, den die Kugel am Blattansatz mindestens abbekommt (an der Spitze
## wirkt der volle Schub - so bleibt die Stelle des Treffers spuerbar).
const FLIP_BASE := 0.62
## Abschusswinkel ueber der Waagerechten, zur Tischmitte hin.  Am Blattansatz
## steil (geht aufs Oberfeld zu den G-G-E-Z-Gassen), an der Spitze flacher
## (der klassische Querschuss auf die gegenueberliegende Seite).
const FLIP_ANGLE_BASE := 72.0
const FLIP_ANGLE_TIP := 60.0

var is_left := true
var rest_deg := 28.0
var pressed_deg := -32.0
var _target := 0.0
var _held := false
var _flash := 0.0
var _art: Node2D
var _area: Area2D
## Wie lange der Stoss nach dem Druecken noch bereitsteht.  Eine Kugel, die
## beim Nachdruecken kurz keinen Blattkontakt hat, bekommt ihn so trotzdem.
var _boost_left := 0.0


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
	# Absorbierendes Material: die Kugel dopst nicht auf dem Blatt, sondern
	# bleibt liegen und rollt.  Der Schlag kommt allein aus der Drehung.
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.32
	pm.absorbent = true
	pm.friction = 0.7
	physics_material_override = pm
	var col := CollisionPolygon2D.new()
	col.polygon = _shape_points()
	add_child(col)

	# Grafik als eigener Knoten - dreht sich mit dem Koerper mit.
	var art := Node2D.new()
	art.draw.connect(_draw_art.bind(art))
	add_child(art)
	_art = art
	z_index = 5

	# Beruehrungs-Sensor: laesst den Hebel nur bei Ballkontakt aufleuchten
	var area := Area2D.new()
	var acol := CollisionPolygon2D.new()
	var grown := PackedVector2Array()
	for p in _shape_points():
		grown.append(p * 1.18)
	acol.polygon = grown
	area.add_child(acol)
	add_child(area)
	area.body_entered.connect(_on_touch)
	_area = area


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

	# Neon-Schein nur bei Ballberuehrung, darauf die pinke Aussenkante
	var closed := pts.duplicate()
	closed.append(pts[0])
	if _flash > 0.0:
		c.draw_polyline(closed, Color(Table.NEON_PINK.r, Table.NEON_PINK.g,
				Table.NEON_PINK.b, 0.30 * _flash), 10.0, true)
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
		_boost_left = 0.16
	_target = new_target
	_held = on


func _on_touch(body: Node2D) -> void:
	if body is PinBall:
		_flash = 1.0
		_art.queue_redraw()


## Schlag aus dem Stand: alles, was beim Hochschwingen auf dem Blatt liegt,
## bekommt einen Stoss quer zum Blatt.  Die reine Drehung reicht dafuer nicht -
## eine am Ansatz liegende Kugel wuerde kaum wegkommen.  Gibt zurueck, ob eine
## Kugel getroffen wurde.
func _kick_resting_balls() -> bool:
	if _area == null or _target == rotation:
		return false
	var hit := false
	# Die Kugel geht schraeg nach oben zur Tischmitte weg - links nach rechts
	# oben, rechts nach links oben.  Wie steil, haengt vom Treffpunkt ab.
	# Waere die aktuelle Blattstellung massgeblich, ginge ein Schlag aus dem
	# gehaltenen Hebel seitwaerts in den Slingshot statt nach oben.
	var side := 1.0 if is_left else -1.0
	for b in _area.get_overlapping_bodies():
		var ball := b as PinBall
		if ball == null or ball.freeze:
			continue
		var arm := ball.global_position - global_position
		var reach := clampf(arm.length() / TIP_X, 0.0, 1.0)
		var deg := lerpf(FLIP_ANGLE_BASE, FLIP_ANGLE_TIP, reach)
		var push := Vector2(cos(deg_to_rad(deg)) * side, -sin(deg_to_rad(deg)))
		var power := FLIP_POWER * lerpf(FLIP_BASE, 1.0, reach)
		# Nur so viel zugeben, dass die Kugel auf Solltempo kommt - eine
		# schon schnell anfliegende Kugel wird dadurch nicht doppelt beschleunigt
		var have := ball.linear_velocity.dot(push)
		if have < power:
			ball.apply_central_impulse(push * (power - have))
		hit = true
		_flash = 1.0
		_art.queue_redraw()
	return hit


func _physics_process(delta: float) -> void:
	if _boost_left > 0.0:
		_boost_left = 0.0 if _kick_resting_balls() else _boost_left - delta
	rotation = move_toward(rotation, _target, (SPEED if _held else RETURN_SPEED) * delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		_art.queue_redraw()
