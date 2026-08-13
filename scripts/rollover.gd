class_name RolloverLane
extends Area2D
## Rollover-Gasse: die Kugel rollt durch, der Buchstabe leuchtet auf.
## Ob die ganze Bank komplett ist, prueft main.gd (Event "rollover").
##
## Der Sensor ist ein schmales Rechteck laengs der Gasse, kein Kreis: bei 38
## Einheiten Gassenabstand beruehrt eine Kugel (Radius 13) zwei runde Felder
## mit Radius 12 gleichzeitig und setzt zwei Buchstaben auf einmal.  Mit halber
## Breite 5 bleiben 5+13=18 < 19, die Kugel liegt also immer nur in einer
## Gasse.  Zusaetzlich muss sie die Gasse entlang laufen: die Stege sind nur
## 28 Einheiten lang, darueber und darunter kommt man quer ueber die ganze
## Reihe.

## Gezaehlt wird, wer wirklich durchrollt: die Kugel muss auf der anderen Seite
## wieder herauskommen als sie hereingekommen ist - von oben herab genauso wie
## von unten herauf.  Ueber die Flugrichtung laesst sich das nicht entscheiden
## (eine vom Bumper hochkommende Kugel faehrt oft schraeg), und ueber die
## Eintrittsstelle allein auch nicht: wer quer ueber die Reihe rutscht, kommt
## aus Sicht der Gasse durch deren oberes Ende herein.  Der Buchstabe geht
## deshalb erst beim Verlassen an, wenige Hundertstel spaeter.
## Ein Durchgang, ein Buchstabe: nach einem Treffer ist die ganze Bank fuer
## dieselbe Kugel kurz gesperrt.  Schraeg unter den kurzen Stegen hindurch
## streift sie sonst zwei Gassen nacheinander und setzt zwei Lichter.
const BANK_SPERRE := 0.45

## Gilt fuer alle Gassen gemeinsam - deshalb statisch.
static var _sperr_kugel := 0
static var _sperr_zeit := 0.0

var letter := ""
var lit := false
var _dir := Vector2.DOWN
var _label: Label
## Kugel-Kennung -> auf welcher Seite der Gasse sie hereinkam (+1 / -1)
var _eintritt := {}


func _init(pos: Vector2, letter_: String, dir: Vector2) -> void:
	position = pos
	letter = letter_
	_dir = dir.normalized()


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10.0, 34.0)
	cs.shape = sh
	# Lange Achse des Rechtecks auf die Gassenrichtung drehen
	cs.rotation = _dir.angle() - PI / 2.0
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_pass)
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


## Eintrittsseite merken: laengs der Gasse vorne (+1) oder hinten (-1).
func _on_enter(body: Node2D) -> void:
	if not body is PinBall:
		return
	_eintritt[body.get_instance_id()] = signf(
			(body.global_position - global_position).dot(_dir))


func _on_pass(body: Node2D) -> void:
	if not body is PinBall:
		return
	var id := body.get_instance_id()
	var vorher: float = _eintritt.get(id, 0.0)
	_eintritt.erase(id)
	if body.freeze or vorher == 0.0:
		return
	# Durchgerollt heisst: auf der anderen Seite wieder heraus.  Wer auf
	# derselben Seite umkehrt oder quer ueber die Reihe streift, zaehlt nicht.
	var nachher := signf((body.global_position - global_position).dot(_dir))
	if nachher == 0.0 or nachher == vorher:
		return
	var jetzt := float(Time.get_ticks_msec()) / 1000.0
	if body.get_instance_id() == _sperr_kugel and jetzt - _sperr_zeit < BANK_SPERRE:
		return
	_sperr_kugel = body.get_instance_id()
	_sperr_zeit = jetzt
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
