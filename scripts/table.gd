class_name Table
extends RefCounted
## Tisch-Geometrie nach der Weltraum-Vorlage, im Carry-Queen-Neon-Schema:
## Draht-Hochbahn ueber dem Tisch (2. Ebene), Mulde mit Hoernern in der Mitte,
## Bumper-Pad, I-C-H-Bank links, In-/Outlanes beidseitig, Spiral-Scheibe unten.

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
	_wall(parent, [Vector2(LEFT, 760), Vector2(LEFT, 330)], NEON_PINK)
	_wall(parent, _arch_points(), NEON_PINK)
	_wall(parent, [Vector2(RIGHT, 330), Vector2(RIGHT, 960)], NEON_PINK)
	# Abschussbahn (rechts) mit Abweiser oben
	_wall(parent, [Vector2(DIVIDER, 960), Vector2(DIVIDER, 300)], NEON_VIOLET)
	_wall(parent, [Vector2(DIVIDER, 305), Vector2(445, 335)], NEON_VIOLET)
	_wall(parent, [Vector2(DIVIDER, 935), Vector2(RIGHT, 935)], NEON_VIOLET)
	# Fang-Trichter oben links: leitet Baelle in die Hochbahn-Einfahrt
	_wall(parent, [Vector2(160, 150), Vector2(82, 232)], NEON_CYAN)
	# Linke Seite: Ablenk-Leiste (wie die schraege Bande der Vorlage) + Inlane
	_wall(parent, [Vector2(24, 598), Vector2(92, 508)], NEON_GREEN)
	_wall(parent, [Vector2(95, 690), Vector2(154, 830)], NEON_GREEN)
	# Rechte Inlane ("KEIN PLAN")
	_wall(parent, [Vector2(410, 700), Vector2(336, 830)], NEON_GREEN)
	# Thron-Pfosten
	_wall(parent, [Vector2(250, 82), Vector2(250, 160)], NEON_GOLD)
	_wall(parent, [Vector2(290, 82), Vector2(290, 160)], NEON_GOLD)
	# Hoerner der Mulde (Trichter unter dem S-Bumper)
	_wall(parent, [Vector2(240, 455), Vector2(252, 492)], NEON_GOLD)
	_wall(parent, [Vector2(300, 455), Vector2(288, 492)], NEON_GOLD)
	# Untere Bogen-Banden: sanfte Kurven fuehren aussen herum zur
	# Drain-Oeffnung in der Mitte (Skizze des Nutzers)
	_wall(parent, [Vector2(LEFT, 760), Vector2(25, 820), Vector2(40, 875), Vector2(65, 915), Vector2(100, 940), Vector2(140, 952), Vector2(180, 956), Vector2(210, 956)], NEON_PINK)
	_wall(parent, [Vector2(DIVIDER, 600), Vector2(462, 680), Vector2(445, 750), Vector2(420, 810), Vector2(385, 865), Vector2(340, 910), Vector2(300, 940), Vector2(285, 948)], NEON_PINK)

	var refs := {}

	var fl := Flipper.new(true, Vector2(160, 850))
	var fr := Flipper.new(false, Vector2(330, 850))
	parent.add_child(fl)
	parent.add_child(fr)
	refs["flipper_l"] = fl
	refs["flipper_r"] = fr

	# Schlanke Viereck-Slingshots mit Laufrinne dahinter
	parent.add_child(Slingshot.new([Vector2(127, 676), Vector2(190, 765), Vector2(168, 777), Vector2(139, 722)], Vector2(89, -63)))
	parent.add_child(Slingshot.new([Vector2(362, 691), Vector2(297, 771), Vector2(315, 783), Vector2(346, 731)], Vector2(-80, -65)))

	# WASD-Bumper auf dem Pad, S liegt tiefer und fuettert die Mulde
	for b in [["W", Vector2(270, 300)], ["A", Vector2(175, 350)], ["D", Vector2(365, 350)], ["S", Vector2(270, 395)]]:
		parent.add_child(Bumper.new(b[1], b[0]))

	var drops := []
	var letters := ["D", "A", "M", "A", "G", "E"]
	for i in 6:
		var d := DropTarget.new(Vector2(150 + i * 38, 545), letters[i])
		parent.add_child(d)
		drops.append(d)
	refs["drops"] = drops

	# I-C-H-Bank an der linken Aussenwand (wie die Pillen-Bank der Vorlage)
	var standups := []
	var ich := ["I", "C", "H"]
	for i in 3:
		var s := Standup.new(Vector2(31, 310 + i * 60), ich[i])
		parent.add_child(s)
		standups.append(s)
	refs["standups"] = standups

	# OP-Spinner in der Hochbahn-Einfahrt oben links
	var sp := Spinner.new(Vector2(55, 222))
	parent.add_child(sp)
	refs["spinner"] = sp

	var throne := Throne.new(Vector2(270, 132))
	parent.add_child(throne)
	refs["throne"] = throne

	parent.add_child(LaneGate.new(Vector2(495, 276)))

	# Mulde in der Mitte (schwarzes Loch der Vorlage)
	parent.add_child(Scoop.new(Vector2(270, 505)))

	# Draht-Hochbahn (2. Ebene) ueber den Tisch
	var ramp := WireRamp.new()
	parent.add_child(ramp)
	refs["ramp"] = ramp

	# Dekos im Stil der Vorlage
	parent.add_child(TableDeco.new("pad", Vector2(270, 350), NEON_CYAN))
	parent.add_child(TableDeco.new("spiral", Vector2(270, 640)))
	parent.add_child(TableDeco.new("rays", Vector2(245, 944), NEON_PINK))
	parent.add_child(TableDeco.new("spring", Vector2(495, 904), NEON_VIOLET))
	parent.add_child(TableDeco.new("star", Vector2(218, 705), Color(1.6, 1.5, 1.2)))
	parent.add_child(TableDeco.new("star", Vector2(322, 668), Color(1.6, 1.5, 1.2), 0.7))
	parent.add_child(TableDeco.new("comet", Vector2(38, 540), NEON_GOLD, 1.0, 15.0))
	parent.add_child(TableDeco.new("comet", Vector2(448, 580), NEON_GOLD, 1.0, -15.0))
	parent.add_child(TableDeco.new("saturn", Vector2(60, 610), NEON_GOLD))
	parent.add_child(TableDeco.new("bolt", Vector2(445, 185), NEON_GOLD))
	parent.add_child(TableDeco.new("arrow", Vector2(375, 520), NEON_CYAN, 1.0, -35.0))
	for i in 5:
		parent.add_child(TableDeco.new("chevron", Vector2(495, 540 + i * 60), NEON_GOLD))
	parent.add_child(TableDeco.new("chevron", Vector2(105, 170), NEON_PINK, 1.0, 225.0))
	parent.add_child(TableDeco.new("chevron", Vector2(85, 200), NEON_PINK, 1.0, 225.0))

	_deco(parent, "KEIN HEAL", Vector2(30, 745), Color(0.35, 1.8, 0.25, 0.5), 11, 72.0)
	_deco(parent, "KEIN PLAN", Vector2(412, 698), Color(0.35, 1.8, 0.25, 0.5), 11, 62.0)
	_deco(parent, "KEIN SKILL.", Vector2(208, 900), Color(1.0, 0.3, 0.6, 0.55), 12, 0.0)
	_deco(parent, "CARRY QUEEN", Vector2(225, 655), Color(1.0, 0.24, 0.62, 0.75), 12, 0.0)
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
