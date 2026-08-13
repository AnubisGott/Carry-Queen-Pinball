class_name RolloverLane
extends Node2D
## Rollover-Gasse: die Kugel rollt durch, der Buchstabe leuchtet auf.
## Ob die ganze Bank komplett ist, prueft main.gd (Event "rollover").
##
## Erkannt wird der Durchgang an der Flugbahn, nicht ueber ein Sensorfeld:
## jedes Physikbild wird die Lage der Kugel in Gassenkoordinaten festgehalten
## (laengs u, quer w).  Wechselt u das Vorzeichen, hat sie die Gassenmitte
## ueberquert; der Kreuzungspunkt wird zwischen den beiden Bildern
## interpoliert und muss quer innerhalb der Gasse liegen.
##
## Ein Sensorfeld waere hier zu grob: bei Flippertempo legt die Kugel 13
## Einheiten je Bild zurueck und springt ueber ein schmales Feld hinweg, ohne
## dass eine Beruehrung gemeldet wird - schraege Treffer zaehlten dann nicht.
## Breiter darf das Feld aber nicht sein, sonst liegt die Kugel gleichzeitig
## in zwei Gassen (Abstand 38, Kugeldurchmesser 26).

## Halbe Gassenbreite: der Kreuzungspunkt muss so nah an der Gassenmitte
## liegen.  15+15 = 30 < 38, zwei Gassen koennen also nie gleichzeitig passen.
const HALB_BREITE := 15.0
## Nur Kugeln in diesem Umkreis werden verfolgt.
const NAEHE := 52.0
## Ein Anlauf, ein Buchstabe: prallt die Kugel oben am Bogen ab und faellt
## gleich durch die Nachbargasse zurueck, sieht das aus wie zwei Lichter auf
## einmal.  Innerhalb dieser Zeit zaehlt deshalb nur der erste Durchgang.
const BANK_SPERRE := 0.35

## Gilt fuer alle Gassen gemeinsam - deshalb statisch.
static var _sperr_kugel := 0
static var _sperr_zeit := 0.0
## Nur fuer die Diagnose (tools/diag_gassen): meldet jede Ueberquerung.
static var debug := false

var letter := ""
var lit := false
var _dir := Vector2.DOWN
var _quer := Vector2.RIGHT
var _label: Label
## Kugel-Kennung -> letzte Lage als (laengs, quer)
var _spur := {}


func _init(pos: Vector2, letter_: String, dir: Vector2) -> void:
	position = pos
	letter = letter_
	_dir = dir.normalized()
	_quer = Vector2(-_dir.y, _dir.x)


func _ready() -> void:
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


func _physics_process(_delta: float) -> void:
	var gesehen := {}
	for b in get_tree().get_nodes_in_group("balls"):
		var ball := b as PinBall
		if ball == null or ball.freeze:
			continue
		var rel: Vector2 = ball.global_position - global_position
		if rel.length() > NAEHE:
			continue
		var id := ball.get_instance_id()
		var jetzt := Vector2(rel.dot(_dir), rel.dot(_quer))
		gesehen[id] = true
		if _spur.has(id):
			var vor: Vector2 = _spur[id]
			# Vorzeichenwechsel laengs = die Kugel hat die Mitte ueberquert
			if vor.x != 0.0 and signf(vor.x) != signf(jetzt.x):
				var t: float = vor.x / (vor.x - jetzt.x)
				var quer_kreuz := absf(lerpf(vor.y, jetzt.y, t))
				if debug:
					print("    [%s] Ueberquerung bei quer=%.1f (Grenze %.0f), laengs %.1f -> %.1f" % [
							letter, quer_kreuz, HALB_BREITE, vor.x, jetzt.x])
				if quer_kreuz <= HALB_BREITE:
					_durchgang(ball)
		_spur[id] = jetzt
	for id in _spur.keys():
		if not gesehen.has(id):
			_spur.erase(id)


func _durchgang(ball: PinBall) -> void:
	var zeit := float(Time.get_ticks_msec()) / 1000.0
	if ball.get_instance_id() == _sperr_kugel and zeit - _sperr_zeit < BANK_SPERRE:
		return
	_sperr_kugel = ball.get_instance_id()
	_sperr_zeit = zeit
	if lit:
		Sfx.play("tick", -8.0)
		return
	set_lit(true)
	Sfx.play("standup", -6.0)
	Game.add_score(500, ball)
	Game.emit("rollover", {"letter": letter, "index": get_index()})


func _draw() -> void:
	# Leucht-Kapsel laengs der Gasse
	var a := -_dir * 16.0
	var b := _dir * 16.0
	var col := Table.NEON_GOLD if lit else Color(0.5, 0.25, 0.85, 0.5)
	draw_line(a, b, Color(col.r, col.g, col.b, 0.18), 16.0)
	draw_line(a, b, col, 2.5)
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, col, 1.5)
