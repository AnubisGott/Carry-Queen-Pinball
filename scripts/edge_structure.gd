class_name EdgeStructure
extends Node2D
## Randaufbau entlang einer Bande, nachgebaut aus der Spielfeldtextur von
## Flipper03: ein Blechband mit Fase, darauf Klemmschellen mit Schrauben, ein
## parallel laufendes Neonrohr, Wabenfelder, Leiterbahnen und Schraffuren.
##
## Das Band ist reine Spielfeldgrafik - die Kugel rollt darueber, genau wie
## ueber die bedruckte Platte eines echten Tisches.
##
## `side` gibt an, auf welcher Seite der Bande das Band liegt: +1 bedeutet in
## Richtung der Normalen (Laufrichtung um 90 Grad gedreht), -1 entgegengesetzt.

const PLATE := Color(0.125, 0.140, 0.168)
const PLATE_LIT := Color(0.46, 0.51, 0.59)
const PLATE_DARK := Color(0.055, 0.065, 0.080)
const SCREW_RING := Color(0.44, 0.48, 0.55)
const SCREW_HOLE := Color(0.05, 0.05, 0.07)
const PIPE_CORE := Color(0.08, 0.13, 0.16)

var path := PackedVector2Array()
var side := 1.0
var band_w := 26.0
var accent := Color(1.7, 0.28, 1.0)
var clamp_step := 96.0
var start_offset := 40.0
## Bogenlaengen, an denen kein Beschlag gesetzt wird - dort sitzen einzeln
## platzierte Schellen (EdgeClamp).
var skip_at: Array = []

var _len := PackedFloat32Array()


func _init(pts: Array, s: float, col: Color, width: float = 26.0, offset: float = 40.0) -> void:
	path = PackedVector2Array(pts)
	side = s
	accent = col
	band_w = width
	start_offset = offset
	z_index = -6


func _ready() -> void:
	_len.append(0.0)
	for i in range(1, path.size()):
		_len.append(_len[i - 1] + path[i - 1].distance_to(path[i]))


func _total() -> float:
	return _len[_len.size() - 1] if _len.size() > 0 else 0.0


## Richtung an Stuetzpunkt i (mit Nachbarn geglaettet).
func _dir_at(i: int) -> Vector2:
	if path.size() < 2:
		return Vector2.RIGHT
	if i == 0:
		return (path[1] - path[0]).normalized()
	if i == path.size() - 1:
		return (path[i] - path[i - 1]).normalized()
	return (path[i + 1] - path[i - 1]).normalized()


func _off_at(i: int) -> Vector2:
	return _dir_at(i).orthogonal() * side


## Position und Laufrichtung bei Bogenlaenge d.
func _sample(d: float) -> Array:
	var total := _total()
	d = clampf(d, 0.0, total)
	for i in range(1, _len.size()):
		if d <= _len[i]:
			var seg := maxf(0.001, _len[i] - _len[i - 1])
			var t := (d - _len[i - 1]) / seg
			return [path[i - 1].lerp(path[i], t), (path[i] - path[i - 1]).normalized()]
	return [path[path.size() - 1], _dir_at(path.size() - 1)]


func _draw() -> void:
	if path.size() < 2:
		return
	_draw_band()
	_draw_pipe()
	_draw_fittings()


## Blechband als Folge von Vierecken - je Segment eins, damit auch enge Boegen
## sauber fuellen.
func _draw_band() -> void:
	# Je Segment ein echtes Rechteck aus der Normalen *dieses* Segments.  Mit
	# gemittelten Normalen wuerde das Viereck an einem rechten Winkel zur
	# Schleife und die Triangulierung scheitert.
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		if a.distance_to(b) < 0.01:
			continue
		var n := (b - a).normalized().orthogonal() * side * band_w
		draw_colored_polygon(PackedVector2Array([a, b, b + n, a + n]), PLATE)
		draw_colored_polygon(PackedVector2Array([
			a + n * 0.62, b + n * 0.62, b + n, a + n]), PLATE_DARK)

	# Knicke auffuellen: Dreieck zwischen den beiden Segmentnormalen
	for i in range(1, path.size() - 1):
		var p := path[i]
		var n0 := (p - path[i - 1]).normalized().orthogonal() * side * band_w
		var n1 := (path[i + 1] - p).normalized().orthogonal() * side * band_w
		if n0.distance_to(n1) < 0.5:
			continue
		draw_colored_polygon(PackedVector2Array([p, p + n0, p + n1]), PLATE)

	# Fase: helle Kante an der Bande, dunkle Kante innen
	var inner := PackedVector2Array()
	for i in path.size():
		inner.append(path[i] + _off_at(i) * band_w)
	draw_polyline(path, PLATE_LIT, 2.0, true)
	draw_polyline(inner, Color(0.02, 0.03, 0.04, 0.9), 2.0, true)


