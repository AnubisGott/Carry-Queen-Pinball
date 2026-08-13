class_name Table
extends RefCounted
## Tisch-Geometrie nach der Weltraum-Vorlage, im Carry-Queen-Neon-Schema:
## Mulde mit Hoernern in der Mitte, Bumper-Pad, I-C-H-Bank links,
## In-/Outlanes beidseitig, Spiral-Scheibe unten.

const BG_SHADER := preload("res://shaders/playfield_bg.gdshader")

## Spielfeldbreite und Breite der Chat-Spalte rechts daneben.
const FIELD_W := 540.0
const CHAT_W := 120.0
const TOTAL_W := FIELD_W + CHAT_W

const LEFT := 20.0
const RIGHT := 520.0
const DIVIDER := 470.0
const ARCH_C := Vector2(270, 330)
const ARCH_R := 250.0

const NEON_PINK := Color(1.7, 0.28, 1.0)
const NEON_GREEN := Color(0.3, 1.35, 0.22)
const NEON_CYAN := Color(0.15, 1.6, 1.8)
const NEON_GOLD := Color(1.22, 0.9, 0.2)
const NEON_VIOLET := Color(1.1, 0.4, 1.9)

## Aufbau der Banden nach dem Vorbild von Flipper03 (_draw_rails):
## Schlagschatten, weiter Schein, dunkler Kern, helle Kante.  Erst der dunkle
## Kern macht aus einer Leuchtlinie ein Profil mit Koerper.
const CORE_DARK := Color(0.08, 0.13, 0.16)
const SHADOW_OFF := Vector2(2, 3)

## Feature-Schalter: G-G-E-Z-Rollover-Gassen oben mitte (Ex-Thron-Platz).
## Auf false setzen, um die Bank samt Logik komplett abzuschalten.
const FEATURE_GGEZ := true

## Feature-Schalter: E-G-O-Standup-Bank schraeg an der Trichterwand oben
## links.  Alle drei getroffen -> Ego-Multiplikator steigt sofort.
const FEATURE_EGO := true

## Mitte der G-G-E-Z-Gassen-Bank.  300 = urspruengliche Lage rechts der
## Spielfeld-Mittelachse; mittig (245) getestet und wieder verworfen.
const GGEZ_CENTER := 300.0


