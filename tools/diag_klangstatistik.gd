extends Node
## Zaehlt im laufenden Spiel mit, wie oft jeder Klang gespielt wird.  Damit
## laesst sich beurteilen, ob die Jubel-Klaenge zu dicht kommen, statt es zu
## schaetzen.  Gespielt wird mit Zufallsflippern wie im Autotest.
##   godot --headless --path . res://tools/diag_klangstatistik.tscn [-- <sekunden>]

const MAIN := preload("res://scenes/main.tscn")
## Was als Jubel gilt: die feiernden Jingles, nicht die Mechanik.  Der
## Auswurf der Mulde zaehlt nicht dazu, der ist Mechanik; die Auszahlung des
## Gluecksrads schon, auch wenn sie jetzt einen eigenen kurzen Klang hat.
const JUBEL := ["jackpot", "save", "mode", "ego_up", "count_go", "rad_zahlt"]

var _dauer := 180.0
var _zaehler := {}
var _lief := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			_dauer = float(a)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	while Sfx._streams.is_empty() or Sfx._bau_task != -1:
		await get_tree().process_frame

	var t := 0.0
	var flip := 0.0
	while t < _dauer:
		await get_tree().physics_frame
		t += 1.0 / 120.0
		flip -= 1.0 / 120.0
		if flip <= 0.0:
			flip = 0.35
			for a in ["flip_left", "flip_right", "launch"]:
				if randf() < 0.5:
					Input.action_press(a)
				else:
					Input.action_release(a)
		_zaehle()
	for a in ["flip_left", "flip_right", "launch"]:
		Input.action_release(a)

	var namen := _zaehler.keys()
	namen.sort_custom(func(x, y): return _zaehler[x] > _zaehler[y])
	print("--- %.0f Sekunden Spiel ---" % _dauer)
	var jubel_gesamt := 0
	for n in namen:
		var pro_min: float = 60.0 * float(_zaehler[n]) / _dauer
		var markierung := "  <- Jubel" if n in JUBEL else ""
		if n in JUBEL:
			jubel_gesamt += int(_zaehler[n])
		print("  %-10s %4d mal  %5.1f je Minute%s" % [n, _zaehler[n], pro_min, markierung])
	print("Jubel-Klaenge zusammen: %d in %.0f s = %.1f je Minute" % [
			jubel_gesamt, _dauer, 60.0 * float(jubel_gesamt) / _dauer])
	get_tree().quit()


## Ein Klang zaehlt, wenn ein Spieler neu anfaengt oder auf einen anderen
## Klang umschaltet.
func _zaehle() -> void:
	for i in Sfx._players.size():
		var p: AudioStreamPlayer = Sfx._players[i]
		var jetzt: AudioStream = p.stream if p.playing else null
		if jetzt != null and jetzt != _lief.get(i):
			for name in Sfx._streams:
				if jetzt == Sfx._streams[name]:
					_zaehler[name] = int(_zaehler.get(name, 0)) + 1
					break
		_lief[i] = jetzt
