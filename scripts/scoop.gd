class_name Scoop
extends Area2D
## Mulde am Ende der linken Spinner-Bahn: haelt die Kugel kurz fest,
## gibt Bonus und wirft sie zurueck in die Spielfeldmitte.

var _busy := false


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(60, 30)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_enter)
	z_index = 4


func _draw() -> void:
	# Hell = Mulde faengt; dunkel = zu, die Kugel rollt einfach durch.
	var main := Color(0.15, 1.6, 1.8) if not _busy else Color(0.08, 0.4, 0.45, 0.55)
	var sub := Color(0.15, 1.6, 1.8, 0.5) if not _busy else Color(0.08, 0.4, 0.45, 0.3)
	draw_arc(Vector2.ZERO, 22.0, 0.15 * PI, 0.85 * PI, 20, main, 3.0)
	draw_arc(Vector2.ZERO, 14.0, 0.2 * PI, 0.8 * PI, 16, sub, 2.0)


func _on_enter(body: Node2D) -> void:
	if _busy or not body is PinBall:
		return
	# Nur von oben faellt die Kugel hinein - von unten kommend fliegt sie
	# durch (und wird erst gefangen, wenn sie von oben zurueckfaellt).
	if body.linear_velocity.y < 30.0:
		return
	_busy = true
	queue_redraw()
	var ball := body as PinBall
	ball.set_deferred("freeze", true)
	ball.hide()
	Sfx.play("lock", -6.0)
	Game.add_score(1000, ball)
	Game.add_ego(2)
	Game.emit("scoop")
	_eject_later(ball)


func _eject_later(ball: PinBall) -> void:
	await get_tree().create_timer(0.9, false).timeout
	if is_instance_valid(ball):
		ball.global_position = global_position + Vector2(0, -20)
		ball.freeze = false
		ball.show()
		# Auswurf nach oben, zufaellig links oder rechts an den Hoernern vorbei
		var side := 1.0 if randf() < 0.5 else -1.0
		ball.linear_velocity = Vector2(side * randf_range(180, 260), -580)
		Sfx.play("eject", -4.0)
	await get_tree().create_timer(1.0, false).timeout
	_busy = false
	queue_redraw()