static func build(parent: Node2D) -> Dictionary:
	_background(parent)
	# Aussenwaende
	_wall(parent, [Vector2(LEFT, 760), Vector2(LEFT, 330)], NEON_PINK)
	_wall(parent, _arch_points(), NEON_PINK)
	_wall(parent, [Vector2(RIGHT, 330), Vector2(RIGHT, 960)], NEON_PINK)
	# Abschussbahn (rechts) mit Abweiser oben.  Die Trennwand bekommt einen
	# unsichtbaren Zwilling 4px daneben: durch zwei dicht gestaffelte
	# Segmente tunnelt auch ein sehr schneller Ball nicht mehr hindurch.
	_wall(parent, [Vector2(DIVIDER, 960), Vector2(DIVIDER, 300)], NEON_VIOLET)
	_wall(parent, [Vector2(466, 960), Vector2(466, 300)], NEON_VIOLET, false, true)
	# (Der schraege Abweiser am Bahnkopf ist entfallen: mit dem obersten
	# EGO-Target darunter bildete er eine Tasche, in der die Kugel haengen
	# blieb.  Den Abschuss lenkt ohnehin der Aussenbogen nach links.)
	_wall(parent, [Vector2(DIVIDER, 935), Vector2(RIGHT, 935)], NEON_VIOLET)
	# Leitplanke oben links nach der roten Linie des Nutzers: Kuppe mit
	# Scheitel bei x=140, flacher Mittelteil.  Sie endet exakt im
	# Ablenker-Stuetzpunkt (184,154) - ab dort uebernimmt dessen schwarze
	# Kante die Fuehrung, keine doppelte Linie mehr davor.
	_wall(parent, [Vector2(100, 160), Vector2(110, 153), Vector2(120, 149),
			Vector2(130, 147), Vector2(140, 146), Vector2(152, 147),
			Vector2(164, 149), Vector2(176, 152), Vector2(184, 154)], NEON_CYAN)
	# Ablenker am linken Bogen-Abstieg: gleiche Lage und Enden wie zuvor,
	# aber als fliessende Kurve ausgelegt - der Bogenteil ist ein sauberer
	# Kreisbogen (r=27 um 207,140), an den sich der Auslauf tangential
	# anschliesst.  Dadurch keine sichtbaren Knicke mehr.
	_wall(parent, [Vector2(230, 96), Vector2(214, 102), Vector2(200, 110),
			Vector2(190, 119), Vector2(184, 127), Vector2(180, 135),
			Vector2(180, 145), Vector2(184, 154), Vector2(190, 161),
			Vector2(196, 165), Vector2(202, 169), Vector2(207, 172)], NEON_CYAN)
	# (Leit-Band wieder entfernt - hat optisch nicht gepasst)
	# Inlane-Fuehrungen als Winkel, gebaut wie die Aussenbanden: Leuchtkante
	# als Lauflaeche, dahinter das Blechband mit Schellen (Rand-Material).
	# Das Schraegstueck liegt auf der Achse des ruhenden Flippers
	# (y = 846 - (146-x) * tan 20 Grad), damit Fuehrung und Flipperblatt eine
	# durchgehende Linie bilden.  Die unteren Enden ueberlappen den
	# Schwenkkreis der hinteren Flipper-Ecke - sonst bildet sich dort je nach
	# Flipperstellung eine Kerbe, in der die Kugel liegen bleibt.
	var inlane_l := [Vector2(86, 679), Vector2(86, 824), Vector2(146, 846)]
	var inlane_r := [Vector2(404, 679), Vector2(404, 824), Vector2(344, 846)]
	# Rein passive Banden: kein Abstoss, kein Aufleuchten bei Beruehrung.
	_wall(parent, inlane_l, NEON_CYAN)
	_wall(parent, inlane_r, NEON_CYAN)
	parent.add_child(EdgeStructure.new(inlane_l, -1.0, NEON_CYAN, 18.0, 40.0))
	parent.add_child(EdgeStructure.new(inlane_r, 1.0, NEON_CYAN, 18.0, 40.0))
	# Hoerner des Durchlaufs unter dem S-Bumper.  Sie blinken, wenn der
	# Durchlauf fuer eine Sonderfunktion gebraucht wird (siehe PassGate).
	var horn_l := _wall(parent, [Vector2(215, 455), Vector2(227, 492)], NEON_GOLD)
	var horn_r := _wall(parent, [Vector2(275, 455), Vector2(263, 492)], NEON_GOLD)
	# Hoerner der Fang-Mulden beidseitig: leiten die Seitenlaeufe in die Schalen
	_wall(parent, [Vector2(408, 576), Vector2(421, 602)], NEON_GOLD, false, false, true)
	_wall(parent, [Vector2(468, 572), Vector2(455, 598)], NEON_GOLD, false, false, true)
	_wall(parent, [Vector2(82, 576), Vector2(69, 602)], NEON_GOLD, false, false, true)
	_wall(parent, [Vector2(22, 572), Vector2(35, 598)], NEON_GOLD, false, false, true)
	# Untere Banden: kantig gefast statt rund gebogen - wenige lange Geraden
	# mit scharfen Knicken, wie die Ecken der Vorlage.  Die Drain-Oeffnung in
	# der Mitte (210..285) bleibt unveraendert.
	_wall(parent, [Vector2(LEFT, 760), Vector2(LEFT, 838), Vector2(58, 904),
			Vector2(128, 946), Vector2(210, 958)], NEON_PINK, true)
	# Rechte Auslauf-Bande ohne eigene Linie - nur Kollision.  Sie folgt exakt
	# dem gespiegelten Verlauf der linken (und damit ihrem eigenen sichtbaren
	# Blechband): der alte, weiter oben abknickende Verlauf verengte die
	# rechte Auslaufbahn auf Kugelbreite - dort blieb die Kugel an einer
	# unsichtbaren Kante haengen.
	_wall(parent, [Vector2(DIVIDER, 760), Vector2(DIVIDER, 838), Vector2(432, 904),
			Vector2(362, 946), Vector2(280, 958)], NEON_PINK, true, true)

	# Randaufbau: Blechband mit Schellen, Rohr, Waben und Leiterbahnen entlang
	# der Banden - die Struktur der Vorlagentextur als echte Elemente.
	# Rohrfarbe immer anders als die Bande daneben - sonst liest sich das als
	# verdoppelte Linie statt als Strangbuendel wie in der Vorlage.
	# Der Randaufbau am Bogen sitzt wieder im urspruenglichen Raster.  Zwei
	# Stellen sind ausgespart: bei Bogenlaenge 252 (die Schelle, die im
	# Kanal ueber der Leitplanke sass) und bei 344 - dort stehen einzeln
	# gesetzte Schellen, die ueber allem gezeichnet werden.
	var arch_edge := EdgeStructure.new(_arch_points(), -1.0, NEON_CYAN, 26.0, 60.0)
	arch_edge.skip_at = [252.0, 348.0]
	parent.add_child(arch_edge)
	# Beschlaege eine Buchstabenlaenge (60) tiefer als frueher, damit die
	# Schraffur nicht auf dem dritten Target liegt.  Der erste Beschlag
	# entfaellt - der saesse sonst quer auf dem mittleren Target.
	var left_edge := EdgeStructure.new(
			[Vector2(LEFT, 330), Vector2(LEFT, 760)], 1.0, NEON_CYAN, 24.0, 106.0)
	left_edge.skip_at = [106.0]
	parent.add_child(left_edge)
	# Rechts laeuft das Cyan-Band wie links ganz aussen herum und biegt in die
	# Ecke ab - nicht diagonal durchs Feld.
	parent.add_child(EdgeStructure.new(
			[Vector2(LEFT, 760), Vector2(LEFT, 838), Vector2(58, 904),
				Vector2(128, 946), Vector2(210, 958)], 1.0, NEON_CYAN, 22.0, 30.0))
	parent.add_child(EdgeStructure.new(
			[Vector2(RIGHT, 330), Vector2(RIGHT, 935), Vector2(DIVIDER, 935)],
			-1.0, NEON_CYAN, 22.0, 54.0))
	# Rechte Seite exakt spiegelbildlich zur linken.  Spiegelachse ist x=245,
	# die Mitte zwischen linker Bande (20) und Trennwand (470):
	#   20 -> 470 | 58 -> 432 | 128 -> 362 | 210 -> 280
	var div_edge := EdgeStructure.new(
			[Vector2(DIVIDER, 330), Vector2(DIVIDER, 760)], -1.0, NEON_CYAN, 24.0, 106.0)
	div_edge.skip_at = [106.0]
	parent.add_child(div_edge)
	parent.add_child(EdgeStructure.new(
			[Vector2(DIVIDER, 760), Vector2(DIVIDER, 838), Vector2(432, 904),
				Vector2(362, 946), Vector2(280, 958)], -1.0, NEON_CYAN, 22.0, 30.0))

	# Einzeln gesetzte Schellen (voll sichtbar, ueber Banden und Eckplatten):
	# eine am Fusspunkt der Leitplanke, eine oben am Bogen.  Die obere sitzt
	# 3px weiter rechts, damit das Ende des Ablenkers unter ihr verschwindet.
	for spec in [[198.0, Vector2.ZERO], [344.0, Vector2(3, 0)]]:
		var at := _arch_at(spec[0])
		parent.add_child(EdgeClamp.new(at[0] + spec[1], at[1], -1.0))

	var refs := {}

	# Drehpunkte 16 Einheiten tiefer als die Inlane-Fuehrung endet: so faellt
	# die Kugel vom Schraegstueck auf das Blatt, statt in der Kerbe zwischen
	# Fuehrungsende und hinterer Flipper-Ecke liegen zu bleiben.
	# Drehpunkte weit genug aussen: bei 20 Grad Ruhewinkel bleiben zwischen
	# den Blattspitzen 31 Einheiten, die Kugel faellt dort also durch.  Dafuer sitzt die
	# Blattwurzel dicht am Ende der Inlane-Fuehrung, sodass dazwischen keine
	# Luecke klafft, durch die die Kugel verschwinden koennte.
	var fl := Flipper.new(true, Vector2(156, 866))
	var fr := Flipper.new(false, Vector2(334, 866))
	# Gegenseitig bekannt machen: haelt man den anderen Hebel oben, wandert
	# eine liegende Kugel als Pass zu ihm hinueber statt aufs Oberfeld.
	fl.partner = fr
	fr.partner = fl
	parent.add_child(fl)
	parent.add_child(fr)
	refs["flipper_l"] = fl
	refs["flipper_r"] = fr

	# Slingshots als Dreieck durch die drei vom Nutzer gesetzten Punkte:
	# senkrechte Innenkante parallel zur Inlane-Fuehrung, kurze Unterkante
	# und die Hypotenuse als Schlagflaeche zur Spielfeldmitte.
	# Rechts exakt an der Achse x=245 gespiegelt.
	parent.add_child(Slingshot.new([Vector2(122, 703), Vector2(122, 770),
			Vector2(152, 798)], Vector2(89, -63)))
	parent.add_child(Slingshot.new([Vector2(368, 703), Vector2(338, 798),
			Vector2(368, 770)], Vector2(-89, -63)))

	# WASD-Bumper auf dem Pad, S liegt tiefer und fuettert die Mulde.
	# Die ganze Mittelgruppe steht auf der Spielfeld-Mittelachse x=245
	# (Mitte zwischen linker Bande und Trennwand), nicht auf der Bogenmitte.
	var bumpers := {}
	for b in [["W", Vector2(245, 300)], ["A", Vector2(150, 350)],
			["D", Vector2(340, 350)], ["S", Vector2(245, 395)]]:
		var bu := Bumper.new(b[1], b[0])
		parent.add_child(bu)
		bumpers[b[0]] = bu
	refs["bumpers"] = bumpers

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
		var s := Standup.new(Vector2(31, 370 + i * 60), ich[i])
		parent.add_child(s)
		standups.append(s)
	refs["standups"] = standups

	# Einzelner EGO-Knopf (FEATURE_EGO): jeder Treffer = Ego-Stufe rauf
	# E-G-O-Bank an der Trennwand rechts, spiegelbildlich zur I-C-H-Bank
	# links (Achse x=245).  Um 180 Grad gedreht, damit der Buchstabe zum
	# Spielfeld hin steht statt in die Abschussbahn.
	var ego_bank := []
	if FEATURE_EGO:
		var ego_letters := ["E", "G", "O"]
		for i in 3:
			var e := Standup.new(Vector2(459, 370 + i * 60), ego_letters[i], 180.0)
			parent.add_child(e)
			ego_bank.append(e)
	refs["ego_bank"] = ego_bank

	# OP-Spinner quer im Ausgang der Abschussbahn: jede abgeschossene Kugel
	# faehrt hindurch, und wie lange er dreht haengt am Federzug.  Die
	# Rechteck-Zone (56 breit) deckt die 50 Einheiten breite Bahn genau ab.
	var sp := Spinner.new(Vector2(495, 330))
	parent.add_child(sp)
	refs["spinner"] = sp

	# Thron auf Nutzerwunsch entfernt - die Mitte oben ist frei
	parent.add_child(LaneGate.new(Vector2(495, 276)))

	# G-G-E-Z-Rollover-Gassen oben mitte auf dem Ex-Thron-Platz
	# (FEATURE_GGEZ): fuenf schraege Stege nach Nutzer-Skizze, die Kugel
	# faellt vom Bogen kommend von oben hindurch aufs Bumper-Pad.
	var ggez := []
	if FEATURE_GGEZ:
		# Der mittlere Steg steht exakt ueber dem W-Bumper: kein Gassen-
		# Ausgang muendet auf die Bumper-Kuppe (sonst verstopft er die Gasse
		# und pingpongt die Kugel endlos senkrecht zwischen Bumper und Bogen).
		# Stege enden bei y=248: die Gassen-Ausgaenge links und rechts des
		# Plug-Stegs haben so gut 34px Abstand zur Bumper-Kuppe (Kugel: 26).
		# Fuenf schraege Stege, symmetrisch um GGEZ_CENTER
		var lane_dir := Vector2(0.483, -0.877)
		for i in 5:
			_wall(parent, [Vector2(GGEZ_CENTER - 69.0 + i * 38.0, 226),
					Vector2(GGEZ_CENTER - 84.0 + i * 38.0, 198)],
					NEON_VIOLET, false, false, true)
		var ggez_letters := ["G", "G", "E", "Z"]
		for i in 4:
			var r := RolloverLane.new(
					Vector2(GGEZ_CENTER - 57.0 + i * 38.0, 212),
					ggez_letters[i], lane_dir)
			parent.add_child(r)
			ggez.append(r)
	refs["ggez"] = ggez

	# Durchlauf in der Mitte statt der frueheren Mulde: die Kugel rollt
	# zwischen den Hoernern hindurch, gefangen wird sie nicht mehr.
	var gate := PassGate.new(Vector2(245, 500))
	gate.watch_horn(horn_l)
	gate.watch_horn(horn_r)
	parent.add_child(gate)
	refs["gate"] = gate

	# Fang-Mulden an beiden Seitenlaeufen: kurz fangen, sofort zurueck ins Feld
	parent.add_child(SidePocket.new(Vector2(438, 612), -1.0))
	parent.add_child(SidePocket.new(Vector2(52, 612), 1.0))

	# Dekos im Stil der Vorlage
	parent.add_child(TableDeco.new("pad", Vector2(245, 350), NEON_CYAN))
	parent.add_child(TableDeco.new("spiral", Vector2(245, 640)))
	parent.add_child(TableDeco.new("rays", Vector2(245, 944), NEON_PINK))
	# Echte Abschuss-Feder statt Deko: Ball sitzt sichtbar auf dem Teller
	var plunger := Plunger.new()
	parent.add_child(plunger)
	refs["plunger"] = plunger
	parent.add_child(TableDeco.new("star", Vector2(218, 705), Color(1.6, 1.5, 1.2)))
	parent.add_child(TableDeco.new("star", Vector2(322, 668), Color(1.6, 1.5, 1.2), 0.7))
	parent.add_child(TableDeco.new("comet", Vector2(38, 540), NEON_GOLD, 1.0, 15.0))
	parent.add_child(TableDeco.new("comet", Vector2(445, 540), NEON_GOLD, 1.0, -15.0))
	parent.add_child(TableDeco.new("saturn", Vector2(82, 475), NEON_GOLD))
	parent.add_child(TableDeco.new("arrow", Vector2(375, 520), NEON_CYAN, 1.0, -35.0))
	# Lane-Pfeile: blinken, solange ein Ball abschussbereit ist (main.gd)
	var lane_chevrons := []
	for i in 5:
		var ch := TableDeco.new("chevron", Vector2(495, 540 + i * 60), NEON_GOLD)
		parent.add_child(ch)
		lane_chevrons.append(ch)
	refs["lane_chevrons"] = lane_chevrons
	parent.add_child(TableDeco.new("chevron", Vector2(105, 170), NEON_PINK, 1.0, 225.0))
	parent.add_child(TableDeco.new("chevron", Vector2(85, 200), NEON_PINK, 1.0, 225.0))

	# Beide Texte frei lesbar in den Auslauf-Rinnen neben den Inlane-Leisten
	_deco(parent, "KEIN HEAL", Vector2(58, 712), Color(0.3, 1.35, 0.22, 0.6), 11, 64.0)
	_deco(parent, "KEIN PLAN", Vector2(427, 723), Color(0.3, 1.35, 0.22, 0.6), 11, 63.0)
	_deco(parent, "KEIN SKILL.", Vector2(208, 900), Color(1.0, 0.3, 0.6, 0.55), 12, 0.0)
	_deco(parent, "CARRY QUEEN", Vector2(200, 655), Color(1.0, 0.24, 0.62, 0.75), 12, 0.0)
	_deco(parent, "SPACE HALTEN", Vector2(505, 740), Color(1.1, 0.4, 1.9, 0.5), 10, 90.0)

	return refs


