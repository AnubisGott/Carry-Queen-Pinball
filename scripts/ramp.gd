class_name WireRamp
extends Node2D
## Zwei-Ebenen-Drahtbahn: faengt die Kugel oben links, fuehrt sie sichtbar
## UEBER den Tisch (S-Kurve) und entlaesst sie in der Feldmitte.

const POINTS := [
	Vector2(52, 265), Vector2(135, 330), Vector2(185, 415), Vector2(115, 495),
	Vector2(85, 565), Vector2(140, 630), Vector2(245, 655),
]
const EXIT_SPEED_MIN := 380.0

var curve := Curve2D.new()
var _riders: Array = []
var _len := 0.0


func _ready() -> void:
	for p in POINTS:
		curve.add_point(p)
	_smooth()
	_len = curve.get_baked_length()
	var area := Area2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(64, 44)
	cs.shape = sh
	area.position = Vector2(50, 268)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_enter)
	z_index = 30


func _smooth() -> void:
	for i in curve.point_count:
		var prev := curve.get_point_position(maxi(i - 1, 0))
		var next := curve.get_point_position(mini(i + 1, curve.point_count - 1))
		var dir := (next - prev) * 0.25
		curve.set_point_in(i, -dir)
		curve.set_point_out(i, dir)


func _on_enter(body: Node2D) -> void:
	if not body is PinBall:
		return
	if body.freeze or body.linear_velocity.y < -120.0:
		return
	for r in _riders:
		if r["ball"] == body:
			return
	var ball := body as PinBall
	ball.set_deferred("freeze", true)
	ball.z_index = 40
	ball.scale = Vector2(1.15, 1.15)
	_riders.append({"ball": ball, "dist": 0.0, "speed": maxf(ball.linear_velocity.length() * 0.7, 320.0)})
	Sfx.play("spin", -6.0)
	Game.add_score(750, ball)
	Game.add_ego(2)
	Game.emit("ramp")


func _physics_process(delta: float) -> void:
	var done: Array = []
	for r in _riders:
		if not is_instance_valid(r["ball"]):
			done.append(r)
			continue
		r["speed"] = minf(r["speed"] + 260.0 * delta, 900.0)
		r["dist"] += r["speed"] * delta
		if r["dist"] >= _len:
			_release(r)
			done.append(r)
		else:
			r["ball"].global_position = curve.sample_baked(r["dist"])
	for r in done:
		_riders.erase(r)


func _release(r: Dictionary) -> void:
	var ball: PinBall = r["ball"]
	var p1 := curve.sample_baked(_len)
	var p0 := curve.sample_baked(_len - 8.0)
	var dir := (p1 - p0).normalized()
	ball.global_position = p1 + dir * 4.0
	ball.freeze = false
	ball.z_index = 10
	ball.scale = Vector2.ONE
	ball.linear_velocity = dir * maxf(r["speed"], EXIT_SPEED_MIN)
	Sfx.play("eject", -8.0)


func _draw() -> void:
	var pts := curve.get_baked_points()
	if pts.size() < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var t: Vector2
		if i == 0:
			t = (pts[1] - pts[0]).normalized()
		else:
			t = (pts[i] - pts[i - 1]).normalized()
		var n := Vector2(-t.y, t.x) * 7.0
		left.append(pts[i] + n)
		right.append(pts[i] - n)
	draw_polyline(left, Color(1.2, 1.2, 1.4, 0.55), 2.0)
	draw_polyline(right, Color(1.2, 1.2, 1.4, 0.55), 2.0)
	var d := 0.0
	while d < _len:
		var p := curve.sample_baked(d)
		var p2 := curve.sample_baked(minf(d + 6.0, _len))
		var t := (p2 - p).normalized()
		var n := Vector2(-t.y, t.x) * 7.0
		draw_line(p + n, p - n, Color(1.1, 1.1, 1.3, 0.35), 1.5)
		draw_line(p + n, p - n + t * 8.0, Color(1.1, 1.1, 1.3, 0.18), 1.0)
		d += 16.0
	draw_arc(Vector2(50, 268), 24.0, 0, TAU, 24, Color(0.15, 1.6, 1.8, 0.6), 2.0)
