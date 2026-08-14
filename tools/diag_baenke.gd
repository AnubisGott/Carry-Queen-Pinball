extends Node
## Wie viele Buchstaben raeumt eine einzige vorbeirollende Kugel ab?
##
## I-C-H und E-G-O stehen je zu dritt senkrecht untereinander an der Wand
## (Abstand 60, Target 34 hoch).  Eine Kugel, die die Bahn herunterrollt,
## streift alle drei nacheinander - die Bank ist damit in einem Durchgang
## erledigt.  Dieses Werkzeug misst das bei verschiedenen Tempi und zeigt
## nebenbei, wie lange so ein Durchgang dauert.
##   godot --headless --path . res://tools/diag_baenke.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _treffer := []


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	await get_tree().create_timer(0.8).timeout
	Game.event.connect(_auf_ereignis)
	_main.god_mode = true

	# Die Kugel rollt senkrecht an der Wand entlang.  Wie dicht sie dabei
	# vorbeikommt, entscheidet alles - deshalb mehrere Abstaende.  Das Target
	# ragt 5 von der Wand weg, die Kugel misst 13: bei 18 schleift sie.
	print("--- ein Durchgang, senkrecht an der Bank vorbei ---")
	print("  %-6s %-7s %-6s %-24s %s" % ["Bank", "Abstand", "Tempo", "Buchstaben", "Dauer"])
	var schlimmster := 0
	for bank in [["I-C-H", 31.0], ["E-G-O", 459.0]]:
		for abstand in [16.0, 18.0, 20.0]:
			for tempo in [200.0, 450.0, 800.0]:
				var n := await _durchgang(float(bank[1]), abstand, tempo)
				schlimmster = maxi(schlimmster, n)
	print("--- Ergebnis ---")
	print("  hoechstens %d Buchstaben in einem Durchgang" % schlimmster)
	print("  %s" % ["ok - eine Kugel raeumt hoechstens einen ab" if schlimmster <= 1
			else "zu einfach: eine Kugel raeumt bis zu %d ab" % schlimmster])
	get_tree().quit(0 if schlimmster <= 1 else 1)


## Eine Kugel von oben an der Bank vorbeirollen lassen und zaehlen, welche
## Buchstaben dabei angehen.
func _durchgang(x: float, abstand: float, tempo: float) -> int:
	# Die Kugel des vorigen Durchgangs muss wirklich weg sein, sonst haelt sie
	# die Sperre der Bank noch am Leben.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for s in _main.standups:
		s.reset()
	for s in _main.ego_bank:
		s.reset()
	_main._ich_done = false
	_main._ego_done = false
	_treffer.clear()
	# Oberhalb des ersten Targets starten und senkrecht daran vorbeirollen
	var richtung := 1.0 if x < 245.0 else -1.0
	var b: PinBall = _main._spawn_ball(Vector2(x + richtung * abstand, 320.0))
	b.linear_velocity = Vector2(0.0, tempo)
	var t0 := Time.get_ticks_msec()
	var erster := 0
	var letzter := 0
	while Time.get_ticks_msec() - t0 < 2500:
		await get_tree().physics_frame
		if _treffer.size() == 1 and erster == 0:
			erster = Time.get_ticks_msec()
		if not _treffer.is_empty():
			letzter = Time.get_ticks_msec()
		if b.global_position.y > 560.0:
			break
	if is_instance_valid(b):
		b.queue_free()
	var dauer := 0 if _treffer.size() < 2 else letzter - erster
	print("  %-6s %5.0f   %4.0f   %-24s %s" % [
			"I-C-H" if x < 245.0 else "E-G-O", abstand, tempo, str(_treffer),
			"%d ms vom ersten zum letzten" % dauer if dauer > 0 else "-"])
	return _treffer.size()


func _auf_ereignis(kind: String, data: Dictionary) -> void:
	if kind == "standup":
		_treffer.append(str(data.get("letter", "?")))
