class_name SegmentDisplay
extends Node2D
## Ziffernanzeige aus Segmenten, wie sie Flipper der Achtziger hatten: sieben
## Balken je Stelle plus Punkt als achtes Segment - der dient hier als
## Tausenderpunkt.
##
## Nicht leuchtende Segmente bleiben schwach sichtbar.  Erst dadurch sieht es
## nach einem echten Display aus und nicht nach gezeichneten Zahlen: man ahnt
## immer die volle Acht dahinter.

## Welche Segmente je Ziffer leuchten.  Reihenfolge: a oben, b rechts oben,
## c rechts unten, d unten, e links unten, f links oben, g Mitte.
const ZIFFERN := {
	"0": [true, true, true, true, true, true, false],
	"1": [false, true, true, false, false, false, false],
	"2": [true, true, false, true, true, false, true],
	"3": [true, true, true, true, false, false, true],
	"4": [false, true, true, false, false, true, true],
	"5": [true, false, true, true, false, true, true],
	"6": [true, false, true, true, true, true, true],
	"7": [true, true, true, false, false, false, false],
	"8": [true, true, true, true, true, true, true],
	"9": [true, true, true, true, false, true, true],
	" ": [false, false, false, false, false, false, false],
}

var text := "0": set = _setze_text
## Breite und Hoehe einer Stelle, Staerke der Balken
var zeichen := Vector2(19.0, 30.0)
var staerke := 4.0
## Abstand zwischen zwei Stellen und Breite eines Tausenderpunkts
var luecke := 4.0
var punkt_breite := 7.0
## Weiss statt der roten Plasma-Roehren: passt besser zum Neon des Tisches.
## Genau 1.0 und nicht darueber, damit die Anzeige nicht ueberstrahlt.
var an := Color(1.0, 1.0, 1.0)
var aus := Color(0.30, 0.30, 0.36, 0.5)


func _setze_text(t: String) -> void:
	text = t
	queue_redraw()


## Gesamtbreite der aktuellen Anzeige - damit sie sich zentrieren laesst.
func breite() -> float:
	var b := 0.0
	for c in text:
		b += (punkt_breite if c == "." else zeichen.x + luecke)
	return b


func _draw() -> void:
	var x := -breite() * 0.5
	for c in text:
		if c == ".":
			draw_circle(Vector2(x + punkt_breite * 0.5, zeichen.y * 0.5), staerke * 0.55, an)
			x += punkt_breite
			continue
		_zeichne_ziffer(Vector2(x, 0.0), str(c))
		x += zeichen.x + luecke


func _zeichne_ziffer(pos: Vector2, c: String) -> void:
	var muster: Array = ZIFFERN.get(c, ZIFFERN[" "])
	var w := zeichen.x
	var h := zeichen.y
	var m := h * 0.5
	# a, d, g liegen waagerecht, b, c, e, f senkrecht
	var lage := [
		[Vector2(0, 0), w, true],       # a
		[Vector2(w, 0), m, false],      # b
		[Vector2(w, m), m, false],      # c
		[Vector2(0, h), w, true],       # d
		[Vector2(0, m), m, false],      # e
		[Vector2(0, 0), m, false],      # f
		[Vector2(0, m), w, true],       # g
	]
	for i in 7:
		var start: Vector2 = pos + lage[i][0]
		var laenge: float = lage[i][1]
		var waagerecht: bool = lage[i][2]
		draw_colored_polygon(_balken(start, laenge, waagerecht),
				an if muster[i] else aus)


## Ein Segment als Sechseck mit angeschraegten Enden - so sahen die
## Plasma-Anzeigen aus.
func _balken(von: Vector2, laenge: float, waagerecht: bool) -> PackedVector2Array:
	var d := staerke * 0.5
	var e := staerke * 0.6
	if waagerecht:
		return PackedVector2Array([
			von + Vector2(e, -d), von + Vector2(laenge - e, -d),
			von + Vector2(laenge, 0), von + Vector2(laenge - e, d),
			von + Vector2(e, d), von + Vector2(0, 0)])
	return PackedVector2Array([
		von + Vector2(-d, e), von + Vector2(-d, laenge - e),
		von + Vector2(0, laenge), von + Vector2(d, laenge - e),
		von + Vector2(d, e), von + Vector2(0, 0)])
