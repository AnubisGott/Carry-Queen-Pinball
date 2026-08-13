extends Node
## Hoerprobe ohne Hoeren: listet zu allen Klangdateien in einem Ordner die
## Laenge auf.  Praktisch, um aus einem heruntergeladenen Paket die passend
## kurzen Treffer herauszusuchen, bevor man sie einbaut.
##   godot --headless --path . res://tools/diag_ogg.tscn -- <ordner> [filter]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Aufruf: -- <ordner> [namensteil]")
		get_tree().quit()
		return
	var ordner: String = args[0]
	var filter: String = args[1] if args.size() > 1 else ""
	var dir := DirAccess.open(ordner)
	if dir == null:
		print("Ordner nicht lesbar: ", ordner)
		get_tree().quit()
		return
	var zeilen := []
	for datei in dir.get_files():
		if filter != "" and not datei.containsn(filter):
			continue
		var pfad := ordner.path_join(datei)
		var s: AudioStream = null
		if datei.ends_with(".ogg"):
			s = AudioStreamOggVorbis.load_from_file(pfad)
		elif datei.ends_with(".wav"):
			s = AudioStreamWAV.load_from_file(pfad)
		if s != null:
			zeilen.append([s.get_length(), datei])
	zeilen.sort_custom(func(a, b): return a[0] < b[0])
	for z in zeilen:
		print("  %6.0f ms  %s" % [1000.0 * z[0], z[1]])
	print("%d Dateien" % zeilen.size())
	get_tree().quit()
