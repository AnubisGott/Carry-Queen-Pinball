extends Node2D
## Diagnose: Kugel auf dem angehobenen Flipper einfangen, dann loslassen und
## messen, ob sie dabei einen Huepfer macht.
##   godot --headless --path . res://tools/diag_trap.tscn

var _fl: Flipper


func _ready() -> void:
	var refs := Table.build(self)
	_fl = refs["flipper_l"]
	_fl.set_pressed(true)
	var b := PinBall.new()
	b.position = Vector2(200, 780)
	add_child(b)
	_run(b)


func _run(b: PinBall) -> void:
	# Kugel auf dem gehobenen Blatt zur Ruhe kommen lassen
	for i in 360:
		await get_tree().physics_frame
	var rest_y := b.global_position.y
	var rest_v := b.linear_velocity.length()
	_fl.set_pressed(false)
	var hop := 0.0
	var rise := 0.0
	for i in 120:
		await get_tree().physics_frame
		hop = maxf(hop, -b.linear_velocity.y)
		rise = maxf(rise, rest_y - b.global_position.y)
	print("Ruhe bei y=%.1f (v=%.1f) -> nach dem Loslassen: Huepfer %.0f px/s, %.1f px hoch" % [
			rest_y, rest_v, hop, rise])
	get_tree().quit()