## Punkt und Laufrichtung auf dem Aussenbogen bei Bogenlaenge d (0 = linkes
## Ende bei (20,330), Gesamtlaenge PI * ARCH_R).
static func _arch_at(d: float) -> Array:
	var a := PI + PI * d / (PI * ARCH_R)
	return [ARCH_C + Vector2(cos(a), sin(a)) * ARCH_R, Vector2(-sin(a), cos(a))]


static func _arch_points() -> Array:
	var pts := []
	for i in 27:
		var a := PI + PI * i / 26.0
		pts.append(ARCH_C + Vector2(cos(a), sin(a)) * ARCH_R)
	return pts


## `sharp` zeichnet die Bande mit spitzen Knicken und geraden Enden statt
## rund verschliffen - das gibt den kantigen Look der Vorlage.
## `hidden` baut nur die Kollision, ohne Linie - fuer Banden, deren Optik ein
## darueberliegendes Element traegt.
## Gibt die helle Kantenlinie zurueck (null bei `hidden`) - daran koennen
## Elemente wie das Muldentor ihre Blink-Animation haengen.
static func _wall(parent: Node2D, pts: Array, color: Color, sharp: bool = false,
		hidden: bool = false, flash: bool = false) -> Line2D:
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
	var joint := Line2D.LINE_JOINT_SHARP if sharp else Line2D.LINE_JOINT_ROUND
	var cap := Line2D.LINE_CAP_BOX if sharp else Line2D.LINE_CAP_ROUND
	var packed := PackedVector2Array(pts)

	if hidden:
		return null

	# Schlagschatten leicht versetzt - hebt die Bande vom Untergrund ab
	var shadow := Line2D.new()
	var shifted := PackedVector2Array()
	for p in pts:
		shifted.append(p + SHADOW_OFF)
	shadow.points = shifted
	shadow.width = 9.0
	shadow.default_color = Color(0, 0, 0, 0.7)
	shadow.joint_mode = joint
	shadow.begin_cap_mode = cap
	shadow.end_cap_mode = cap
	parent.add_child(shadow)

	var under := Line2D.new()
	under.points = packed
	under.width = 12.0
	under.default_color = Color(color.r, color.g, color.b, 0.13)
	under.joint_mode = joint
	under.begin_cap_mode = cap
	under.end_cap_mode = cap
	parent.add_child(under)

	# Dunkler Kern: macht aus der Leuchtlinie ein koerperhaftes Profil
	var core := Line2D.new()
	core.points = packed
	core.width = 6.5
	core.default_color = CORE_DARK
	core.joint_mode = joint
	core.begin_cap_mode = cap
	core.end_cap_mode = cap
	parent.add_child(core)

	# Helle Kante obenauf
	var line := Line2D.new()
	line.points = packed
	line.width = 2.4
	line.default_color = color
	line.joint_mode = joint
	line.begin_cap_mode = cap
	line.end_cap_mode = cap
	parent.add_child(line)
	if flash:
		# Dezenter Blitz wie bei den gruenen Leisten: nur eine Spur heller
		var tf := TouchFlash.new(pts, 6.0)
		tf.watch(under, Color(color.r + 0.1, color.g + 0.1, color.b + 0.1, 0.17))
		tf.watch(line, Color(color.r + 0.1, color.g + 0.1, color.b + 0.1, color.a))
		parent.add_child(tf)
	# Knotenpunkte als kleine Quadrate betonen
	if sharp:
		for i in range(1, pts.size() - 1):
			var node := Polygon2D.new()
			var s := 5.0
			node.polygon = PackedVector2Array([
				Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
			node.position = pts[i]
			node.color = Color(color.r, color.g, color.b, 0.95)
			parent.add_child(node)
	return line


## Dickes Kapsel-Band entlang einer Polylinie - die Optik der Inlane-
## Leisten fuer geschwungene Leit-Bahnen (Kollision kommt separat).
static func _thick_band(parent: Node2D, pts: Array, color: Color) -> void:
	var packed := PackedVector2Array(pts)
	var shifted := PackedVector2Array()
	for p in pts:
		shifted.append(p + SHADOW_OFF)
	var layers := [
		[shifted, 16.0, Color(0, 0, 0, 0.7)],
		[packed, 20.0, Color(color.r, color.g, color.b, 0.15)],
		[packed, 12.0, CORE_DARK],
		[packed, 9.0, Color(color.r, color.g, color.b, 0.55)],
		[packed, 3.0, Color(1.1, 1.1, 1.1, 0.5)],
	]
	for l in layers:
		var line := Line2D.new()
		line.points = l[0]
		line.width = l[1]
		line.default_color = l[2]
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		parent.add_child(line)


## Rein dekorativer Winkel in einer Ecke: zwei Schenkel im rechten Winkel und
## ein kleines Quadrat.  `dir` gibt an, in welche Richtung die Schenkel zeigen.
static func _corner_bracket(parent: Node2D, at: Vector2, dir: Vector2, color: Color) -> void:
	var arm := 34.0
	var line := Line2D.new()
	line.points = PackedVector2Array([
		at + Vector2(dir.x * arm, 0), at, at + Vector2(0, dir.y * arm)])
	line.width = 3.0
	line.default_color = Color(color.r, color.g, color.b, 0.85)
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_BOX
	line.z_index = -3
	parent.add_child(line)

	var box := Line2D.new()
	var s := 9.0
	var c := at + Vector2(dir.x * 15.0, dir.y * 15.0)
	box.points = PackedVector2Array([
		c + Vector2(-s, -s), c + Vector2(s, -s), c + Vector2(s, s),
		c + Vector2(-s, s), c + Vector2(-s, -s)])
	box.width = 2.0
	box.default_color = Color(color.r, color.g, color.b, 0.6)
	box.joint_mode = Line2D.LINE_JOINT_SHARP
	box.z_index = -3
	parent.add_child(box)


static func _bar(parent: Node2D, a: Vector2, b: Vector2, color: Color,
		flash: bool = false) -> void:
	# Breites, kapselfoermiges Band mit echter physischer Dicke
	var body := StaticBody2D.new()
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.28
	pm.friction = 0.1
	body.physics_material_override = pm
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 6.0
	cap.height = a.distance_to(b)
	cs.shape = cap
	body.position = (a + b) * 0.5
	body.rotation = (b - a).angle() - PI / 2.0
	body.add_child(cs)
	parent.add_child(body)
	var shadow := Line2D.new()
	shadow.points = PackedVector2Array([a + SHADOW_OFF, b + SHADOW_OFF])
	shadow.width = 18.0
	shadow.default_color = Color(0, 0, 0, 0.7)
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(shadow)
	var under := Line2D.new()
	under.points = PackedVector2Array([a, b])
	under.width = 26.0
	under.default_color = Color(color.r, color.g, color.b, 0.13)
	under.begin_cap_mode = Line2D.LINE_CAP_ROUND
	under.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(under)
	# dunkler Koerper, darauf erst die Leuchtkante
	var shell := Line2D.new()
	shell.points = PackedVector2Array([a, b])
	shell.width = 15.0
	shell.default_color = CORE_DARK
	shell.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shell.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(shell)
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.width = 11.0
	line.default_color = Color(color.r, color.g, color.b, 0.55)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)
	var core := Line2D.new()
	core.points = PackedVector2Array([a, b])
	core.width = 4.0
	core.default_color = Color(1.1, 1.1, 1.1, 0.5)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(core)
	if flash:
		# Dezenter Blitz nach Nutzer-Vorgabe: nur eine Spur heller, nicht grell
		var tf := TouchFlash.new([a, b], 8.0)
		tf.watch(under, Color(0.4, 1.5, 0.33, 0.17))
		tf.watch(line, Color(0.4, 1.5, 0.33, 0.66))
		tf.watch(core, Color(1.6, 1.6, 1.6, 0.66))
		parent.add_child(tf)


static func _background(parent: Node2D) -> void:
	# Platinen-Hintergrund als Shader: Wabenraster, Magenta-Kern hinter der
	# Scheibe, kalter Schein hinter dem Bumper-Pad, Vignette.
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(TOTAL_W, 0), Vector2(TOTAL_W, 960), Vector2(0, 960)])
	bg.color = Color.WHITE
	bg.z_index = -10
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	mat.set_shader_parameter("rect_size", Vector2(TOTAL_W, 960))
	bg.material = mat
	parent.add_child(bg)

	# schwache Leiterbahnen als Struktur
	for i in 7:
		var x := 46.0 + i * 74.0
		var trace := Line2D.new()
		trace.points = PackedVector2Array([
			Vector2(x, 90), Vector2(x, 300 + i * 40), Vector2(x + 30, 340 + i * 40),
			Vector2(x + 30, 950)])
		trace.width = 1.0
		trace.default_color = Color(0.55, 0.16, 0.70, 0.22)
		trace.z_index = -9
		parent.add_child(trace)

	# Rahmen um das Spielfeld - der Stream-Look der Vorlage
	var frame := Line2D.new()
	frame.points = PackedVector2Array([
		Vector2(4, 88), Vector2(FIELD_W - 4, 88), Vector2(FIELD_W - 4, 956),
		Vector2(4, 956), Vector2(4, 88)])
	frame.width = 2.5
	frame.default_color = Color(0.15, 1.4, 1.6, 0.85)
	frame.joint_mode = Line2D.LINE_JOINT_SHARP
	frame.z_index = -8
	parent.add_child(frame)

	# Eckstrukturen: Metallplatten mit Schrauben, Wabenfeld und Neonrohr -
	# so wie die Textur der Vorlage ihre Struktur in die Ecken legt und die
	# Mitte frei laesst.
	# Letzter Wert je Ecke ist die Wabenfarbe (unabhaengig vom Akzent).
	for spec in [
		[Vector2(4, 88), Vector2(1, 1), Vector2(122, 152), NEON_CYAN, NEON_CYAN],
		[Vector2(FIELD_W - 4, 88), Vector2(-1, 1), Vector2(122, 152), NEON_PINK, NEON_PINK],
		# Unten rechts sitzt die Platte an der Spielfeldecke, nicht an der
		# Rahmenecke - sonst liegt sie hinter der Schussbahn und steht nicht
		# spiegelbildlich zur linken (Achse x=245: 4..116 -> 374..486).
		[Vector2(486, 956), Vector2(-1, -1), Vector2(112, 126), NEON_CYAN, NEON_VIOLET],
		[Vector2(4, 956), Vector2(1, -1), Vector2(112, 126), NEON_CYAN, NEON_GREEN],
	]:
		var plate := CornerPlate.new(spec[0], spec[1], spec[2], spec[3], spec[4])
		# In den unteren Ecken ohne Neonrohr: es schnitt diagonal durch die
		# Auslaufbahn (Nutzerwunsch).
		if spec[0].y > 500.0:
			plate.show_pipe = false
		parent.add_child(plate)


static func _deco(parent: Node2D, text: String, pos: Vector2, col: Color, size: int, rot: float) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.rotation_degrees = rot
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.z_index = -5
	parent.add_child(l)
