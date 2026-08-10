class_name LaneGate
extends Area2D
## Einweg-Klappe oben in der Abschussbahn: hochgeschossene Baelle passieren,
## zurueckfallende werden ins Spielfeld gelenkt (kein nerviges Neu-Abschiessen).

var _flash := 0.0


func _init(pos: Vector2) -> void:
	position = pos


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 56)
	cs.shape = sh
	add_child(cs)
	z_index = 4


func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()
	for body in get_overlapping_bodies():
		if body is PinBall and not body.freeze and body.linear_velocity.y > 30.0:
			# Kraeftig genug nach oben, dass der Ball die Trennwand-Oberkante
			# (470,300) sicher ueberfliegt - mit dem alten flachen Bogen
			# streifte er aus dem unteren Zonenteil die Kante und fiel
			# zurueck in die Abschussbahn.
			body.linear_velocity = Vector2(minf(-260.0, -absf(body.linear_velocity.y) * 0.8), -230.0)
			Sfx.play("tick", -6.0)
			_flash = 1.0
			queue_redraw()


func _draw() -> void:
	var col := Color(1.1, 0.4, 1.9).lerp(Color(2.0, 2.0, 2.0), _flash)
	draw_line(Vector2(-24, 10), Vector2(24, -2), col, 3.0)
	draw_line(Vector2(-24, 10), Vector2(-14, -14), Color(col.r, col.g, col.b, 0.5), 2.0)
