class_name CircuitRun
extends Node2D
## Rechtwinkliges Leiterbahn-Buendel, wie es die Vorlagentextur an den Raendern
## zeigt: mehrere parallele Straenge in Treppenform, die sich unterwegs
## aufteilen und wieder zusammenlaufen, mit kleinen Knotenplatten an den Ecken.
##
## Reine Spielfeldgrafik - die Kugel rollt darueber.  Die eigentliche Bande
## bleibt davon unberuehrt.

const PLATE := Color(0.135, 0.150, 0.180)
const PLATE_EDGE := Color(0.42, 0.46, 0.54)
const CORE_DARK := Color(0.08, 0.13, 0.16)

var a := Vector2.ZERO
var b := Vector2.ONE
var steps := 4
var accent := Color(1.7, 0.28, 1.0)

## Je Strang: [Versatz quer, Startanteil, Endanteil, Strichstaerke]
var strands := []


func _init(from: Vector2, to: Vector2, step_count: int, col: Color) -> void:
	a = from
	b = to
	steps = step_count
	accent = col
	z_index = -6
	# Hauptstrang durchgehend, zwei duennere Straenge zweigen ab und
	# laufen wieder auf - das "Aufteilen" der Vorlage.
	strands = [
		[0.0, 0.0, 1.0, 3.6],
		[14.0, 0.18, 0.86, 2.4],
		[27.0, 0.38, 0.66, 1.8],
		[-14.0, 0.10, 0.52, 2.0],
	]


## Treppe von `from` nach `to`: abwechselnd senkrecht und waagerecht.
func _staircase(from: Vector2, to: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array([from])
	var cur := from
	for i in n:
		var t := float(i + 1) / float(n)
		var target := from.lerp(to, t)
		cur = Vector2(cur.x, target.y)
		pts.append(cur)
		cur = Vector2(target.x, cur.y)
		pts.append(cur)
	return pts


## Versetzte Variante: quer zur Gesamtrichtung verschoben, gekuerzt.
func _strand(offset: float, t0: float, t1: float) -> PackedVector2Array:
	var dir := (b - a).normalized()
	var nrm := dir.orthogonal()
	var s := a.lerp(b, t0) + nrm * offset
	var e := a.lerp(b, t1) + nrm * offset
	return _staircase(s, e, maxi(2, int(round(steps * (t1 - t0)))))


func _draw() -> void:
	for spec in strands:
		var pts := _strand(spec[0], spec[1], spec[2])
		var w: float = spec[3]
		_draw_strand(pts, w)
		_draw_nodes(pts, w)


## Vier Schichten wie die Rails im Referenzprojekt.
func _draw_strand(pts: PackedVector2Array, w: float) -> void:
	var shifted := PackedVector2Array()
	for p in pts:
		shifted.append(p + Vector2(2, 3))
	draw_polyline(shifted, Color(0, 0, 0, 0.6), w + 3.0, true)
	draw_polyline(pts, Color(accent.r, accent.g, accent.b, 0.13), w * 3.6, true)
	draw_polyline(pts, CORE_DARK, w * 1.9, true)
	draw_polyline(pts, accent, w, true)


## Knotenplatten an jeder zweiten Ecke, dazu ein Abzweig-Stummel.
func _draw_nodes(pts: PackedVector2Array, w: float) -> void:
	for i in range(1, pts.size() - 1, 2):
		var p: Vector2 = pts[i]
		var s := 4.0 + w
		draw_rect(Rect2(p.x - s, p.y - s, s * 2.0, s * 2.0), PLATE)
		draw_rect(Rect2(p.x - s, p.y - s, s * 2.0, s * 2.0), PLATE_EDGE, false, 1.2)
		draw_rect(Rect2(p.x - 2.0, p.y - 2.0, 4.0, 4.0),
				Color(accent.r, accent.g, accent.b, 0.9))
		if i % 4 == 1:
			var stub := Vector2(p.x, p.y - 18.0)
			draw_line(p, stub, Color(accent.r, accent.g, accent.b, 0.5), 1.4, true)
			draw_circle(stub, 2.4, Color(accent.r, accent.g, accent.b, 0.75))
