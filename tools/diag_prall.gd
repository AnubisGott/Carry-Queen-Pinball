extends Node
## Diagnose: schiesst eine Kugel auf den ruhenden, ganz ausgefahrenen linken
## Flipper und vergleicht Eingang mit Ausgang.  Erwartet wird ein Abprall -
## Ausgangstempo hoechstens so gross wie das Eingangstempo, Einfallswinkel
## gleich Ausfallswinkel.  Gibt der Hebel Schwung dazu, faellt das hier auf.
##   godot --headless --path . res://tools/diag_prall.tscn [-- --nachdruecken]

const MAIN := preload("res://scenes/main.tscn")
## Anflug: [Name, Startpunkt, Anfangstempo]
const ANFLUEGE := [
	["senkrecht auf Blattmitte", Vector2(196, 700), Vector2(0, 700)],
	["schraeg auf Blattmitte", Vector2(150, 700), Vector2(400, 620)],
	["senkrecht auf Spitze", Vector2(215, 700), Vector2(0, 700)],
	["schraeg auf Spitze", Vector2(180, 690), Vector2(220, 700)],
]

var _nachdruecken := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--nachdruecken":
			_nachdruecken = true
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	for a in ANFLUEGE:
		await _wurf(main, a[0], a[1], a[2])
	get_tree().quit()


func _wurf(main: Node2D, name: String, start: Vector2, v0: Vector2) -> void:
	# Hebel ganz hochziehen und stehen lassen - er ist damit in Ruhe
	Input.action_press("flip_left")
	await get_tree().create_timer(1.0).timeout

	var ball := PinBall.new()
	ball.position = start
	main.add_child(ball)
	ball.linear_velocity = v0

	var v_ein := v0
	var v_aus := Vector2.ZERO
	var beruehrt := false
	for i in 180:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		var v: Vector2 = ball.linear_velocity
		if not beruehrt:
			# Umkehr der Bewegungsrichtung nach oben = Treffer.  Das Tempo
			# davor ist der Eingang, das danach der Ausgang.
			if v.y < -20.0:
				beruehrt = true
				v_aus = v
			else:
				v_ein = v
			if beruehrt and _nachdruecken:
				# Genau im Treffermoment neu druecken - so spielt man
				# wirklich, und hier faellt ein zu grosszuegiger Schub auf.
				Input.action_release("flip_left")
				await get_tree().create_timer(0.03).timeout
				Input.action_press("flip_left")
				await get_tree().create_timer(0.06).timeout
				if is_instance_valid(ball):
					v_aus = ball.linear_velocity
		else:
			break
	Input.action_release("flip_left")
	if beruehrt:
		print("%-24s: ein %4.0f px/s (%3.0f Grad) -> aus %4.0f px/s (%3.0f Grad)  Faktor %.2f" % [
				name, v_ein.length(), rad_to_deg(v_ein.angle()),
				v_aus.length(), rad_to_deg(v_aus.angle()),
				v_aus.length() / maxf(1.0, v_ein.length())])
	else:
		print("%-24s: kein Treffer" % name)
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.5).timeout
