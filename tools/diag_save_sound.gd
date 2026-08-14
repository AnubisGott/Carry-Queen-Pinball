extends Node
## Prueft, welche Klaenge im Carry-Save laufen: dort soll nichts aus einer
## Aufnahme kommen, sondern nur Erzeugtes.  Beim echten Ballverlust dagegen
## muss die Aufnahme der herunterfallenden Kugel zu hoeren sein.
##   godot --headless --path . res://tools/diag_save_sound.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _aufnahmen := {}
var _erzeugt := {}
## Dateien ohne erzeugtes Gegenstueck - die laufen allein
var _eigene := {}


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	while Sfx._streams.is_empty() or Sfx._bau_task != -1:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	# Nur die Klaenge des jeweiligen Ablaufs zaehlen - waehrenddessen rollt die
	# Kugel weiter und loest nebenbei Banden, Bumper und Ziele aus.
	print("--- Carry-Save mit Countdown ---")
	_zaehlen_an()
	Game.ball_save_armed = true
	_main._save_return()
	await get_tree().create_timer(3.5).timeout
	_bericht(["rumble", "count", "count_go", "launch"], false)

	print("--- echter Ballverlust ---")
	_zaehlen_an()
	Sfx.play("drain", 4.0)
	await get_tree().create_timer(0.6).timeout
	_bericht(["drain"], true)

	# Die volle WSAD-Reihe hat eine eigene Aufnahme.  Die soll den erzeugten
	# Jubel ersetzen, nicht neben ihm laufen.
	print("--- WSAD komplett ---")
	_zaehlen_an()
	for id in ["W", "A", "S", "D"]:
		_main._on_bumper(id)
		await get_tree().physics_frame
	await get_tree().create_timer(0.4).timeout
	var datei: bool = _eigene.has("wasd-complete")
	var jubel: bool = _erzeugt.has("ego_up")
	print("  Datei wasd-complete: %s   erzeugter Jubel ego_up: %s -> %s"
			% [str(datei), str(jubel),
			"OK" if datei and not jubel else "ABWEICHUNG"])

	# Dasselbe fuer die abgeraeumte DAMAGE-Bank
	print("--- DAMAGE-Bank abgeraeumt ---")
	# Ueber den echten Weg: eine Kugel trifft jedes Ziel, das Ereignis
	# "drop_target" laesst main die Bank pruefen.
	var kugel: PinBall = _main._spawn_ball(Vector2(270, 600))
	kugel.freeze = true
	_zaehlen_an()
	for d in _main.drops:
		d._on_hit(kugel)
		await get_tree().physics_frame
	await get_tree().create_timer(0.4).timeout
	var datei2: bool = _eigene.has("damage-complete")
	var modus: bool = _erzeugt.has("mode")
	print("  Datei damage-complete: %s   erzeugter Klang mode: %s -> %s"
			% [str(datei2), str(modus),
			"OK" if datei2 and not modus else "ABWEICHUNG"])

	# Beide Buchstaben-Baenke teilen sich eine Aufnahme.  Auch hier ueber den
	# echten Weg: die Kugel trifft jedes Ziel der Bank.
	for fall in [["I-C-H", _main.standups], ["E-G-O", _main.ego_bank]]:
		print("--- %s komplett ---" % fall[0])
		_zaehlen_an()
		for s in fall[1]:
			s._on_hit(kugel)
			# Zwischen zwei Buchstaben muss ein Bild vergehen: nur einer je
			# Vorbeirollen geht an, und die Sperre faellt erst, wenn keine
			# Kugel mehr bei der Bank ist (siehe standup.gd).  Die Testkugel
			# liegt weit weg, es fehlt also nur der Zeitschritt.
			await get_tree().process_frame
			await get_tree().physics_frame
		await get_tree().create_timer(0.4).timeout
		var d3: bool = _eigene.has("ich-oder-ego-complete")
		var j3: bool = _erzeugt.has("jackpot")
		print("  Datei ich-oder-ego-complete: %s   erzeugter jackpot: %s -> %s"
				% [str(d3), str(j3), "OK" if d3 and not j3 else "ABWEICHUNG"])
	get_tree().quit()


func _zaehlen_an() -> void:
	_aufnahmen.clear()
	_erzeugt.clear()
	_eigene.clear()
	set_process(true)


func _process(_d: float) -> void:
	for p in Sfx._players:
		if not p.playing or p.stream == null:
			continue
		for name in Sfx._streams:
			if p.stream == Sfx._streams[name]:
				_erzeugt[name] = true
			elif Sfx._aus_datei.has(name) and p.stream == Sfx._aus_datei[name]:
				_aufnahmen[name] = true
		for name in Sfx._nur_datei:
			if p.stream == Sfx._nur_datei[name]:
				_eigene[name] = true


func _bericht(namen: Array, aufnahme_erwartet: bool) -> void:
	var e := []
	var a := []
	for n in namen:
		if _erzeugt.has(n):
			e.append(n)
		if _aufnahmen.has(n):
			a.append(n)
	print("  erzeugt:   %s" % str(e))
	print("  Aufnahmen: %s -> %s" % [str(a),
			"OK" if (a.size() > 0) == aufnahme_erwartet else "ABWEICHUNG"])
