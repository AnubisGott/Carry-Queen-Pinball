class_name Slingshot
extends StaticBody2D
## Slingshot-Kicker im Spike-Schulterpolster-Look.

var pts: PackedVector2Array
var kick_normal: Vector2
var _cool := 0.0
var _flash := 0.0
## Schlagflaeche: Stuetzpunkt und Aussen-Normale.  Nur davor wird
## abgestossen - an Rueckseite und Unterkante ist der Slingshot eine
## normale Bande (dort laeuft die Kugel die Inlane hinunter).
var _face_at := Vector2.ZERO
var _face_n := Vector2.RIGHT


func _init(points: Array, normal: Vector2) -> void:
	pts = PackedVector2Array(points)
	kick_normal = normal.normalized()


func _ready() -> void:
	_find_face()
	var col := CollisionPolygon2D.new()
	col.polygon = pts
	add_child(col)
	var area := Area2D.new()
	var acol := CollisionPolygon2D.new()
	var c := _centroid()
	var grow := PackedVector2Array()
	for p in pts:
		grow.append(c + (p - c) * 1.12)
	acol.polygon = grow
	area.add_child(acol)
	add_child(area)
	area.body_entered.connect(_on_hit)
	z_index = 4


## Sucht die Kante, deren Aussen-Normale am besten zur Abstossrichtung
## passt - das ist die Schlagflaeche.
func _find_face() -> void:
	var c := _centroid()
	var best := -INF
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var n := (b - a).orthogonal().normalized()
		if n.dot((a + b) * 0.5 - c) < 0.0:
			n = -n
		var d := n.dot(kick_normal)
		if d > best:
			best = d
			_face_at = a
			_face_n = n


func _centroid() -> Vector2:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	return c / pts.size()


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	draw_colored_polygon(pts, Color(0.07, 0.04, 0.1))
	var closed := pts.duplicate()
	closed.append(pts[0])
	var col := Color(1.7, 0.3, 1.0).lerp(Color(2.0, 2.0, 2.0), _flash)
	draw_polyline(closed, col, 3.0)
	var c := _centroid()
	for p in pts:
		draw_line(c, c + (p - c) * 0.95, Color(col.r, col.g, col.b, 0.35), 1.5)


func _on_hit(body: Node2D) -> void:
	if not body is PinBall or _cool > 0.0:
		return
	# Nur Treffer vor der Schlagflaeche zaehlen
	if _face_n.dot(body.global_position - _face_at) <= 0.0:
		return
	_cool = 0.12
	_flash = 1.0
	body.apply_central_impulse(kick_normal * 520.0)
	Sfx.play("sling", -6.0)
	Game.add_score(60, body)
	Game.emit("sling")
	queue_redraw()
