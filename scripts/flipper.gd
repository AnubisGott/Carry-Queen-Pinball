class_name Flipper
extends AnimatableBody2D
## Flipperfinger, kinematisch rotiert (sync_to_physics schiebt die Kugel).
##
## Optik nach dem Vorbild des Referenzprojekts: dunkler Koerper mit pinker
## Kante, cyanfarbene Linie auf der Oberseite, Nieten und ein gruener
## Lagerring am Drehpunkt.  Die Kollisionsform bleibt davon unberuehrt.

const SPEED := 22.0
## Zurueck in die Ruhelage geht es deutlich langsamer - wie bei einer echten
## Rueckstellfeder.  Ein schnell wegfallendes Blatt laesst die aufliegende
## Kugel sonst kurz in der Luft stehen und sie kommt als Huepfer wieder auf.
const RETURN_SPEED := 8.0
const METAL := Color(0.78, 0.83, 0.92)
const TIP_X := 78.0
## Schub des "Solenoids": eine aufliegende Kugel bekommt beim Schlag diesen
## Stoss quer zum Blatt mit.  Ohne ihn haette eine am Blattansatz liegende
## Kugel kaum Umfangsgeschwindigkeit und kaeme nicht bis nach oben - aus dem
## Stand muss der Schlag aber bis zu den G-G-E-Z-Gassen (y = 212) reichen.
const FLIP_POWER := 2150.0
## Anteil, den die Kugel am Blattansatz mindestens abbekommt (an der Spitze
## wirkt der volle Schub - so bleibt die Stelle des Treffers spuerbar).
const FLIP_BASE := 0.74
## Abschusswinkel ueber der Waagerechten, zur Tischmitte hin.  Am Blattansatz
## steil (geht aufs Oberfeld zu den G-G-E-Z-Gassen), an der Spitze flach
## (der klassische Querschuss auf die gegenueberliegende Seite).
const FLIP_ANGLE_BASE := 78.0
const FLIP_ANGLE_TIP := 60.0
## Bis hierhin liegt die Kugel praktisch auf dem Lager.  Dort hat auch ein
## echter Flipper keine Hebelwirkung: es gibt keinen Schuss, sondern einen
## flachen Pass hinueber aufs Blatt des anderen Hebels.  Ab dieser Entfernung
## faechert der Treffpunkt zum Schuss auf.
##
## Die Grenze liegt unter der Stelle, an der eine gefangene Kugel zur Ruhe
## kommt (28 bis 29 px vom Drehpunkt) - aus dem Cradle heraus muss ein
## richtiger Schuss moeglich sein, sonst kommt man nie ins Oberfeld.
##
## Der Pass wird darum bewusst angefordert: haelt man den anderen Hebel oben
## (man will die Kugel dort auffangen), geht sie als flacher Pass hinueber
## statt aufs Oberfeld.  Liegt sie wirklich auf dem Lager, passt sie immer -
## dort gibt es ohnehin keine Hebelwirkung.
const ARM_PASS := 20.0
## Bis hier heraus laesst sich passen.  Weiter aussen auf dem Blatt ist es
## immer ein Schuss, egal was der andere Hebel macht.
const ARM_PASS_MAX := 46.0
## Ab dieser Zeit auf dem Blatt gilt eine Kugel als liegend: sie wird bewusst
## abgeschossen und bekommt den vollen Schub.  Eine gerade erst aufgeprallte
## Kugel ist zwar auch kurz langsam, aber eben nicht lange genug.
const RUHE_ZEIT := 0.08
const RUHE_TEMPO := 250.0
const PASS_SPEED := 420.0
const PASS_ANGLE := 40.0

var is_left := true
## Der Hebel auf der anderen Seite - wird er gehalten, wandert die Kugel als
## Pass zu ihm hinueber (siehe ARM_PASS).
var partner: Flipper
var rest_deg := 28.0
var pressed_deg := -32.0
var _target := 0.0
var _held := false
var _flash := 0.0
var _art: Node2D
var _area: Area2D
## Wie lange der Stoss nach dem Druecken noch bereitsteht.  Eine Kugel, die
## beim Nachdruecken kurz keinen Blattkontakt hat, bekommt ihn so trotzdem.
var _boost_left := 0.0
## Kugel-Kennung -> wie lange sie schon ruhig beim Hebel liegt
var _ruhe := {}
## Welche Kugeln im Moment des Druckens dort lagen.  Nur die gelten als
## bewusst abgeschossen; was danach angeflogen kommt, richtet sich nach der
## tatsaechlichen Blattbewegung.
var _liegend := {}


