class_name FortuneWheel
extends StaticBody2D
## Gluecksrad: die Kugel stoesst die Scheibe an, sie dreht sich aus und zahlt
## am Ende den Sektor aus, der oben unter der Krone steht.
##
## Waehrend des Drehens tickt jeder Sektor, der unter der Krone durchlaeuft,
## und zahlt dabei - der Punktestand klettert also sichtbar im Takt des
## Tickens, bis die Scheibe steht.  Ein weiterer Treffer
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
## Punkte je Tick, also jedes Mal, wenn ein Sektor unter der Krone
## durchlaeuft.  So steigt der Punktestand sichtbar mit dem Ticken mit,
## statt nur einmal je Umdrehung zu springen.  Sechs Sektoren ergeben
## 150 Punkte je Umdrehung.
const PER_TICK := 25
## Punkte allein fuers Anstossen
const ANSTOSS := 120

## Sektorfarben: alle sechs kommen so schon auf dem Spielfeld vor - die vier
## Wabenfelder in den Ecken (Cyan oben links, Magenta oben rechts, Lila unten
## rechts, Gruen unten links), das Gold der Hoerner und das Rot der
## DAMAGE-Buchstaben.
##
## Der Tisch leuchtet ueber Farbwerte groesser 1 (HDR-Glow der Umgebung).  Das
## Rad soll nicht leuchten, deshalb sind alle Werte so herunterskaliert, dass
## der groesste Kanal genau 1 ist: gleiche Farbe, kein Schein.
## Gold etwas gelber als die reine Skalierung (0.74 Gruen), weil das Gold der
## Hoerner durch seinen Leuchtschein heller und gelber wirkt als sein Grundwert.
const F_GOLD := Color(1.0, 0.85, 0.18)    # Hoerner,      Tisch: 1.22,0.9,0.2
const F_LILA := Color(0.58, 0.21, 1.0)    # Ecke u. re.,  Tisch: 1.1,0.4,1.9
const F_ROT := Color(1.0, 0.17, 0.28)     # DAMAGE,       Tisch: 1.8,0.3,0.5
const F_CYAN := Color(0.08, 0.89, 1.0)    # Ecke o. li.,  Tisch: 0.15,1.6,1.8
const F_GRUEN := Color(0.22, 1.0, 0.16)   # Ecke u. li.,  Tisch: 0.3,1.35,0.22
const F_MAGENTA := Color(1.0, 0.16, 0.59) # Ecke o. re.,  Tisch: 1.7,0.28,1.0

## Reihenfolge auf der Scheibe: hohe und niedrige Ligen wechseln sich ab,
## damit nicht ein ganzer Bogen wertlos ist.  Die Farbe haengt dagegen am
## Wert, nicht am Platz.
const SEKTOREN := [
	{"punkte": 500, "kurz": "500", "rang": "BRONZE", "farbe": F_MAGENTA},
	{"punkte": 5000, "kurz": "5K", "rang": "DIAMANT", "farbe": F_ROT},
	{"punkte": 1000, "kurz": "1K", "rang": "SILBER", "farbe": F_GRUEN},
	{"punkte": 25000, "kurz": "25K", "rang": "CHALLENGER", "farbe": F_GOLD},
	{"punkte": 2000, "kurz": "2K", "rang": "GOLD", "farbe": F_CYAN},
	{"punkte": 10000, "kurz": "10K", "rang": "MASTER", "farbe": F_LILA},
]

var _winkel := 0.0
var _speed := 0.0
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
	_winkel = fmod(_winkel + _speed * delta, TAU)
	# Jeder Sektor, der unter der Krone durchlaeuft, tickt und zahlt
	var sekt := _sektor_oben()
	if sekt != _letzter_sektor:
		_letzter_sektor = sekt
		Sfx.play("tick", -18.0)
		Game.add_score(PER_TICK, _ball if is_instance_valid(_ball) else null)
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
		var grund: Color = SEKTOREN[i]["farbe"]
		# Fast deckend: bei halber Deckkraft wird das Gold ueber dem dunklen
		# Tisch braun statt golden.  Der Gewinnsektor leuchtet beim Auszahlen
		# zusaetzlich kurz auf.
		var stark: float = 0.85 + 0.15 * (_leuchten if i == _gewinn_sektor else 0.0)
		# Sektorflaeche als Faecher
		var punkte := PackedVector2Array([Vector2.ZERO])
		for k in 9:
			punkte.append(Vector2.RIGHT.rotated(von + pro * float(k) / 8.0) * (RADIUS - 2.0))
		draw_colored_polygon(punkte, Color(grund.r, grund.g, grund.b, stark))
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(von) * (RADIUS - 2.0),
				Color(0.02, 0.02, 0.04, 0.9), 1.5)
		# Beschriftung mitdrehend.  Auf hellem Grund dunkel, sonst hell -
		# sonst verschwindet die Zahl im Untergrund.
		var mitte := von + pro * 0.5
		var txt := str(SEKTOREN[i]["kurz"])
		var schrift := Color(0.04, 0.03, 0.07) if grund.get_luminance() > 0.45 \
				else Color(1.0, 1.0, 1.0)
		draw_set_transform(Vector2.RIGHT.rotated(mitte) * (RADIUS * 0.62), mitte + PI / 2.0, Vector2.ONE)
		draw_string(f, Vector2(-11, 4), txt, HORIZONTAL_ALIGNMENT_CENTER, 22, 11, schrift)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Rand, Nabe und Krone - ebenfalls hoechstens Wert 1, damit nichts strahlt
	var rand := F_GOLD if dreht else F_LILA
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48,
			Color(rand.r, rand.g, rand.b, 0.85 + 0.15 * _leuchten), 2.5)
	draw_circle(Vector2.ZERO, 7.0, Color(0.08, 0.06, 0.12))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, F_CYAN, 1.5)
	# Krone als Zeiger ueber dem Rad
	var kz := F_GOLD
	draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -RADIUS - 12), Vector2(9, -RADIUS - 12),
			Vector2(0, -RADIUS - 1)]), kz)
	draw_line(Vector2(-9, -RADIUS - 12), Vector2(-9, -RADIUS - 19), kz, 2.0)
	draw_line(Vector2(0, -RADIUS - 12), Vector2(0, -RADIUS - 21), kz, 2.0)
	draw_line(Vector2(9, -RADIUS - 12), Vector2(9, -RADIUS - 19), kz, 2.0)

