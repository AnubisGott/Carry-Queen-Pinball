extends Node
## Macht einen Screenshot mit laufendem Bericht (Wizard), damit die Anzeige
## oben - Titel samt Faktor links neben dem Zeitbalken - geprueft werden kann.
##   godot --path . res://tools/shot_bericht.tscn -- <ausgabeordner>

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var ordner := "shot_bericht"
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			ordner = a
	DirAccess.make_dir_recursive_absolute(ordner)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	var nur_frenzy := "--frenzy" in OS.get_cmdline_user_args()
	if nur_frenzy:
		# Nur die Damage-Frenzy laufen lassen
		Game.frenzy = true
		main.frenzy_time = main.FRENZY_TIME * 0.7
	else:
		# Alle vier Disziplinen abhaken - das startet den Bericht
		for d in ["DAMAGE", "EGO", "CARRY", "ICH"]:
			Game.discipline_done(d)
	await get_tree().create_timer(1.5).timeout
	print("Bericht: %s  Frenzy: %s  Restzeit %.1f / %.1f s" % [str(Game.wizard),
			str(Game.frenzy), main.wizard_time, main.frenzy_time])
	await RenderingServer.frame_post_draw
	var bild := get_viewport().get_texture().get_image()
	bild.save_png(ordner.path_join("bericht.png"))
	print("geschrieben: ", ordner.path_join("bericht.png"))
	get_tree().quit()
