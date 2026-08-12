extends Node
## Diagnose: loest die vier Bumper der Reihe nach aus und prueft, ob die
## Kill-Serie zuendet und den Ego-Multiplikator hebt.
##   godot --headless --path . res://tools/diag_kill.tscn

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	print("Bumper-Aufdrucke: %s" % [_labels(main)])
	print("vorher : Kills=%d  EGO x%d" % [Game.kills, Game.ego_mult])
	for id in ["W", "A", "S", "D"]:
		main._on_bumper(id)
		await get_tree().physics_frame
	print("nachher: Kills=%d  EGO x%d  Hurry=%s" % [Game.kills, Game.ego_mult,
			str(main.hurry_active)])
	# Zweite Runde - muss erneut zuenden
	for id in ["W", "A", "S", "D"]:
		main._on_bumper(id)
		await get_tree().physics_frame
	print("2. Runde: Kills=%d  EGO x%d" % [Game.kills, Game.ego_mult])
	get_tree().quit()


func _labels(main: Node2D) -> String:
	var out := []
	for k in main.bumpers:
		out.append("%s=%s" % [k, main.bumpers[k].label])
	return ", ".join(out)
