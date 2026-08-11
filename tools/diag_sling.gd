extends Node2D
## Diagnose: laesst eine Kugel auf die Schlagflaeche eines Slingshots fallen
## und meldet, ob der Abstoss ausgeloest hat.
##   godot --headless --path . res://tools/diag_sling.tscn -- <x> <y>

var _hits := 0
var _start := Vector2(137, 650)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_start = Vector2(float(args[0]), float(args[1]))
	Table.build(self)
	Game.event.connect(_on_event)
	var b := PinBall.new()
	b.position = _start
	add_child(b)
	_run(b)


func _on_event(kind: String, _data: Dictionary) -> void:
	if kind == "sling":
		_hits += 1


func _run(b: PinBall) -> void:
	var vmax := 0.0
	for i in 240:
		await get_tree().physics_frame
		if is_instance_valid(b):
			vmax = maxf(vmax, b.linear_velocity.length())
	print("START %s -> Sling-Events=%d  vmax=%.0f  Endpos=%s" % [
			_start, _hits, vmax, b.global_position])
	get_tree().quit()
