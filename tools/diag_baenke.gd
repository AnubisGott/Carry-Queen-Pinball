extends Node
## Wann zaehlt ein Buchstabe bei I-C-H und E-G-O?
##
## Nur ein Treffer auf die Vorderseite, vom Spielfeld her.  Beides war einmal
## anders: erst raeumte eine einzige an der Wand herunterrollende Kugel die
## ganze Bank ab, danach zaehlte noch eine senkrecht auf die Oberkante
## fallende Kugel.  Beides wird hier nachgestellt, dazu die Gegenprobe, dass
## ein Schuss vom Feld weiterhin zaehlt.
##   godot --headless --path . res://tools/diag_baenke.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _fehler := 0
## Buchstaben, die seit dem letzten Zuruecksetzen angegangen sind
var _treffer := []


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(0.8).timeout
	Game.event.connect(_auf_ereignis)

	print("--- an der Bank vorbeirollen zaehlt nicht ---")
	# Frueher fielen so alle drei Buchstaben in einem Durchgang.
	for bank in _baenke():
		for abstand in [16.0, 18.0, 20.0]:
			for tempo in [200.0, 450.0, 800.0]:
				await _vorbeirollen(bank, abstand, tempo)

	print("--- senkrecht darauffallen zaehlt nicht ---")
	# Beim Spielen ist eine Kugel senkrecht auf das H gefallen und es hat
	# gezaehlt.  Geprueft wird mit und ohne Anfangstempo.
	for bank in _baenke():
		for tempo in [0.0, 400.0, 900.0]:
			await _fallenlassen(bank, tempo)

	print("--- vom Spielfeld her zaehlt jeder Schuss genau einen ---")
	for bank in _baenke():
		await _aufraeumen()
		var folge := []
		for s in bank["ziele"]:
			var neu := await _schuss(bank, s)
			folge.append_array(neu)
		var voll: bool = folge.size() == bank["ziele"].size()
		var lampe: bool = Game.disciplines.get(bank["disziplin"], false)
		# Nicht nur der Zustand, auch die Beschriftung oben in der Leiste
		var farbe: Color = _main.hud._disc_labels[bank["disziplin"]].get_theme_color("font_color")
		var hell: bool = farbe.is_equal_approx(Hud.PINK)
		if not voll or not lampe or not hell:
			_fehler += 1
		print("  %s %-6s %s, Lampe %s: %s, Beschriftung: %s"
				% ["ok  " if voll and lampe and hell else "FEHL", bank["name"],
				str(folge), bank["disziplin"], "an" if lampe else "AUS",
				"hell" if hell else "grau"])

	print("--- nach einem neuen Spiel geht es wieder ---")
	# Ohne Zuruecksetzen von _ich_done/_ego_done blieben die Lampen ab dem
	# zweiten Spiel fuer immer grau.
	_main._restart()
	await get_tree().create_timer(0.5).timeout
	for bank in _baenke():
		var farbe: Color = _main.hud._disc_labels[bank["disziplin"]].get_theme_color("font_color")
		var grau: bool = farbe.is_equal_approx(Hud.DIM)
		if not grau:
			_fehler += 1
		print("  %s %s: Beschriftung nach dem Neustart grau: %s"
				% ["ok  " if grau else "FEHL", bank["disziplin"], str(grau)])
	for bank in _baenke():
		var folge := []
		for s in bank["ziele"]:
			var neu := await _schuss(bank, s)
			folge.append_array(neu)
		var lampe: bool = Game.disciplines.get(bank["disziplin"], false)
		if folge.size() != bank["ziele"].size() or not lampe:
			_fehler += 1
		print("  %s %-6s %s, Lampe %s: %s" % [
				"ok  " if folge.size() == bank["ziele"].size() and lampe else "FEHL",
				bank["name"], str(folge), bank["disziplin"],
				"an" if lampe else "AUS"])

	print("--- die Sperre ueberlebt den Ballwechsel nicht ---")
	# Wer trifft, sperrt seine Nachbarn, solange die Kugel bei der Bank ist.
	# Wird die Bank neu aufgestellt, muss die Sperre mit weg sein - sonst
	# schluckt sie den ersten Treffer der neuen Runde.  Alles in einem Bild.
	var kugel: PinBall = _main._spawn_ball(Vector2(270, 700))
	kugel.freeze = true
	for s in _main.standups:
		s.reset()
	_main.standups[0]._on_hit(_hilfskugel(_main.standups[0]))
	var sperre_stand: bool = _main.standups[1]._gesperrt
	for s in _main.standups:
		s.reset()
	_main.standups[1]._on_hit(_hilfskugel(_main.standups[1]))
	var kam_durch: bool = _main.standups[1].lit
	if not sperre_stand or not kam_durch:
		_fehler += 1
	print("  %s nach dem Treffer gesperrt: %s, nach reset() zaehlt der naechste: %s"
			% ["ok  " if sperre_stand and kam_durch else "FEHL",
			str(sperre_stand), str(kam_durch)])
	kugel.queue_free()

	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if _fehler == 0 else "%d Fehler" % _fehler])
	get_tree().quit(0 if _fehler == 0 else 1)


