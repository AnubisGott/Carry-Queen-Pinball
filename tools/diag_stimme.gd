extends Node
## Prueft, was aus assets/voice/ tatsaechlich im Spiel ankommt.
##
## Der Weg vom abgelegten Ordner bis zum gesprochenen Satz hat drei Stellen,
## an denen etwas danebengehen kann: der Name wird nicht eingedampft wie
## erwartet, er passt zu keinem Fach, oder die Datei laesst sich nicht laden.
## Dieses Werkzeug geht alle drei durch und nennt jede Datei beim Namen.
##   godot --headless --path . res://tools/diag_stimme.tscn

func _ready() -> void:
	await get_tree().process_frame
	print("--- Namen eindampfen ---")
	var proben := {
		"Ich bin die beste1": "ich_bin_die_beste",
		"ich bin die beste2": "ich_bin_die_beste",
		"Multiball4": "multiball",
		"zeig doch mal was du kannst3": "zeig_doch_mal_was_du_kannst",
		"kein_skill": "kein_skill",
		"Kein Plan (2)": "kein_plan",
		"Vocals-Carry-Queen (Lead Vocal) (1)": "vocals_carry_queen_lead_vocal",
	}
	var fehler := 0
	for roh in proben:
		var ist: String = Sfx._texthaken(roh)
		var soll: String = proben[roh]
		var ok := ist == soll
		if not ok:
			fehler += 1
		print("  %s  \"%s\" -> %s%s" % ["ok " if ok else "FEHL", roh, ist,
				"" if ok else "  (erwartet: %s)" % soll])

	print("--- Zuordnung: aehnliche Saetze duerfen nicht zusammenfallen ---")
	var paare := {
		"kein_plan": "kein_plan",
		"kein_skill": "kein_skill",
		"der_bericht": "bericht",
		"der_knopf_oben_links_nicht_so_schwer": "kanal_5",
		"die_ulti_beginnt": "bericht",
		# ein ausgelassenes Wort mitten im Satz
		"du_warst_auch_dabei_das_bestimmt_schoen_fuer_dich": "outro",
		"zuschauen_kannst_du_ja_wenigstens": "kanal_4",
		"zeig_doch_mal_was_du_kannst": "ball_start",
		# Kuerzel vorneweg, mit Tippfehler im Satz ("ch" statt "ich")
		"s4_ch_haette_den_gehalten_locker": "spott_4",
		"s1_warst_du_nicht_gut_genug": "spott_1",
		"c2_abonnieren_kostet_nichts_skill_schon": "kanal_2",
		# nichts, was passt: darf zu keinem Fach fuehren
		"vocals_carry_queen_lead_vocal": "",
	}
	for h in paare:
		var ist2: String = Sfx._fach_zu(str(h))
		var ok2: bool = ist2 == paare[h]
		if not ok2:
			fehler += 1
		print("  %s  %s -> %s%s" % ["ok " if ok2 else "FEHL", h,
				ist2 if ist2 != "" else "(kein Fach)",
				"" if ok2 else "  (erwartet: %s)" % paare[h]])

	print("--- Was liegt im Verzeichnis ---")
	var dateien := _alle_dateien("res://assets/voice")
	var zugeordnet := 0
	for pfad in dateien:
		var name: String = pfad.get_file().get_basename()
		var fach: String = Sfx._fach_zu(Sfx._texthaken(name))
		if fach == "":
			fach = Sfx._fach_zu(Sfx._texthaken(pfad.get_base_dir().get_file()))
		if fach != "":
			zugeordnet += 1
		print("  %-42s -> %s" % [pfad.get_file(), fach if fach != "" else "(kein Fach)"])

	print("--- Kuerzel und Satz muessen dasselbe Fach ergeben ---")
	# Ordner wie "s4-ich haette den gehalten" tragen die Aussage doppelt: im
	# Kuerzel und im Wortlaut.  Widersprechen die beiden sich, spraeche sie an
	# der falschen Stelle - das faellt hier auf, bevor man es hoert.
	var gesehen := {}
	for pfad in dateien:
		var ordner: String = Sfx._texthaken(pfad.get_base_dir().get_file())
		var ab: int = ordner.find("_")
		if ab <= 0 or ab > 4 or gesehen.has(ordner):
			continue
		gesehen[ordner] = true
		var ueber_kuerzel: String = Sfx._fach_zu(ordner.substr(0, ab))
		var ueber_satz: String = Sfx._fach_zu(ordner.substr(ab + 1))
		if ueber_kuerzel == "" or ueber_satz == "":
			continue
		var einig := ueber_kuerzel == ueber_satz
		if not einig:
			fehler += 1
			print("  FEHL %s: Kuerzel sagt %s, Satz sagt %s"
					% [ordner, ueber_kuerzel, ueber_satz])
		else:
			print("  ok   %-40s beide -> %s" % [ordner, ueber_kuerzel])

	print("--- Was das Spiel geladen hat ---")
	var faecher: Array = Sfx._voice.keys()
	faecher.sort()
	var geladen := 0
	for f in faecher:
		var liste: Array = Sfx._voice[f]
		geladen += liste.size()
		var laengen := PackedStringArray()
		for s in liste:
			laengen.append("%.2f s" % s.get_length())
		print("  %-12s %d Fassungen: %s" % [f, liste.size(), ", ".join(laengen)])

	print("--- Wuerfeln: keine Fassung zweimal hintereinander ---")
	for f in faecher:
		var liste: Array = Sfx._voice[f]
		if liste.size() < 2:
			continue
		var folge := PackedStringArray()
		var letzte := -1
		var doppelt := 0
		for i in 30:
			# Zwischen zwei Saetzen ist sie still - sonst faellt das Beiwerk
			# nach der Regel unten aus und wir messen gar nichts.
			Sfx._voice_player.stop()
			Sfx.say(f)
			# say() merkt sich die Wahl - genau die lesen wir hier ab.
			var jetzt := int(Sfx._voice_letzte[f])
			if jetzt == letzte:
				doppelt += 1
			letzte = jetzt
			folge.append(str(jetzt + 1))
		if doppelt > 0:
			fehler += 1
		print("  %s %s  %s" % ["FEHL" if doppelt > 0 else "ok  ", f,
				" ".join(folge)])

	print("--- Sie faellt sich nicht selbst ins Wort ---")
	# Beiwerk (hier: der Ballstart-Satz) muss ausfallen, solange noch ein Satz
	# laeuft; ein wichtiger Satz darf unterbrechen.
	for fall in [["ball_start", false], ["beste", true]]:
		var fach: String = fall[0]
		var darf: bool = fall[1]
		if not Sfx.hat_stimme(fach):
			continue
		Sfx._voice_player.stop()
		Sfx.say("koop")
		var vorher: AudioStream = Sfx._voice_player.stream
		Sfx.say(fach)
		var kam_durch: bool = Sfx._voice_player.stream != vorher
		var ok := kam_durch == darf
		if not ok:
			fehler += 1
		print("  %s %-11s waehrend sie spricht: %s (erwartet: %s)"
				% ["ok  " if ok else "FEHL", fach,
				"unterbricht" if kam_durch else "faellt aus",
				"unterbricht" if darf else "faellt aus"])

	print("--- Ballwechsel: kommt der Spott hinter \"Kein Skill.\" durch? ---")
	# Der neue Ball folgt dem Ballverlust ohne Pause.  Deshalb wartet der
	# Spott 1,2 s - laenger als die laengste Kein-Skill-Aufnahme.  Hier wird
	# genau diese Abfolge in echter Zeit nachgestellt.
	if Sfx.hat_stimme("kein_skill") and Sfx.hat_stimme("spott_1"):
		var laengste := 0.0
		for s in Sfx._voice["kein_skill"] as Array:
			laengste = maxf(laengste, s.get_length())
		Sfx._voice_player.stop()
		Sfx.say("kein_skill")
		Sfx.say("spott_1")
		var sofort := Sfx._voice_player.stream in (Sfx._voice["spott_1"] as Array)
		await get_tree().create_timer(1.2).timeout
		Sfx.say("spott_1")
		var spaeter := Sfx._voice_player.stream in (Sfx._voice["spott_1"] as Array)
		var ok3 := not sofort and spaeter
		if not ok3:
			fehler += 1
		print("  %s laengstes \"Kein Skill.\" %.2f s, Wartezeit 1,20 s"
				% ["ok  " if ok3 else "FEHL", laengste])
		print("       sofort: %s   nach 1,2 s: %s"
				% ["kommt durch" if sofort else "faellt aus",
				"kommt durch" if spaeter else "faellt aus"])

	print("--- Faecher, Verdrahtung, Aufnahmen ---")
	# Jedes Sfx.say() im Code muss ein Fach treffen; jedes Fach, das nirgends
	# gerufen wird, ist totes Gewicht.  Beides faellt hier auf.
	var gerufen := _say_im_code()
	for s in gerufen:
		if not Sfx.VOICE_FILES.has(s):
			print("  FEHL Sfx.say(\"%s\") - dieses Fach gibt es nicht" % s)
			fehler += 1
	var namen: Array = Sfx.VOICE_FILES.keys()
	namen.sort()
	for f in namen:
		var n: int = (Sfx._voice.get(f, []) as Array).size()
		print("  %-12s %-14s %s" % [f,
				"verdrahtet" if f in gerufen else "ohne Aufruf",
				"%d Aufnahmen" % n if n > 0 else "-"])

	print("--- Ergebnis ---")
	print("  %d Dateien im Verzeichnis, %d davon einem Fach zugeordnet"
			% [dateien.size(), zugeordnet])
	print("  %d Aufnahmen in %d Faechern geladen" % [geladen, faecher.size()])
	if zugeordnet != geladen:
		print("  FEHL: zugeordnet und geladen gehen auseinander")
		fehler += 1
	print("  %s" % ["alles in Ordnung" if fehler == 0 else "%d Fehler" % fehler])
	get_tree().quit(0 if fehler == 0 else 1)


