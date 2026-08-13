extends Node
## Prozeduraler Sound - keine Asset-Dateien noetig. Autoload "Sfx".
## Optional: legt man Audiodateien in assets/music/ bzw. assets/voice/ ab,
## werden sie automatisch verwendet (siehe README.md).
##
## Aufbau der Klaenge: ein Flipper-Geraeusch besteht immer aus zwei Schichten -
## dem mechanischen Klack (gefiltertes Rauschen, wenige Millisekunden) und dem
## Koerper, der danach ausklingt (abklingende Teiltoene).  Ein einzelner
## Rechteckton allein klingt nach Spielzeug.
##
## Alle Klaenge laufen ueber drei Busse (SFX / Musik / Stimme), damit Hall,
## Kompressor und Limiter zentral wirken und die Musik leiser wird, wenn die
## Queen spricht.

const RATE := 44100
const SFX_BUS := "SFX"
const MUSIK_BUS := "Musik"
const STIMME_BUS := "Stimme"
const MUSIK_DB := -6.0

## Melodische Klaenge bekommen keine Tonhoehen-Streuung - sonst klingen die
## Jingles jedes Mal verstimmt.  Alles andere wird pro Treffer leicht
## variiert, damit eine Bumper-Serie nicht wie ein Maschinengewehr klingt.
const KEIN_ZUFALL := ["jackpot", "save", "mode", "over", "ego_up", "count",
		"count_go", "beste"]

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _voice: Dictionary = {}
var _duck: Tween

const VOICE_FILES := {
	"koop": "koop_modus",
	"beste": "ich_bin_die_beste",
	"carry_rettet": "mein_carry_rettet",
	"gern": "gern_geschehen",
	"kein_skill": "kein_skill",
	"kein_plan": "kein_plan",
	"ohne_mich": "ohne_mich",
	"outro": "outro",
	"bericht": "der_bericht",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_busse()
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_players.append(p)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = STIMME_BUS
	add_child(_voice_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIK_BUS
	add_child(_music_player)
	_build_all()
	_load_optional_audio()


# ---------------------------------------------------------------- Busse ----

## Drei Busse mit Effektkette.  Wird beim Start angelegt, damit das Projekt
## ohne eingecheckte Bus-Konfiguration auskommt.
func _setup_busse() -> void:
	var sfx := _neuer_bus(SFX_BUS)
	# Kleiner Raum: der Tisch steht in einem Gehaeuse, nicht im Freien.
	var hall := AudioEffectReverb.new()
	hall.room_size = 0.32
	hall.damping = 0.62
	hall.spread = 0.7
	hall.hipass = 0.15
	hall.predelay_msec = 8.0
	hall.dry = 1.0
	hall.wet = 0.13
	AudioServer.add_bus_effect(sfx, hall)
	# Kompressor: haelt einzelne laute Treffer im Zaum, wenn viel gleichzeitig
	# passiert (Multiball, Bumper-Serie).
	var komp := AudioEffectCompressor.new()
	komp.threshold = -18.0
	komp.ratio = 3.5
	komp.attack_us = 30.0
	komp.release_ms = 120.0
	komp.gain = 3.0
	AudioServer.add_bus_effect(sfx, komp)

	_neuer_bus(MUSIK_BUS)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIK_BUS), MUSIK_DB)
	var stimme := _neuer_bus(STIMME_BUS)
	# Sprache etwas dichter, damit sie ueber dem Geschehen bleibt
	var vk := AudioEffectCompressor.new()
	vk.threshold = -20.0
	vk.ratio = 4.0
	vk.gain = 4.0
	AudioServer.add_bus_effect(stimme, vk)

	# Summe gegen Uebersteuern absichern
	var master := AudioServer.get_bus_index("Master")
	if ClassDB.class_exists("AudioEffectHardLimiter"):
		AudioServer.add_bus_effect(master, ClassDB.instantiate("AudioEffectHardLimiter"))
	else:
		AudioServer.add_bus_effect(master, AudioEffectLimiter.new())


func _neuer_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return idx
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	return idx


# -------------------------------------------------------------- Abspielen --

