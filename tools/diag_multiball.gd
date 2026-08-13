extends Node
## Prueft, wann der G-G-E-Z-Multiball startet:
##  1. mit drei brennenden Gassen darf er nicht starten
##  2. mit der vierten startet er
##  3. eine Sekunde spaeter sind die vier Lampen wieder aus - der Multiball
##     laeuft dann weiter, obwohl kaum eine Lampe brennt.  Das sieht im Spiel
##     nach Fehler aus, ist aber die Freigabe fuer die naechste Runde.
##   godot --headless --path . res://tools/diag_multiball.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _multiball_bei := -1


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	Game.event.connect(_on_event)
	await get_tree().create_timer(1.0).timeout

	print("--- drei Gassen ---")
	for i in 3:
		_main.ggez[i].set_lit(true)
	_main._check_ggez()
	await get_tree().create_timer(0.3).timeout
	print("  %d von 4 an -> Multiball: %s  %s" % [_an(), str(Game.multiball),
			"OK" if not Game.multiball else "FEHLER"])

	print("--- vierte Gasse ---")
	_main.ggez[3].set_lit(true)
	_main._check_ggez()
	await get_tree().create_timer(0.3).timeout
	print("  %d von 4 an -> Multiball: %s  %s" % [_an(), str(Game.multiball),
			"OK" if Game.multiball else "FEHLER"])
	print("  Lampen beim Start des Multiballs: %d" % _multiball_bei)

	print("--- eine Sekunde spaeter ---")
	await get_tree().create_timer(1.2).timeout
	# Die Bank wird eine Sekunde nach dem Auszahlen freigegeben.  Dass danach
	# schon wieder eine Lampe brennt, ist kein Fehler: die beiden neuen Kugeln
	# des Multiballs erscheinen bei (270,185), also direkt ueber den Gassen,
	# und fallen als erstes dort hindurch.
	print("  %d von 4 an, Multiball laeuft: %s -> %s" % [_an(), str(Game.multiball),
			"Bank freigegeben OK" if _an() < 4 and Game.multiball else "ABWEICHUNG"])
	print("ERGEBNIS: Multiball startet nur bei vier Lampen (gemessen: %d)" % _multiball_bei)
	get_tree().quit()


func _an() -> int:
	var n := 0
	for r in _main.ggez:
		if r.lit:
			n += 1
	return n


func _on_event(kind: String, _data: Dictionary) -> void:
	if kind == "multiball" and _multiball_bei < 0:
		_multiball_bei = _an()
