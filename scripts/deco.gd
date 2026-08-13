class_name TableDeco
extends Node2D
## Dekorative Elemente im Stil der Vorlage, gezeichnet in unserem Neon-Schema:
## spiral (rotierende Galaxie), comet, saturn, chevron, pad, rays, bolt, arrow.

## Bild auf der drehenden Scheibe.  Fehlt die Datei, bleibt die Scheibe so,
## wie sie war.
const QUEEN_BILD := "res://assets/face02.jpg"

var kind := "comet"
var deco_size := 1.0
var col := Color(1.22, 0.9, 0.2)
var _blink := false
var _blink_t := 0.0
var _queen: Texture2D


## Blinken ein-/ausschalten (z.B. Lane-Pfeile bei abschussbereitem Ball)
func set_blink(on: bool) -> void:
	if _blink == on:
		return
	_blink = on
	_blink_t = 0.0
	if not on:
		modulate.a = 1.0


func _init(k: String, pos: Vector2, c: Color = Color(1.22, 0.9, 0.2), s: float = 1.0, rot_deg: float = 0.0) -> void:
	kind = k
	position = pos
	col = c
	deco_size = s
	rotation_degrees = rot_deg
	z_index = -4


func _ready() -> void:
	if kind == "spiral" and ResourceLoader.exists(QUEEN_BILD):
		_queen = load(QUEEN_BILD)
		queue_redraw()


func _process(delta: float) -> void:
	if kind == "spiral":
		rotation += delta * 0.35
	if _blink:
		_blink_t += delta
		modulate.a = 0.2 + 0.8 * (0.5 + 0.5 * sin(_blink_t * 9.0))


func _draw() -> void:
	match kind:
		"spiral":
			draw_circle(Vector2.ZERO, 74.0 * deco_size, Color(0.10, 0.04, 0.10, 0.9))
			var arm_cols := [Color(1.5, 0.3, 0.75, 0.55), Color(1.15, 0.8, 0.2, 0.5), Color(0.2, 1.4, 1.6, 0.45)]
			for arm in 3:
				var pts := PackedVector2Array()
				for i in 30:
					var rr := 8.0 + i * 2.2
					var th := arm * TAU / 3.0 + rr * 0.055
					pts.append(Vector2(cos(th), sin(th)) * rr * deco_size)
				draw_polyline(pts, arm_cols[arm], 3.0)
			# Bild der Queen auf der Scheibe: rund ausgeschnitten und halb
			# durchsichtig.  Der Ausschnitt entsteht ueber ein Vieleck mit
			# Bildkoordinaten - das Bild selbst bleibt unveraendert.  Weil es
			# im drehenden Knoten gezeichnet wird, dreht es sich mit.
			if _queen != null:
				var gr := Vector2(_queen.get_size())
				var kante := minf(gr.x, gr.y)
				var r := 68.0 * deco_size
				var ecken := PackedVector2Array()
				var bild_uv := PackedVector2Array()
				for i in 48:
					var w := TAU * float(i) / 48.0
					var d := Vector2(cos(w), sin(w))
					ecken.append(d * r)
					bild_uv.append((gr * 0.5 + d * kante * 0.5) / gr)
				draw_colored_polygon(ecken, Color(1, 1, 1, 0.5), bild_uv, _queen)
			draw_arc(Vector2.ZERO, 74.0 * deco_size, 0, TAU, 48, Color(1.15, 0.8, 0.2, 0.5), 2.0)
			draw_circle(Vector2.ZERO, 10.0 * deco_size, Color(1.15, 0.8, 0.2, 0.8))
		"comet":
			draw_circle(Vector2.ZERO, 5.0 * deco_size, col)
			for i in 3:
				var off := (i - 1) * 3.0
				draw_line(Vector2(off, 2), Vector2(off * 2.2 + 14, 30.0 * deco_size), Color(col.r, col.g, col.b, 0.35), 2.0)
		"saturn":
			draw_circle(Vector2.ZERO, 8.0 * deco_size, Color(1.5, 1.0, 0.4))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
			draw_arc(Vector2.ZERO, 14.0 * deco_size, 0, TAU, 24, Color(0.2, 1.4, 1.6, 0.8), 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"chevron":
			var c := PackedVector2Array([Vector2(-8, 5) * deco_size, Vector2(0, -5) * deco_size, Vector2(8, 5) * deco_size])
			draw_polyline(c, col, 2.5)
		"pad":
			draw_circle(Vector2.ZERO, 105.0 * deco_size, Color(0.15, 1.6, 1.8, 0.045))
			draw_arc(Vector2.ZERO, 105.0 * deco_size, 0, TAU, 48, Color(0.15, 1.6, 1.8, 0.12), 2.0)
		"rays":
			for i in 7:
				var a := -PI / 2.0 + (i - 3) * 0.16
				draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 130.0 * deco_size, Color(1.5, 0.3, 0.7, 0.07), 3.0)
		"bolt":
			draw_arc(Vector2.ZERO, 16.0 * deco_size, 0, TAU, 24, col, 2.0)
			draw_polyline(PackedVector2Array([Vector2(-3, -9), Vector2(3, -2), Vector2(-1, -2), Vector2(3, 9)]), col, 2.0)
		"spring":
			var coil := PackedVector2Array()
			for i in 7:
				coil.append(Vector2((-8.0 if i % 2 == 0 else 8.0) * deco_size, i * 5.0 * deco_size))
			draw_polyline(coil, col, 2.0)
			draw_line(Vector2(-10 * deco_size, 31 * deco_size), Vector2(10 * deco_size, 31 * deco_size), col, 3.0)
		"star":
			draw_line(Vector2(0, -7 * deco_size), Vector2(0, 7 * deco_size), col, 2.0)
			draw_line(Vector2(-7 * deco_size, 0), Vector2(7 * deco_size, 0), col, 2.0)
			draw_line(Vector2(-3, -3) * deco_size, Vector2(3, 3) * deco_size, Color(col.r, col.g, col.b, 0.5), 1.5)
			draw_line(Vector2(-3, 3) * deco_size, Vector2(3, -3) * deco_size, Color(col.r, col.g, col.b, 0.5), 1.5)
		"arrow":
			var a := PackedVector2Array([
				Vector2(0, -20), Vector2(13, -2), Vector2(6, -2), Vector2(6, 16),
				Vector2(-6, 16), Vector2(-6, -2), Vector2(-13, -2), Vector2(0, -20),
			])
			draw_polyline(a, col, 2.5)