func _init(left: bool, pivot: Vector2) -> void:
	is_left = left
	position = pivot
	# Flacher Ruhewinkel: die Kugel liegt auf dem Blatt wie auf einem Brett
	# statt sofort zur Spitze zu rutschen, und der Schlag traegt weiter nach
	# oben.  Damit zwischen den Blattspitzen weiterhin eine Kugel durchfaellt,
	# stehen die Drehpunkte entsprechend weiter aussen (siehe table.gd).
	if left:
		rest_deg = 20.0
		pressed_deg = -34.0
	else:
		rest_deg = -20.0
		pressed_deg = 34.0
	rotation = deg_to_rad(rest_deg)
	_target = rotation


func _ready() -> void:
	sync_to_physics = true
	# Absorbierendes Material: die Kugel dopst nicht auf dem Blatt, sondern
	# bleibt liegen und rollt.  Der Schlag kommt allein aus der Drehung.
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.32
	pm.absorbent = true
	pm.friction = 0.7
	physics_material_override = pm
	var col := CollisionPolygon2D.new()
	col.polygon = _shape_points()
	add_child(col)

	# Grafik als eigener Knoten - dreht sich mit dem Koerper mit.
	var art := Node2D.new()
	art.draw.connect(_draw_art.bind(art))
	add_child(art)
	_art = art
	z_index = 5

	# Beruehrungs-Sensor: laesst den Hebel nur bei Ballkontakt aufleuchten
	var area := Area2D.new()
	var acol := CollisionPolygon2D.new()
	var grown := PackedVector2Array()
	for p in _shape_points():
		grown.append(p * 1.18)
	acol.polygon = grown
	area.add_child(acol)
	add_child(area)
	area.body_entered.connect(_on_touch)
	_area = area


func _shape_points() -> PackedVector2Array:
	var base := [Vector2(-14, -13), Vector2(62, -7), Vector2(78, 0), Vector2(62, 7), Vector2(-14, 13), Vector2(-20, 0)]
	if not is_left:
		var mirrored := []
		for p in base:
			mirrored.append(Vector2(-p.x, p.y))
		mirrored.reverse()
		base = mirrored
	return PackedVector2Array(base)


func _draw_art(c: Node2D) -> void:
	var pts := _shape_points()
	var tip := Vector2(TIP_X if is_left else -TIP_X, 0.0)
	var up := Vector2(0, -1)

	# Schlagschatten
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(3, 5))
	c.draw_colored_polygon(shadow, Color(0, 0, 0, 0.65))

	# Koerper: sehr dunkel, innen eine Spur heller
	c.draw_colored_polygon(pts, Color(0.015, 0.020, 0.030))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(Vector2(p.x * 0.88, p.y * 0.52))
	c.draw_colored_polygon(inner, Color(0.080, 0.090, 0.120))

	# Neon-Schein nur bei Ballberuehrung, darauf die pinke Aussenkante
	var closed := pts.duplicate()
	closed.append(pts[0])
	if _flash > 0.0:
		c.draw_polyline(closed, Color(Table.NEON_PINK.r, Table.NEON_PINK.g,
				Table.NEON_PINK.b, 0.30 * _flash), 10.0, true)
	c.draw_polyline(closed, Table.NEON_PINK, 3.0, true)

	# cyanfarbene Linie auf der Oberseite
	c.draw_line(Vector2.ZERO.lerp(tip, 0.16) + up * 8.0,
			Vector2.ZERO.lerp(tip, 0.92) + up * 3.5, Table.NEON_CYAN, 2.0, true)

	# Nieten laengs der Oberseite
	for f in [0.30, 0.52, 0.74]:
		c.draw_circle(Vector2.ZERO.lerp(tip, f) + up * 3.0, 2.0, METAL)

	# Lager: dunkler Kreis, gruener Ring, pinker Kern
	c.draw_circle(Vector2.ZERO, 13.0, Color(0.03, 0.04, 0.05))
	c.draw_arc(Vector2.ZERO, 13.0, 0, TAU, 28, Table.NEON_GREEN, 3.0, true)
	c.draw_circle(Vector2.ZERO, 3.0, Table.NEON_PINK)


func set_pressed(on: bool) -> void:
	var new_target := deg_to_rad(pressed_deg if on else rest_deg)
	if on and new_target != _target:
		Sfx.play("flip", -8.0)
		_boost_left = 0.16
		_liegend.clear()
		for id in _ruhe:
			if float(_ruhe[id]) >= RUHE_ZEIT:
				_liegend[id] = true
	_target = new_target
	_held = on


## Ob die Taste dieses Hebels gerade gedrueckt gehalten wird.
func haelt() -> bool:
	return _held


func _on_touch(body: Node2D) -> void:
	if body is PinBall:
		_flash = 1.0
		_art.queue_redraw()


