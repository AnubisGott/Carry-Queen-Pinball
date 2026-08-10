class_name CornerPlate
extends Node2D
## Eckstruktur nach dem Vorbild der Flipper03-Spielfeldtextur: Metallplatte mit
## abgeschraegter Innenkante, Schrauben, Wabenfeld, Neonrohr und ein paar
## Leiterbahn-Strichen.  Rein dekorativ, keine Kollision.
##
## `dir` zeigt von der Ecke ins Feld, also (1,1) fuer oben links,
## (-1,-1) fuer unten rechts.

const PLATE := Color(0.135, 0.150, 0.180)
const PLATE_LIT := Color(0.48, 0.53, 0.61)
const PLATE_EDGE := Color(0.26, 0.30, 0.36)
const SCREW_RING := Color(0.44, 0.48, 0.55)
const SCREW_HOLE := Color(0.05, 0.05, 0.07)

var dir := Vector2(1, 1)
var plate_size := Vector2(120, 150)
var accent := Color(1.7, 0.28, 1.0)
## Wabenfeld kann eine eigene Farbe haben - ohne Angabe die des Akzents.
var hex_col := Color(0, 0, 0, 0)
var cut := 36.0


func _init(pos: Vector2, d: Vector2, size: Vector2, col: Color,
		hexes: Color = Color(0, 0, 0, 0)) -> void:
	position = pos
	dir = d
	plate_size = size
	accent = col
	hex_col = hexes
	z_index = -7


## Umriss der Platte: Rechteck mit einer schraeg abgeschnittenen Innenecke.
func _outline() -> PackedVector2Array:
	var w := plate_size.x * dir.x
	var h := plate_size.y * dir.y
	var cx := cut * dir.x
	var cy := cut * dir.y
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(w, 0),
		Vector2(w, h - cy * 2.2),
		Vector2(w - cx, h - cy * 1.2),
		Vector2(w - cx * 1.9, h),
		Vector2(0, h),
	])


func _draw() -> void:
	var pts := _outline()

	# Platte mit Schlagschatten
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(3, 4))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.55))
	draw_colored_polygon(pts, PLATE)

	# Fase: helle Aussenkanten, dunkle Innenkanten
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, PLATE_EDGE, 2.0, true)
	draw_polyline(PackedVector2Array([pts[5], pts[0], pts[1]]), PLATE_LIT, 2.4, true)

	# Neonrohr entlang der abgeschraegten Innenkante
	var pipe := PackedVector2Array([pts[2], pts[3], pts[4]])
	draw_polyline(pipe, Color(accent.r, accent.g, accent.b, 0.16), 9.0, true)
	draw_polyline(pipe, Color(0.08, 0.13, 0.16), 5.0, true)
	draw_polyline(pipe, accent, 2.0, true)

	_draw_hex_patch(Vector2(plate_size.x * 0.30 * dir.x, plate_size.y * 0.30 * dir.y))
	_draw_traces(pts)

	# Schrauben in den Aussenecken
	for f in [Vector2(0.13, 0.10), Vector2(0.84, 0.10), Vector2(0.13, 0.80)]:
		_draw_screw(Vector2(plate_size.x * f.x * dir.x, plate_size.y * f.y * dir.y))


func _draw_screw(at: Vector2) -> void:
	draw_circle(at + Vector2(1, 1), 5.0, Color(0, 0, 0, 0.6))
	draw_circle(at, 4.6, SCREW_RING)
	draw_circle(at, 3.0, SCREW_HOLE)
	draw_line(at + Vector2(-2.4, -2.4), at + Vector2(2.4, 2.4), SCREW_RING, 1.2, true)


## Kleines Wabenfeld, wie die Sechseckflaechen der Vorlage.
func _draw_hex_patch(at: Vector2) -> void:
	var c0 := accent if hex_col.a <= 0.0 else hex_col
	var r := 9.0
	for row in 3:
		for colu in 2:
			var c := at + Vector2(
				(colu * 1.74 + (row % 2) * 0.87) * r * dir.x,
				row * 1.5 * r * dir.y)
			var hex := PackedVector2Array()
			for i in 7:
				var a := deg_to_rad(30.0 + i * 60.0)
				hex.append(c + Vector2(cos(a), sin(a)) * r)
			draw_polyline(hex, Color(c0.r, c0.g, c0.b, 0.55), 1.4, true)


## Feine Leiterbahnen von der Aussenkante zur Fase.
func _draw_traces(pts: PackedVector2Array) -> void:
	for i in 4:
		var t := 0.24 + i * 0.17
		var a := pts[0].lerp(pts[5], t)
		var b := a + Vector2(plate_size.x * 0.42 * dir.x, 0)
		var c := b + Vector2(plate_size.x * 0.14 * dir.x, plate_size.y * 0.07 * dir.y)
		draw_polyline(PackedVector2Array([a, b, c]),
				Color(accent.r, accent.g, accent.b, 0.16), 1.2, true)
		draw_circle(c, 2.0, Color(accent.r, accent.g, accent.b, 0.35))
