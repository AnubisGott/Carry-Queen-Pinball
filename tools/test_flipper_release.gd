extends Node2D
## Testfall (Regression): Eine Kugel, die auf dem angehobenen rechten
## Flipper zur Ruhe gekommen ist, muss beim Loslassen ins Rollen kommen.
## Vorher blieb sie schlafend in der Luft haengen (RigidBody2D-Sleep).
## Aufruf:  godot --headless --path . res://tools/test_flipper_release.tscn

const MOVE_MIN := 30.0


func _ready() -> void:
	# Nachbau der Spielsituation: rechter Flipper + Inlane-Leiste
	var f := Flipper.new(false, Vector2(330, 850))
	add_child(f)
	f.set_pressed(true)
	Table._bar(self, Vector2(410, 700), Vector2(339, 834), Color(0.25, 0.95, 0.18))
	var b := PinBall.new()
	b.position = Vector2(322, 790)
	add_child(b)
	_run(f, b)


func _run(f: Flipper, b: PinBall) -> void:
	# Kugel auf dem gehobenen Hebel zur Ruhe kommen lassen
	await get_tree().create_timer(2.5).timeout
	var rest_pos := b.global_position
	var rest_speed := b.linear_velocity.length()
	f.set_pressed(false)
	await get_tree().create_timer(1.5).timeout
	var moved := b.global_position.distance_to(rest_pos)
	print("TEST flipper-release: ruhe=%s v=%.1f bewegt=%.1f" % [rest_pos, rest_speed, moved])
	if moved > MOVE_MIN:
		print("TEST RESULT: PASS")
		get_tree().quit(0)
	else:
		print("TEST RESULT: FAIL (Kugel rollt nach dem Loslassen nicht los)")
		get_tree().quit(1)
