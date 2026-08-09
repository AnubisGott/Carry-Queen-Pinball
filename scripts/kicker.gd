class_name Throne
extends Area2D
## Der Thron: Ball-Lock (Ko-op-Multiball), Jackpot- und Hurry-Up-Ziel.

signal captured(ball: PinBall)

var _busy := false


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 16.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_enter)
	z_index = 4


func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.12, 0.05, 0.16))
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 32, Color(1.9, 0.9, 0.2), 2.5)
	var col := Color(1.9, 0.9, 0.2)
	var y := -26.0
	draw_polyline(PackedVector2Array([
		Vector2(-14, y + 8), Vector2(-14, y - 4), Vector2(-7, y + 2), Vector2(0, y - 8),
		Vector2(7, y + 2), Vector2(14, y - 4), Vector2(14, y + 8), Vector2(-14, y + 8),
	]), col, 2.0)


func _on_enter(body: Node2D) -> void:
	if _busy or not body is PinBall:
		return
	_busy = true
	var ball := body as PinBall
	ball.set_deferred("freeze", true)
	ball.hide()
	Sfx.play("lock", -4.0)
	captured.emit(ball)


func release_ready() -> void:
	_busy = false


func eject(ball: PinBall) -> void:
	if not is_instance_valid(ball):
		return
	ball.global_position = global_position + Vector2(0, 26)
	ball.linear_velocity = Vector2.ZERO
	ball.freeze = false
	ball.show()
	ball.apply_central_impulse(Vector2(randf_range(-80, 80), 520))
	Sfx.play("eject", -4.0)
