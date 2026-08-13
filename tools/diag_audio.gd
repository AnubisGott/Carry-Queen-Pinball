extends Node
## Diagnose des Sounds: prueft die Busse samt Effektkette und misst zu jedem
## erzeugten Klang Dauer, Spitzenpegel und Effektivwert.  Uebersteuerung
## (Spitze 1.00 ueber viele Samples) und stumme Klaenge fallen so auf, ohne
## dass man hinhoeren muss.
##   godot --headless --path . res://tools/diag_audio.tscn [-- --wav <ordner>]

var _wav_out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--wav" and i + 1 < args.size():
			_wav_out = args[i + 1]

	# Sfx baut die Klaenge im Hintergrund und ersetzt danach die, fuer die es
	# eigene Dateien gibt.  Fertig ist beides erst, wenn der Bau-Auftrag
	# abgemeldet ist - vorher gemessen, saehe man noch die erzeugten Klaenge.
	var t_start := Time.get_ticks_msec()
	while Sfx._streams.is_empty() or Sfx._bau_task != -1:
		await get_tree().process_frame
	print("Fertig nach %d ms (Nebenlaeufer, blockiert den Start nicht)" % (
			Time.get_ticks_msec() - t_start))
	var t0 := Time.get_ticks_msec()
	Sfx._build_all()
	print("Reine Rechenzeit aller Klaenge: %d ms" % (Time.get_ticks_msec() - t0))

	print("--- Busse ---")
	for i in AudioServer.bus_count:
		var effekte := []
		for e in AudioServer.get_bus_effect_count(i):
			effekte.append(AudioServer.get_bus_effect(i, e).get_class().replace("AudioEffect", ""))
		print("  %-8s %+5.1f dB -> %-8s %s" % [
				AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i),
				AudioServer.get_bus_send(i), str(effekte)])

	print("--- Zwei Ebenen: erzeugt plus Aufnahme ---")
	for name in ["flip", "bump_w", "drain", "jackpot"]:
		Sfx.play(name, -6.0)
		await get_tree().process_frame
		await get_tree().process_frame
		var laufen := []
		for p in Sfx._players:
			if p.playing:
				laufen.append("%s %.0f dB" % [
						"Aufnahme" if p.stream == Sfx._aus_datei.get(name) else "erzeugt",
						p.volume_db])
		print("  %-9s -> %d Stimme(n): %s" % [name, laufen.size(), ", ".join(PackedStringArray(laufen))])
		await get_tree().create_timer(1.2).timeout

	print("--- Klaenge ---")
	var streams: Dictionary = Sfx._streams
	var namen := streams.keys()
	namen.sort()
	for n in namen:
		# Aus Dateien geladene Klaenge sind je nach Format kein AudioStreamWAV -
		# die lassen sich hier nicht Sample fuer Sample nachmessen.
		if not streams[n] is AudioStreamWAV:
			print("  %-10s %5.0f ms  [aus Datei, %s]" % [n,
					1000.0 * streams[n].get_length(), streams[n].get_class()])
			continue
		var wav: AudioStreamWAV = streams[n]
		var data := wav.data
		var anzahl := data.size() / 2
		var spitze := 0.0
		var summe := 0.0
		var voll := 0
		for i in anzahl:
			var v := float(data.decode_s16(i * 2)) / 32767.0
			var a := absf(v)
			spitze = maxf(spitze, a)
			summe += v * v
			if a > 0.995:
				voll += 1
		var rms := sqrt(summe / maxf(1.0, float(anzahl)))
		print("  %-10s %5.0f ms  Spitze %.2f  Effektivwert %.3f  %s%s" % [
				n, 1000.0 * float(anzahl) / float(wav.mix_rate), spitze, rms,
				"[+ Aufnahme] " if Sfx._aus_datei.has(n) else "",
				("ANSCHLAG %d Samples" % voll) if voll > 20 else ""])
		if _wav_out != "":
			_schreibe_wav(wav, "%s/%s.wav" % [_wav_out, n])
	get_tree().quit()


## Klang als echte WAV-Datei ablegen - zum Reinhoeren ausserhalb des Spiels.
func _schreibe_wav(wav: AudioStreamWAV, pfad: String) -> void:
	DirAccess.make_dir_recursive_absolute(pfad.get_base_dir())
	var f := FileAccess.open(pfad, FileAccess.WRITE)
	if f == null:
		return
	var daten := wav.data
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + daten.size())
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(wav.mix_rate)
	f.store_32(wav.mix_rate * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(daten.size())
	f.store_buffer(daten)
	f.close()
