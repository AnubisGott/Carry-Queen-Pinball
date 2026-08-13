extends Node
## Zaehlt mit, welche Texte mitten auf dem Spielfeld eingeblendet werden und
## wie oft.  Damit laesst sich beurteilen, ob es zu viele sind, statt es zu
## schaetzen.  Gespielt wird mit Zufallsflippern wie im Autotest.
##   godot --headless --path . res://tools/diag_meldungen.tscn [-- <sekunden>]

const MAIN := preload("res://scenes/main.tscn")

var _dauer := 180.0
var _gross := {}
var _klein := {}
var _letzt_gross := ""
var _letzt_klein := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			_dauer = float(a)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	var hud: Hud = main.hud

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
		_merke(hud._msg_label.text, _gross, true)
		_merke(hud._sub_label.text, _klein, false)
	for a in ["flip_left", "flip_right", "launch"]:
		Input.action_release(a)

	print("--- %.0f Sekunden Spiel ---" % _dauer)
	var g := _summe(_gross)
	var k := _summe(_klein)
	print("Grosse Meldungen: %d = %.1f je Minute" % [g, 60.0 * g / _dauer])
	_liste(_gross)
	print("Kleine Zeilen darunter: %d = %.1f je Minute" % [k, 60.0 * k / _dauer])
	_liste(_klein)
	print("Zusammen %.1f Einblendungen je Minute" % (60.0 * float(g + k) / _dauer))
	get_tree().quit()


func _merke(text: String, wohin: Dictionary, ist_gross: bool) -> void:
	var letzt := _letzt_gross if ist_gross else _letzt_klein
	if text == letzt:
		return
	if ist_gross:
		_letzt_gross = text
	else:
		_letzt_klein = text
	if text.strip_edges() == "":
		return
	wohin[text] = int(wohin.get(text, 0)) + 1


func _summe(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _liste(d: Dictionary) -> void:
	var namen := d.keys()
	namen.sort_custom(func(x, y): return d[x] > d[y])
	for n in namen:
		print("  %3d x  %s" % [d[n], n])
