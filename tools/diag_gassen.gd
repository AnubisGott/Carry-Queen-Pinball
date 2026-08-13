extends Node
## Diagnose der G-G-E-Z-Gassen: eine Kugel darf immer nur einen Buchstaben
## auf einmal setzen.
##  1. laengs durch jede der vier Gassen -> genau dieser eine Buchstabe
##  2. quer ueber die Reihe (ober- und unterhalb der kurzen Stege) -> keiner
##   godot --headless --path . res://tools/diag_gassen.tscn

const MAIN := preload("res://scenes/main.tscn")
## Gassenmitten laut table.gd: GGEZ_CENTER 300, Abstand 38, y=212
const LANE_X := [243.0, 281.0, 319.0, 357.0]
const LANE_Y := 212.0
## Richtung der Gassen: die Stege laufen von (x,226) nach (x-15,198).
## Als Konstante ausgerechnet, weil normalized() dort nicht erlaubt ist.
const LANE_DIR := Vector2(-0.47193, -0.88094)

var _main: Node2D
var _gassen := []


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	_gassen = _main.ggez
	var orte := []
	for g in _gassen:
		orte.append("%s bei (%.0f,%.0f)" % [g.letter, g.global_position.x, g.global_position.y])
	print("Gassen: ", ", ".join(orte))

	print("--- laengs durch jede Gasse ---")
	for i in LANE_X.size():
		# Die Gassenrichtung zeigt nach oben rechts - die Kugel kommt also von
		# oben rechts und faellt nach unten links hindurch.
		# Dicht ueber der Gasse und zuegig, damit die Kugel auf dem kurzen Weg
		# nicht in die Nachbargasse faellt.
		var start := Vector2(LANE_X[i], LANE_Y) + LANE_DIR * 38.0
		await _lauf("Gasse %d (%s)" % [i + 1, _buchstabe(i)], start,
				-LANE_DIR * 600.0, 1)

	print("--- von unten herauf ---")
	for i in LANE_X.size():
		# Von unterhalb der Reihe senkrecht hoch, wie nach einem Bumper-Stoss
		# Am unteren Ende der Gasse ansetzen, nicht an ihrer Mitte
		var unten: Vector2 = Vector2(LANE_X[i], LANE_Y) - LANE_DIR * 30.0
		await _lauf("Gasse %d von unten senkrecht" % [i + 1],
				Vector2(unten.x, unten.y + 20.0), Vector2(0, -620), 1)
	# Schraeg von unten links, wie die Kugel vom Bumper-Pad hochkommt
	await _lauf("schraeg von unten links herauf", Vector2(300, 262),
			Vector2(-190, -600), 1)
	await _lauf("schraeg von unten rechts herauf", Vector2(330, 262),
			Vector2(-150, -620), 1)

	print("--- an der Reihe entlang statt hindurch ---")
	# Querlaeufe ueber und unter der Reihe lassen sich nicht sauber isolieren:
	# oben stehen Stegkoepfe und Bogen im Weg, unten das Bumper-Pad, und was
	# nach einem Abpraller durch eine Gasse rollt, ist ein echter Durchgang.
	# Entscheidend ist deshalb, dass dabei nie zwei Buchstaben entstehen.
	print("--- Querlaeufe: hoechstens ein Buchstabe ---")
	var quer := [
		["oberhalb, schnell", Vector2(210, 178), Vector2(900, -180)],
		["oberhalb, langsam", Vector2(210, 186), Vector2(520, -60)],
		["oberhalb, von rechts", Vector2(395, 180), Vector2(-820, -120)],
		["dicht unter den Stegen", Vector2(212, 240), Vector2(760, -90)],
		["dicht unter den Stegen, von rechts", Vector2(392, 240), Vector2(-760, -90)],
		["flach von links unten", Vector2(205, 258), Vector2(700, -260)],
	]
	for q in quer:
		await _lauf(q[0], q[1], q[2], 1, true)
	# Unter der Reihe entlang: rein und auf derselben Seite wieder raus,
	# also kein Durchgang.
	await _lauf("schraeg unter der Reihe entlang", Vector2(215, 250),
			Vector2(620, -320), 0)
	# Von rechts unten nach links oben: die Kugel rollt schraeg, kommt aber auf
	# der anderen Seite wieder heraus - das ist ein Durchgang und zaehlt.
	await _lauf("schraeg von rechts unten herauf", Vector2(390, 250),
			Vector2(-620, -320), 1)
	get_tree().quit()


func _buchstabe(i: int) -> String:
	return ["G", "G", "E", "Z"][i]


## Kugel losschicken und zaehlen, wie viele Buchstaben dabei angehen.
func _lauf(name: String, start: Vector2, v0: Vector2, erwartet: int,
		hoechstens: bool = false) -> void:
	for g in _gassen:
		g.set_lit(false)
	var ball := PinBall.new()
	ball.position = start
	_main.add_child(ball)
	ball.linear_velocity = v0
	# Kurzes Fenster: es geht um einen Durchgang.  Laenger beobachtet, kaeme
	# die Kugel oben am Bogen zurueck und rollte zu Recht durch eine zweite
	# Gasse - das waere dann kein Fehler, wuerde die Messung aber verwaschen.
	for i in 30:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
	var an := []
	for i in _gassen.size():
		if _gassen[i].lit:
			an.append(_buchstabe(i) + str(i + 1))
	var gut := an.size() <= erwartet if hoechstens else an.size() == erwartet
	print("  %-36s %d Buchstabe(n) %-14s %s %d  %s" % [
			name, an.size(), str(an), "hoechstens" if hoechstens else "erwartet",
			erwartet, "OK" if gut else "ABWEICHUNG"])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.3).timeout
