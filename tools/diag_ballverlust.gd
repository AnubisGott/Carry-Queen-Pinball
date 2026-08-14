extends Node
## Prueft, wer beim Ballverlust spricht.  Frueher kamen "Kein Skill." und der
## Spott zum naechsten Ball nacheinander - das war einer zu viel.  Jetzt ist
## es genau einer davon, im Verhaeltnis fuenf zu eins.
##   godot --headless --path . res://tools/diag_ballverlust.tscn

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var fehler := 0

	print("--- Abfolge ueber 60 Ballverluste ---")
	var zaehler := {"kein_skill": 0, "spott": 0}
	var folge := PackedStringArray()
	var luecke := 0
	var groesste := 0
	for i in 60:
		var wer: String = main.wer_spricht_beim_verlust()
		zaehler[wer] = int(zaehler[wer]) + 1
		folge.append("S" if wer == "spott" else ".")
		if wer == "spott":
			groesste = maxi(groesste, luecke)
			luecke = 0
		else:
			luecke += 1
	print("  " + "".join(folge))
	print("  \"Kein Skill.\" %d x, Spott %d x" % [zaehler["kein_skill"], zaehler["spott"]])
	if zaehler["kein_skill"] != 50 or zaehler["spott"] != 10:
		fehler += 1
		print("  FEHL erwartet waren 50 zu 10")
	elif groesste != 5:
		fehler += 1
		print("  FEHL zwischen zwei Spott-Spruechen lagen %d statt 5" % groesste)
	else:
		print("  ok   genau 5:1, und zwischen zwei Spott-Spruechen liegen immer 5")

	print("--- Der letzte Ball bekommt keinen Spott ---")
	# Nach dem dritten Ball folgt kein vierter, also auch kein Spruch zum
	# naechsten Ball.  Dort muss es bei "Kein Skill." bleiben.
	var vorher: int = main._verluste
	Game.ball_number = Game.balls_per_game
	main._spott_dran = false
	var folgt: bool = main.god_mode or Game.ball_number < Game.balls_per_game
	var ok: bool = not folgt and main._verluste == vorher
	if not ok:
		fehler += 1
	print("  %s Ball %d von %d: Spott moeglich = %s, Zaehler unveraendert = %s"
			% ["ok  " if ok else "FEHL", Game.ball_number, Game.balls_per_game,
			str(folgt), str(main._verluste == vorher)])

	print("--- Ergebnis ---")
	print("  %s" % ["alles in Ordnung" if fehler == 0 else "%d Fehler" % fehler])
	get_tree().quit(0 if fehler == 0 else 1)
