class_name Standup
extends StaticBody2D
## Standup-Target (I / C / H), montiert an der linken Orbit-Wand, zeigt nach rechts.

const W := 10.0
const H := 34.0

## Solange das Target leuchtet, wandert seine Innenfarbe langsam durch die
## Neonfarben des Tisches - sonst haelt man die stehenden Schalter fuer Deko.
const LIT_CYCLE := [
	Color(0.04, 0.34, 0.40),
	Color(0.38, 0.07, 0.23),
	Color(0.25, 0.10, 0.44),
	Color(0.42, 0.07, 0.10),
]
const CYCLE_TIME := 2.6

var letter := "I"
var lit := false
var _cool := 0.0
var _cycle_t := 0.0


func _init(pos: Vector2, l: String, rot_deg: float = 0.0) -> void:
	position = pos
	letter = l
	rotation = deg_to_rad(rot_deg)


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
	if lit:
		_cycle_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(-W / 2, -H / 2, W, H)
	var col := Color(0.18, 1.5, 0.95) if lit else Color(0.1, 0.5, 0.4)
	var bg := Color(0.03, 0.09, 0.08)
	if lit:
		# Langsamer Durchlauf durch die Neonfarben Cyan, Pink, Lila, Rot
		var f := fmod(_cycle_t / CYCLE_TIME, float(LIT_CYCLE.size()))
		var i := int(f)
		bg = LIT_CYCLE[i].lerp(LIT_CYCLE[(i + 1) % LIT_CYCLE.size()], f - i)
	draw_rect(r, bg)
	draw_rect(r, col, false, 2.0)
	# Buchstabe bleibt aufrecht, auch wenn das Target gedreht montiert ist
	var f := ThemeDB.fallback_font
	draw_set_transform(Vector2(12, 5), -rotation, Vector2.ONE)
	draw_string(f, Vector2.ZERO, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_hit(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall:
		return
	_cool = 0.4
	Sfx.play("standup", -5.0)
	Game.add_score(300, body)
	if not lit:
		lit = true
		queue_redraw()
		Game.emit("standup", {"letter": letter})


func reset() -> void:
	lit = false
	queue_redraw()
