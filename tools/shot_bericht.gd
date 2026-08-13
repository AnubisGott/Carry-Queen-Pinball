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
		# Ueber den echten Weg: alle DAMAGE-Ziele umlegen und die Bank pruefen
		# lassen.  Den Zustand direkt zu setzen wuerde genau den Teil
		# ueberspringen, um den es geht.
		for d in main.drops:
			d.dropped = true
			d.queue_redraw()
		main._check_bank()
		print("Bank umgelegt -> Frenzy %s, Restzeit %.1f s" % [str(Game.frenzy),
				main.frenzy_time])
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
