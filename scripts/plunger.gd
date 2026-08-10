class_name Plunger
extends AnimatableBody2D
## Sichtbare Abschuss-Feder: der Ball sitzt auf dem Teller.  Solange die
## Leertaste gehalten wird, zieht sich die Feder zusammen und der Ball sinkt
## mit; beim Loslassen schnellen Teller und Ball nach vorne.

const REST_Y := 873.0
const TRAVEL := 40.0
const BASE_Y := 933.0
const VIOLET := Color(1.1, 0.4, 1.9)

var _target := REST_Y


func _init() -> void:
	position = Vector2(495, REST_Y)


func _ready() -> void:
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 5.0
	cap.height = 36.0
	cs.shape = cap
	cs.rotation = PI / 2.0
	add_child(cs)
	z_index = 6


func compress(p: float) -> void:
	_target = REST_Y + TRAVEL * clampf(p, 0.0, 1.0)


func release() -> void:
	_target = REST_Y


func _physics_process(delta: float) -> void:
	# Langsam sinken, aber blitzschnell zurueckschnellen
	var speed := 70.0 if _target > position.y else 1100.0
	var new_y := move_toward(position.y, _target, speed * delta)
	if new_y != position.y:
		position.y = new_y
		queue_redraw()


func _draw() -> void:
	var h := BASE_Y - position.y
	# Spiralfeder als Zickzack zwischen Teller und Sockel
	var n := 10
	var pts := PackedVector2Array()
	pts.append(Vector2(0, 4))
	for i in n:
		var t := (i + 0.5) / n
		pts.append(Vector2(12.0 if i % 2 == 0 else -12.0, 4.0 + (h - 8.0) * t))
	pts.append(Vector2(0, h - 2.0))
	draw_polyline(pts, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.28), 6.0)
	draw_polyline(pts, VIOLET, 2.5)
	# Sockel am Bahnboden
	draw_line(Vector2(-14, h), Vector2(14, h), Color(0.08, 0.13, 0.16), 6.0)
	draw_line(Vector2(-14, h - 1.5), Vector2(14, h - 1.5),
			Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.8), 2.0)
	# Teller, auf dem die Kugel sitzt
	draw_line(Vector2(-16, 0), Vector2(16, 0), Color(0.08, 0.13, 0.16), 9.0)
	draw_line(Vector2(-16, -2.5), Vector2(16, -2.5), Color(1.6, 1.6, 1.8, 0.9), 2.2)
	draw_line(Vector2(-16, 2.0), Vector2(16, 2.0), VIOLET, 2.0)