## Alle Faecher, die im Quelltext gesprochen werden.  Neben dem geraden
## Sfx.say("beste") gibt es die gebaute Form Sfx.say("spott_%d" % ...) - dort
## zaehlt die ganze Reihe als verdrahtet.
func _say_im_code() -> Array:
	var raus := []
	var re := RegEx.new()
	# Der Nachsatz laeuft ueber einen Umweg mit Wartezeit, spricht aber
	# dasselbe Fach - sonst gaelte er hier als unbenutzt.
	re.compile("(?:Sfx\\.say|_nachsatz)\\(\"([a-z_0-9]+)(%d)?\"")
	var d := DirAccess.open("res://scripts")
	if d == null:
		return raus
	for datei in d.get_files():
		if not datei.ends_with(".gd"):
			continue
		var f := FileAccess.open("res://scripts/" + datei, FileAccess.READ)
		if f == null:
			continue
		for t in re.search_all(f.get_as_text()):
			var name := t.get_string(1)
			if t.get_string(2) == "":
				if not name in raus:
					raus.append(name)
				continue
			# "spott_" mit Nummer: alle Faecher dieser Reihe
			for k in Sfx.VOICE_FILES:
				if str(k).begins_with(name) and not k in raus:
					raus.append(k)
	raus.sort()
	return raus


func _alle_dateien(pfad: String, tiefe: int = 0) -> Array:
	var raus := []
	var d := DirAccess.open(pfad)
	if d == null:
		return raus
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n != "." and n != "..":
			var voll := pfad + "/" + n
			if d.current_is_dir():
				if tiefe < 3:
					raus.append_array(_alle_dateien(voll, tiefe + 1))
			elif n.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
				raus.append(voll)
		n = d.get_next()
	d.list_dir_end()
	raus.sort()
	return raus
