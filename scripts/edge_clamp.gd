class_name EdgeClamp
extends Node2D
## Einzeln gesetzte Klemmschelle - gleiche Optik wie die Schellen des
## automatischen Randaufbaus, aber frei platzierbar und ueber allem
## gezeichnet, damit sie nicht hinter Banden oder Eckplatten verschwindet.

const PLATE_LIT := Color(0.46, 0.51, 0.59)
const SCREW_RING := Color(0.44, 0.48, 0.55)
const SCREW_HOLE := Color(0.05, 0.05, 0.07)

var band_w := 26.0
var _dir := Vector2.RIGHT
var _nrm := Vector2.DOWN


## `dir` ist die Laufrichtung der Bande, `side` wie bei EdgeStructure
## (-1 = Band liegt entgegen der Normalen, also innen am Bogen).
func _init(pos: Vector2, dir: Vector2, side: float, width: float = 26.0) -> void:
	position = pos
	_dir = dir.normalized()
	_nrm = _dir.orthogonal() * side
	band_w = width
	z_index = 8


func _draw() -> void:
	var half := 7.0
	var a := -_dir * half
	var b := _dir * half
	draw_colored_polygon(PackedVector2Array([
		a + _nrm * 2.0, b + _nrm * 2.0,
		b + _nrm * (band_w - 2.0), a + _nrm * (band_w - 2.0)]),
		PLATE_LIT.darkened(0.42))
	draw_polyline(PackedVector2Array([
		a + _nrm * 2.0, b + _nrm * 2.0, b + _nrm * (band_w - 2.0),
		a + _nrm * (band_w - 2.0), a + _nrm * 2.0]), PLATE_LIT, 1.3, true)
	_screw(_nrm * 6.0)
	_screw(_nrm * (band_w - 6.0))


func _screw(at: Vector2) -> void:
	draw_circle(at + Vector2(1, 1), 3.8, Color(0, 0, 0, 0.55))
	draw_circle(at, 3.4, SCREW_RING)
	draw_circle(at, 2.1, SCREW_HOLE)
