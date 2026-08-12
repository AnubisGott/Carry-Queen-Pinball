extends Node
## Diagnose: laedt die Feder mehrfach gleich lang und misst die tatsaechliche
## Abschussgeschwindigkeit - zeigt, wie gleichmaessig der Abschuss ist.
##   godot --headless --path . res://tools/diag_launch.tscn -- <ladezeit>

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _hold := 1.5


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			_hold = float(a)
	_main = MAIN.instantiate()
	add_child(_main)
	# God-Modus: nach jedem Versuch kommt sofort eine neue Kugel
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	print("Ladezeit %.2f s (voll ab 1.25 s)" % _hold)
	for i in 6:
		await _one_launch(i + 1)
	get_tree().quit()


func _lane_ball() -> PinBall:
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and b.global_position.y > 780.0:
			return b
	return null


func _one_launch(nr: int) -> void:
	# Warten, bis wieder eine Kugel auf der Feder liegt
	var ball: PinBall = null
	for i in 400:
		ball = _lane_ball()
		if ball != null and ball.linear_velocity.length() < 20.0:
			break
		await get_tree().physics_frame
	if ball == null:
		print("  Versuch %d: keine Kugel in der Bahn" % nr)
		return
	Input.action_press("launch")
	await get_tree().create_timer(_hold).timeout
	var charge: float = _main.charge
	Input.action_release("launch")
	var vmax := 0.0
	for i in 60:
		await get_tree().physics_frame
		if is_instance_valid(ball):
			vmax = maxf(vmax, -ball.linear_velocity.y)
	print("  Versuch %d: Ladung %.2f -> Abschuss %.0f px/s" % [nr, charge, vmax])
	# Kugel nach unten aus dem Feld setzen - der normale Ballverlust legt
	# dann (dank God-Modus) sofort eine neue auf die Feder.
	if is_instance_valid(ball):
		ball.global_position = Vector2(245, 1200)
	await get_tree().create_timer(1.2).timeout
