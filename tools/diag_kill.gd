extends Node
## Diagnose: loest die vier Bumper der Reihe nach aus und prueft, ob die
## Kill-Serie zuendet und den Ego-Multiplikator hebt.
##   godot --headless --path . res://tools/diag_kill.tscn

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var fehler := 0
	print("Bumper-Aufdrucke: %s" % [_labels(main)])
	print("vorher : Kills=%d  EGO x%d" % [Game.kills, Game.ego_mult])
	for id in ["W", "A", "S", "D"]:
		main._on_bumper(id)
		await get_tree().physics_frame
	print("nachher: Kills=%d  EGO x%d  Hurry=%s" % [Game.kills, Game.ego_mult,
			str(main.hurry_active)])
	# Die Disziplin in der oberen Leiste (dort als WSAD beschriftet) muss mit
	# den vier Bumpern angehen - nicht erst beim Multiball.
	print("WSAD-Lampe oben: %s -> %s" % [str(Game.disciplines["CARRY"]),
			"OK" if Game.disciplines["CARRY"] else "FEHLER"])
	fehler += 0 if Game.disciplines["CARRY"] else 1
	# Ballverlust darf sie nicht loeschen
	main._start_ball()
	await get_tree().create_timer(0.3).timeout
	print("nach Ballwechsel:  %s -> %s" % [str(Game.disciplines["CARRY"]),
			"bleibt an OK" if Game.disciplines["CARRY"] else "FEHLER"])
	fehler += 0 if Game.disciplines["CARRY"] else 1
	# Erst der fertige Bericht setzt sie zurueck
	main._end_wizard()
	await get_tree().create_timer(0.3).timeout
	print("nach dem Bericht:  %s -> %s" % [str(Game.disciplines["CARRY"]),
			"aus OK" if not Game.disciplines["CARRY"] else "FEHLER"])
	fehler += 1 if Game.disciplines["CARRY"] else 0
	# Solange die Hoerner blinken, muessen alle vier Bumper markiert bleiben
	print("waehrend das Hurry-Up laeuft: markiert %s -> %s" % [
			_marken(main), "OK" if _alle_markiert(main) else "FEHLER"])
	fehler += 0 if _alle_markiert(main) else 1
	# Hurry-Up ablaufen lassen - erst danach gehen sie aus
	main.hurry_time = 0.05
	await get_tree().create_timer(0.4).timeout
	print("nach Ablauf des Hurry-Ups:    markiert %s -> %s" % [
			_marken(main), "OK" if _marken(main) == "[]" else "FEHLER"])
	fehler += 0 if _marken(main) == "[]" else 1
	# Zweite Runde - muss erneut zuenden
	for id in ["W", "A", "S", "D"]:
		main._on_bumper(id)
		await get_tree().physics_frame
	print("2. Runde: Kills=%d  EGO x%d" % [Game.kills, Game.ego_mult])

	# Waehrend die Hoerner blinken, spielt man weiter und trifft Bumper.  Ist
	# das Blinken vorbei, muessen trotzdem alle vier dunkel werden - sonst
	# bleiben die zwischendurch getroffenen an und die naechste Serie faengt
	# nicht bei null an.
	main._on_bumper("W")
	main._on_bumper("A")
	await get_tree().physics_frame
	print("waehrend des Blinkens W und A getroffen: markiert %s" % _marken(main))
	main.hurry_time = 0.05
	await get_tree().create_timer(0.4).timeout
	print("danach: markiert %s -> %s" % [_marken(main),
			"alle dunkel OK" if _marken(main) == "[]" else "FEHLER"])
	fehler += 0 if _marken(main) == "[]" else 1
	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if fehler == 0 else "%d Fehler" % fehler])
	get_tree().quit(0 if fehler == 0 else 1)


func _marken(main: Node2D) -> String:
	var out := []
	for k in main.bumpers:
		if main.bumpers[k].marked:
			out.append(str(k))
	return str(out)


func _alle_markiert(main: Node2D) -> bool:
	for k in main.bumpers:
		if not main.bumpers[k].marked:
			return false
	return true


func _labels(main: Node2D) -> String:
	var out := []
	for k in main.bumpers:
		out.append("%s=%s" % [k, main.bumpers[k].label])
	return ", ".join(out)
