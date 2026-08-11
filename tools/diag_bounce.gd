extends Node2D
## Diagnose: laesst eine Kugel auf das ruhende Flipperblatt fallen und misst,
## wie stark sie zurueckspringt.
##   godot --headless --path . res://tools/diag_bounce.tscn -- <x> <y>

var _start := Vector2(200, 760)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_start = Vector2(float(args[0]), float(args[1]))
	Table.build(self)
	var b := PinBall.new()
	b.position = _start
	add_child(b)
	_run(b)


func _run(b: PinBall) -> void:
	var touched := false
	var rebound := 0.0
	var fall := 0.0
	for i in 300:
		await get_tree().physics_frame
		if not is_instance_valid(b):
			break
		var vy := b.linear_velocity.y
		if not touched:
			fall = maxf(fall, vy)
			if b.get_contact_count() > 0 or vy < fall - 50.0:
				touched = true
		else:
			rebound = maxf(rebound, -vy)
	print("START %s  Fallgeschwindigkeit=%.0f  Rueckprall nach oben=%.0f" % [
			_start, fall, rebound])
	get_tree().quit()
