class_name Standup
extends StaticBody2D
## Standup-Target (I / C / H), montiert an der linken Orbit-Wand, zeigt nach rechts.

const W := 10.0
const H := 34.0

var letter := "I"
var lit := false
var _cool := 0.0


func _init(pos: Vector2, l: String) -> void:
	position = pos
	letter = l


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(W, H)
	cs.shape = sh
	add_child(cs)
	var area := Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(W + 10, H + 6)
	acs.shape = ash
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_hit)
	z_index = 4


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)


func _draw() -> void:
	var r := Rect2(-W / 2, -H / 2, W, H)
	var col := Color(0.2, 2.0, 1.2) if lit else Color(0.1, 0.5, 0.4)
	draw_rect(r, Color(0.03, 0.09, 0.08))
	draw_rect(r, col, false, 2.0)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(12, 5), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)


func _on_hit(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall:
		return
	_cool = 0.4
	Sfx.play("standup", -5.0)
	Game.add_score(300, body)
	Game.add_ego(1)
	if not lit:
		lit = true
		queue_redraw()
		Game.emit("standup", {"letter": letter})


func reset() -> void:
	lit = false
	queue_redraw()
