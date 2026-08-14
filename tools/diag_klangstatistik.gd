extends Node
## Zaehlt im laufenden Spiel mit, wie oft jeder Klang gespielt wird.  Damit
## laesst sich beurteilen, ob die Jubel-Klaenge zu dicht kommen, statt es zu
## schaetzen.  Gespielt wird mit Zufallsflippern wie im Autotest.
##   godot --headless --path . res://tools/diag_klangstatistik.tscn [-- <sekunden>]

const MAIN := preload("res://scenes/main.tscn")
## Was als Jubel gilt: die feiernden Jingles, nicht die Mechanik.  Der
## Auswurf der Mulde zaehlt nicht dazu, der ist Mechanik; die Auszahlung des
## Gluecksrads schon, auch wenn sie jetzt einen eigenen kurzen Klang hat.
const JUBEL := ["jackpot", "save", "mode", "ego_up", "count_go", "rad_zahlt",
		"wasd-complete", "damage-complete", "ich-oder-ego-complete"]
## So lange vor einem Jubel wird nach einem Ereignis gesucht, das ihn
## erklaert.  Reichlich bemessen, weil manche Klaenge ans Ende einer
## Inszenierung gehoeren: der Carry-Save zaehlt erst 3-2-1 herunter, sein
## Abschluss kommt zweieinhalb Sekunden nach dem Ballverlust.
const URSACHE_FENSTER := 3.5

var _dauer := 180.0
var _zaehler := {}
var _lief := {}
## [Zeit, Ereignis] der letzten Sekunden
var _ereignisse := []
var _t := 0.0
## Jubel-Klaenge, zu denen sich kein Ereignis finden liess
var _ohne_ursache := []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			_dauer = float(a)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	while Sfx._streams.is_empty() or Sfx._bau_task != -1:
		await get_tree().process_frame
	Game.event.connect(_auf_ereignis)

	print("--- Jubel-Klaenge und was ihnen vorausging ---")
	var t := 0.0
	var flip := 0.0
	while t < _dauer:
		await get_tree().physics_frame
		t += 1.0 / 120.0
		_t = t
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
	print("--- Ergebnis ---")
	if _ohne_ursache.is_empty():
		print("  ok - zu jedem Jubel gab es in den %.1f s davor ein Ereignis"
				% URSACHE_FENSTER)
	else:
		print("  FEHL %d Jubel ohne Ereignis davor:" % _ohne_ursache.size())
		var wie_oft := {}
		for n in _ohne_ursache:
			wie_oft[n] = int(wie_oft.get(n, 0)) + 1
		for n in wie_oft:
			print("       %-22s %d mal" % [n, wie_oft[n]])
	get_tree().quit(0 if _ohne_ursache.is_empty() else 1)


func _auf_ereignis(kind: String, data: Dictionary) -> void:
	var extra := ""
	for k in ["letter", "name", "rang"]:
		if data.has(k):
			extra = " " + str(data[k])
	_ereignisse.append([_t, kind + extra])


## Welche Ereignisse lagen kurz vor diesem Klang?
func _ursachen() -> String:
	var raus := PackedStringArray()
	for e in _ereignisse:
		if _t - float(e[0]) <= URSACHE_FENSTER:
			raus.append(str(e[1]))
	while _ereignisse.size() > 0 and _t - float(_ereignisse[0][0]) > 4.0:
		_ereignisse.pop_front()
	return ", ".join(raus)


## Ein Klang zaehlt, wenn ein Spieler neu anfaengt oder auf einen anderen
## Klang umschaltet.
func _zaehle() -> void:
	for i in Sfx._players.size():
		var p: AudioStreamPlayer = Sfx._players[i]
		var jetzt: AudioStream = p.stream if p.playing else null
		if jetzt != null and jetzt != _lief.get(i):
			var name := _name_von(jetzt)
			if name != "":
				_zaehler[name] = int(_zaehler.get(name, 0)) + 1
				if name in JUBEL:
					var warum := _ursachen()
					if warum == "":
						_ohne_ursache.append(name)
					print("  %6.1f s  %-22s %s" % [_t, name,
							warum if warum != "" else "OHNE ERKENNBARE URSACHE"])
		_lief[i] = jetzt


## Zu einem Datenstrom den Klangnamen finden - erzeugt oder eigene Datei.
func _name_von(s: AudioStream) -> String:
	for name in Sfx._streams:
		if s == Sfx._streams[name]:
			return str(name)
	for name in Sfx._nur_datei:
		if s == Sfx._nur_datei[name]:
			return str(name)
	return ""
