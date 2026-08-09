class_name Table
extends RefCounted
## Baut die komplette Tisch-Geometrie im Neon-Look auf (alles aus Code, keine Assets).

const LEFT := 20.0
const RIGHT := 520.0
const DIVIDER := 470.0
const ARCH_C := Vector2(270, 330)
const ARCH_R := 250.0

const NEON_PINK := Color(1.7, 0.28, 1.0)
const NEON_GREEN := Color(0.35, 1.8, 0.25)
const NEON_CYAN := Color(0.15, 1.6, 1.8)
const NEON_GOLD := Color(1.9, 1.3, 0.2)
const NEON_VIOLET := Color(1.1, 0.4, 1.9)


static func build(parent: Node2D) -> Dictionary:
	_background(parent)
	# Aussenwaende
	_wall(parent, [Vector2(LEFT, 960), Vector2(LEFT, 330)], NEON_PINK)
	_wall(parent, _arch_points(), NEON_PINK)
	_wall(parent, [Vector2(RIGHT, 330), Vector2(RIGHT, 960)], NEON_PINK)
	# Abschussbahn (rechts) mit Abweiser oben
	_wall(parent, [Vector2(DIVIDER, 960), Vector2(DIVIDER, 300)], NEON_VIOLET)
	_wall(parent, [Vector2(DIVIDER, 305), Vector2(445, 335)], NEON_VIOLET)
	_wall(parent, [Vector2(DIVIDER, 935), Vector2(RIGHT, 935)], NEON_VIOLET)
	# Linke Orbit-Wand: Spinner-Bahn mit breitem Eingang und Fang-Trichter,
	# am Ende faengt eine Mulde (Scoop) die Kugel und wirft sie zur Mitte zurueck.
	# Wand endet oberhalb der hinteren Flipper-Ecke, damit die Kugel auf die
	# Hebel-Oberseite rollt statt hinter dem Hebel zu verklemmen
	_wall(parent, [Vector2(85, 285), Vector2(85, 540), Vector2(154, 830)], NEON_CYAN)
	_wall(parent, [Vector2(160, 150), Vector2(82, 232)], NEON_CYAN)
	# Rechte Outlane ("KEIN PLAN")
	_wall(parent, [Vector2(DIVIDER, 690), Vector2(415, 775)], NEON_GREEN)
	_wall(parent, [Vector2(410, 700), Vector2(336, 830)], NEON_GREEN)
	# Thron-Pfosten
	_wall(parent, [Vector2(250, 82), Vector2(250, 160)], NEON_GOLD)
	_wall(parent, [Vector2(290, 82), Vector2(290, 160)], NEON_GOLD)

	var refs := {}

	var fl := Flipper.new(true, Vector2(160, 850))
	var fr := Flipper.new(false, Vector2(330, 850))
	parent.add_child(fl)
	parent.add_child(fr)
	refs["flipper_l"] = fl
	refs["flipper_r"] = fr

	# Schlanke Viereck-Slingshots mit ~35 px Laufrinne dahinter: Die Kugel kann
	# hinter dem Slingshot an der Inlane-Wand entlang auf den Flipperhebel rollen.
	parent.add_child(Slingshot.new([Vector2(157, 692), Vector2(206, 777), Vector2(184, 787), Vector2(167, 735)], Vector2(85, -49)))
	parent.add_child(Slingshot.new([Vector2(362, 691), Vector2(297, 771), Vector2(315, 783), Vector2(346, 731)], Vector2(-80, -65)))

	for b in [["W", Vector2(270, 300)], ["A", Vector2(175, 350)], ["D", Vector2(365, 350)], ["S", Vector2(270, 415)]]:
		parent.add_child(Bumper.new(b[1], b[0]))

	var drops := []
	var letters := ["D", "A", "M", "A", "G", "E"]
	for i in 6:
		var d := DropTarget.new(Vector2(150 + i * 38, 560), letters[i])
		parent.add_child(d)
		drops.append(d)
	refs["drops"] = drops

	var standups := []
	var ich := ["I", "C", "H"]
	for i in 3:
		var s := Standup.new(Vector2(93, 300 + i * 65), ich[i])
		parent.add_child(s)
		standups.append(s)
	refs["standups"] = standups

	var sp := Spinner.new(Vector2(52, 430))
	parent.add_child(sp)
	refs["spinner"] = sp

	var throne := Throne.new(Vector2(270, 132))
	parent.add_child(throne)
	refs["throne"] = throne

	parent.add_child(LaneGate.new(Vector2(495, 276)))
	parent.add_child(Scoop.new(Vector2(57, 568)))

	_deco(parent, "KEIN HEAL", Vector2(38, 240), Color(0.35, 1.8, 0.25, 0.4), 11, 90.0)
	_deco(parent, "KEIN PLAN", Vector2(412, 698), Color(0.35, 1.8, 0.25, 0.5), 11, 62.0)
	_deco(parent, "KEIN SKILL.", Vector2(214, 934), Color(1.0, 0.3, 0.6, 0.55), 12, 0.0)
	_deco(parent, "CARRY QUEEN PINBALL", Vector2(146, 620), Color(1.0, 0.24, 0.62, 0.35), 18, 0.0)
	_deco(parent, "gern geschehen.", Vector2(206, 648), Color(0.2, 0.85, 0.95, 0.3), 11, 0.0)
	_deco(parent, "SPACE HALTEN", Vector2(505, 740), Color(1.1, 0.4, 1.9, 0.5), 10, 90.0)

	return refs


static func _arch_points() -> Array:
	var pts := []
	for i in 27:
		var a := PI + PI * i / 26.0
		pts.append(ARCH_C + Vector2(cos(a), sin(a)) * ARCH_R)
	return pts


static func _wall(parent: Node2D, pts: Array, color: Color) -> void:
	var body := StaticBody2D.new()
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.28
	pm.friction = 0.1
	body.physics_material_override = pm
	for i in pts.size() - 1:
		var cs := CollisionShape2D.new()
		var seg := SegmentShape2D.new()
		seg.a = pts[i]
		seg.b = pts[i + 1]
		cs.shape = seg
		body.add_child(cs)
	parent.add_child(body)
	var packed := PackedVector2Array(pts)
	var under := Line2D.new()
	under.points = packed
	under.width = 11.0
	under.default_color = Color(color.r, color.g, color.b, 0.16)
	under.joint_mode = Line2D.LINE_JOINT_ROUND
	under.begin_cap_mode = Line2D.LINE_CAP_ROUND
	under.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(under)
	var line := Line2D.new()
	line.points = packed
	line.width = 4.0
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)


static func _background(parent: Node2D) -> void:
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2(0, 0), Vector2(540, 0), Vector2(540, 960), Vector2(0, 960)])
	bg.color = Color(0.035, 0.018, 0.055)
	bg.z_index = -10
	parent.add_child(bg)
	for i in 12:
		var scan := Line2D.new()
		scan.points = PackedVector2Array([Vector2(0, 80 * i), Vector2(540, 80 * i)])
		scan.width = 1.0
		scan.default_color = Color(0.15, 1.6, 1.8, 0.035)
		scan.z_index = -9
		parent.add_child(scan)


static func _deco(parent: Node2D, text: String, pos: Vector2, col: Color, size: int, rot: float) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.rotation_degrees = rot
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.z_index = -5
	parent.add_child(l)
