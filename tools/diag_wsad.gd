extends Node
## Stimmt die Leiste oben mit dem Feld ueberein - und darf der Bericht wirklich
## nur starten, wenn alle vier Bumper leuchten?
##
## DMG, EGO und ICH bleiben bis zum Ende des Berichts stehen; WSAD raeumt sich
## dagegen selbst wieder ab, sobald das Hurry-Up vorbei ist.  Frueher blieb die
## Anzeige oben trotzdem an - dadurch konnte der Bericht losgehen, obwohl die
## vier Bumper laengst dunkel waren (genau der Fall aus dem Screenshot).
##   godot --headless --path . res://tools/diag_wsad.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _kugel: PinBall
var _fehler := 0
## Beim Start des Berichts festgehalten: wie viele Bumper brannten in dem
## Moment?  Das ist die eigentliche Forderung.
var _lampen_beim_bericht := -1


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	Game.event.connect(_mitschreiben)
	await get_tree().create_timer(1.0).timeout
	_kugel = _main._spawn_ball(Vector2(270, 700))
	_kugel.freeze = true

	_zeile("vor allem", false, 0, false)

	# --- 1. Vier Bumper: WSAD an, alle vier Lampen an ------------------------
	await _vier_bumper()
	_zeile("nach vier Bumpern", true, 4, true)

	# --- 2. Hurry-Up laeuft ab: beides muss ausgehen -------------------------
	await _hurry_auslaufen()
	_zeile("nach abgelaufenem Hurry", false, 0, false)

	# --- 3. Hurry-Up am Durchlauf kassiert: ebenso ---------------------------
	await _vier_bumper()
	_main._on_event("gate", {})
	await get_tree().create_timer(0.3).timeout
	_zeile("nach kassiertem Hurry", false, 0, false)

	# --- 4. Der Fall aus dem Screenshot -------------------------------------
	# DMG, EGO und ICH stehen, WSAD ist abgelaufen.  Der Bericht darf nicht
	# starten - drei von vier reichen nicht.
	await _damage_abraeumen()
	await _buchstaben_abraeumen()
	_zeile("DMG+EGO+ICH ohne WSAD", false, 0, false)
	_pruefe("Bericht bleibt aus", not Game.wizard, "wizard=%s" % str(Game.wizard))
	_pruefe("drei Disziplinen stehen",
			Game.disciplines["DAMAGE"] and Game.disciplines["EGO"]
					and Game.disciplines["ICH"],
			str(Game.disciplines))

	# --- 5. Jetzt WSAD dazu: der Bericht startet, Lampen brennen ------------
	await _vier_bumper()
	_pruefe("Bericht laeuft", Game.wizard, "wizard=%s" % str(Game.wizard))
	_pruefe("beim Start des Berichts brennen alle vier Bumper",
			_lampen_beim_bericht == 4, "%d von 4" % _lampen_beim_bericht)

	# --- 6. Bericht zu Ende: WSAD folgt den Lampen, nicht dem Bericht -------
	_main._end_wizard()
	await get_tree().create_timer(0.3).timeout
	_pruefe("DMG, EGO, ICH sind zurueckgestellt",
			not Game.disciplines["DAMAGE"] and not Game.disciplines["EGO"]
					and not Game.disciplines["ICH"],
			str(Game.disciplines))
	# Das Hurry-Up laeuft noch, also leuchten die vier Bumper weiter - dann
	# gehoert WSAD auch oben wieder hin.
	_zeile("nach dem Bericht (Hurry laeuft)", true, 4, true)

	# --- 7. Ballverlust beendet das Hurry-Up --------------------------------
	# Erst muss das Feld leer sein: _after_drain steigt aus, solange noch eine
	# Kugel laeuft - und seit dem Spielstart liegt eine im Schacht.
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().process_frame
	Game.ball_save_armed = false
	_main._after_drain()
	await get_tree().create_timer(0.5).timeout
	_zeile("nach dem Ballverlust", false, 0, false)

	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if _fehler == 0 else "%d Fehler" % _fehler])
	get_tree().quit(0 if _fehler == 0 else 1)


func _mitschreiben(kind: String, _data: Dictionary) -> void:
	if kind == "all_disciplines":
		_lampen_beim_bericht = _lampen()


# ------------------------------------------------------------- Handgriffe ---

func _vier_bumper() -> void:
	for l in ["W", "A", "S", "D"]:
		_main._on_event("bumper", {"letter": l})
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout


func _hurry_auslaufen() -> void:
	_main.hurry_time = 0.02
	await get_tree().create_timer(0.6).timeout


func _damage_abraeumen() -> void:
	for d in _main.drops:
		d._on_hit(_kugel)
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout


## I-C-H und E-G-O von Hand setzen.  Ueber _on_hit ginge es nicht: die Targets
## zaehlen seit der Verschaerfung nur noch Treffer von vorn mit Mindesttempo,
## und eine eingefrorene Testkugel bringt beides nicht mit.  Geprueft wird hier
## ohnehin die Leiste, nicht die Trefferregel (dafuer gibt es diag_stand).
func _buchstaben_abraeumen() -> void:
	for s in _main.standups:
		s.lit = true
	for s in _main.ego_bank:
		s.lit = true
	Game.emit("standup", {})
	await get_tree().create_timer(0.3).timeout


# ---------------------------------------------------------------- Pruefung ---

func _lampen() -> int:
	var n := 0
	for l in _main.bumpers:
		if _main.bumpers[l].marked:
			n += 1
	return n


func _zeile(phase: String, soll_wsad: bool, soll_lampen: int, soll_hurry: bool) -> void:
	var wsad: bool = Game.disciplines.get("CARRY", false)
	var lampen := _lampen()
	var hurry: bool = _main.hurry_active
	var ok: bool = wsad == soll_wsad and lampen == soll_lampen and hurry == soll_hurry
	if not ok:
		_fehler += 1
	print("  %s %-32s WSAD=%-5s (Soll %-5s)  Lampen=%d (Soll %d)  Hurry=%s (Soll %s)"
			% ["ok  " if ok else "FEHL", phase, str(wsad), str(soll_wsad),
			lampen, soll_lampen, str(hurry), str(soll_hurry)])


func _pruefe(was: String, ok: bool, gemessen: String) -> void:
	if not ok:
		_fehler += 1
	print("  %s %-32s %s" % ["ok  " if ok else "FEHL", was, gemessen])