func play(snd: String, volume_db: float = 0.0) -> void:
	if not _streams.has(snd):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[snd]
	if snd in KEIN_ZUFALL:
		p.pitch_scale = 1.0
		p.volume_db = volume_db
	else:
		p.pitch_scale = randf_range(0.97, 1.03)
		p.volume_db = volume_db + randf_range(-1.5, 1.5)
	p.play()


func say(line: String) -> void:
	if not _voice.has(line):
		return
	_voice_player.stream = _voice[line]
	_voice_player.play()
	_ducke(_voice[line].get_length())


## Musik zurueckdrehen, solange gesprochen wird.
func _ducke(dauer: float) -> void:
	var bus := AudioServer.get_bus_index(MUSIK_BUS)
	if bus == -1:
		return
	if _duck != null and _duck.is_valid():
		_duck.kill()
	_duck = create_tween()
	_duck.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v),
			AudioServer.get_bus_volume_db(bus), MUSIK_DB - 9.0, 0.15)
	_duck.tween_interval(maxf(0.1, dauer - 0.3))
	_duck.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v),
			MUSIK_DB - 9.0, MUSIK_DB, 0.45)


# --------------------------------------------------------------- Synthese --

## Bandbegrenzung fuer Rechteck und Saegezahn.  Ohne sie spiegeln sich die
## Oberwellen oberhalb der halben Abtastrate zurueck und klingen schrill.
func _blep(t: float, dt: float) -> float:
	if dt <= 0.0:
		return 0.0
	if t < dt:
		var a := t / dt
		return a + a - a * a - 1.0
	if t > 1.0 - dt:
		var b := (t - 1.0) / dt
		return b * b + b + b + 1.0
	return 0.0


