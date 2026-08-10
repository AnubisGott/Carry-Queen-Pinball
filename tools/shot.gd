extends Node

## Entwicklerwerkzeug: startet den Tisch, spielt kurz automatisch und legt
## Screenshots ab.  Aufruf:
##   godot --path . res://tools/shot.tscn -- <ausgabeordner>

const MAIN := preload("res://scenes/main.tscn")

var out_dir := "user://shots"


func _ready() -> void:
	_hide_window()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			out_dir = a
	DirAccess.make_dir_recursive_absolute(out_dir)
	add_child(MAIN.instantiate())
	_run()


## Zum Rendern braucht Godot ein echtes Fenster (--headless zeichnet nicht).
## Also: kein Fokus, keine Taskleiste, weit ausserhalb des Bildschirms - der
## Testlauf stoert damit die laufende Arbeit nicht.
func _hide_window() -> void:
	var w := get_window()
	w.set_flag(Window.FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-4000, -4000))


func _run() -> void:
	await _wait(1.0)
	await _shot("01_start")
	await _wait(3.0)
	await _shot("02_spiel")
	await _wait(5.0)
	await _shot("03_spaeter")
	print("screenshots -> ", out_dir)
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
