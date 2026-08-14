extends Node
## Wird das Hurry-Up am Durchlauf wirklich kassiert?
##
## Beim Spielen war die Kill-Serie voll, die Hoerner blinkten, die Kugel ging
## durch die Mitte - und es passierte nichts.  Hier faehrt eine Kugel den
## Durchlauf mit verschiedenen Tempi und seitlichen Versaetzen an; gemessen
## wird, ob das Ereignis kommt und ob Punkte gutgeschrieben werden.
##   godot --headless --path . res://tools/diag_hurry.tscn

const MAIN := preload("res://scenes/main.tscn")
## Durchlauf laut table.gd; die Hoerner enden bei x = 227 und 263
const GATE := Vector2(245, 500)

var _main: Node2D
var _fehler := 0
var _gate_ereignis := false
var _jackpot := false


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	Game.event.connect(_auf_ereignis)

	print("--- Kugel von unten durch den Durchlauf, Hurry-Up laeuft ---")
	print("  %-8s %-8s %-10s %-10s %s" % ["x", "Tempo", "Ereignis", "Punkte", "Hoerner danach"])
	for x in [225.0, 235.0, 245.0, 255.0, 265.0]:
		# Von 700 px/s (gerade genug, um die 120 Pixel hochzukommen) bis ans
		# Tempolimit der Kugel.
		for tempo in [700.0, 1000.0, 1300.0, 1600.0]:
			await _durchfahrt(x, tempo)

	print("--- und von oben herunter durch die Hoerner ---")
	# Nach der vollen Bumper-Serie ist die Kugel oben im Feld - sie kommt also
	# auch von dort wieder durch die Mitte.
	for x in [235.0, 245.0, 255.0]:
		for tempo in [400.0, 900.0, 1400.0]:
			await _durchfahrt(x, tempo, true)

	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if _fehler == 0
			else "%d Durchfahrten ohne Gutschrift" % _fehler])
	get_tree().quit(0 if _fehler == 0 else 1)


## Kuerzester Abstand der Strecke zum Durchlauf - wie in pass_gate.gd.
func _bahn(von: Vector2, nach: Vector2) -> float:
	var d := nach - von
	var l2 := d.length_squared()
	if l2 < 0.0001:
		return von.length()
	var t: float = clampf(-von.dot(d) / l2, 0.0, 1.0)
	return (von + d * t).length()


func _auf_ereignis(kind: String, _data: Dictionary) -> void:
	if kind == "gate":
		_gate_ereignis = true
	elif kind == "jackpot":
		_jackpot = true


## Hurry-Up frisch starten und einmal von unten durch die Mitte fahren.
func _durchfahrt(x: float, tempo: float, von_oben: bool = false) -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	# Der Durchlauf sperrt sich nach einer Durchfahrt 0,4 s lang.  Ohne diese
	# Pause misst der naechste Lauf nur die Sperre - genau daran ist die erste
	# Messreihe gescheitert.
	await get_tree().create_timer(0.6).timeout
	# Kill-Serie ueber die vier Bumper, wie im Spiel
	_main.hurry_active = false
	_main.streak_letters.clear()
	for id in ["W", "A", "S", "D"]:
		_main._on_bumper(id)
		await get_tree().physics_frame
	await get_tree().physics_frame
	var lief: bool = _main.hurry_active
	var punkte_vor: int = Game.score
	_gate_ereignis = false
	_jackpot = false

	# Von unterhalb der DAMAGE-Bank losschicken, wie ein Schuss vom Flipper.
	# Von unten aus 120 Pixel Abstand.  Von oben nur 45 - weiter oben steht
	# der S-Bumper genau ueber dem Durchlauf und schlaegt die Kugel weg,
	# bevor sie unten ankommt.  Das ist so gewollt: die Mitte spielt man von
	# den Flippern aus an, nicht von oben herunter.
	var b2: PinBall = _main._spawn_ball(Vector2(x,
			GATE.y - 45.0 if von_oben else GATE.y + 120.0))
	b2.linear_velocity = Vector2(0.0, tempo if von_oben else -tempo)
	# Mitschreiben, ob die Kugel den Durchlauf ueberhaupt beruehrt haette:
	# Rechteck 30 mal 16 plus Kugelradius 13.
	var geometrisch := false
	var hoch := 9999.0
	# Denselben Bahnabstand mitrechnen, den der Durchlauf prueft - so laesst
	# sich trennen, ob die Kugel danebenflog oder ob sie erkannt wurde.
	var naechste := 9999.0
	var vorher: Vector2 = b2.global_position
	for i in 120:
		await get_tree().physics_frame
		if not is_instance_valid(b2):
			break
		var p: Vector2 = b2.global_position
		naechste = minf(naechste, _bahn(vorher - GATE, p - GATE))
		vorher = p
		hoch = minf(hoch, p.y)
		if absf(p.x - GATE.x) < 15.0 + 13.0 and absf(p.y - GATE.y) < 8.0 + 13.0:
			geometrisch = true
		if (p.y > GATE.y + 60.0) if von_oben else (p.y < GATE.y - 60.0):
			break
	var dazu: int = Game.score - punkte_vor
	if geometrisch and not _gate_ereignis:
		print("       durch den Durchlauf geflogen, aber nichts gemeldet"
				+ " (hoechstens y=%.0f, naechster Bahnabstand %.1f)" % [hoch, naechste])
	# Der Durchlauf muss das Hurry-Up beenden - daran sieht man auch auf dem
	# Feld, dass es kassiert wurde (die Hoerner hoeren auf zu blinken).
	var ok: bool = lief and _gate_ereignis and _jackpot and not _main.hurry_active
	if not ok:
		_fehler += 1
	print("  %s %-6.0f %-8.0f %-10s %-10s %s" % ["ok  " if ok else "FEHL", x,
			tempo * (-1.0 if von_oben else 1.0),
			str(_gate_ereignis), str(dazu),
			"aus" if not _main.hurry_active else "BLINKEN LAEUFT WEITER"])
	b2.queue_free()
	await get_tree().physics_frame
