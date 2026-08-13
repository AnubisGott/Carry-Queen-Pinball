class_name FortuneWheel
extends StaticBody2D
## Gluecksrad: die Kugel stoesst die Scheibe an, sie dreht sich aus und zahlt
## am Ende den Sektor aus, der oben unter der Krone steht.
##
## Waehrend des Drehens gibt es Punkte je Umdrehung wie beim Spinner - wer
## kraeftig trifft, kassiert also schon beim Ausdrehen.  Ein weiterer Treffer
## bringt die Scheibe wieder auf Anfangstempo: wer nachlegt, dreht laenger,
## verschiebt aber auch, wo sie stehen bleibt.
##
## Thema: das Ranked-Rad.  Die Sektoren sind Ligen von Bronze bis Challenger,
## und die Queen kommentiert, was dabei herauskommt.

const RADIUS := 36.0
## Anfangstempo in Bogenmass je Sekunde (gut zwei Umdrehungen)
const START_SPEED := 14.0
## Bremsung je Sekunde - daraus ergeben sich rund 6 Sekunden Auslauf
const REIBUNG := 2.3
## Punkte je Umdrehung waehrend des Drehens
const PER_REV := 60
## Punkte allein fuers Anstossen
const ANSTOSS := 120

## Reihenfolge auf der Scheibe: hohe und niedrige Ligen wechseln sich ab,
## damit nicht ein ganzer Bogen wertlos ist.
const SEKTOREN := [
	{"punkte": 500, "kurz": "500", "rang": "BRONZE"},
	{"punkte": 5000, "kurz": "5K", "rang": "DIAMANT"},
	{"punkte": 1000, "kurz": "1K", "rang": "SILBER"},
	{"punkte": 25000, "kurz": "25K", "rang": "CHALLENGER"},
	{"punkte": 2000, "kurz": "2K", "rang": "GOLD"},
	{"punkte": 10000, "kurz": "10K", "rang": "MASTER"},
]

var _winkel := 0.0
var _speed := 0.0
var _rev_acc := 0.0
var _cool := 0.0
var _letzter_sektor := -1
var _leuchten := 0.0
var _gewinn_sektor := -1
var _ball: PinBall = null


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = RADIUS
	cs.shape = sh
	add_child(cs)
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.55
	physics_material_override = pm
	# Beruehrungssensor knapp ausserhalb der Scheibe
	var area := Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := CircleShape2D.new()
	ash.radius = RADIUS + 5.0
	acs.shape = ash
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_hit)
	z_index = 4
	_winkel = randf() * TAU
	_letzter_sektor = _sektor_oben()


## Sektor unter der Krone (oben, also in Richtung -90 Grad).
func _sektor_oben() -> int:
	var pro := TAU / float(SEKTOREN.size())
	return int(wrapf(-PI / 2.0 - _winkel, 0.0, TAU) / pro) % SEKTOREN.size()


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _leuchten > 0.0:
		_leuchten = maxf(0.0, _leuchten - delta * 1.2)
		queue_redraw()
	if _speed <= 0.0:
		return
	var schritt := _speed * delta
	_winkel = fmod(_winkel + schritt, TAU)
	# Punkte je Umdrehung, wie beim Spinner
	_rev_acc += schritt
	while _rev_acc >= TAU:
		_rev_acc -= TAU
		Game.add_score(PER_REV, _ball if is_instance_valid(_ball) else null)
	# Ticken, sobald ein Sektor an der Krone vorbeilaeuft
	var sekt := _sektor_oben()
	if sekt != _letzter_sektor:
		_letzter_sektor = sekt
		Sfx.play("tick", -18.0)
	_speed = maxf(0.0, _speed - REIBUNG * delta)
	if _speed <= 0.0:
		_auszahlen()
	queue_redraw()


func _auszahlen() -> void:
	var sekt: Dictionary = SEKTOREN[_sektor_oben()]
	_gewinn_sektor = _sektor_oben()
	_leuchten = 1.0
	var pts: int = Game.add_score(int(sekt["punkte"]))
	Game.emit("wheel", {"punkte": pts, "rang": str(sekt["rang"]),
			"roh": int(sekt["punkte"])})
	queue_redraw()


func _on_hit(body: Node2D) -> void:
	if not body is PinBall or body.freeze or _cool > 0.0:
		return
	_cool = 0.25
	_ball = body as PinBall
	# Jeder Treffer setzt wieder aufs Anfangstempo - auch mitten im Auslauf
	_speed = START_SPEED
	_rev_acc = 0.0
	_gewinn_sektor = -1
	Sfx.play("spin", -6.0)
	Game.add_score(ANSTOSS, _ball)
	Game.emit("wheel_hit")
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	var pro := TAU / float(SEKTOREN.size())
	var dreht := _speed > 0.0
	# Schatten und dunkler Teller
	draw_circle(Vector2(2, 3), RADIUS + 2.0, Color(0, 0, 0, 0.6))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.05, 0.04, 0.09))
	for i in SEKTOREN.size():
		var von := _winkel + i * pro
		var hoch: bool = int(SEKTOREN[i]["punkte"]) >= 5000
		var grund := Table.NEON_VIOLET if i % 2 == 0 else Table.NEON_PINK
		if hoch:
			grund = Table.NEON_GOLD
		var stark: float = 0.16 + (0.5 if i == _gewinn_sektor else 0.0) * _leuchten
		# Sektorflaeche als Faecher
		var punkte := PackedVector2Array([Vector2.ZERO])
		for k in 9:
			punkte.append(Vector2.RIGHT.rotated(von + pro * float(k) / 8.0) * (RADIUS - 2.0))
		draw_colored_polygon(punkte, Color(grund.r, grund.g, grund.b, stark))
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(von) * (RADIUS - 2.0),
				Color(grund.r, grund.g, grund.b, 0.55), 1.5)
		# Beschriftung mitdrehend
		var mitte := von + pro * 0.5
		var txt := str(SEKTOREN[i]["kurz"])
		draw_set_transform(Vector2.RIGHT.rotated(mitte) * (RADIUS * 0.62), mitte + PI / 2.0, Vector2.ONE)
		draw_string(f, Vector2(-11, 4), txt, HORIZONTAL_ALIGNMENT_CENTER, 22, 11,
				grund if not hoch else Color(1.5, 1.2, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Rand, Nabe und Krone
	var rand := Table.NEON_GOLD if dreht else Table.NEON_VIOLET
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48,
			Color(rand.r, rand.g, rand.b, 0.85 + 0.15 * _leuchten), 2.5)
	draw_circle(Vector2.ZERO, 7.0, Color(0.08, 0.06, 0.12))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, Table.NEON_CYAN, 1.5)
	# Krone als Zeiger ueber dem Rad
	var kz := Color(1.4, 1.05, 0.3)
	draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -RADIUS - 12), Vector2(9, -RADIUS - 12),
			Vector2(0, -RADIUS - 1)]), kz)
	draw_line(Vector2(-9, -RADIUS - 12), Vector2(-9, -RADIUS - 19), kz, 2.0)
	draw_line(Vector2(0, -RADIUS - 12), Vector2(0, -RADIUS - 21), kz, 2.0)
	draw_line(Vector2(9, -RADIUS - 12), Vector2(9, -RADIUS - 19), kz, 2.0)
