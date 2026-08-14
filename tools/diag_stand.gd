extends Node
## Schuss aus dem Stand: haengt die Richtung wirklich davon ab, wo die Kugel
## auf dem Blatt liegt?
##
## Der Spieler laesst die Kugel bis zur Spitze rollen, um weit nach rechts zu
## kommen, und schlaegt schon bei der Haelfte, um senkrecht hochzukommen.
## Gemessen wird deshalb fuer mehrere Auflagepunkte, wo die Kugel oben
## ankommt - auf Hoehe der Bumper (y = 505) und an den G-G-E-Z-Gassen
## (y = 212).
##   godot --headless --path . res://tools/diag_stand.tscn

const MAIN := preload("res://scenes/main.tscn")

## Drehpunkt und Blattlaenge des linken Hebels (table.gd, flipper.gd)
const PIVOT := Vector2(156, 866)
const BLATT := 78.0
## Hoehen, auf denen gemessen wird
const H_BUMPER := 505.0
const H_GASSEN := 212.0
## Soll laut Zeichnung: bei halbem Blatt senkrecht hoch (x = 220 auf
## Bumperhoehe), an der Spitze weit nach rechts (x = 443).
const SOLL_MITTE := 220.0
const SOLL_SPITZE := 443.0

var _main: Node2D
## Was die Kugel auf ihrem Weg beruehrt hat
var _getroffen := []


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout

	print("--- linker Hebel, Kugel an verschiedenen Stellen des Blattes ---")
	print("  %-6s %-7s %-18s %-8s %-12s %s" % ["Anteil", "Abstand", "Abschuss v",
			"Winkel", "x bei y=505", "x bei y=212"])
	var ergebnis := []
	for anteil in [0.25, 0.4, 0.5, 0.6, 0.75, 0.9, 1.0]:
		ergebnis.append(await _schuss(anteil))

	print("--- was kaeme durch, wenn die Richtung stimmt? ---")
	# Unabhaengig vom Hebel: eine Kugel mit gesetzter Geschwindigkeit vom
	# Blatt aus losschicken.  So trennt sich die Frage "welchen Winkel gibt
	# der Hebel?" von der Frage "welcher Winkel passt ueberhaupt durch?".
	print("  %-8s %-12s %-12s %s" % ["Winkel", "x bei y=505", "x bei y=212", "beruehrt"])
	for grad in [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0]:
		await _freier_schuss(grad)

	print("--- Soll ---")
	print("  bei halbem Blatt senkrecht hoch: x bei y=505 nahe %.0f" % SOLL_MITTE)
	print("  an der Spitze weit nach rechts:  x bei y=505 nahe %.0f" % SOLL_SPITZE)
	var mitte := _naechster(ergebnis, 0.5)
	var spitze := _naechster(ergebnis, 1.0)
	var spanne_ist: float = _grenze(ergebnis, true) - _grenze(ergebnis, false)
	var spanne_soll: float = SOLL_SPITZE - SOLL_MITTE
	print("--- Ergebnis ---")
	print("  halbes Blatt: x=%.0f (Soll %.0f, Abweichung %.0f)"
			% [mitte, SOLL_MITTE, absf(mitte - SOLL_MITTE)])
	print("  Spitze:       x=%.0f (Soll %.0f, Abweichung %.0f)"
			% [spitze, SOLL_SPITZE, absf(spitze - SOLL_SPITZE)])
	print("  ueberstrichene Spanne: %.0f px, gebraucht werden %.0f px"
			% [spanne_ist, spanne_soll])
	var ok: bool = absf(mitte - SOLL_MITTE) < 60.0 and absf(spitze - SOLL_SPITZE) < 60.0
	print("  %s" % ["ok - der Faecher wird abgedeckt" if ok
			else "FEHL - der Faecher wird nicht abgedeckt"])
	get_tree().quit(0 if ok else 1)


