extends Node
## Entwicklerwerkzeug: startet das Spiel, zwingt den Wizard-Modus an und legt
## zwei Aufnahmen ab - damit laesst sich das Pulsieren der Disziplinen und der
## Zeitbalken pruefen.
##   godot --path . res://tools/shot_wizard.tscn -- <ausgabeordner>

const MAIN := preload("res://scenes/main.tscn")

var out_dir := "user://shots"


func _ready() -> void:
	var w := get_window()
	w.set_flag(Window.FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-4000, -4000))
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			out_dir = a
	DirAccess.make_dir_recursive_absolute(out_dir)
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	if "--banks" in OS.get_cmdline_user_args():
		# I-C-H und E-G-O anzuenden und den Farbwechsel ueber mehrere
		# Aufnahmen festhalten
		for s in main.standups:
			s.lit = true
		for s in main.ego_bank:
			s.lit = true
		for i in 4:
			await get_tree().create_timer(1.3).timeout
			await _shot("bank_%d" % (i + 1))
		print("screenshots -> ", out_dir)
		get_tree().quit()
		return
	if "--frenzy" in OS.get_cmdline_user_args():
		# DAMAGE-Bank fallen lassen und die Frenzy anwerfen
		for d in main.drops:
			d.dropped = true
			d.queue_redraw()
		Game.frenzy = true
		main.frenzy_time = main.FRENZY_TIME
		await get_tree().create_timer(0.4).timeout
		await _shot("frenzy_a")
		await get_tree().create_timer(0.32).timeout
		await _shot("frenzy_b")
		print("screenshots -> ", out_dir)
		get_tree().quit()
		return
	main._start_wizard()
	await get_tree().create_timer(0.6).timeout
	await _shot("wizard_a")
	await get_tree().create_timer(0.35).timeout
	await _shot("wizard_b")
	print("screenshots -> ", out_dir)
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
