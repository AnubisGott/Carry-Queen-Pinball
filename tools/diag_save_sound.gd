extends Node
## Prueft, welche Klaenge im Carry-Save laufen: dort soll nichts aus einer
## Aufnahme kommen, sondern nur Erzeugtes.  Beim echten Ballverlust dagegen
## muss die Aufnahme der herunterfallenden Kugel zu hoeren sein.
##   godot --headless --path . res://tools/diag_save_sound.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _aufnahmen := {}
var _erzeugt := {}


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
	get_tree().quit()


func _zaehlen_an() -> void:
	_aufnahmen.clear()
	_erzeugt.clear()
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
