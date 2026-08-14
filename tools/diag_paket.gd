extends Node
## Schaut in ein fertiges Paket (.pck) hinein und listet auf, was darin
## liegt.  Damit laesst sich nachsehen, ob eine Datei im Export wirklich
## ankommt, statt es am fertigen Spiel zu erraten.
##   godot --headless --path . res://tools/diag_paket.tscn -- <datei.pck> [suchtext]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Aufruf: -- <datei.pck> [suchtext]")
		get_tree().quit(1)
		return
	var pfad: String = args[0]
	var suche: String = args[1] if args.size() > 1 else ""
	var f := FileAccess.open(pfad, FileAccess.READ)
	if f == null:
		print("Paket nicht lesbar: ", pfad)
		get_tree().quit(1)
		return

	# Kopf des Godot-Pakets
	if f.get_32() != 0x43504447:  # "GDPC"
		print("Kein Godot-Paket (Kennung GDPC fehlt): ", pfad)
		get_tree().quit(1)
		return
	var format := f.get_32()
	var vmaj := f.get_32()
	var vmin := f.get_32()
	var vpat := f.get_32()
	if format >= 2:
		f.get_32()   # Merkmale
		f.get_64()   # Anfang der Daten
	for i in 16:
		f.get_32()   # reserviert
	var anzahl := f.get_32()
	print("Paket %s  (Format %d, Godot %d.%d.%d, %d Dateien)" % [
			pfad.get_file(), format, vmaj, vmin, vpat, anzahl])

	var treffer := 0
	var gesamt := 0
	var summe := 0
	for i in anzahl:
		var laenge := f.get_32()
		var name := f.get_buffer(laenge).get_string_from_utf8()
		f.get_64()                 # Anfang
		var groesse := f.get_64()  # Laenge
		f.get_buffer(16)           # Pruefsumme
		if format >= 2:
			f.get_32()             # Merkmale
		gesamt += 1
		summe += groesse
		if suche == "" or name.containsn(suche):
			treffer += 1
			if treffer <= 60:
				print("  %8d  %s" % [groesse, name])
	print("--- %d von %d Dateien passen%s, Paket zusammen %.1f MB ---" % [
			treffer, gesamt, "" if suche == "" else " zu \"%s\"" % suche,
			float(summe) / 1048576.0])
	get_tree().quit(0)
