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
## So blass steht der Pfeil da, solange der Durchlauf nichts Besonderes ist
const RUHE_ALPHA := 0.35

var armed := false

var _horns: Array = []
var _pfeile: Array = []
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


## Ein Pfeil, der dasselbe Blinken mitmacht.  Nicht ueber set_blink() der
## Deko - der liefe mit eigener Uhr und geriete gegen die Hoerner aus dem
## Takt.  Hier haengt er an derselben Helligkeit.
func watch_pfeil(node: Node2D) -> void:
	if node != null:
		_pfeile.append(node)
		node.modulate = Color(1.0, 1.0, 1.0, RUHE_ALPHA)


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
	for p in _pfeile:
		# Ueber 1 hinaus, damit er wie die Hoerner ins Leuchten geht statt nur
		# heller zu werden - der Tisch hat einen Glow-Schwellwert von 1.
		p.modulate = Color(1.0 + 0.55 * t, 1.0 + 0.35 * t, 1.0 + 0.1 * t,
				RUHE_ALPHA + (1.0 - RUHE_ALPHA) * t)
		p.scale = Vector2.ONE * (1.0 + 0.12 * t)


func _on_pass(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall or body.freeze:
		return
	_cool = 0.4
	Sfx.play("tick", -4.0)
	Game.add_score(BASE_SCORE, body)
	Game.emit("gate", {"armed": armed})
	set_armed(false)
