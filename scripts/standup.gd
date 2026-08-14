class_name Standup
extends StaticBody2D
## Standup-Target (I / C / H), montiert an der linken Orbit-Wand, zeigt nach rechts.

const W := 10.0
const H := 34.0
## So viele Kreuze stehen uebereinander im getroffenen Target
const KREUZE := 3

## Solange das Target leuchtet, wandert seine Innenfarbe langsam durch die
## Neonfarben des Tisches - sonst haelt man die stehenden Schalter fuer Deko.
const LIT_CYCLE := [
	Color(0.04, 0.34, 0.40),
	Color(0.38, 0.07, 0.23),
	Color(0.25, 0.10, 0.44),
	Color(0.42, 0.07, 0.10),
]
const CYCLE_TIME := 2.6

var letter := "I"
var lit := false
var _cool := 0.0
var _cycle_t := 0.0

## Die anderen Targets derselben Bank (von table.gd gesetzt, self ist dabei).
## Nur einer der drei Buchstaben geht je Vorbeirollen an: wer trifft, sperrt
## die Nachbarn, solange die Kugel noch bei der Bank ist.  Vorher raeumte
## eine einzige senkrecht herunterrollende Kugel die ganze Bank ab - gemessen
## 406 ms vom ersten bis zum dritten Buchstaben.
var bank: Array = []
## So weit muss die Kugel von jedem Target der Bank weg sein, damit die
## Sperre faellt.  Der Abstand der Targets untereinander ist 60.
const BANK_WEG := 75.0
## So schnell muss die Kugel quer auf das Target zulaufen, damit der Treffer
## zaehlt.  Eine vorbeirollende Kugel bekommt beim Streifen nur ein paar
## Dutzend px/s zur Seite ab; ein Schuss vom Spielfeld bringt Hunderte mit.
const ANFAHRT := 120.0
var _gesperrt := false


func _init(pos: Vector2, l: String, rot_deg: float = 0.0) -> void:
	position = pos
	letter = l
	rotation = deg_to_rad(rot_deg)


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(W, H)
	cs.shape = sh
	add_child(cs)
	var area := Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := RectangleShape2D.new()
	ash.size = Vector2(W + 10, H + 6)
	acs.shape = ash
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_hit)
	z_index = 4


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _gesperrt and not _kugel_bei_der_bank():
		_gesperrt = false
	if lit:
		_cycle_t += delta
		queue_redraw()


## Ist noch eine Kugel in Reichweite der Bank?  Solange bleibt die Sperre -
## damit haengt sie nicht an einer Zeit, die bei langsam rollenden Kugeln
## zu kurz waere.
func _kugel_bei_der_bank() -> bool:
	for b in get_tree().get_nodes_in_group("balls"):
		if not b is Node2D:
			continue
		for g in bank:
			if b.global_position.distance_to(g.global_position) < BANK_WEG:
				return true
	return false


func _draw() -> void:
	var r := Rect2(-W / 2, -H / 2, W, H)
	var col := Color(0.18, 1.5, 0.95) if lit else Color(0.1, 0.5, 0.4)
	var bg := Color(0.03, 0.09, 0.08)
	if lit:
		# Langsamer Durchlauf durch die Neonfarben Cyan, Pink, Lila, Rot
		var f := fmod(_cycle_t / CYCLE_TIME, float(LIT_CYCLE.size()))
		var i := int(f)
		bg = LIT_CYCLE[i].lerp(LIT_CYCLE[(i + 1) % LIT_CYCLE.size()], f - i)
	draw_rect(r, bg)
	draw_rect(r, col, false, 2.0)
	# Getroffen heisst durchgestrichen: Kreuze von Ecke zu Ecke.  Ueber die
	# ganze Hoehe waere eine Diagonale bei 10 zu 34 fast senkrecht und saehe
	# aus wie eine Sanduhr - deshalb drei Kreuze uebereinander.  Der Rahmen
	# ist 2 breit, deshalb 2 nach innen versetzt.
	if lit:
		var a := r.grow(-2.0)
		var h := a.size.y / KREUZE
		for i in KREUZE:
			var o := a.position + Vector2(0.0, i * h)
			draw_line(o, o + Vector2(a.size.x, h), col, 2.0)
			draw_line(o + Vector2(0.0, h), o + Vector2(a.size.x, 0.0), col, 2.0)
	# Buchstabe bleibt aufrecht, auch wenn das Target gedreht montiert ist
	var f := ThemeDB.fallback_font
	draw_set_transform(Vector2(12, 5), -rotation, Vector2.ONE)
	draw_string(f, Vector2.ZERO, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_hit(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall:
		return
	# Gezaehlt wird nur ein Treffer auf die Vorderseite.  Eine Kugel, die
	# senkrecht an der Wand herunterfaellt, kommt oben ueber die Kante herein
	# und liesse den Buchstaben sonst angehen, ohne dass jemand darauf
	# gezielt haette - egal wie schnell sie ist.
	#
	# Massgeblich ist deshalb die Stelle, nicht der Winkel: die Kugel muss
	# neben dem Target sein, nicht darueber oder darunter.  Ein steiler Schuss
	# vom Spielfeld her zaehlt damit weiter, ein Fall auf die Oberkante nicht.
	# Dazu muss sie sich ueberhaupt auf das Target zu bewegen.
	var d: Vector2 = (body.global_position - global_position).rotated(-rotation)
	var v: Vector2 = (body as PinBall).linear_velocity.rotated(-rotation)
	if absf(d.y) > H / 2.0 + 4.0 or v.x > -ANFAHRT:
		return
	_cool = 0.4
	# Der Treffer klingt und zaehlt immer - nur der Buchstabe geht nicht an,
	# wenn eben schon ein anderer der Bank dran war.
	Sfx.play("standup", -5.0)
	Game.add_score(300, body)
	if not lit and not _gesperrt:
		lit = true
		queue_redraw()
		Game.emit("standup", {"letter": letter})
		for g in bank:
			if g != self:
				g._gesperrt = true


func reset() -> void:
	lit = false
	# Auch die Sperre faellt: sonst bliebe sie ueber den Ballwechsel hinweg
	# stehen und schluckte den ersten Treffer der neuen Runde.
	_gesperrt = false
	_cool = 0.0
	queue_redraw()
