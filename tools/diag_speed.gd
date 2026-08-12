extends Node
## Diagnose: misst, wie schnell die Kugel im laufenden Spiel wird.  Zaehlt,
## wie viel Zeit sie oberhalb einzelner Tempostufen verbringt, und meldet die
## Spitzenwerte samt Ort.  Gespielt wird mit Zufallsflippern wie im Autotest.
##   godot --headless --path . res://tools/diag_speed.tscn [-- <Sekunden>]

const MAIN := preload("res://scenes/main.tscn")
const STUFEN := [800.0, 1200.0, 1600.0, 2000.0, 2400.0]

var _dauer := 90.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			_dauer = float(a)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	await get_tree().create_timer(1.0).timeout

	var frames := 0
	var ueber := [0, 0, 0, 0, 0]
	var vmax := 0.0
	var wo := Vector2.ZERO
	var t := 0.0
	var flip_t := 0.0
	while t < _dauer:
		await get_tree().physics_frame
		t += 1.0 / 120.0
		# Zufallsflipper wie im Autotest
		flip_t -= 1.0 / 120.0
		if flip_t <= 0.0:
			flip_t = 0.35
			_setze("flip_left", randf() < 0.5)
			_setze("flip_right", randf() < 0.5)
			# Feder abwechselnd spannen und loslassen, sonst startet nie ein Ball
			_setze("launch", randf() < 0.5)
		for b in get_tree().get_nodes_in_group("balls"):
			var v: float = b.linear_velocity.length()
			frames += 1
			for i in STUFEN.size():
				if v > STUFEN[i]:
					ueber[i] += 1
			if v > vmax:
				vmax = v
				wo = b.global_position
	Input.action_release("flip_left")
	Input.action_release("flip_right")
	Input.action_release("launch")

	print("Messdauer %.0f s, %d Kugel-Bilder" % [_dauer, frames])
	for i in STUFEN.size():
		print("  ueber %5.0f px/s: %5.1f %% der Zeit" % [
				STUFEN[i], 100.0 * float(ueber[i]) / maxf(1.0, float(frames))])
	print("Spitze: %.0f px/s bei (%.0f,%.0f)" % [vmax, wo.x, wo.y])
	get_tree().quit()


func _setze(aktion: String, an: bool) -> void:
	if an:
		Input.action_press(aktion)
	else:
		Input.action_release(aktion)
