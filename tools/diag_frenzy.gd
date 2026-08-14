extends Node
## Wann stellt sich die DAMAGE-Bank wieder auf?
##
## Frueher: sobald die Frenzy vorbei war.  Damit ging eine geschaffte
## Disziplin auf dem Feld von selbst wieder auf.  Jetzt bleibt sie liegen -
## zurueckgesetzt wird sie zusammen mit I-C-H und E-G-O, wenn der Bericht
## durch ist.
##   godot --headless --path . res://tools/diag_frenzy.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _fehler := 0


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	var kugel: PinBall = _main._spawn_ball(Vector2(270, 700))
	kugel.freeze = true

	_zeile("vor dem Abraeumen", 0, false, false)
	# Bank abraeumen wie im Spiel: jedes Target einzeln ausloesen
	for d in _main.drops:
		d._on_hit(kugel)
		await get_tree().physics_frame
	await get_tree().create_timer(0.4).timeout
	_zeile("waehrend der Frenzy", 6, true, true)

	# Frenzy auslaufen lassen - die Bank muss liegen bleiben
	_main.frenzy_time = 0.02
	await get_tree().create_timer(0.6).timeout
	_zeile("nach der Frenzy", 6, false, false)

	# Auch der Ballwechsel raeumt sie nicht wieder auf
	_main._start_ball()
	await get_tree().create_timer(0.4).timeout
	_zeile("nach dem Ballwechsel", 6, false, false)

	# Erst der fertige Bericht stellt alles zurueck - zusammen mit I-C-H,
	# E-G-O und den Disziplin-Lampen.
	for s in _main.standups:
		s._on_hit(kugel)
		await get_tree().process_frame
		await get_tree().physics_frame
	for s in _main.ego_bank:
		s._on_hit(kugel)
		await get_tree().process_frame
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	var vorher := "%d/%d I-C-H, %d/%d E-G-O" % [_leuchtet(_main.standups),
			_main.standups.size(), _leuchtet(_main.ego_bank), _main.ego_bank.size()]
	_main._end_wizard()
	await get_tree().create_timer(0.4).timeout
	_zeile("nach dem Bericht", 0, false, false)
	var nachher := "%d/%d I-C-H, %d/%d E-G-O" % [_leuchtet(_main.standups),
			_main.standups.size(), _leuchtet(_main.ego_bank), _main.ego_bank.size()]
	var baenke_aus: bool = _leuchtet(_main.standups) == 0 and _leuchtet(_main.ego_bank) == 0
	if not baenke_aus:
		_fehler += 1
	print("  %s Buchstaben-Baenke: vorher %s -> nachher %s"
			% ["ok  " if baenke_aus else "FEHL", vorher, nachher])

	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if _fehler == 0 else "%d Fehler" % _fehler])
	get_tree().quit(0 if _fehler == 0 else 1)


func _leuchtet(bank: Array) -> int:
	var n := 0
	for s in bank:
		if s.lit:
			n += 1
	return n


func _zeile(phase: String, soll_unten: int, soll_blinkt: bool, soll_frenzy: bool) -> void:
	var unten := 0
	var blinkt := 0
	for d in _main.drops:
		if d.dropped:
			unten += 1
		if d.pulsing:
			blinkt += 1
	var ok: bool = unten == soll_unten and (blinkt > 0) == soll_blinkt \
			and Game.frenzy == soll_frenzy
	if not ok:
		_fehler += 1
	print("  %s %-22s gefallen=%d/%d (Soll %d)  blinkend=%d  Frenzy=%s"
			% ["ok  " if ok else "FEHL", phase, unten, _main.drops.size(),
			soll_unten, blinkt, str(Game.frenzy)])
