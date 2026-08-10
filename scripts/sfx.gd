extends Node
## Prozeduraler Sound - keine Asset-Dateien noetig. Autoload "Sfx".
## Optional: legt man Audiodateien in assets/music/ bzw. assets/voice/ ab,
## werden sie automatisch verwendet (siehe README.md).

const RATE := 22050

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _voice: Dictionary = {}

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
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -6.0
	add_child(_music_player)
	_build_all()
	_load_optional_audio()


func play(snd: String, volume_db: float = 0.0) -> void:
	if not _streams.has(snd):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[snd]
	p.volume_db = volume_db
	p.play()


func say(line: String) -> void:
	if _voice.has(line):
		_voice_player.stream = _voice[line]
		_voice_player.play()


func _tone(freq: float, dur: float, vol: float = 0.4, shape: String = "sine", slide: float = 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := freq + slide * t
		phase += f / RATE
		var s: float
		match shape:
			"square":
				s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"saw":
				s = 2.0 * fmod(phase, 1.0) - 1.0
			"noise":
				s = randf() * 2.0 - 1.0
			_:
				s = sin(phase * TAU)
		var env := (1.0 - t) * (1.0 - t)
		out[i] = s * vol * env
	return out


func _mix(parts: Array) -> AudioStreamWAV:
	var total := 0
	for p in parts:
		total += p.size()
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var idx := 0
	for p in parts:
		for i in p.size():
			var v := int(clampf(p[i], -1.0, 1.0) * 32767.0)
			bytes.encode_s16(idx * 2, v)
			idx += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _build_all() -> void:
	_streams["flip"] = _mix([_tone(180, 0.05, 0.5, "square", 60)])
	# Tiefe, pro Bumper unterschiedliche Toene (S am tiefsten, D am hoechsten)
	_streams["bump_w"] = _mix([_tone(233, 0.12, 0.55, "square", 60)])
	_streams["bump_a"] = _mix([_tone(196, 0.12, 0.55, "square", 50)])
	_streams["bump_s"] = _mix([_tone(165, 0.12, 0.55, "square", 40)])
	_streams["bump_d"] = _mix([_tone(262, 0.12, 0.55, "square", 70)])
	_streams["sling"] = _mix([_tone(240, 0.07, 0.5, "saw", 120)])
	_streams["spin"] = _mix([_tone(880, 0.03, 0.25, "square")])
	_streams["target"] = _mix([_tone(300, 0.08, 0.5, "square", -80)])
	_streams["standup"] = _mix([_tone(660, 0.08, 0.4, "square", 120)])
	_streams["lock"] = _mix([_tone(200, 0.3, 0.4, "saw", 300)])
	_streams["eject"] = _mix([_tone(500, 0.15, 0.45, "saw", -250)])
	_streams["jackpot"] = _mix([_tone(523, 0.1, 0.45, "square"), _tone(659, 0.1, 0.45, "square"), _tone(784, 0.12, 0.45, "square"), _tone(1047, 0.25, 0.5, "square")])
	_streams["drain"] = _mix([_tone(160, 0.5, 0.5, "saw", -100)])
	_streams["launch"] = _mix([_tone(120, 0.25, 0.5, "saw", 500)])
	_streams["save"] = _mix([_tone(392, 0.09, 0.45, "square"), _tone(523, 0.09, 0.45, "square"), _tone(659, 0.18, 0.5, "square")])
	_streams["mode"] = _mix([_tone(262, 0.12, 0.5, "saw"), _tone(330, 0.12, 0.5, "saw"), _tone(392, 0.2, 0.5, "saw")])
	_streams["over"] = _mix([_tone(300, 0.2, 0.4, "saw", -80), _tone(250, 0.2, 0.4, "saw", -80), _tone(200, 0.4, 0.45, "saw", -80)])
	_streams["tick"] = _mix([_tone(1200, 0.02, 0.2, "square")])
	_streams["count"] = _mix([_tone(520, 0.1, 0.45, "square")])
	_streams["count_go"] = _mix([_tone(784, 0.09, 0.45, "square"), _tone(1047, 0.16, 0.5, "square")])
	_streams["rumble"] = _mix([_tone(65, 0.45, 0.5, "saw", 30), _tone(85, 0.5, 0.55, "saw", 150)])
	_streams["crank"] = _mix([_tone(150, 0.035, 0.4, "square", -40)])


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
