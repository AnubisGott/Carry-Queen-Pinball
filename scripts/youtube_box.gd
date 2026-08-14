class_name YoutubeBox
extends Button
## Kasten unten in der Chat-Spalte: fuehrt zum Musikvideo der Carry Queen.
##
## Wie das Abzeichen in der Kopfleiste ist das Symbol gezeichnet und keine
## Bilddatei - das Projekt kommt ohne fremde Grafiken aus, und es stellt sich
## keine Frage nach Markenrechten an einer mitgelieferten Datei.

const URL := "https://youtu.be/l-_McphkpyY"
const ROT := Color(0.95, 0.15, 0.15)
const ROT_HELL := Color(1.0, 0.35, 0.3)
const RAHMEN := Color(0.72, 0.20, 0.95, 0.85)

var _drueber := false


func _init(groesse: Vector2) -> void:
	custom_minimum_size = groesse
	size = groesse
	flat = true
	# Nicht fokussierbar: sonst faengt der Knopf die Leertaste statt des
	# Abschusses (derselbe Fehler wie beim Abzeichen oben).
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "Musikvideo: Ich bin die Beste (gern geschehen)"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	pressed.connect(func() -> void: OS.shell_open(URL))
	mouse_entered.connect(func() -> void: _drueber = true; queue_redraw())
	mouse_exited.connect(func() -> void: _drueber = false; queue_redraw())


func _draw() -> void:
	var rot := ROT_HELL if _drueber else ROT
	var f := ThemeDB.fallback_font
	# Kasten im Stil der Chat-Spalte
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.028, 0.012, 0.050, 0.94), true)
	draw_rect(r, RAHMEN if not _drueber else Color(1.0, 0.45, 1.0, 0.95), false, 2.0)

	# Ueberschrift
	draw_string(f, Vector2(8, 16), "MUSIKVIDEO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(0.35, 0.95, 0.25))

	# Symbol: abgerundetes Rechteck mit Dreieck
	var x := 8.0
	var y := 24.0
	var w := 30.0
	var h := 21.0
	draw_rect(Rect2(x, y + 1, w, h), rot, true)
	draw_rect(Rect2(x - 2.0, y + 4, w + 4.0, h - 7.0), rot, true)
	draw_colored_polygon(PackedVector2Array([
			Vector2(x + 12, y + 5.5), Vector2(x + 12, y + 17.5),
			Vector2(x + 22, y + 11.5)]), Color(1, 1, 1))

	# Titel neben dem Symbol, zweizeilig
	var hell := Color(1, 1, 1) if not _drueber else Color(1.0, 0.9, 0.9)
	draw_string(f, Vector2(x + w + 6, y + 12), "Ich bin", HORIZONTAL_ALIGNMENT_LEFT,
			-1, 11, hell)
	draw_string(f, Vector2(x + w + 6, y + 24), "die Beste", HORIZONTAL_ALIGNMENT_LEFT,
			-1, 11, hell)

	# Fusszeile
	draw_string(f, Vector2(8, size.y - 8), "youtu.be ansehen",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.65, 0.8))
