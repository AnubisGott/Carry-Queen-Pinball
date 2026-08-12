class_name Bumper
extends StaticBody2D
## Pop-Bumper im RGB-Tastatur-Look (W / A / S / D).  `letter` ist die
## Kennung fuer Klang und Kill-Serie, `label` der aufgedruckte Buchstabe -
## normalerweise derselbe.

const RADIUS := 30.0
const KICK := 620.0

var letter := "W"
var label := "W"
var sfx_name := "bump_w"
var _cool := 0.0
var _flash := 0.0
var _repeat := 0
var _repeat_t := 0.0
var marked := false
var _lbl: Label


func _init(pos: Vector2, l: String, aufdruck: String = "") -> void:
	position = pos
	letter = l
	label = aufdruck if aufdruck != "" else l
	sfx_name = "bump_" + l.to_lower()


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = RADIUS
	cs.shape = sh
	add_child(cs)
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.9
	physics_material_override = pm
	var area := Area2D.new()
	var acs := CollisionShape2D.new()
	var ash := CircleShape2D.new()
	ash.radius = RADIUS + 4.0
	acs.shape = ash
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_hit)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.95))
	lbl.position = Vector2(-8, -16)
	add_child(lbl)
	_lbl = lbl
	z_index = 4


## Streak-Markierung: zeigt, dass dieser Bumper in der laufenden
## Kill-Serie schon getroffen wurde (main.gd steuert das).
func set_marked(v: bool) -> void:
	if marked == v:
		return
	marked = v
	_lbl.add_theme_color_override("font_color",
			Color(1.5, 1.1, 0.3) if marked else Color(0.9, 1.0, 0.95))
	queue_redraw()


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	_repeat_t = maxf(0.0, _repeat_t - delta)
	if _repeat_t <= 0.0:
		_repeat = 0
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 4.0)
		queue_redraw()


func _draw() -> void:
	var glow := Color(0.35, 1.5, 0.22) if _flash > 0.0 else Color(0.2, 0.95, 0.14)
	draw_circle(Vector2.ZERO, RADIUS + 5.0, Color(glow.r, glow.g, glow.b, 0.10 + 0.3 * _flash))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.05, 0.09, 0.05).lerp(Color(0.2, 0.5, 0.2), _flash))
	draw_arc(Vector2.ZERO, RADIUS - 1.0, 0.0, TAU, 40, glow, 3.0)
	draw_arc(Vector2.ZERO, RADIUS - 8.0, 0.0, TAU, 40, Color(glow.r, glow.g, glow.b, 0.5), 1.5)
	if marked:
		draw_arc(Vector2.ZERO, RADIUS - 14.0, 0.0, TAU, 32, Color(1.3, 0.95, 0.25, 0.9), 2.5)


func _on_hit(body: Node2D) -> void:
	if not body is PinBall or _cool > 0.0:
		return
	_cool = 0.08
	_flash = 1.0
	var dir := (body.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	# Kleine seitliche Streuung: verhindert endloses Senkrecht-Pingpong
	# zwischen Bumper und Bogendecke (z.B. in einer Gassen-Mündung)
	dir = (dir + Vector2(randf_range(-0.22, 0.22), 0.0)).normalized()
	# Schnelle Wiederholungs-Treffer werden schwaecher: ein Dauer-Zyklus
	# zwischen Bumper und Decke verliert so Energie und bricht von selbst ab
	if _repeat_t > 0.0:
		_repeat += 1
	else:
		_repeat = 1
	_repeat_t = 1.1
	var kick := maxf(KICK * pow(0.72, _repeat - 1), 140.0)
	body.apply_central_impulse(dir * kick)
	Sfx.play(sfx_name, -6.0)
	Game.add_score(150, body)
	Game.emit("bumper", {"letter": letter})
	queue_redraw()