## Huellkurve, einmal je Klang vorberechnet: kurze Rampe hinein (gegen
## Knackser), danach exponentielles Abklingen wie bei einem angeschlagenen
## Koerper, zum Schluss 5 ms sauber auf Null.  "abfall" ist die Zahl der
## e-Faltungen ueber die Laenge - groesser heisst kuerzer.
func _huellkurve(n: int, attack: float, abfall: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	var a := mini(maxi(1, int(attack * RATE)), maxi(1, n / 4))
	var r := exp(-abfall / maxf(1.0, float(n - a)))
	var v := 1.0
	for i in n:
		if i < a:
			out[i] = float(i) / float(a)
		else:
			v *= r
			out[i] = v
	var f := mini(n, int(0.005 * RATE))
	for j in f:
		out[n - 1 - j] *= float(j) / float(f)
	return out


func _tone(freq: float, dur: float, vol: float = 0.4, shape: String = "sine",
		slide: float = 0.0, abfall: float = 3.5) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var huelle := _huellkurve(n, 0.002, abfall)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := maxf(20.0, freq + slide * t)
		var dt := f / RATE
		phase = fmod(phase + dt, 1.0)
		var s: float
		match shape:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
				s += _blep(phase, dt) - _blep(fmod(phase + 0.5, 1.0), dt)
			"saw":
				s = 2.0 * phase - 1.0 - _blep(phase, dt)
			"noise":
				s = randf() * 2.0 - 1.0
			_:
				s = sin(phase * TAU)
		out[i] = s * vol * huelle[i]
	return out


## Mechanischer Klack: Rauschen durch einen Bandpass.  "cutoff" bestimmt, wie
## hell es klackt, "res" wie metallisch es nachklingt.
func _klack(dur: float, vol: float, cutoff: float, res: float = 1.0,
		sweep: float = 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var huelle := _huellkurve(n, 0.0005, 5.0)
	var tief := 0.0
	var band := 0.0
	var q: float = clampf(1.0 / maxf(0.05, res), 0.0, 1.9)
	for i in n:
		var t := float(i) / n
		var fc: float = clampf(cutoff + sweep * t, 60.0, RATE * 0.45)
		var f: float = clampf(2.0 * sin(PI * fc / RATE), 0.0, 1.4)
		var x := randf() * 2.0 - 1.0
		tief += f * band
		var hoch := x - tief - q * band
		band += f * hoch
		out[i] = clampf(band, -1.5, 1.5) * vol * huelle[i]
	return out


## Koerper: mehrere abklingende Teiltoene.  Leicht verstimmt, damit es nach
## Blech und nicht nach Orgel klingt.
func _koerper(freqs: Array, dur: float, vol: float,
		abfall: float = 4.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in freqs.size():
		var f: float = freqs[k]
		var amp: float = vol / (1.0 + 1.5 * float(k))
		# Hohe Teiltoene sterben frueher - so klingt es nach Blech, nicht nach Orgel
		var huelle := _huellkurve(n, 0.001, abfall + 1.5 * float(k))
		# Sinus als Rekursion statt sin() je Sample: s[n] = 2cos(w)*s[n-1] - s[n-2].
		# Klanglich identisch, aber ein Vielfaches schneller beim Aufbau.
		var w := TAU * f / RATE
		var c := 2.0 * cos(w)
		var s1 := sin(-w)
		var s2 := sin(-2.0 * w)
		for i in n:
			var s := c * s1 - s2
			s2 = s1
			s1 = s
			out[i] += s * amp * huelle[i]
	return out


## Klaenge nacheinander (fuer Jingles).
func _seq(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


## Klaenge uebereinander (Klack + Koerper).
func _stack(parts: Array) -> PackedFloat32Array:
	var laenge := 0
	for p in parts:
		laenge = maxi(laenge, p.size())
	var out := PackedFloat32Array()
	out.resize(laenge)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _build_all() -> void:
	# Flipper: Spulen-Klack plus dumpfer Koerper
	_streams["flip"] = _wav(_stack([
			_klack(0.035, 0.42, 1700.0, 1.1, 900.0),
			_koerper([118.0, 179.0], 0.085, 0.26, 2.4)]))

	# Bumper: harter Anschlag, danach der jeweils eigene Ton (S am tiefsten,
	# D am hoechsten) - die Tonhoehen bleiben wie gehabt.
	for b in [["w", 233.0], ["a", 196.0], ["s", 165.0], ["d", 262.0]]:
		var f: float = b[1]
		_streams["bump_" + str(b[0])] = _wav(_stack([
				_klack(0.028, 0.34, 2500.0, 0.9),
				_koerper([f, f * 2.01, f * 3.03], 0.24, 0.40, 2.2),
				_tone(f * 2.0, 0.09, 0.12, "square", 40.0)]))

	# Slingshot: schnappt, kurz und hell
	_streams["sling"] = _wav(_stack([
			_klack(0.05, 0.44, 3100.0, 0.8, -1200.0),
			_tone(240.0, 0.07, 0.3, "saw", 120.0)]))
	_streams["spin"] = _wav(_stack([
			_klack(0.014, 0.22, 5200.0, 0.7),
			_tone(880.0, 0.03, 0.16, "square")]))
	_streams["target"] = _wav(_stack([
			_klack(0.02, 0.3, 3400.0, 0.9),
			_koerper([620.0, 1290.0], 0.11, 0.3, 2.6)]))
	_streams["standup"] = _wav(_stack([
			_klack(0.018, 0.28, 4200.0, 0.8),
			_koerper([1180.0, 1790.0], 0.12, 0.28, 3.0)]))
	# Mulde: Kugel faellt ein und wird ausgeworfen
	_streams["lock"] = _wav(_stack([
			_klack(0.16, 0.3, 900.0, 1.4, 1600.0),
			_tone(200.0, 0.3, 0.28, "saw", 300.0)]))
	_streams["eject"] = _wav(_stack([
			_klack(0.09, 0.36, 2800.0, 1.0, -2000.0),
			_tone(500.0, 0.15, 0.32, "saw", -250.0)]))
	_streams["jackpot"] = _wav(_seq([
			_tone(523.0, 0.1, 0.4, "square"), _tone(659.0, 0.1, 0.4, "square"),
			_tone(784.0, 0.12, 0.4, "square"),
			_stack([_tone(1047.0, 0.3, 0.4, "square"),
					_koerper([1047.0, 2100.0], 0.3, 0.2, 2.0)])]))
	# Ballverlust: faellt in sich zusammen
	_streams["drain"] = _wav(_stack([
			_klack(0.5, 0.3, 1400.0, 1.6, -1250.0),
			_tone(160.0, 0.5, 0.34, "saw", -100.0)]))
	_streams["launch"] = _wav(_stack([
			_klack(0.25, 0.34, 400.0, 1.2, 3000.0),
			_tone(120.0, 0.25, 0.34, "saw", 500.0)]))
	_streams["save"] = _wav(_seq([
			_tone(392.0, 0.09, 0.4, "square"), _tone(523.0, 0.09, 0.4, "square"),
			_stack([_tone(659.0, 0.22, 0.42, "square"),
					_koerper([659.0, 1320.0], 0.22, 0.18, 2.0)])]))
	_streams["mode"] = _wav(_seq([
			_tone(262.0, 0.12, 0.42, "saw"), _tone(330.0, 0.12, 0.42, "saw"),
			_stack([_tone(392.0, 0.24, 0.44, "saw"),
					_koerper([392.0, 785.0], 0.24, 0.2, 2.0)])]))
	_streams["over"] = _wav(_seq([
			_tone(300.0, 0.2, 0.34, "saw", -80.0),
			_tone(250.0, 0.2, 0.34, "saw", -80.0),
			_stack([_tone(200.0, 0.45, 0.38, "saw", -80.0),
					_klack(0.45, 0.16, 700.0, 1.8, -500.0)])]))
	_streams["tick"] = _wav(_stack([
			_klack(0.01, 0.16, 6000.0, 0.6),
			_tone(1200.0, 0.02, 0.14, "square")]))
	_streams["count"] = _wav(_stack([
			_tone(520.0, 0.1, 0.38, "square"),
			_koerper([520.0, 1045.0], 0.1, 0.16, 2.4)]))
	_streams["count_go"] = _wav(_seq([
			_tone(784.0, 0.09, 0.4, "square"),
			_stack([_tone(1047.0, 0.2, 0.42, "square"),
					_koerper([1047.0, 2095.0], 0.2, 0.2, 2.0)])]))
	# Grollen vor dem Carry-Save: tief, rau, laenger stehend
	_streams["rumble"] = _wav(_stack([
			_tone(65.0, 0.5, 0.4, "saw", 30.0, 1.1),
			_tone(85.0, 0.5, 0.42, "saw", 150.0, 1.1),
			_klack(0.5, 0.22, 260.0, 1.8, 220.0)]))
	_streams["crank"] = _wav(_stack([
			_klack(0.016, 0.24, 2200.0, 0.7),
			_tone(150.0, 0.035, 0.22, "square", -40.0)]))
	_streams["ego_up"] = _wav(_seq([
			_tone(330.0, 0.07, 0.42, "square"), _tone(415.0, 0.07, 0.42, "square"),
			_tone(523.0, 0.07, 0.42, "square"),
			_stack([_tone(659.0, 0.2, 0.44, "square", 80.0),
					_koerper([659.0, 1325.0], 0.2, 0.2, 2.0)])]))


func _load_optional_audio() -> void:
	for key in VOICE_FILES:
		var s := _load_stream("res://assets/voice/" + VOICE_FILES[key])
		if s != null:
			_voice[key] = s
	var m := _load_stream("res://assets/music/loop")
	if m != null:
		if m is AudioStreamOggVorbis:
			m.loop = true
		elif m is AudioStreamMP3:
			m.loop = true
		_music_player.stream = m
		_music_player.play()


func _load_stream(base: String) -> AudioStream:
	if FileAccess.file_exists(base + ".ogg"):
		return AudioStreamOggVorbis.load_from_file(base + ".ogg")
	if FileAccess.file_exists(base + ".mp3"):
		var f := FileAccess.open(base + ".mp3", FileAccess.READ)
		if f:
			var mp3 := AudioStreamMP3.new()
			mp3.data = f.get_buffer(f.get_length())
			return mp3
	return null
