class_name Spinner
extends Area2D
## "OP"-Spinner in der linken Orbit-Bahn.

var _cool := 0.0
var _spin := 0.0
var _spin_speed := 0.0


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(56, 10)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_pass)
	z_index = 4


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _spin_speed > 0.1:
		_spin += _spin_speed * delta
		_spin_speed = lerpf(_spin_speed, 0.0, delta * 2.0)
		queue_redraw()


func _draw() -> void:
	var w := 26.0 * absf(cos(_spin))
	draw_line(Vector2(-w, 0), Vector2(w, 0), Color(0.2, 1.8, 2.0), 4.0)
	draw_circle(Vector2(-28, 0), 3.0, Color(0.2, 1.8, 2.0))
	draw_circle(Vector2(28, 0), 3.0, Color(0.2, 1.8, 2.0))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-10, -12), "OP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 2.0, 2.2))


func _on_pass(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall:
		return
	_cool = 0.5
	var pb := body as RigidBody2D
	_spin_speed = clampf(pb.linear_velocity.length() / 30.0, 8.0, 60.0)
	Sfx.play("spin", -8.0)
	Game.add_score(200, body)
	Game.add_ego(2)
	Game.emit("spinner")
