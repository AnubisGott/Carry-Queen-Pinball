class_name RolloverLane
extends Area2D
## Rollover-Gasse: die Kugel rollt durch, der Buchstabe leuchtet auf.
## Ob die ganze Bank komplett ist, prueft main.gd (Event "rollover").

var letter := ""
var lit := false
var _dir := Vector2.DOWN
var _label: Label


func _init(pos: Vector2, letter_: String, dir: Vector2) -> void:
	position = pos
	letter = letter_
	_dir = dir.normalized()


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 12.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_pass)
	z_index = 3
	_label = Label.new()
	_label.text = letter
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_constant_override("outline_size", 5)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.position = Vector2(-9, -12)
	_label.size = Vector2(18, 22)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	_update()


func set_lit(v: bool) -> void:
	lit = v
	_update()
	queue_redraw()


func _update() -> void:
	_label.add_theme_color_override("font_color",
			Table.NEON_GOLD if lit else Color(0.55, 0.5, 0.7))


func _on_pass(body: Node2D) -> void:
	if not body is PinBall or body.freeze:
		return
	if lit:
		Sfx.play("tick", -8.0)
		return
	set_lit(true)
	Sfx.play("standup", -6.0)
	Game.add_score(500, body)
	Game.emit("rollover", {"letter": letter, "index": get_index()})


func _draw() -> void:
	# Leucht-Kapsel laengs der Gasse
	var a := -_dir * 16.0
	var b := _dir * 16.0
	var col := Table.NEON_GOLD if lit else Color(0.5, 0.25, 0.85, 0.5)
	draw_line(a, b, Color(col.r, col.g, col.b, 0.18), 16.0)
	draw_line(a, b, col, 2.5)
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, col, 1.5)
