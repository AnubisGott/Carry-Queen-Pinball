class_name DropTarget
extends StaticBody2D
## Drop-Target der D-A-M-A-G-E-Bank.

const W := 30.0
const H := 12.0

var letter := "D"
var dropped := false
var _col: CollisionShape2D
var _area: Area2D


func _init(pos: Vector2, l: String) -> void:
	position = pos
	letter = l


func _ready() -> void:
	_col = CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(W, H)
	_col.shape = sh
	add_child(_col)
	_area = Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(W + 8, H + 8)
	acs.shape = ash
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(_on_hit)
	z_index = 4


func _draw() -> void:
	if dropped:
		return
	var r := Rect2(-W / 2, -H / 2, W, H)
	draw_rect(r, Color(0.1, 0.03, 0.08))
	draw_rect(r, Color(1.8, 0.3, 0.5), false, 2.0)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-5, 4), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(2.0, 0.5, 0.8))


func _on_hit(body: Node2D) -> void:
	if dropped or not body is PinBall:
		return
	dropped = true
	_col.set_deferred("disabled", true)
	_area.set_deferred("monitoring", false)
	queue_redraw()
	Sfx.play("target", -4.0)
	var pts := Game.add_score(500, body)
	Game.damage_points += pts
	Game.add_ego(2)
	Game.emit("drop_target", {"letter": letter})


func reset() -> void:
	dropped = false
	_col.set_deferred("disabled", false)
	_area.set_deferred("monitoring", true)
	queue_redraw()
