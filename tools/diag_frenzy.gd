extends Node
## Diagnose: raeumt die DAMAGE-Bank ab, wartet die Frenzy aus und prueft, ob
## die Targets danach wieder dunkel (also erneut abraeumbar) sind.
##   godot --headless --path . res://tools/diag_frenzy.tscn

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	_report("vor dem Abraeumen", main)
	# Bank abraeumen wie im Spiel: jedes Target einzeln ausloesen
	var ball := PinBall.new()
	ball.position = Vector2(-500, -500)
	main.add_child(ball)
	for d in main.drops:
		d._on_hit(ball)
		await get_tree().physics_frame
	await get_tree().create_timer(0.4).timeout
	_report("waehrend der Frenzy", main)
	await get_tree().create_timer(main.FRENZY_TIME + 1.0).timeout
	_report("nach der Frenzy", main)
	get_tree().quit()


func _report(phase: String, main: Node2D) -> void:
	var down := 0
	var pulsing := 0
	for d in main.drops:
		if d.dropped:
			down += 1
		if d.pulsing:
			pulsing += 1
	print("%-22s gefallen=%d/6  blinkend=%d  Frenzy=%s" % [phase, down, pulsing,
			str(Game.frenzy)])