## Ein Schuss aus dem Stand.  Rueckgabe: [Anteil, x auf Bumperhoehe].
func _schuss(anteil: float) -> Array:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().physics_frame
	Input.action_release("flip_left")
	# Auf das ruhende Blatt legen: Punkt auf der Blattachse, dann quer nach
	# oben um Kugelradius plus halbe Blattdicke.
	var achse := Vector2.RIGHT.rotated(deg_to_rad(_main.flipper_l.rest_deg))
	var quer := achse.rotated(-PI / 2.0)
	var ball: PinBall = _main._spawn_ball(PIVOT + achse * (anteil * BLATT) + quer * 20.0)
	ball.linear_velocity = Vector2.ZERO
	# Nur kurz setzen lassen - laenger, und sie rollt zur Spitze, dann misst
	# man nicht mehr die gewaehlte Stelle.
	for i in 12:
		await get_tree().physics_frame
	var abstand: float = (ball.global_position - PIVOT).length()
	# Ueber die Eingabe, nicht ueber den Hebel: main setzt ihn in jedem
	# Physikbild aus der Tastatur neu, ein direktes set_pressed() waere im
	# naechsten Bild wieder weg.
	Input.action_press("flip_left")

	var v_ab := Vector2.ZERO
	var x505 := 0.0
	var x212 := 0.0
	var hoch := Vector2(0, 9999)
	_getroffen.clear()
	for i in 400:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		# Hoechster Punkt: zeigt, wo eine Kugel haengen bleibt, die es nicht
		# bis nach oben schafft.
		if ball.global_position.y < hoch.y:
			hoch = ball.global_position
		# Woran sie unterwegs stoesst - sonst raet man, warum ein Schuss
		# stecken bleibt.
		if v_ab != Vector2.ZERO and ball.global_position.y < 840.0:
			for k in ball.get_colliding_bodies():
				var n := k.get_class() if k.get_script() == null \
						else str(k.get_script().resource_path.get_file().get_basename())
				if not n in _getroffen:
					_getroffen.append(n)
		# Abschusstempo: erster Messwert, sobald die Kugel das Blatt verlassen
		# hat und wirklich nach oben unterwegs ist
		if v_ab == Vector2.ZERO and ball.global_position.y < 820.0 \
				and ball.linear_velocity.y < -100.0:
			v_ab = ball.linear_velocity
		if x505 == 0.0 and ball.global_position.y <= H_BUMPER:
			x505 = ball.global_position.x
		if x212 == 0.0 and ball.global_position.y <= H_GASSEN:
			x212 = ball.global_position.x
			break
		if i > 60 and ball.linear_velocity.y > 0.0 and ball.global_position.y > 820.0:
			break
	Input.action_release("flip_left")
	var winkel := 0.0
	if v_ab != Vector2.ZERO:
		# Winkel gegen die Senkrechte, positiv nach rechts
		winkel = rad_to_deg(atan2(v_ab.x, -v_ab.y))
	print("  %-6.2f %5.0f   (%5.0f,%6.0f)  %5.1f Grad %8s %13s   hoechstens (%.0f,%.0f)"
			% [anteil, abstand, v_ab.x, v_ab.y, winkel,
			"%.0f" % x505 if x505 > 0.0 else "-",
			"%.0f" % x212 if x212 > 0.0 else "-", hoch.x, hoch.y])
	if not _getroffen.is_empty():
		print("         unterwegs beruehrt: %s" % ", ".join(PackedStringArray(_getroffen)))
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.3).timeout
	return [anteil, x505]


## Kugel mit gesetzter Geschwindigkeit vom Blatt aus - misst die Geometrie,
## nicht den Hebel.  Tempo wie beim gemessenen Standschuss (rund 1450 px/s).
func _freier_schuss(grad: float) -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().physics_frame
	var achse := Vector2.RIGHT.rotated(deg_to_rad(_main.flipper_l.rest_deg))
	var quer := achse.rotated(-PI / 2.0)
	var start: Vector2 = PIVOT + achse * (0.7 * BLATT) + quer * 22.0
	var ball: PinBall = _main._spawn_ball(start)
	ball.linear_velocity = Vector2(sin(deg_to_rad(grad)), -cos(deg_to_rad(grad))) * 1450.0
	var x505 := 0.0
	var x212 := 0.0
	_getroffen.clear()
	for i in 300:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		for k in ball.get_colliding_bodies():
			var n := k.get_class() if k.get_script() == null \
					else str(k.get_script().resource_path.get_file().get_basename())
			if not n in _getroffen:
				_getroffen.append(n)
		if x505 == 0.0 and ball.global_position.y <= H_BUMPER:
			x505 = ball.global_position.x
		if ball.global_position.y <= H_GASSEN:
			x212 = ball.global_position.x
			break
		if ball.linear_velocity.y > 0.0 and ball.global_position.y > 700.0:
			break
	print("  %5.0f    %10s   %10s   %s" % [grad,
			"%.0f" % x505 if x505 > 0.0 else "-",
			"%.0f" % x212 if x212 > 0.0 else "-",
			", ".join(PackedStringArray(_getroffen)) if not _getroffen.is_empty() else "nichts"])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.2).timeout


func _naechster(liste: Array, anteil: float) -> float:
	var best := 0.0
	var abstand := 99.0
	for e in liste:
		if absf(float(e[0]) - anteil) < abstand and float(e[1]) > 0.0:
			abstand = absf(float(e[0]) - anteil)
			best = float(e[1])
	return best


func _grenze(liste: Array, oben: bool) -> float:
	var wert := 0.0 if oben else 9999.0
	for e in liste:
		var x := float(e[1])
		if x <= 0.0:
			continue
		wert = maxf(wert, x) if oben else minf(wert, x)
	return wert
