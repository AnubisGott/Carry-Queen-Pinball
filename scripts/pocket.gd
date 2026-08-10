class_name SidePocket
extends Area2D
## Fang-Mulde an den Seitenlaeufen: faengt die herabrollende Kugel kurz
## und puckt sie sofort wieder zurueck aufs Spielfeld.

var _busy := false
var _dir := -1.0


func _init(pos: Vector2, dir: float = -1.0) -> void:
	position = pos
	_dir = dir


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 24.0
	cs.shape = sh
	cs.position = Vector2(0, 4)
	add_child(cs)
	body_entered.connect(_on_enter)
	z_index = 4


func _draw() -> void:
	# Schale im Stil der mittleren Mulde, in den Farben der Seitenlaeufe.
	# Hell = Mulde faengt; dunkel = zu, die Kugel rollt durch.
	draw_circle(Vector2(0, 6), 20.0, Color(0.08, 0.13, 0.16, 0.9))
	var ring := Color(1.1, 0.4, 1.9) if not _busy else Color(0.4, 0.18, 0.65, 0.5)
	var inner := Color(1.22, 0.9, 0.2, 0.6) if not _busy else Color(0.6, 0.42, 0.1, 0.3)
	draw_arc(Vector2(0, 2), 24.0, 0.1 * PI, 0.9 * PI, 22, ring, 3.0)
	draw_arc(Vector2(0, 2), 16.0, 0.15 * PI, 0.85 * PI, 16, inner, 2.0)


func _on_enter(body: Node2D) -> void:
	if _busy or not body is PinBall or body.freeze:
		return
	# Nur von oben faellt die Kugel hinein - von unten kommend fliegt sie durch
	if body.linear_velocity.y < 30.0:
		return
	_busy = true
	queue_redraw()
	var ball := body as PinBall
	ball.set_deferred("freeze", true)
	ball.set_deferred("global_position", global_position + Vector2(0, -4))
	Sfx.play("lock", -6.0)
	Game.add_score(1500, ball)
	Game.emit("pocket")
	_eject_later(ball)


func _eject_later(ball: PinBall) -> void:
	await get_tree().create_timer(0.3, false).timeout
	if is_instance_valid(ball):
		ball.global_position = global_position + Vector2(0, -26)
		ball.freeze = false
		# Flach genug nach oben, dass das innere Horn nicht im Weg steht
		ball.linear_velocity = Vector2(_dir * randf_range(180, 260), randf_range(-660, -580))
		Sfx.play("eject", -4.0)
	await get_tree().create_timer(1.0, false).timeout
	_busy = false
	queue_redraw()
