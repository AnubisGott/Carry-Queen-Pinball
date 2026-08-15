extends Node
## Macht das Hintergrundbild fuer den itch.io-Rahmen ("Embed BG"): das Bild,
## das hinter dem "Run game"-Knopf steht, bevor jemand das Spiel startet.
##
## Der Tisch wird dafuer in einen vorzeigbaren Zustand gebracht - ein paar
## Bahnen leuchten, die Bank ist angebrochen, der Chat hat Text.  Zwei
## Fassungen: einmal wie gesehen, einmal abgedunkelt, damit der pinke Knopf in
## der Mitte dagegen ankommt.
##
##   godot --path . --resolution 1320x1920 res://tools/shot_embed.tscn -- <ordner>
##
## Die Wunschgroesse ist doppelte Spielgroesse.  Passt sie nicht auf den
## Bildschirm, verkleinert Windows das Fenster - dann kommt eben weniger heraus
## (auf einem 1920x1080-Schirm rund 976x1421).  Das genuegt: der Rahmen bei
## itch.io ist 662x992, das Bild soll nur etwas groesser sein als er.

const MAIN := preload("res://scenes/main.tscn")

## Ereignisse, die der Chat kommentiert.  Die stehen in main.gd nicht in der
## Verteilung, koennen also nichts am Spielstand verstellen - hier soll sich
## nur die rechte Spalte fuellen.
const GEPLAUDER := ["spinner", "pocket", "ggez", "jackpot", "kill", "save",
		"multiball", "wheel_hit", "frenzy", "standup"]


func _ready() -> void:
	var ordner := "shot_embed"
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			ordner = a
	DirAccess.make_dir_recursive_absolute(ordner)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	_fenster_verstecken()
	await get_tree().create_timer(1.0).timeout

	_tisch_herrichten(main)
	await _chat_fuellen()
	# Kurz warten, bis die eingeblendeten Zeilen wieder weg sind - ueber der
	# Mitte sitzt spaeter der Knopf, dort soll nichts stehen.
	await get_tree().create_timer(3.0).timeout
	# Die Kugel zum Schluss und eingefroren: waehrend der Chat sich fuellte,
	# waere sie laengst unten durch und im Schacht wieder aufgetaucht.  Im
	# offenen Feld sieht der Tisch nach Spiel aus statt nach Wartestellung.
	main._spawn_ball(Vector2(150, 430)).freeze = true

	await RenderingServer.frame_post_draw
	var bild := get_viewport().get_texture().get_image()
	bild.save_png(ordner.path_join("embed-bg.png"))

	# Zweite Fassung, abgedunkelt.  Eine schwarze Scheibe im Spiel selbst ginge
	# nicht: die HUD-Ebene liegt schon auf 128, hoeher laesst Godot nicht, und
	# die Leiste samt Chat bliebe hell.  Also am fertigen Bild, ueber
	# blend_rect - das macht die Engine, nicht eine Schleife in GDScript.
	var dunkel := bild.duplicate() as Image
	dunkel.convert(Image.FORMAT_RGBA8)
	var schleier := Image.create(dunkel.get_width(), dunkel.get_height(), false,
			Image.FORMAT_RGBA8)
	schleier.fill(Color(0, 0, 0, 0.45))
	dunkel.blend_rect(schleier, Rect2i(Vector2i.ZERO, dunkel.get_size()),
			Vector2i.ZERO)
	dunkel.save_png(ordner.path_join("embed-bg-dunkel.png"))

	print("geschrieben: %s (%dx%d)" % [ordner, bild.get_width(), bild.get_height()])
	get_tree().quit()


## Zum Rendern braucht Godot ein echtes Fenster.  Es liegt weit ausserhalb des
## Bildschirms und nimmt keinen Fokus - so stoert die Aufnahme nicht.
func _fenster_verstecken() -> void:
	var w := get_window()
	w.set_flag(Window.FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-4000, -4000))


## Ein Spielstand mittendrin: angefangen, aber nicht abgeraeumt.  Ein ganz
## leerer Tisch sieht auf dem Bild nach nichts aus, ein voll abgeraeumter nach
## Ende.
func _tisch_herrichten(main: Node2D) -> void:
	Game.score = 486230
	Game.ego_mult = 6
	Game.ball_number = 2
	Game.emit("score", {"points": 0})
	# DAMAGE angebrochen
	for i in main.drops.size():
		if i < 4:
			main.drops[i].dropped = true
			main.drops[i].queue_redraw()
	# I-C-H und E-G-O je halb
	for i in main.standups.size():
		if i < 2:
			main.standups[i].lit = true
			main.standups[i].queue_redraw()
	for i in main.ego_bank.size():
		if i < 1:
			main.ego_bank[i].lit = true
			main.ego_bank[i].queue_redraw()
	# Zwei der vier Gassen oben
	for i in main.ggez.size():
		if i < 2:
			main.ggez[i].set_lit(true)
	# Drei der vier Bumper markiert - die Serie laeuft noch
	for l in ["W", "A", "S"]:
		main.streak_letters[l] = true
	main._update_bumper_marks()


## Der Chat lebt von Ereignissen.  Ohne sie bleibt die rechte Spalte leer.
func _chat_fuellen() -> void:
	for kind in GEPLAUDER:
		Game.emit(kind, {})
		await get_tree().create_timer(0.35).timeout
	for kind in GEPLAUDER:
		Game.emit(kind, {})
		await get_tree().create_timer(0.35).timeout
