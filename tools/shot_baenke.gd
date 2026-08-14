extends Node
## Macht eine Nahaufnahme der beiden Buchstaben-Baenke: links I-C-H, rechts
## E-G-O, jeweils zur Haelfte getroffen.  Bei 10 mal 34 Pixeln je Target
## laesst sich nur am Bild beurteilen, ob das Kreuz etwas taugt - deshalb
## wird der Ausschnitt sechsfach vergroessert abgelegt.
##   godot --path . res://tools/shot_baenke.tscn -- <ausgabeordner>

const MAIN := preload("res://scenes/main.tscn")
const ZOOM := 6


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.2).timeout
	# Erst der unberuehrte Zustand zum Vergleich - nur so laesst sich auf
	# einem Spiel-Screenshot entscheiden, ob ein Target leuchtet oder nicht.
	await RenderingServer.frame_post_draw
	_ausschnitte("dunkel")
	# Je Bank die ersten beiden getroffen, der dritte noch offen - so steht
	# beides nebeneinander im Bild.
	for i in main.standups.size():
		if i < 2:
			main.standups[i].lit = true
			main.standups[i].queue_redraw()
	for i in main.ego_bank.size():
		if i < 2:
			main.ego_bank[i].lit = true
			main.ego_bank[i].queue_redraw()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw

	_ausschnitte("getroffen")
	get_tree().quit()


func _ausschnitte(stand: String) -> void:
	var ordner: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	var voll := get_viewport().get_texture().get_image()
	# Beide Baenke liegen auf derselben Hoehe, nur an den Aussenraendern
	for fall in [["ich", 8, 340, 70, 200], ["ego", 430, 340, 70, 200]]:
		var r := Rect2i(int(fall[1]), int(fall[2]), int(fall[3]), int(fall[4]))
		r = r.intersection(Rect2i(Vector2i.ZERO, voll.get_size()))
		var teil := voll.get_region(r)
		teil.resize(r.size.x * ZOOM, r.size.y * ZOOM, Image.INTERPOLATE_NEAREST)
		var pfad: String = ordner.path_join("bank_%s_%s.png" % [stand, fall[0]])
		teil.save_png(pfad)
		print("SHOT ", pfad)
