class_name YoutubeBadge
extends Button
## Anklickbares YouTube-Abzeichen in der Kopfleiste: Icon, "LIVE" und ein
## pulsierender Punkt.  Ein Klick oeffnet den Kanal im Browser.
##
## Das Icon ist gezeichnet, keine Bilddatei - so bleibt das Projekt bei seinem
## Grundsatz, ohne fremde Grafiken auszukommen, und es gibt keine Frage nach
## Markenrechten an einer mitgelieferten Datei.

## Dasselbe Ziel wie der Kasten unten in der Chat-Spalte: das Musikvideo der
## Carry Queen.  Beide Knoepfe fuehren an dieselbe Stelle, damit niemand auf
## einem toten Kanal landet - deshalb steht die Adresse in YoutubeBox und
## wird hier nur uebernommen.
const URL := YoutubeBox.URL
const ROT := Color(0.95, 0.15, 0.15)
const ROT_HELL := Color(1.0, 0.35, 0.3)

var _puls := 0.0
var _drueber := false


func _init() -> void:
	custom_minimum_size = Vector2(74, 18)
	size = Vector2(74, 18)
	flat = true
	# Nicht fokussierbar: sonst faengt die Leertaste den Knopf statt den
	# Abschuss.
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "Musikvideo: Ich bin die Beste (gern geschehen)"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	pressed.connect(func() -> void: OS.shell_open(URL))
	mouse_entered.connect(func() -> void: _drueber = true)
	mouse_exited.connect(func() -> void: _drueber = false)


func _process(delta: float) -> void:
	_puls += delta * 3.2
	queue_redraw()


func _draw() -> void:
	var rot := ROT_HELL if _drueber else ROT
	# Icon: abgerundetes Rechteck mit Dreieck, wie das bekannte Symbol
	var w := 24.0
	var h := 17.0
	draw_rect(Rect2(0, 1, w, h), rot, true)
	draw_rect(Rect2(-1.5, 4, w + 3.0, h - 6.0), rot, true)
	draw_colored_polygon(PackedVector2Array([
			Vector2(9.5, 4.5), Vector2(9.5, 14.5), Vector2(17.5, 9.5)]),
			Color(1, 1, 1))
	# Schrift daneben
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(30, 14), "LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(1, 1, 1) if not _drueber else Color(1.0, 0.9, 0.9))
	# Pulsierender Punkt wie bei einer laufenden Uebertragung
	draw_circle(Vector2(66, 9.5), 3.0 + 0.6 * sin(_puls),
			Color(rot.r, rot.g, rot.b, 0.6 + 0.4 * sin(_puls)))
