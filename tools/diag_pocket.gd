extends Node
## Diagnose der Fang-Mulden: laesst eine Kugel die Seitenbahn herunterrollen
## und meldet, mit welcher Geschwindigkeit sie an der Mulde ankommt und ob
## sie gefangen wurde.
##   godot --headless --path . res://tools/diag_pocket.tscn

const MAIN := preload("res://scenes/main.tscn")
## Muldenmitte laut table.gd
const MULDE_Y := 612.0
## [Name, Startpunkt, Anfangstempo].  Weiter oben als y=250 liegt links schon
## der Bogen - eine schnell ankommende Kugel wird deshalb ueber ein
## Anfangstempo nachgestellt statt ueber einen hoeheren Startpunkt.
const LAEUFE := [
	["links, von oben", Vector2(52, 380), Vector2.ZERO],
	["links, hoch oben", Vector2(52, 250), Vector2.ZERO],
	["links, mit Schwung", Vector2(52, 420), Vector2(0, 700)],
	# Volles Tempo: nach einem Schuss die Bahn hinauf faellt die Kugel mit
	# Hoechstgeschwindigkeit wieder herunter.
	["links, volles Tempo", Vector2(52, 420), Vector2(0, 1400)],
	# Schraeg herunter statt senkrecht.  Der Anlauf zeigt zur Mulde hin -
	# schraeg von ihr weg gestartet, kommt die Kugel gar nicht erst an ihr
	# vorbei, dann misst man nichts.
	["links, schraeg von innen", Vector2(76, 470), Vector2(-300, 760)],
	["rechts, von oben", Vector2(438, 380), Vector2.ZERO],
	["rechts, hoch oben", Vector2(438, 250), Vector2.ZERO],
	["rechts, mit Schwung", Vector2(438, 420), Vector2(0, 700)],
	["rechts, volles Tempo", Vector2(438, 420), Vector2(0, 1400)],
	["rechts, schraeg von innen", Vector2(414, 470), Vector2(300, 760)],
	# Langsam ankommend: kurz oberhalb der Mulde losgelassen, damit die Kugel
	# gar nicht erst Tempo aufnimmt.  Genau das wurde beim Spielen gemeldet -
	# eine gemaechlich herunterrollende Kugel rollte durch.
	["links, langsam", Vector2(52, 560), Vector2.ZERO],
	["links, sehr langsam", Vector2(52, 592), Vector2.ZERO],
	["links, kriechend", Vector2(52, 604), Vector2(0, 20)],
	["rechts, langsam", Vector2(438, 560), Vector2.ZERO],
	["rechts, sehr langsam", Vector2(438, 592), Vector2.ZERO],
	["rechts, kriechend", Vector2(438, 604), Vector2(0, 20)],
]

var _gefangen := false


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	main.god_mode = true
	Game.event.connect(_on_event)
	await get_tree().create_timer(1.0).timeout
	var durch := []
	for l in LAEUFE:
		if not await _lauf(main, l[0], l[1], l[2]):
			durch.append(l[0])
	print("--- Ergebnis ---")
	# Jede Kugel, die von oben in die Schale kommt, gehoert hinein - egal wie
	# schnell.  Eine Tempogrenze gab es hier zweimal, beide Male falsch.
	print("  %d von %d Anfahrten gefangen" % [LAEUFE.size() - durch.size(), LAEUFE.size()])
	if durch.is_empty():
		print("  ok - keine rollt durch")
	else:
		print("  FEHL durchgerollt: %s" % ", ".join(PackedStringArray(durch)))
	get_tree().quit(0 if durch.is_empty() else 1)


func _on_event(kind: String, _data: Dictionary) -> void:
	if kind == "pocket":
		_gefangen = true


func _lauf(main: Node2D, name: String, start: Vector2, v0: Vector2) -> bool:
	_gefangen = false
	var ball := PinBall.new()
	ball.position = start
	main.add_child(ball)
	ball.linear_velocity = v0
	var v_an_mulde := Vector2.ZERO
	var pos_an_mulde := Vector2.ZERO
	for i in 360:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		if absf(ball.global_position.y - MULDE_Y) < 10.0 and v_an_mulde == Vector2.ZERO:
			v_an_mulde = ball.linear_velocity
			pos_an_mulde = ball.global_position
		if _gefangen:
			break
	print("  %-24s an der Mulde x=%.0f v=(%.0f,%.0f) Betrag %4.0f px/s -> %s" % [
			name + ":", pos_an_mulde.x, v_an_mulde.x, v_an_mulde.y, v_an_mulde.length(),
			"GEFANGEN" if _gefangen else "DURCHGEROLLT"])
	if is_instance_valid(ball):
		ball.queue_free()
	# Die Mulde ist nach einem Fang 1.3 s gesperrt - so lange warten, sonst
	# misst der naechste Lauf nur die Sperre statt der Fangbedingung.
	await get_tree().create_timer(2.2).timeout
	return _gefangen
