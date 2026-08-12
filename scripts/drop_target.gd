class_name DropTarget
extends StaticBody2D
## Drop-Target der D-A-M-A-G-E-Bank.

const W := 30.0
const H := 12.0

var letter := "D"
var dropped := false
var _area: Area2D
var _flash := 0.0
## Pulsieren waehrend der Damage-Frenzy - je knapper die Zeit, desto
## schneller (siehe main.gd).
var pulsing := false
var _pulse_t := 0.0
var _pulse_speed := 6.0


func _init(pos: Vector2, l: String) -> void:
	position = pos
	letter = l


func _ready() -> void:
	# Kein physischer Koerper: die Kugel rollt immer ueber die Buchstaben,
	# nichts prallt ab - getroffen wird rein per Sensor-Flaeche.
	_area = Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(W + 8, H + 8)
	acs.shape = ash
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(_on_hit)
	z_index = 4


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()
	if pulsing:
		_pulse_t += delta * _pulse_speed
		queue_redraw()


## `speed` steuert die Blinkfrequenz; ohne Phasensprung umschaltbar.
func set_pulsing(on: bool, speed: float = 6.0) -> void:
	_pulse_speed = speed
	if pulsing == on:
		return
	pulsing = on
	if not on:
		queue_redraw()


func _draw() -> void:
	# Einheitliche Bank-Logik im ganzen Spiel: getroffen = leuchtet.
	# Stehende Targets sind gedimmt, gefallene leuchten kraeftig rot.
	var r := Rect2(-W / 2, -H / 2, W, H)
	var bg: Color
	var border: Color
	var letter_col: Color
	if dropped:
		bg = Color(0.1, 0.03, 0.08)
		border = Color(1.8, 0.3, 0.5)
		letter_col = Color(2.0, 0.5, 0.8)
	else:
		bg = Color(0.05, 0.02, 0.04)
		border = Color(0.5, 0.12, 0.2)
		letter_col = Color(0.62, 0.2, 0.32)
	border = border.lerp(Color(2.2, 2.2, 2.2), _flash)
	letter_col = letter_col.lerp(Color(2.2, 1.6, 1.8), _flash)
	if pulsing:
		var t := 0.5 + 0.5 * sin(_pulse_t)
		bg = bg.lerp(Color(0.45, 0.08, 0.22), t)
		border = border.lerp(Color(2.4, 1.5, 0.4), t)
		letter_col = letter_col.lerp(Color(2.4, 1.9, 0.6), t)
	draw_rect(r, bg)
	draw_rect(r, border, false, 2.0 if dropped else 1.5)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-5, 4), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, letter_col)


func _on_hit(body: Node2D) -> void:
	if dropped or not body is PinBall:
		return
	dropped = true
	_flash = 1.0
	_area.set_deferred("monitoring", false)
	queue_redraw()
	Sfx.play("target", -4.0)
	var pts := Game.add_score(500, body)
	Game.damage_points += pts
	Game.emit("drop_target", {"letter": letter})


func reset() -> void:
	if dropped:
		_flash = 1.0
	dropped = false
	pulsing = false
	_area.set_deferred("monitoring", true)
	queue_redraw()
