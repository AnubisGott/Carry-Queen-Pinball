extends Node
## Nahaufnahme der Tischmitte: der neue Pfeil unter den Hoernern, einmal in
## Ruhe und einmal im hellsten Moment des Blinkens.  Dazu die DAMAGE-Bank,
## abgeraeumt und nach der Frenzy - sie soll liegen bleiben.
##   godot --path . res://tools/shot_pfeil.tscn -- <ausgabeordner>

const MAIN := preload("res://scenes/main.tscn")
const ZOOM := 3
## Ausschnitt: vom Bumper-Feld bis unter die DAMAGE-Bank
const BILD := Rect2i(120, 430, 300, 190)

var _main: Node2D


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	_bild("ruhe")

	# Hurry-Up nachstellen: der Durchlauf ist scharf, Hoerner und Pfeil
	# blinken.  Auf den hellsten Moment warten.
	# Ueber das Spiel scharf machen, nicht am Durchlauf direkt: main setzt
	# gate.set_armed(hurry_active) in jedem Bild neu.
	_main.hurry_active = true
	_main.hurry_time = 12.0
	await get_tree().create_timer(0.2).timeout
	# Auf den hellsten Moment stellen statt darauf zu warten: die Uhr des
	# Blinkens kurz vor den Scheitel setzen, das naechste Bild trifft ihn.
	_main.gate._t = PI / 2.0 - 0.1
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_bild("blinkt")

	# DAMAGE-Bank abraeumen und die Frenzy auslaufen lassen
	_main.hurry_active = false
	var kugel: PinBall = _main._spawn_ball(Vector2(270, 700))
	kugel.freeze = true
	for d in _main.drops:
		d._on_hit(kugel)
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	_bild("frenzy_laeuft")
	_main.frenzy_time = 0.02
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_bild("frenzy_vorbei")
	print("DAMAGE-Ziele noch unten: %d von %d" % [_gefallen(), _main.drops.size()])
	get_tree().quit()


func _gefallen() -> int:
	var n := 0
	for d in _main.drops:
		if d.dropped:
			n += 1
	return n


func _bild(name: String) -> void:
	var ordner: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	var voll := get_viewport().get_texture().get_image()
	var r := BILD.intersection(Rect2i(Vector2i.ZERO, voll.get_size()))
	var teil := voll.get_region(r)
	teil.resize(r.size.x * ZOOM, r.size.y * ZOOM, Image.INTERPOLATE_NEAREST)
	var pfad: String = ordner.path_join("mitte_%s.png" % name)
	teil.save_png(pfad)
	print("SHOT ", pfad)
