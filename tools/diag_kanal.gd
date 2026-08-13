extends Node
## Prueft das YouTube-Abzeichen und die Kanal-Erwaehnungen im Chat:
##  1. sitzt das Abzeichen in der Leiste und zeigt es auf den richtigen Kanal?
##  2. faengt es die Leertaste nicht ab (sonst startet kein Ball mehr)?
##  3. taucht der Kanal im Chat auf, wenn genug Zeit vergeht?
##   godot --headless --path . res://tools/diag_kanal.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	var hud: Hud = _main.hud

	var abzeichen := _finde(hud)
	print("--- Abzeichen ---")
	if abzeichen == null:
		print("  FEHLT")
		get_tree().quit()
		return
	print("  gefunden bei (%.0f,%.0f), Groesse %.0fx%.0f" % [
			abzeichen.position.x, abzeichen.position.y,
			abzeichen.size.x, abzeichen.size.y])
	print("  Ziel: %s" % YoutubeBadge.URL)
	print("  Fokus aus: %s -> %s" % [
			str(abzeichen.focus_mode == Control.FOCUS_NONE),
			"Leertaste bleibt beim Abschuss OK"
			if abzeichen.focus_mode == Control.FOCUS_NONE else "FEHLER"])

	print("--- Kanal im Chat ---")
	# Die Wartezeit abkuerzen, statt zwei Minuten zuzusehen
	hud._kanal_t = 0.05
	var vorher := hud._chat_vbox.get_child_count()
	await get_tree().create_timer(0.5).timeout
	var neu := ""
	if hud._chat_vbox.get_child_count() > 0:
		var letzte: Label = hud._chat_vbox.get_child(hud._chat_vbox.get_child_count() - 1)
		neu = letzte.text
	var passt := neu.containsn("youtube") or neu.containsn("abonn") \
			or neu.containsn("stream") or neu.containsn("link") or neu.containsn("YT")
	print("  neue Zeile: %s" % neu)
	print("  Kanal erwaehnt: %s -> %s" % [str(passt), "OK" if passt else "ABWEICHUNG"])
	print("  naechste Erwaehnung in %.0f s" % hud._kanal_t)
	get_tree().quit()


func _finde(n: Node) -> YoutubeBadge:
	if n is YoutubeBadge:
		return n
	for c in n.get_children():
		var t := _finde(c)
		if t != null:
			return t
	return null
