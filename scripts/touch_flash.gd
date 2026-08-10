class_name TouchFlash
extends Area2D
## Laesst die Leuchtschichten eines Banden-Elements bei Ballberuehrung kurz
## hell neon aufblitzen und wieder abklingen.

var _layers: Array = []
var _tw: Tween


func _init(pts: Array, radius: float = 6.0) -> void:
	monitorable = false
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var cs := CollisionShape2D.new()
		var cap := CapsuleShape2D.new()
		cap.radius = radius
		cap.height = a.distance_to(b) + radius * 2.0
		cs.shape = cap
		cs.position = (a + b) * 0.5
		cs.rotation = (b - a).angle() - PI / 2.0
		add_child(cs)


## Registriert eine Leuchtschicht, die beim Blitz mit hochgezogen wird.
## Ohne `flash_color` gilt die Standard-Formel (_boost), sonst exakt der Wert.
func watch(line: Line2D, flash_color = null) -> void:
	_layers.append({"line": line, "color": line.default_color,
			"width": line.width, "flash": flash_color})


func _ready() -> void:
	body_entered.connect(_on_touch)


func _on_touch(body: Node2D) -> void:
	if not body is PinBall:
		return
	if _tw:
		_tw.kill()
	for l in _layers:
		var line: Line2D = l["line"]
		line.default_color = l["flash"] if l["flash"] != null else _boost(l["color"])
		line.width = l["width"] * 1.6
	_tw = create_tween().set_parallel(true)
	for l in _layers:
		_tw.tween_property(l["line"], "default_color", l["color"], 0.45)
		_tw.tween_property(l["line"], "width", l["width"], 0.45)


func _boost(c: Color) -> Color:
	return Color(c.r * 2.2 + 0.25, c.g * 2.2 + 0.25, c.b * 2.2 + 0.25,
			minf(1.0, c.a * 2.5 + 0.15))