func _baenke() -> Array:
	return [
		{"name": "I-C-H", "ziele": _main.standups, "disziplin": "ICH", "seite": 1.0},
		{"name": "E-G-O", "ziele": _main.ego_bank, "disziplin": "EGO", "seite": -1.0},
	]


## Kugel, die genau auf das Target zufliegt - fuer die Sperr-Pruefung, die
## ohne Flugzeit auskommen muss.
func _hilfskugel(ziel: Node2D) -> PinBall:
	var b: PinBall = _main._spawn_ball(ziel.global_position
			+ Vector2.RIGHT.rotated(ziel.rotation) * 30.0)
	b.linear_velocity = -Vector2.RIGHT.rotated(ziel.rotation) * 400.0
	return b


func _auf_ereignis(kind: String, data: Dictionary) -> void:
	if kind == "standup":
		_treffer.append(str(data.get("letter", "?")))


func _aufraeumen() -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	for s in _main.standups:
		s.reset()
	for s in _main.ego_bank:
		s.reset()
	_main._ich_done = false
	_main._ego_done = false
	await get_tree().physics_frame
	await get_tree().physics_frame


## Senkrecht an der Bank entlang herunterrollen.
func _vorbeirollen(bank: Dictionary, abstand: float, tempo: float) -> void:
	await _aufraeumen()
	_treffer.clear()
	var erstes: Node2D = bank["ziele"][0]
	var b: PinBall = _main._spawn_ball(erstes.global_position
			+ Vector2(float(bank["seite"]) * abstand, -50.0))
	b.linear_velocity = Vector2(0.0, tempo)
	var v_beim_treffer := Vector2.ZERO
	for i in 200:
		var v_vorher: Vector2 = b.linear_velocity
		await get_tree().physics_frame
		if not _treffer.is_empty() and v_beim_treffer == Vector2.ZERO:
			v_beim_treffer = v_vorher
		if b.global_position.y > 560.0:
			break
	if not _treffer.is_empty():
		_fehler += 1
	print("  %s %-6s Abstand %2.0f, %3.0f px/s -> %s" % [
			"ok  " if _treffer.is_empty() else "FEHL", bank["name"], abstand, tempo,
			"nichts" if _treffer.is_empty()
			else "%s bei v=(%.0f,%.0f), quer/laengs %.2f" % [str(_treffer),
			v_beim_treffer.x, v_beim_treffer.y,
			absf(v_beim_treffer.x) / maxf(1.0, absf(v_beim_treffer.y))]])
	b.queue_free()


## Senkrecht von oben auf jedes Target der Bank fallen lassen.
func _fallenlassen(bank: Dictionary, tempo: float) -> void:
	await _aufraeumen()
	_treffer.clear()
	for s in bank["ziele"]:
		var b: PinBall = _main._spawn_ball(s.global_position
				+ Vector2(float(bank["seite"]) * 15.0, -70.0))
		b.linear_velocity = Vector2(0.0, tempo)
		for i in 45:
			await get_tree().physics_frame
		b.queue_free()
		await get_tree().physics_frame
	if not _treffer.is_empty():
		_fehler += 1
	print("  %s %-6s %3.0f px/s -> %s" % ["ok  " if _treffer.is_empty() else "FEHL",
			bank["name"], tempo, "nichts" if _treffer.is_empty() else str(_treffer)])


## Waagerechter Schuss vom Spielfeld auf ein bestimmtes Target.
func _schuss(bank: Dictionary, ziel: Node2D) -> Array:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().physics_frame
	_treffer.clear()
	var seite: float = bank["seite"]
	var b2: PinBall = _main._spawn_ball(ziel.global_position + Vector2(seite * 60.0, 0.0))
	b2.linear_velocity = Vector2(-seite * 700.0, 0.0)
	for i in 45:
		await get_tree().physics_frame
	b2.queue_free()
	await get_tree().physics_frame
	return _treffer.duplicate()
