class_name SidePocket
extends Area2D
## Fang-Mulde am rechten Lauf: faengt die herabrollende Kugel, zaehlt
## sicht- und hoerbar 3-2-1 runter und schiesst sie zurueck aufs Spielfeld.

var _busy := false
var _count_label: Label


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 24.0
	cs.shape = sh
	cs.position = Vector2(0, 4)
	add_child(cs)
	body_entered.connect(_on_enter)
	z_index = 4
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 26)
	_count_label.add_theme_color_override("font_color", Color(1.9, 1.3, 0.2))
	_count_label.add_theme_constant_override("outline_size", 7)
	_count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_count_label.position = Vector2(-40, -66)
	_count_label.size = Vector2(80, 32)
	_count_label.pivot_offset = Vector2(40, 16)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.visible = false
	add_child(_count_label)


func _draw() -> void:
	# Schale im Stil der mittleren Mulde, in den Farben der rechten Seite
	draw_circle(Vector2(0, 6), 20.0, Color(0.08, 0.13, 0.16, 0.9))
	draw_arc(Vector2(0, 2), 24.0, 0.1 * PI, 0.9 * PI, 22, Color(1.1, 0.4, 1.9), 3.0)
	draw_arc(Vector2(0, 2), 16.0, 0.15 * PI, 0.85 * PI, 16, Color(1.9, 1.3, 0.2, 0.6), 2.0)


func _on_enter(body: Node2D) -> void:
	if _busy or not body is PinBall or body.freeze:
		return
	_busy = true
	var ball := body as PinBall
	ball.set_deferred("freeze", true)
	ball.set_deferred("global_position", global_position + Vector2(0, -4))
	Sfx.play("lock", -6.0)
	Game.add_score(1500, ball)
	Game.add_ego(1)
	Game.emit("pocket")
	_countdown(ball)


func _countdown(ball: PinBall) -> void:
	await get_tree().create_timer(0.35, false).timeout
	for n in [3, 2, 1]:
		if not is_instance_valid(ball):
			break
		_count_label.text = str(n)
		_count_label.visible = true
		_count_label.scale = Vector2(1.4, 1.4)
		var tw := create_tween()
		tw.tween_property(_count_label, "scale", Vector2.ONE, 0.2)
		Sfx.play("count", -4.0)
		await get_tree().create_timer(0.55, false).timeout
	_count_label.visible = false
	if is_instance_valid(ball):
		ball.global_position = global_position + Vector2(0, -26)
		ball.freeze = false
		# Flach genug nach oben, dass das linke Horn nicht im Weg steht
		ball.linear_velocity = Vector2(randf_range(-260, -180), randf_range(-660, -580))
		Sfx.play("count_go", -3.0)
		Sfx.play("eject", -6.0)
	await get_tree().create_timer(1.2, false).timeout
	_busy = false