## Neonrohr laeuft parallel im Band mit - Schein, dunkler Kern, helle Kante.
func _draw_pipe() -> void:
	var line := PackedVector2Array()
	for i in path.size():
		line.append(path[i] + _off_at(i) * (band_w * 0.42))
	draw_polyline(line, Color(accent.r, accent.g, accent.b, 0.14), 9.0, true)
	draw_polyline(line, PIPE_CORE, 5.0, true)
	draw_polyline(line, accent, 1.8, true)


## Klemmschellen, Wabenfelder, Leiterbahnen und Schraffuren im Wechsel.
func _draw_fittings() -> void:
	var total := _total()
	var d := start_offset
	var n := 0
	while d < total - 12.0:
		if _skipped(d):
			d += clamp_step
			n += 1
			continue
		var s := _sample(d)
		var pos: Vector2 = s[0]
		var dir: Vector2 = s[1]
		var nrm := dir.orthogonal() * side
		match n % 4:
			0, 2:
				_draw_clamp(pos, dir, nrm)
			1:
				_draw_hatch(pos, dir, nrm)
			3:
				_draw_hex_pair(pos, dir, nrm)
		if n % 2 == 1:
			_draw_trace(pos, dir, nrm)
		d += clamp_step
		n += 1


func _skipped(d: float) -> bool:
	for s in skip_at:
		if absf(d - float(s)) < 12.0:
			return true
	return false


## Schelle quer ueber das Band, mit zwei Schrauben - haelt das Rohr.
func _draw_clamp(pos: Vector2, dir: Vector2, nrm: Vector2) -> void:
	var half := 7.0
	var a := pos - dir * half
	var b := pos + dir * half
	draw_colored_polygon(PackedVector2Array([
		a + nrm * 2.0, b + nrm * 2.0,
		b + nrm * (band_w - 2.0), a + nrm * (band_w - 2.0)]), PLATE_LIT.darkened(0.42))
	draw_polyline(PackedVector2Array([
		a + nrm * 2.0, b + nrm * 2.0, b + nrm * (band_w - 2.0),
		a + nrm * (band_w - 2.0), a + nrm * 2.0]), PLATE_LIT, 1.3, true)
	_draw_screw(pos + nrm * 6.0)
	_draw_screw(pos + nrm * (band_w - 6.0))


func _draw_screw(at: Vector2) -> void:
	draw_circle(at + Vector2(1, 1), 3.8, Color(0, 0, 0, 0.55))
	draw_circle(at, 3.4, SCREW_RING)
	draw_circle(at, 2.1, SCREW_HOLE)


## Diagonale Schraffur wie die gestrichelten Felder der Vorlage.
func _draw_hatch(pos: Vector2, dir: Vector2, nrm: Vector2) -> void:
	for i in 7:
		var o := pos + dir * (i * 5.0 - 15.0)
		draw_line(o + nrm * 4.0, o + dir * 7.0 + nrm * (band_w - 4.0),
				Color(accent.r, accent.g, accent.b, 0.30), 1.3, true)


## Zwei kleine Waben nebeneinander auf dem Band.
func _draw_hex_pair(pos: Vector2, dir: Vector2, nrm: Vector2) -> void:
	var r := band_w * 0.30
	for k in 2:
		var c := pos + dir * (k * r * 1.8 - r * 0.9) + nrm * (band_w * 0.5)
		var hex := PackedVector2Array()
		for i in 7:
			var a := deg_to_rad(30.0 + i * 60.0)
			hex.append(c + Vector2(cos(a), sin(a)) * r)
		draw_polyline(hex, Color(accent.r, accent.g, accent.b, 0.34), 1.3, true)


## Feine Leiterbahn, die vom Band ins Feld abzweigt.
func _draw_trace(pos: Vector2, dir: Vector2, nrm: Vector2) -> void:
	var a := pos + nrm * (band_w - 3.0)
	var b := a + nrm * 14.0
	var c := b + dir * 18.0
	draw_polyline(PackedVector2Array([a, b, c]),
			Color(accent.r, accent.g, accent.b, 0.20), 1.2, true)
	draw_circle(c, 2.2, Color(accent.r, accent.g, accent.b, 0.42))