## Schlag aus dem Stand: alles, was beim Hochschwingen auf dem Blatt liegt,
## bekommt einen Stoss quer zum Blatt.  Die reine Drehung reicht dafuer nicht -
## eine am Ansatz liegende Kugel wuerde kaum wegkommen.  Gibt zurueck, ob eine
## Kugel getroffen wurde.
func _kick_resting_balls() -> bool:
	if _area == null or _target == rotation:
		return false
	# Wie viel Hub steht ueberhaupt noch bevor?  Wer nachdrueckt, waehrend das
	# Blatt fast am Anschlag steht, bewegt es kaum noch - dann darf es auch
	# keinen vollen Schuss geben, sondern die Kugel prallt einfach ab.
	var hub := absf(_target - rotation) / absf(deg_to_rad(pressed_deg - rest_deg))
	var kraft: float = clampf(hub * 1.8, 0.0, 1.0)
	var hit := false
	# Die Kugel geht schraeg nach oben zur Tischmitte weg - links nach rechts
	# oben, rechts nach links oben.  Wie steil, haengt vom Treffpunkt ab.
	# Waere die aktuelle Blattstellung massgeblich, ginge ein Schlag aus dem
	# gehaltenen Hebel seitwaerts in den Slingshot statt nach oben.
	var side := 1.0 if is_left else -1.0
	for b in _area.get_overlapping_bodies():
		var ball := b as PinBall
		if ball == null or ball.freeze:
			continue
		var dist := (ball.global_position - global_position).length()
		# Pass statt Schuss: wenn die Kugel auf dem Lager liegt, oder wenn der
		# andere Hebel oben steht und sie noch im inneren Teil des Blattes ist -
		# dann will man sie offensichtlich drueben auffangen.
		var passen := dist < ARM_PASS or (dist < ARM_PASS_MAX
				and partner != null and partner.haelt())
		var deg := PASS_ANGLE
		var power := PASS_SPEED
		if not passen:
			var reach: float = clampf((dist - ARM_PASS) / (TIP_X - ARM_PASS), 0.0, 1.0)
			deg = lerpf(FLIP_ANGLE_BASE, FLIP_ANGLE_TIP, reach)
			power = FLIP_POWER * lerpf(FLIP_BASE, 1.0, reach)
		# Eine liegende Kugel wird bewusst abgeschossen - die bekommt den vollen
		# Schub, egal wie viel Hub noch bevorsteht.  Nur eine anfliegende Kugel
		# richtet sich nach der tatsaechlichen Blattbewegung, sonst wuerde sie
		# am Anschlag weggeschleudert, als wuerde sich der Hebel bewegen.
		if not _liegend.has(ball.get_instance_id()):
			if kraft < 0.18:
				continue
			power *= kraft
		var push := Vector2(cos(deg_to_rad(deg)) * side, -sin(deg_to_rad(deg)))
		# Nur so viel zugeben, dass die Kugel auf Solltempo kommt - eine
		# schon schnell anfliegende Kugel wird dadurch nicht doppelt beschleunigt
		var have := ball.linear_velocity.dot(push)
		if have < power:
			ball.apply_central_impulse(push * (power - have))
		hit = true
		_flash = 1.0
		_art.queue_redraw()
	return hit


## Buchfuehrung, welche Kugel wie lange ruhig beim Hebel liegt.  Gemessen wird
## ueber die Naehe zum Drehpunkt, nicht ueber die Blattberuehrung: eine
## gefangene Kugel liegt oft in der Kerbe neben der Blattwurzel und wuerde
## sonst nicht als liegend zaehlen.
func _pflege_ruhe(delta: float) -> void:
	var gesehen := {}
	for b in get_tree().get_nodes_in_group("balls"):
		var ball := b as PinBall
		if ball == null or ball.freeze:
			continue
		if ball.global_position.distance_to(global_position) > TIP_X + 26.0:
			continue
		var id := ball.get_instance_id()
		gesehen[id] = true
		if ball.linear_velocity.length() < RUHE_TEMPO:
			_ruhe[id] = minf(float(_ruhe.get(id, 0.0)) + delta, RUHE_ZEIT * 4.0)
		else:
			_ruhe[id] = 0.0
	# Beim Loslassen sackt das Blatt unter der Kugel weg, der Kontakt reisst
	# kurz ab.  Die Ruhezeit darf davon nicht sofort verschwinden, sonst gilt
	# die eigene Cradle-Kugel beim Nachdruecken als Fremdkoerper.  Nach rund
	# einer Zehntelsekunde ohne Blatt ist sie aber weg.
	for id in _ruhe.keys():
		if not gesehen.has(id):
			_ruhe[id] = float(_ruhe[id]) - delta * 3.0
			if float(_ruhe[id]) <= 0.0:
				_ruhe.erase(id)


func _physics_process(delta: float) -> void:
	_pflege_ruhe(delta)
	if _boost_left > 0.0:
		_boost_left = 0.0 if _kick_resting_balls() else _boost_left - delta
	rotation = move_toward(rotation, _target, (SPEED if _held else RETURN_SPEED) * delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		_art.queue_redraw()











