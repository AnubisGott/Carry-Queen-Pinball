extends Node2D
## Diagnose-Werkzeug: setzt eine Kugel an eine verdaechtige Stelle und meldet
## nach ein paar Sekunden, ob sie liegen geblieben ist und welche Koerper sie
## dabei beruehrt.  Aufruf:
##   godot --headless --path . res://tools/diag_stuck.tscn -- <x> <y>

var _start := Vector2(417, 760)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_start = Vector2(float(args[0]), float(args[1]))
	Table.build(self)
	var b := PinBall.new()
	b.position = _start
	b.contact_monitor = true
	b.max_contacts_reported = 8
	add_child(b)
	_run(b)


func _run(b: PinBall) -> void:
	await get_tree().create_timer(5.0).timeout
	print("START %s -> POS %s  v=%.1f" % [_start, b.global_position,
			b.linear_velocity.length()])
	if b.linear_velocity.length() < 10.0:
		print("  ERGEBNIS: LIEGT FEST")
		for c in b.get_colliding_bodies():
			var nm: String = c.name
			if c.get_parent() != null:
				nm = "%s / Kind von %s" % [nm, c.get_parent().name]
			print("  beruehrt: %s  Klasse=%s  pos=%s" % [nm, c.get_class(),
					c.global_position])
			for ch in c.get_children():
				if ch is CollisionShape2D and ch.shape is SegmentShape2D:
					var sh: SegmentShape2D = ch.shape
					print("      Segment %s -> %s" % [sh.a, sh.b])
				elif ch is CollisionShape2D:
					print("      Shape %s @ %s" % [ch.shape, ch.position])
				elif ch is CollisionPolygon2D:
					print("      Polygon %s" % [ch.polygon])
	else:
		print("  ERGEBNIS: rollt weiter")
	get_tree().quit()
