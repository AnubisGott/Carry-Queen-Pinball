extends Node
## Prueft die vier G-G-E-Z-Gassen mit acht Laeufen: die Kugel kommt einmal von
## oben und einmal von unten in jede Gasse.  Bestanden ist ein Lauf nur, wenn
## dabei genau ein Licht angeht - nicht zwei, nicht keins - und zwar das der
## angefahrenen Gasse.
##
## Von oben rollt sie mit Flippertempo ganz durch (dabei legt sie 11 Einheiten
## je Physikbild zurueck - ein schmales Sensorfeld wuerde sie ueberspringen).
## Von unten kommt sie nur bis zum Buchstaben und faellt wieder zurueck: auch
## das muss zaehlen, die Gasse muss nicht ganz durchrollt werden.
##   godot --headless --path . res://tools/diag_gassen.tscn [-- --spur]
## Mit --spur meldet jede Gasse zusaetzlich ihre erkannten Ueberquerungen.

const MAIN := preload("res://scenes/main.tscn")
## Richtung der Gassen: die Stege laufen von (x,226) nach (x-15,198), also
## nach oben links.  Als Konstante ausgerechnet, weil normalized() hier nicht
## erlaubt ist.
const LANE_DIR := Vector2(-0.47193, -0.88094)
## Von so weit ausserhalb der Gasse wird gestartet.  Oben knapper, weil dort
## der Ablenker am Bogen steht - weiter weg wuerde die Kugel in ihm starten
## und seitlich weggedrueckt.
const ANLAUF_OBEN := 34.0
const ANLAUF_UNTEN := 52.0
## Von oben mit Flippertempo ganz hindurch.  Von unten so bemessen, dass die
## Kugel den Buchstaben gerade erreicht und dann zurueckfaellt:
## v = wurzel(2 * 1250 * 52) sind 360, mit etwas Reserve 430.
const TEMPO_OBEN := 1300.0
const TEMPO_UNTEN := 430.0

var _main: Node2D
var _gassen := []
var _bestanden := 0
var _gesamt := 0


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	RolloverLane.debug = "--spur" in OS.get_cmdline_user_args()
	await get_tree().create_timer(1.0).timeout
	_gassen = _main.ggez

	print("--- von oben durch jede Gasse ---")
	for i in _gassen.size():
		var mitte: Vector2 = _gassen[i].global_position
		await _lauf("Gasse %d (%s) von oben" % [i + 1, _gassen[i].letter],
				mitte + LANE_DIR * ANLAUF_OBEN, -LANE_DIR * TEMPO_OBEN, i)

	print("--- von unten bis zum Buchstaben (rollt nicht durch) ---")
	for i in _gassen.size():
		var mitte: Vector2 = _gassen[i].global_position
		await _lauf("Gasse %d (%s) von unten" % [i + 1, _gassen[i].letter],
				mitte - LANE_DIR * ANLAUF_UNTEN, LANE_DIR * TEMPO_UNTEN, i, true)

	print("ERGEBNIS: %d von %d bestanden" % [_bestanden, _gesamt])
	get_tree().quit()


## Kugel durch die Gasse schicken.  Bestanden, wenn genau die Gasse mit dem
## Index "soll" leuchtet und sonst keine.
func _lauf(name: String, start: Vector2, v0: Vector2, soll: int,
		zurueckfallen: bool = false) -> void:
	for g in _gassen:
		g.set_lit(false)
	var ball := PinBall.new()
	ball.position = start
	_main.add_child(ball)
	ball.linear_velocity = v0
	# Kurzes Fenster: es geht um einen Durchgang.  Laenger beobachtet, kaeme
	# die Kugel oben am Bogen zurueck und rollte zu Recht durch eine zweite
	# Gasse - das waere kein Fehler, wuerde die Messung aber verwaschen.
	var hoechster := start.y
	var ende := start
	for i in 30:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		hoechster = minf(hoechster, ball.global_position.y)
		ende = ball.global_position
	var an := []
	for i in _gassen.size():
		if _gassen[i].lit:
			an.append(_gassen[i].letter + str(i + 1))
	var gut: bool = an.size() == 1 and _gassen[soll].lit
	# Bei diesen Laeufen gehoert zur Probe, dass die Kugel wirklich nicht
	# durchgerollt ist, sondern wieder unterhalb der Gasse gelandet ist.
	var mitte_y: float = _gassen[soll].global_position.y
	var durchgerollt: bool = hoechster < mitte_y - 12.0
	if zurueckfallen and durchgerollt:
		gut = false
		name += " (ROLLTE DURCH)"
	_gesamt += 1
	if gut:
		_bestanden += 1
	print("  %-24s %d Licht(er) %-12s -> %s%s" % [
			name, an.size(), str(an), "OK" if gut else "FEHLER",
			"" if gut else "  [hoechster Punkt y=%.0f]" % hoechster])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.5).timeout
