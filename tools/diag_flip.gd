extends Node
## Diagnose: laesst eine Kugel auf dem ruhenden linken Flipper zur Ruhe kommen
## und schlaegt aus dem Stand.  Gemessen werden Tempo, hoechster Punkt und wo
## die Kugel eine halbe Sekunde spaeter ist.  Zum Vergleich: die G-G-E-Z-Gassen
## liegen bei y = 212, die Bumper bei y = 300.
##   godot --headless --path . res://tools/diag_flip.tscn [-- --cradle]

const MAIN := preload("res://scenes/main.tscn")
const PIVOT := Vector2(160, 866)

## Ablagen: Inlane (rollt von selbst aufs Blatt), Blattmitte, Blattspitze
const DROPS := [
	["Inlane", Vector2(100, 700)],
	["Blattmitte", Vector2(205, 830)],
	["Blattspitze", Vector2(235, 840)],
]

var _cradle := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--cradle":
			_cradle = true
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	for d in DROPS:
		await _one_flip(main, d[0], d[1])
	get_tree().quit()


func _one_flip(main: Node2D, name: String, drop: Vector2) -> void:
	var ball := PinBall.new()
	ball.position = drop
	main.add_child(ball)
	if _cradle:
		# Hebel oben halten: die Kugel sammelt sich am Blattansatz
		Input.action_press("flip_left")
	# zur Ruhe kommen lassen
	var still := 0
	for i in 420:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			print("%-12s: Kugel ging verloren, bevor sie lag" % name)
			Input.action_release("flip_left")
			return
		if ball.linear_velocity.length() < 15.0:
			still += 1
			if still > 20:
				break
		else:
			still = 0
	var rest := ball.global_position
	var arm := rest - PIVOT
	Input.action_release("flip_left")
	await get_tree().physics_frame
	Input.action_press("flip_left")
	var vmax := 0.0
	var top := rest.y
	var after := rest
	for i in 300:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		vmax = maxf(vmax, ball.linear_velocity.length())
		top = minf(top, ball.global_position.y)
		if i == 60:
			after = ball.global_position
	Input.action_release("flip_left")
	print("%-12s: Ablage (%.0f,%.0f) Arm %.0f px -> Tempo %.0f px/s, hoechster Punkt y=%.0f, nach 0.5s (%.0f,%.0f)" % [
			name, rest.x, rest.y, arm.length(), vmax, top, after.x, after.y])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.4).timeout
