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
	print("--- drei Durchgaenge hintereinander: wird die Bank fertig? ---")
	# Ein bereits leuchtendes Target darf die Nachbarn nicht sperren, sonst
	# waere die Bank nie zu schaffen.  Und wenn alle drei stehen, muss die
	# Lampe oben in der Leiste angehen.
	var fehler := 0
	# Einmal sauber aufraeumen, danach beide Baenke nacheinander.  Nicht je
	# Bank zuruecksetzen: sonst stuende die eine Bank beim naechsten Abschnitt
	# wieder auf Anfang und der Fehler nach dem Neustart faellt nur bei der
	# anderen auf.
	Game.reset_disciplines()
	for s in _main.standups:
		s.reset()
	for s in _main.ego_bank:
		s.reset()
	_main._ich_done = false
	_main._ego_done = false
	for bank in [["I-C-H", 31.0, "ICH"], ["E-G-O", 459.0, "EGO"]]:
		var folge := []
		for durchgang in 3:
			# Ohne Zuruecksetzen: die Bank behaelt, was schon leuchtet
			await _durchgang(float(bank[1]), 18.0, 200.0, false)
			folge.append_array(_treffer)
		var lampe: bool = Game.disciplines.get(str(bank[2]), false)
		var voll: bool = folge.size() == 3
		# Der Zustand allein genuegt nicht: die Beschriftung oben wird ueber
		# Ereignisse umgefaerbt.  Deshalb wird hier die wirkliche Schriftfarbe
		# abgelesen, und zwar sofort - die naechste Bank setzt sie zurueck.
		var farbe: Color = _main.hud._disc_labels[str(bank[2])].get_theme_color("font_color")
		var hell: bool = farbe.is_equal_approx(Hud.PINK)
		if not voll or not lampe or not hell:
			fehler += 1
		print("  %s %s  Buchstaben %s, Lampe %s: %s, Beschriftung: %s"
				% ["ok  " if voll and lampe and hell else "FEHL", bank[0], str(folge),
				str(bank[2]), "an" if lampe else "AUS", "hell" if hell else "grau"])

	print("--- und nach einem neuen Spiel noch einmal ---")
	# Der Screenshot aus dem Spiel zeigte alle sechs Targets durchgestrichen,
	# aber die Lampen oben grau.  Genau das wird hier nachgestellt: Bank
	# fertig, neues Spiel, Bank wieder fertig.
	_main._restart()
	await get_tree().create_timer(0.5).timeout
	# Das neue Spiel loescht die Disziplinen - die Beschriftung muss das
	# sofort zeigen und nicht die Farbe des alten Spiels behalten.
	for name in ["ICH", "EGO"]:
		var farbe: Color = _main.hud._disc_labels[name].get_theme_color("font_color")
		var grau: bool = farbe.is_equal_approx(Hud.DIM)
		if not grau:
			fehler += 1
		print("  %s neues Spiel -> %s wieder grau: %s" % ["ok  " if grau else "FEHL",
				name, str(grau)])
	for bank in [["I-C-H", 31.0, "ICH"], ["E-G-O", 459.0, "EGO"]]:
		var folge := []
		for durchgang in 3:
			await _durchgang(float(bank[1]), 18.0, 200.0, false)
			folge.append_array(_treffer)
		var alle_an := true
		for s in (_main.standups if bank[2] == "ICH" else _main.ego_bank):
			if not s.lit:
				alle_an = false
		var lampe: bool = Game.disciplines.get(str(bank[2]), false)
		if not alle_an or not lampe:
			fehler += 1
		print("  %s %s  alle drei leuchten: %s, Lampe %s: %s"
				% ["ok  " if alle_an and lampe else "FEHL", bank[0], str(alle_an),
				str(bank[2]), "an" if lampe else "AUS"])

	print("--- die Sperre ueberlebt den Ballwechsel nicht ---")
	# Beim Messen aufgefallen: die Sperre stand noch, wenn die Bank neu
	# aufgestellt wurde, und schluckte den ersten Treffer der neuen Runde.
	# Alles in einem Bild, damit sie nicht schon von selbst faellt.
	var kugel: PinBall = _main._spawn_ball(Vector2(270, 700))
	kugel.freeze = true
	for s in _main.standups:
		s.reset()
	_main.standups[0]._on_hit(kugel)
	var sperre_stand: bool = _main.standups[1]._gesperrt
	for s in _main.standups:
		s.reset()
	_main.standups[1]._on_hit(kugel)
	var kam_durch: bool = _main.standups[1].lit
	if not sperre_stand or not kam_durch:
		fehler += 1
	print("  %s nach dem Treffer gesperrt: %s, nach reset() zaehlt der naechste: %s"
			% ["ok  " if sperre_stand and kam_durch else "FEHL",
			str(sperre_stand), str(kam_durch)])
	kugel.queue_free()

	print("--- Ergebnis ---")
	print("  hoechstens %d Buchstaben in einem Durchgang: %s" % [schlimmster,
			"ok" if schlimmster <= 1 else "zu einfach"])
	if schlimmster > 1:
		fehler += 1
	print("  %s" % ["alles in Ordnung" if fehler == 0 else "%d Fehler" % fehler])
	get_tree().quit(0 if fehler == 0 else 1)


## Eine Kugel von oben an der Bank vorbeirollen lassen und zaehlen, welche
## Buchstaben dabei angehen.
func _durchgang(x: float, abstand: float, tempo: float, neu: bool = true) -> int:
	# Die Kugel des vorigen Durchgangs muss wirklich weg sein, sonst haelt sie
	# die Sperre der Bank noch am Leben.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if neu:
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
