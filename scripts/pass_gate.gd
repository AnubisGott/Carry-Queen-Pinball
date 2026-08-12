class_name PassGate
extends Area2D
## Durchlauf in der Tischmitte zwischen den goldenen Hoernern.  Frueher sass
## hier eine Mulde, die die Kugel fing und wieder ausspuckte - jetzt rollt
## die Kugel einfach hindurch.
##
## Wird der Durchlauf fuer eine Sonderfunktion gebraucht (Hurry-Up abholen,
## Mega-Jackpot im Wizard), blinken die beiden Hoerner.  Sobald die Kugel
## durchgerollt ist, hoert das Blinken auf.

const BASE_SCORE := 300
const BLINK_SPEED := 7.0

var armed := false

var _horns: Array = []
var _t := 0.0
var _cool := 0.0


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(30, 16)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_pass)
	z_index = 4


## Hoerner anmelden, die beim Blinken mitleuchten sollen.
func watch_horn(line: Line2D) -> void:
	if line != null:
		_horns.append({"line": line, "color": line.default_color,
				"width": line.width})


func set_armed(on: bool) -> void:
	if armed == on:
		return
	armed = on
	_t = 0.0
	if not armed:
		_glow(0.0)


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if armed:
		_t += delta * BLINK_SPEED
		_glow(0.5 + 0.5 * sin(_t))


## 0 = Ruhezustand, 1 = volle Helligkeit.
func _glow(t: float) -> void:
	for h in _horns:
		var c: Color = h["color"]
		h["line"].default_color = Color(c.r + 1.1 * t, c.g + 0.8 * t,
				c.b + 0.3 * t, minf(1.0, c.a + 0.4 * t))
		h["line"].width = h["width"] * (1.0 + 0.6 * t)


func _on_pass(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall or body.freeze:
		return
	_cool = 0.4
	Sfx.play("tick", -4.0)
	Game.add_score(BASE_SCORE, body)
	Game.emit("gate", {"armed": armed})
	set_armed(false)
