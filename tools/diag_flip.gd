extends Node
## Diagnose: laesst eine Kugel auf dem ruhenden linken Flipper zur Ruhe kommen
## und schlaegt aus dem Stand.  Gemessen werden Tempo, hoechster Punkt und wo
## die Kugel eine halbe Sekunde spaeter ist.  Zum Vergleich: die G-G-E-Z-Gassen
## liegen bei y = 212, die Bumper bei y = 300.
##   godot --headless --path . res://tools/diag_flip.tscn [-- --cradle]

const MAIN := preload("res://scenes/main.tscn")
const PIVOT := Vector2(156, 866)

## Ablagen: [Name, Ort, erst zur Ruhe kommen lassen?].  Auf dem gehaltenen
## Hebel rutscht die Kugel immer zum Ansatz - Blattmitte und Spitze werden
## deshalb direkt aufgelegt und sofort geschlagen.
const DROPS := [
	["Inlane", Vector2(100, 700), true],
	["Blattmitte", Vector2(186, 821), false],
	["Blattspitze", Vector2(203, 811), false],
]

var _cradle := false
var _right := false
## Anderen Hebel oben halten - damit wird der Pass angefordert
var _pass := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--cradle":
			_cradle = true
		elif a == "--right":
			_right = true
		elif a == "--pass":
			_pass = true
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	for d in DROPS:
		# Der Tisch ist spiegelsymmetrisch: x' = 490 - x
		var pos: Vector2 = d[1] if not _right else Vector2(490.0 - d[1].x, d[1].y)
		await _one_flip(main, d[0], pos, d[2])
	get_tree().quit()


func _key() -> String:
	return "flip_right" if _right else "flip_left"


func _one_flip(main: Node2D, name: String, drop: Vector2, settle: bool) -> void:
	var ball := PinBall.new()
	ball.position = drop
	main.add_child(ball)
	if _cradle or not settle:
		# Hebel oben halten: die Kugel sammelt sich am Blattansatz
		Input.action_press(_key())
	# zur Ruhe kommen lassen
	var still := 0
	for i in (420 if settle else 6):
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			print("%-12s: Kugel ging verloren, bevor sie lag" % name)
			Input.action_release(_key())
			return
		if not settle:
			continue
		if ball.linear_velocity.length() < 15.0:
			still += 1
			if still > 20:
				break
		else:
			still = 0
	var rest := ball.global_position
	var arm := rest - (PIVOT if not _right else Vector2(490.0 - PIVOT.x, PIVOT.y))
	Input.action_release(_key())
	if _pass:
		Input.action_press("flip_left" if _right else "flip_right")
	await get_tree().create_timer(0.05).timeout
	Input.action_press(_key())
	var vmax := 0.0
	var top := rest
	var after := rest
	var landung := rest
	for i in 300:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		vmax = maxf(vmax, ball.linear_velocity.length())
		if ball.global_position.y < top.y:
			top = ball.global_position
		if i == 60:
			after = ball.global_position
		if i == 108:
			landung = ball.global_position
	Input.action_release(_key())
	if _pass:
		Input.action_release("flip_left" if _right else "flip_right")
	print("%-12s: Ablage (%.0f,%.0f) Arm %.0f px -> Tempo %.0f px/s, hoechster Punkt (%.0f,%.0f), nach 0.5s (%.0f,%.0f), nach 0.9s (%.0f,%.0f)" % [
			name, rest.x, rest.y, arm.length(), vmax, top.x, top.y, after.x, after.y,
			landung.x, landung.y])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.4).timeout


