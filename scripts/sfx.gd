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

## Rollgeraeusch: unter ROLL_MIN px/s ist es still, ab ROLL_MAX voll da.
## Lautstaerke und Tonhoehe haengen dazwischen linear am Tempo der schnellsten
## Kugel - das ist der Klang, der einem Tisch am meisten Leben gibt.
const ROLL_MIN := 70.0
const ROLL_MAX := 1100.0
const ROLL_DB_LEISE := -44.0
const ROLL_DB_LAUT := -23.0
const ROLL_PITCH_LEISE := 0.70
const ROLL_PITCH_LAUT := 1.60
## Wie schnell Lautstaerke (dB je Sekunde) und Tonhoehe nachgefuehrt werden.
## Ohne Nachfuehrung knackt es bei jedem Abprall.
const ROLL_DB_TEMPO := 95.0
const ROLL_PITCH_TEMPO := 2.4

## Raketenbrausen beim Spannen der Feder: Lautstaerke und Tonhoehe haengen an
## der Spannung (0 bis 1).  Bei voller Ladung steht das Ding kurz vorm Abheben.
const RAKETE_DB_START := -30.0
const RAKETE_DB_VOLL := -7.0
const RAKETE_PITCH_START := 0.70
const RAKETE_PITCH_VOLL := 1.50
## Hochfahren traege (das Triebwerk braucht seine Zeit), Abschalten schnell -
## beim Abschuss soll das Brausen mit der Kugel weg sein, nicht nachhaengen.
const RAKETE_DB_AUF := 95.0
const RAKETE_DB_AB := 220.0
## Pegel, auf den das Brausen beim ersten Antippen sofort springt.  Ohne den
## Ansprung kriecht es aus der Stille hoch und setzt hoerbar zu spaet ein.
const RAKETE_DB_EINSATZ := -36.0
const RAKETE_PITCH_TEMPO := 1.6

## Melodische Klaenge bekommen keine Tonhoehen-Streuung - sonst klingen die
## Jingles jedes Mal verstimmt.  Alles andere wird pro Treffer leicht
## variiert, damit eine Bumper-Serie nicht wie ein Maschinengewehr klingt.
const KEIN_ZUFALL := ["jackpot", "save", "mode", "over", "ego_up", "count",
		"count_go", "beste"]

## Diese Klaenge laufen in Schleife.  Wird einer davon durch eine eigene Datei
## ersetzt, muss die Schleife auch dort gesetzt werden.
const DAUERKLAENGE := ["roll", "rakete"]

## Eigene Dateien ersetzen den erzeugten Klang nicht, sie liegen leise
## darunter: die echte Mechanik gibt dem synthetischen Klang Koerper, ohne
## ihn zu verdecken.  Wert ist der Abstand zum jeweiligen Spielpegel.
const DATEI_DB := -9.0

## Ausnahmen dazu: hier soll die Aufnahme lauter liegen als sonst.  Beim
## Ballverlust traegt die echte Kugel unter den Flippern den Moment, der
## erzeugte Absturz ist nur noch Beiwerk.
const DATEI_LAUTER := {"drain": 9.0}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _roll_player: AudioStreamPlayer
var _rakete_player: AudioStreamPlayer
var _rakete_db := -60.0
var _rakete_pitch := RAKETE_PITCH_START
## Fach -> Liste der Aufnahmen.  Mehrere Fassungen desselben Satzes sorgen
## dafuer, dass sie sich nicht wie ein Anrufbeantworter anhoert.
var _voice: Dictionary = {}
## Fach -> zuletzt gespielte Fassung, damit sie sich nicht wiederholt
var _voice_letzte := {}
## Tondateien in assets/voice/, die zu keinem Satz passten
var _stimme_offen: Array = []
var _duck: Tween
## Die Klaenge entstehen in einem Nebenlaeufer, damit der Start nicht
## sekundenlang haengt.  Bis sie fertig sind, bleibt es still - das faellt
## nicht auf, weil das erste Geraeusch erst mit dem ersten Tastendruck kommt.
var _bau_task := -1
var _rng := RandomNumberGenerator.new()
## Klangname -> Aufnahme aus assets/sfx/, die zusaetzlich mitlaeuft
var _aus_datei := {}

const VOICE_FILES := {
	"koop": "koop_modus",
	"beste": "ich_bin_die_beste",
	"carry_rettet": "mein_carry_rettet",
	"gern": "gern_geschehen",
	"kein_skill": "kein_skill",
	"kein_plan": "kein_plan",
	"ohne_mich": "ohne_mich",
	# Die Zeile zum Schluss.  Hiess frueher "outro" - das klang, als solle sie
	# das Wort sagen.
	"outro": "spiel_vorbei",
	"bericht": "der_bericht",
	"ball_start": "zeig_was_du_kannst",
	# Die fuenf Kanal-Antworten einzeln, damit sie genau die Zeile sprechen
	# kann, die sie daneben in den Chat schreibt.
	"kanal_1": "kanal_1", "kanal_2": "kanal_2", "kanal_3": "kanal_3",
	"kanal_4": "kanal_4", "kanal_5": "kanal_5",
}

## Zweiter Weg zur Aufnahme: ein Ordner, der so heisst wie der gesprochene
## Satz.  Darin liegen die Fassungen, durchnummeriert - "Multiball1.mp3" bis
## "Multiball4.mp3".  Der Schluessel hier ist der eingedampfte Satz (klein,
## ohne Umlaute, ohne Satzzeichen, ohne die Nummer am Ende), der Wert das
## Fach.  So kann man einen Ordner ablegen und muss nichts umbenennen.
const VOICE_TEXTE := {
	"ich_bin_die_beste": "beste",
	"multiball": "koop",
	"koop_modus": "koop",
	"zeig_doch_mal_was_du_kannst": "ball_start",
	"mein_carry_rettet": "carry_rettet",
	"kein_skill": "kein_skill",
	"die_ulti_beginnt": "bericht",
	"der_bericht": "bericht",
	"gern_geschehen": "gern",
	"kein_plan": "kein_plan",
	"ohne_mich": "ohne_mich",
	"spiel_vorbei": "outro",
	"du_warst_auch_dabei_das_war_bestimmt_schoen_fuer_dich": "outro",
	"oben_ist_der_kanal_klicken_jetzt": "kanal_1",
	"abonnieren_kostet_nichts_skill_schon": "kanal_2",
	"im_stream_mache_ich_das_mit_einer_hand": "kanal_3",
	"zuschauen_kannst_du_ja_wenigstens": "kanal_4",
	"der_knopf_oben_links_nicht_so_schwer": "kanal_5",
}

## Faecher, die einen laufenden Satz unterbrechen duerfen.  Alles andere ist
## Beiwerk und schweigt, solange sie noch spricht - sonst redet sie sich
## selbst tot.
const VOICE_WICHTIG := ["beste", "koop", "bericht", "carry_rettet", "kein_skill", "outro"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_busse()
	# Mehr Stimmen als frueher: jeder Klang kann jetzt zwei belegen, den
	# erzeugten und die Aufnahme darunter.
	for i in 20:
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
	# Das Rollen laeuft in Schleife durch, geregelt wird nur ueber Lautstaerke
	# und Tonhoehe - ein staendiges Neustarten wuerde man hoeren.
	_roll_player = AudioStreamPlayer.new()
	_roll_player.bus = SFX_BUS
	_roll_player.volume_db = -60.0
	add_child(_roll_player)
	_rakete_player = AudioStreamPlayer.new()
	_rakete_player.bus = SFX_BUS
	_rakete_player.volume_db = -60.0
	add_child(_rakete_player)
	_rng.randomize()
	_bau_task = WorkerThreadPool.add_task(_baue_im_hintergrund)
	_load_optional_audio()


func _exit_tree() -> void:
	# Beim Beenden kann der Nebenlaeufer noch mitten im Bauen stecken.  Ohne
	# dieses Warten arbeitet er auf einem Objekt weiter, das es nicht mehr
	# gibt - beim schnellen Schliessen gab das eine Fehlermeldung.
	if _bau_task != -1:
		WorkerThreadPool.wait_for_task_completion(_bau_task)
		_bau_task = -1


func _baue_im_hintergrund() -> void:
	var fertig := _build_all()
	# Erst am Stueck uebergeben - waehrend des Bauens sieht der Hauptfaden
	# weiter die (noch leere) alte Sammlung.
	_streams = fertig


func _process(delta: float) -> void:
	if _bau_task != -1 and WorkerThreadPool.is_task_completed(_bau_task):
		WorkerThreadPool.wait_for_task_completion(_bau_task)
		_bau_task = -1
		# Erst wenn die erzeugten Klaenge stehen, koennen eigene Dateien sie
		# ersetzen - so ist die Liste der Namen vollstaendig bekannt.
		_lade_sfx_dateien()
	_rollen_regeln(delta)
	_rakete_regeln(delta)


## Rollgeraeusch am Tempo der schnellsten Kugel ausrichten.  Eine ruhende,
## eingefrorene (Carry-Save) oder gar keine Kugel bedeutet Stille.
func _rollen_regeln(delta: float) -> void:
	if _roll_player == null:
		return
	if _roll_player.stream == null:
		if not _streams.has("roll"):
			return
		_roll_player.stream = _streams["roll"]
		_roll_player.play()
	var tempo := 0.0
	if not get_tree().paused:
		for b in get_tree().get_nodes_in_group("balls"):
			var ball := b as PinBall
			if ball == null or ball.freeze:
				continue
			tempo = maxf(tempo, ball.linear_velocity.length())
	var ziel_db := -60.0
	var ziel_pitch := ROLL_PITCH_LEISE
	if tempo > ROLL_MIN:
		var t: float = clampf((tempo - ROLL_MIN) / (ROLL_MAX - ROLL_MIN), 0.0, 1.0)
		ziel_db = lerpf(ROLL_DB_LEISE, ROLL_DB_LAUT, t)
		ziel_pitch = lerpf(ROLL_PITCH_LEISE, ROLL_PITCH_LAUT, t)
	_roll_player.volume_db = move_toward(
			_roll_player.volume_db, ziel_db, ROLL_DB_TEMPO * delta)
	_roll_player.pitch_scale = move_toward(
			_roll_player.pitch_scale, ziel_pitch, ROLL_PITCH_TEMPO * delta)


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

## `nur_erzeugt` laesst die Aufnahme weg und spielt allein den synthetischen
## Klang - fuer Stellen, an denen echte Mechanik nicht passt, etwa im
## Carry-Save-Countdown: dort waere die Federabschuss-Aufnahme irrefuehrend,
## weil gerade keine Feder gespannt wird.
func play(snd: String, volume_db: float = 0.0, nur_erzeugt: bool = false) -> void:
	if not _streams.has(snd):
		return
	var tonhoehe := 1.0
	var pegel := volume_db
	if not snd in KEIN_ZUFALL:
		tonhoehe = randf_range(0.97, 1.03)
		pegel += randf_range(-1.5, 1.5)
	_spiele(_streams[snd], pegel, tonhoehe)
	# Die echte Aufnahme laeuft leise darunter mit, mit derselben Streuung -
	# sonst laufen Klang und Aufnahme in der Tonhoehe auseinander.
	if _aus_datei.has(snd) and not nur_erzeugt:
		_spiele(_aus_datei[snd], pegel + DATEI_DB + float(DATEI_LAUTER.get(snd, 0.0)),
				tonhoehe)


func _spiele(stream: AudioStream, pegel: float, tonhoehe: float) -> void:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = tonhoehe
	p.volume_db = pegel
	p.play()


## Federspannung 0 bis 1 - danach richten sich Lautstaerke und Tonhoehe des
## Raketenbrausens.  0 schaltet es aus.
func rakete(spannung: float) -> void:
	if spannung <= 0.0:
		_rakete_db = -60.0
		_rakete_pitch = RAKETE_PITCH_START
		return
	var s: float = clampf(spannung, 0.0, 1.0)
	_rakete_db = lerpf(RAKETE_DB_START, RAKETE_DB_VOLL, s)
	_rakete_pitch = lerpf(RAKETE_PITCH_START, RAKETE_PITCH_VOLL, s)
	# Aus der Stille heraus sofort auf Einsatzpegel springen
	if _rakete_player != null and _rakete_player.volume_db < RAKETE_DB_EINSATZ:
		_rakete_player.volume_db = RAKETE_DB_EINSATZ


func _rakete_regeln(delta: float) -> void:
	if _rakete_player == null:
		return
	if _rakete_player.stream == null:
		if not _streams.has("rakete"):
			return
		_rakete_player.stream = _streams["rakete"]
		_rakete_player.play()
	var tempo := RAKETE_DB_AUF if _rakete_db > _rakete_player.volume_db else RAKETE_DB_AB
	_rakete_player.volume_db = move_toward(
			_rakete_player.volume_db, _rakete_db, tempo * delta)
	_rakete_player.pitch_scale = move_toward(
			_rakete_player.pitch_scale, _rakete_pitch, RAKETE_PITCH_TEMPO * delta)


## Einen Satz sprechen.  Gibt es mehrere Fassungen, wird gewuerfelt - nur
## nicht dieselbe zweimal hintereinander.
func say(line: String) -> void:
	var fassungen: Array = _voice.get(line, [])
	if fassungen.is_empty():
		return
	# Beiwerk (Spott, Kanal, Nachsaetze) faellt aus, solange noch ein Satz
	# laeuft.  Sonst schneidet sie sich selbst das Wort ab.
	if _voice_player.playing and not (line in VOICE_WICHTIG):
		return
	var i := 0
	if fassungen.size() > 1:
		i = _rng.randi_range(0, fassungen.size() - 1)
		if i == int(_voice_letzte.get(line, -1)):
			i = (i + 1) % fassungen.size()
	_voice_letzte[line] = i
	var s: AudioStream = fassungen[i]
	_voice_player.stream = s
	_voice_player.play()
	_ducke(s.get_length())


## Liegt fuer dieses Fach ueberhaupt eine Aufnahme? (Fuer die Pruefwerkzeuge.)
func hat_stimme(line: String) -> bool:
	return not (_voice.get(line, []) as Array).is_empty()


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
				s = _rng.randf() * 2.0 - 1.0
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
		var x := _rng.randf() * 2.0 - 1.0
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


## ------------------------------------------------- Werkzeuge fuer Haerte --

## Saettigung.  art 0 = weich (Pade-Naeherung an tanh), 1 = hart abgeschnitten,
## 2 = gefaltet - letzteres erzeugt die schrillen Obertoene, die beissen.
func _verzerre(s: PackedFloat32Array, drive: float, art: int = 0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(s.size())
	for i in s.size():
		var x: float = clampf(s[i] * drive, -8.0, 8.0)
		match art:
			1:
				x = clampf(x, -0.7, 0.7) / 0.7
			2:
				while x > 1.0:
					x = 2.0 - x
				while x < -1.0:
					x = -2.0 - x
			_:
				x = x * (27.0 + x * x) / (27.0 + 9.0 * x * x)
		out[i] = clampf(x, -1.0, 1.0)
	return out


## Bitcrusher: grobe Stufen und gehaltene Samples - digitaler Dreck.
func _crush(s: PackedFloat32Array, stufen: int = 8, halten: int = 3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(s.size())
	var q := 2.0 / float(maxi(2, stufen))
	var gehalten := 0.0
	for i in s.size():
		if i % maxi(1, halten) == 0:
			gehalten = round(s[i] / q) * q
		out[i] = gehalten
	return out


## Stotter-Gate: schneidet den Klang in Stuecke.  "an" ist der Anteil, in dem
## Ton kommt, die Flanken sind 1 ms lang, damit es nicht knackst.
func _stotter(s: PackedFloat32Array, hz: float, an: float = 0.5) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(s.size())
	var periode := maxi(2, int(RATE / maxf(1.0, hz)))
	var offen := maxi(1, int(periode * an))
	var rampe := maxi(1, int(0.001 * RATE))
	for i in s.size():
		var p := i % periode
		var g := 0.0
		if p < offen:
			g = minf(1.0, minf(float(p), float(offen - p)) / float(rampe))
		out[i] = s[i] * g
	return out


## Ringmodulation: multipliziert mit einem Ton.  Macht aus einem Klang etwas
## Metallisches, Unharmonisches - Biss ohne mehr Lautstaerke.
func _ringmod(s: PackedFloat32Array, freq: float, anteil: float = 0.7) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(s.size())
	var phase := 0.0
	for i in s.size():
		phase = fmod(phase + freq / RATE, 1.0)
		var m := sin(phase * TAU)
		out[i] = s[i] * (1.0 - anteil + anteil * m)
	return out


## Mehrstimmiger Saegezahn mit Glissando von f0 nach f1.  Die Stimmen sind
## gegeneinander verstimmt - das ergibt die Breite, die ein einzelner Ton
## nie hat.
func _supersaw(f0: float, f1: float, dur: float, vol: float,
		stimmen: int = 5, verstimmung: float = 0.02,
		abfall: float = 3.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var huelle := _huellkurve(n, 0.002, abfall)
	var phasen := PackedFloat32Array()
	var faktoren := PackedFloat32Array()
	for v in stimmen:
		phasen.append(_rng.randf())
		faktoren.append(1.0 + verstimmung * (float(v) / maxf(1.0, float(stimmen - 1)) - 0.5) * 2.0)
	var verhaeltnis := maxf(0.02, f1 / maxf(1.0, f0))
	var amp := vol / sqrt(float(stimmen))
	for i in n:
		var t := float(i) / n
		var f := f0 * pow(verhaeltnis, t)
		var summe := 0.0
		for v in stimmen:
			var dt: float = clampf(f * faktoren[v] / RATE, 0.0, 0.45)
			phasen[v] = fmod(phasen[v] + dt, 1.0)
			summe += 2.0 * phasen[v] - 1.0 - _blep(phasen[v], dt)
		out[i] = summe * amp * huelle[i]
	return out


## Kreischen: Saegezahn durch einen stark resonanten Filter, dessen
## Grenzfrequenz mitfaehrt.  Das ist der schneidende Anteil.
func _kreisch(dur: float, vol: float, f0: float, f1: float,
		cut0: float, cut1: float, res: float = 4.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var huelle := _huellkurve(n, 0.001, 3.0)
	var phase := 0.0
	var tief := 0.0
	var band := 0.0
	var q: float = clampf(1.0 / maxf(0.05, res), 0.0, 1.9)
	var verhaeltnis := maxf(0.02, f1 / maxf(1.0, f0))
	for i in n:
		var t := float(i) / n
		var f := f0 * pow(verhaeltnis, t)
		var dt: float = clampf(f / RATE, 0.0, 0.45)
		phase = fmod(phase + dt, 1.0)
		var x := 2.0 * phase - 1.0 - _blep(phase, dt)
		var fc: float = clampf(cut0 * pow(maxf(0.02, cut1 / maxf(1.0, cut0)), t), 60.0, RATE * 0.45)
		var g: float = clampf(2.0 * sin(PI * fc / RATE), 0.0, 1.4)
		tief += g * band
		var hoch := x - tief - q * band
		band += g * hoch
		out[i] = clampf(tief + band * 0.6, -1.5, 1.5) * vol * huelle[i]
	return out


## Wumms: Sinus, dessen Tonhoehe schnell abstuerzt - der Bass-Punch unter
## jedem Treffer.
func _wumms(f0: float, f1: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var huelle := _huellkurve(n, 0.0005, 4.0)
	var phase := 0.0
	var verhaeltnis := maxf(0.02, f1 / maxf(1.0, f0))
	for i in n:
		var t := float(i) / n
		phase = fmod(phase + f0 * pow(verhaeltnis, t) / RATE, 1.0)
		out[i] = sin(phase * TAU) * vol * huelle[i]
	return out


## Rollende Kugel als nahtlose Schleife.  Traeger ist ein schmalbandiges,
## tiefes Poltern (hohe Guete, klingt nach Kugel auf Holz statt nach Rauschen);
## der feine Grus darueber ist nur noch angedeutet, sonst zischt es.  Dazu eine
## langsame Schwebung.  Das Ende wird in den Anfang ueberblendet, damit die
## Schleife nicht tickt.
func _rollen(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var blende := int(0.06 * RATE)
	var roh := PackedFloat32Array()
	roh.resize(n + blende)
	var t1 := 0.0
	var b1 := 0.0
	var t2 := 0.0
	var b2 := 0.0
	var f1: float = clampf(2.0 * sin(PI * 165.0 / RATE), 0.0, 1.4)
	var f2: float = clampf(2.0 * sin(PI * 620.0 / RATE), 0.0, 1.4)
	# Zum Schluss noch ein einfacher Tiefpass bei 380 Hz ueber die Summe -
	# er nimmt den Rest des Zischens heraus und laesst das Poltern stehen.
	var tp := 0.0
	var tp_a := 1.0 - exp(-TAU * 380.0 / RATE)
	var schweb := 0.0
	for i in roh.size():
		var x := _rng.randf() * 2.0 - 1.0
		t1 += f1 * b1
		b1 += f1 * (x - t1 - 0.22 * b1)
		t2 += f2 * b2
		b2 += f2 * (x - t2 - 1.5 * b2)
		schweb = fmod(schweb + 2.7 / RATE, 1.0)
		var am := 0.82 + 0.18 * sin(schweb * TAU)
		tp += tp_a * (b1 * 1.5 + b2 * 0.035 + t1 * 1.2 - tp)
		roh[i] = clampf(tp, -1.0, 1.0) * am
	# Ueberblendung: der Anfang der Schleife wird mit dem Material direkt
	# hinter ihrem Ende gemischt.  Damit geht das letzte Sample (roh[n-1])
	# stetig in das erste ueber (roh[n]) - genau das, was beim Rundlauf
	# aneinanderstoesst.  Andersherum gemischt klafft dort eine Stufe.
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = roh[i]
	for j in blende:
		var w := float(j) / float(blende)
		out[j] = roh[n + j] * (1.0 - w) + roh[j] * w
	return out


## Raketenbrausen als nahtlose Schleife: unten ein Grollen (60 Hz, hohe Guete),
## darueber das Roehren der Duese (450 Hz, breiter) und obendrauf ein Zischen,
## das erst die Wucht macht.  Leichte Saettigung gibt Schub statt Rauschen.
## Ueber die Tonhoehe des Players wird daraus beim Spannen ein Hochfahren.
func _rakete_schleife(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var blende := int(0.08 * RATE)
	var roh := PackedFloat32Array()
	roh.resize(n + blende)
	var t1 := 0.0
	var b1 := 0.0
	var t2 := 0.0
	var b2 := 0.0
	var t3 := 0.0
	var b3 := 0.0
	var f1: float = clampf(2.0 * sin(PI * 60.0 / RATE), 0.0, 1.4)
	var f2: float = clampf(2.0 * sin(PI * 450.0 / RATE), 0.0, 1.4)
	var f3: float = clampf(2.0 * sin(PI * 2600.0 / RATE), 0.0, 1.4)
	var schweb := 0.0
	for i in roh.size():
		var x := _rng.randf() * 2.0 - 1.0
		t1 += f1 * b1
		b1 += f1 * (x - t1 - 0.25 * b1)
		t2 += f2 * b2
		b2 += f2 * (x - t2 - 0.9 * b2)
		t3 += f3 * b3
		b3 += f3 * (x - t3 - 1.6 * b3)
		# Langsames Wummern, wie es ein Triebwerk im Standlauf hat
		schweb = fmod(schweb + 5.5 / RATE, 1.0)
		var am := 0.85 + 0.15 * sin(schweb * TAU)
		var mix := b1 * 1.5 + t1 * 1.2 + b2 * 0.9 + b3 * 0.35
		# weiche Saettigung: druckvoll statt spitz
		mix = mix * (27.0 + mix * mix) / (27.0 + 9.0 * mix * mix)
		roh[i] = clampf(mix, -1.0, 1.0) * am
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = roh[i]
	for j in blende:
		var w := float(j) / float(blende)
		out[j] = roh[n + j] * (1.0 - w) + roh[j] * w
	return out


## Wisch: etwas faehrt schnell vorbei.  Ein Rauschband, dessen Mitte erst
## steil hochzieht und danach abfaellt - dieser Knick ist der Doppler-Effekt,
## der einen vorbeifahrenden Zug oder Jet ausmacht.  Die Lautstaerke folgt
## einer Glocke: von fern heran, laut vorbei, wieder weg.
func _wisch(dur: float, vol: float, f_start: float, f_scheitel: float,
		f_ende: float, res: float = 2.2, scheitel: float = 0.42) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var tief := 0.0
	var band := 0.0
	var q: float = clampf(1.0 / maxf(0.05, res), 0.0, 1.9)
	for i in n:
		var t := float(i) / n
		var fc: float
		if t < scheitel:
			fc = f_start * pow(f_scheitel / f_start, t / scheitel)
		else:
			fc = f_scheitel * pow(f_ende / f_scheitel, (t - scheitel) / (1.0 - scheitel))
		var f: float = clampf(2.0 * sin(PI * clampf(fc, 60.0, RATE * 0.45) / RATE), 0.0, 1.4)
		var x := _rng.randf() * 2.0 - 1.0
		tief += f * band
		var hoch := x - tief - q * band
		band += f * hoch
		# Glockenkurve, hinten laenger als vorne - so klingt Vorbeifahren
		var huelle := pow(sin(PI * pow(t, 0.8)), 1.4)
		out[i] = clampf(band * 1.2 + tief * 0.5, -1.5, 1.5) * vol * huelle
	return out


## Auf einen Zielpegel bringen - nach Verzerrung sonst kaum vorhersehbar.
func _norm(s: PackedFloat32Array, ziel: float = 0.8) -> PackedFloat32Array:
	var spitze := 0.0
	for v in s:
		spitze = maxf(spitze, absf(v))
	if spitze < 0.0001:
		return s
	var f := ziel / spitze
	var out := PackedFloat32Array()
	out.resize(s.size())
	for i in s.size():
		out[i] = s[i] * f
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


## Wie _wav, aber als Endlosschleife - fuer das Rollgeraeusch.
func _wav_schleife(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := _wav(samples)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples.size() - 1
	return wav


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


func _build_all() -> Dictionary:
	var s := {}
	# Flipper: Schlag mit Bass darunter, kurz und bissig
	s["flip"] = _wav(_norm(_stack([
			_crush(_klack(0.022, 0.5, 2600.0, 0.9), 6, 3),
			_verzerre(_supersaw(220.0, 90.0, 0.06, 0.5, 3, 0.03, 5.0), 3.0, 1),
			_wumms(150.0, 55.0, 0.09, 0.7)]), 0.82))

	# Bumper: mehrstimmiger Stich, der in die Tiefe rutscht, mit Ringmodulation
	# als Biss.  Die vier Tonhoehen bleiben (S am tiefsten, D am hoechsten).
	for b in [["w", 233.0], ["a", 196.0], ["s", 165.0], ["d", 262.0]]:
		var f: float = b[1]
		s["bump_" + str(b[0])] = _wav(_norm(_stack([
				_wumms(f * 2.0, f * 0.5, 0.13, 0.8),
				_verzerre(_supersaw(f * 4.0, f * 1.98, 0.20, 0.5, 5, 0.035, 3.4), 3.2, 0),
				_ringmod(_kreisch(0.10, 0.35, f * 4.0, f * 7.0, 1100.0, 5400.0, 5.0), f * 3.0, 0.6),
				_crush(_klack(0.02, 0.45, 3000.0, 0.9), 5, 2)]), 0.86))

	# Slingshot: kurzer Kreischer, der nach unten wegzieht
	s["sling"] = _wav(_norm(_stack([
			_kreisch(0.09, 0.5, 900.0, 220.0, 6500.0, 700.0, 6.0),
			_verzerre(_crush(_klack(0.04, 0.5, 3600.0, 0.8, -2200.0), 5, 2), 2.0, 2),
			_wumms(200.0, 60.0, 0.08, 0.5)]), 0.84))
	# Spinner: winziger Digitalzap, kommt pro Umdrehung
	s["spin"] = _wav(_norm(_stack([
			_crush(_kreisch(0.035, 0.5, 1400.0, 2600.0, 3000.0, 7000.0, 6.0), 4, 3),
			_klack(0.012, 0.3, 5200.0, 0.7)]), 0.7))
	s["target"] = _wav(_norm(_stack([
			_verzerre(_supersaw(520.0, 300.0, 0.12, 0.5, 4, 0.03, 4.0), 3.5, 2),
			_crush(_klack(0.018, 0.4, 3400.0, 0.9), 5, 2),
			_wumms(180.0, 70.0, 0.09, 0.5)]), 0.82))
	# Standup: schriller Aufwaertszischer
	s["standup"] = _wav(_norm(_stack([
			_ringmod(_kreisch(0.11, 0.5, 700.0, 2400.0, 1800.0, 8000.0, 6.5), 1150.0, 0.5),
			_crush(_klack(0.014, 0.35, 4200.0, 0.8), 4, 2)]), 0.8))
	# Mulde: die Kugel wird eingesaugt - stotternder Abwaertszug
	s["lock"] = _wav(_norm(_stack([
			_stotter(_verzerre(_supersaw(560.0, 120.0, 0.3, 0.5, 4, 0.03, 2.2), 3.0, 0), 26.0, 0.55),
			_wumms(240.0, 50.0, 0.18, 0.6)]), 0.82))
	# Auswurf: schnell nach oben, verzerrt
	s["eject"] = _wav(_norm(_stack([
			_verzerre(_supersaw(180.0, 900.0, 0.16, 0.5, 4, 0.03, 3.0), 3.4, 1),
			_crush(_klack(0.05, 0.4, 1200.0, 1.0, 4000.0), 5, 2)]), 0.84))
	# Jackpot: Bombast - drei Powerchord-Stiche, dann ein langer, stotternder
	s["jackpot"] = _wav(_norm(_seq([
			_akkord(523.0, 0.12, 0.5, 3.2),
			_akkord(659.0, 0.12, 0.5, 3.2),
			_akkord(784.0, 0.14, 0.5, 3.4),
			_stack([
				_stotter(_akkord(1047.0, 0.42, 0.55, 3.6), 20.0, 0.68),
				_verzerre(_supersaw(1047.0, 1600.0, 0.42, 0.35, 5, 0.03, 2.0), 3.0, 2),
				_wumms(180.0, 60.0, 0.22, 0.8)])]), 0.9))
	# Ballverlust: Absturz mit Faltung, am Ende zerhackt
	s["drain"] = _wav(_norm(_stack([
			_verzerre(_supersaw(330.0, 55.0, 0.75, 0.55, 5, 0.04, 1.8), 3.6, 2),
			_stotter(_verzerre(_kreisch(0.75, 0.4, 220.0, 45.0, 5000.0, 400.0, 5.0), 2.2, 0), 14.0, 0.6),
			_wumms(160.0, 38.0, 0.4, 0.8)]), 0.88))
	# Abschuss: rauf, mit beschleunigendem Stottern
	s["launch"] = _wav(_norm(_stack([
			_stotter(_verzerre(_supersaw(90.0, 520.0, 0.28, 0.5, 5, 0.035, 2.2), 3.0, 0), 30.0, 0.6),
			_kreisch(0.28, 0.35, 120.0, 900.0, 400.0, 6000.0, 5.0),
			_wumms(120.0, 60.0, 0.2, 0.6)]), 0.86))
	# Carry-Save: heldenhafter Aufstieg
	s["save"] = _wav(_norm(_seq([
			_akkord(392.0, 0.11, 0.5, 3.2),
			_akkord(523.0, 0.11, 0.5, 3.2),
			_stack([
				_akkord(659.0, 0.34, 0.55, 3.0),
				_verzerre(_supersaw(659.0, 990.0, 0.34, 0.3, 5, 0.03, 2.2), 2.8, 2),
				_wumms(165.0, 60.0, 0.2, 0.7)])]), 0.9))
	# Modus-Start: fetter Stich mit Zerhacker
	s["mode"] = _wav(_norm(_seq([
			_akkord(262.0, 0.14, 0.5, 3.0),
			_akkord(330.0, 0.14, 0.5, 3.0),
			_stack([
				_stotter(_akkord(392.0, 0.4, 0.55, 2.6), 16.0, 0.62),
				_wumms(196.0, 55.0, 0.24, 0.8)])]), 0.9))
	# Game Over: langer Absturz, gefaltet
	s["over"] = _wav(_norm(_stack([
			_verzerre(_supersaw(300.0, 45.0, 0.9, 0.55, 4, 0.045, 1.4), 3.8, 2),
			_stotter(_kreisch(0.9, 0.35, 240.0, 40.0, 4000.0, 300.0, 5.5), 9.0, 0.55),
			_wumms(140.0, 32.0, 0.5, 0.85)]), 0.88))
	s["tick"] = _wav(_norm(_crush(_klack(0.012, 0.4, 6000.0, 0.6), 4, 2), 0.6))
	# Kurzes trockenes Klack: die Kugel wird festgehalten.  Nur Anschlag,
	# kein Nachklang - man soll hoeren, dass etwas zuschnappt.
	s["klack"] = _wav(_norm(_stack([
			_klack(0.035, 0.6, 1500.0, 1.5, -600.0),
			_koerper([260.0, 520.0], 0.05, 0.35, 6.0)]), 0.8))
	# Auszahlung des Gluecksrads: kurz und eigenstaendig.  Vorher lieh sich das
	# Rad je nach Gewinnhoehe die Jingles von Jackpot, Ego und Countdown - vier
	# fremde Klaenge fuer ein Element, was den Jubel im Spiel verdoppelt hat.
	s["rad_zahlt"] = _wav(_norm(_stack([
			_crush(_kreisch(0.16, 0.5, 700.0, 1500.0, 2200.0, 5200.0, 5.0), 5, 2),
			_wumms(280.0, 110.0, 0.12, 0.55)]), 0.75))
	# Bandenkontakt: kurzer Blechtick.  Lautstaerke kommt vom Aufpralltempo,
	# deshalb hier eher zurueckhaltend gebaut.
	s["rail"] = _wav(_norm(_stack([
			_klack(0.022, 0.5, 2400.0, 1.3),
			_koerper([840.0, 1930.0], 0.05, 0.3, 5.0)]), 0.7))
	# Rollende Kugel, laeuft als Schleife durch (siehe _rollen_regeln)
	s["roll"] = _wav_schleife(_norm(_rollen(1.2), 0.75))
	# Raketenbrausen beim Spannen der Feder (siehe _rakete_regeln)
	s["rakete"] = _wav_schleife(_norm(_rakete_schleife(1.4), 0.8))
	# Abschuss-Wisch: der vorbeischiessende Jet.  Zwei Baender uebereinander,
	# das zweite etwas spaeter und tiefer - das gibt Breite.
	s["wisch"] = _wav(_norm(_stack([
			_wisch(0.55, 0.7, 260.0, 3400.0, 420.0, 2.4),
			_wisch(0.62, 0.45, 180.0, 1500.0, 240.0, 3.2, 0.5),
			_wumms(220.0, 70.0, 0.16, 0.5)]), 0.88))
	s["count"] = _wav(_norm(_stack([
			_verzerre(_supersaw(560.0, 480.0, 0.12, 0.5, 3, 0.03, 3.6), 3.0, 1),
			_wumms(200.0, 70.0, 0.09, 0.5)]), 0.8))
	s["count_go"] = _wav(_norm(_stack([
			_akkord(784.0, 0.3, 0.55, 3.0),
			_verzerre(_supersaw(784.0, 1400.0, 0.3, 0.3, 5, 0.03, 2.4), 3.0, 2),
			_wumms(180.0, 60.0, 0.18, 0.7)]), 0.88))
	# Grollen vor dem Carry-Save: bleibt, wie es ist
	s["rumble"] = _wav(_stack([
			_tone(65.0, 0.5, 0.4, "saw", 30.0, 1.1),
			_tone(85.0, 0.5, 0.42, "saw", 150.0, 1.1),
			_klack(0.5, 0.22, 260.0, 1.8, 220.0)]))
	s["crank"] = _wav(_norm(_crush(_stack([
			_klack(0.014, 0.4, 2200.0, 0.7),
			_tone(150.0, 0.03, 0.3, "saw", -40.0)]), 5, 3), 0.62))
	# Ego-Aufstieg: vierstufige Treppe, jede Stufe haerter
	s["ego_up"] = _wav(_norm(_seq([
			_akkord(330.0, 0.08, 0.45, 3.4),
			_akkord(415.0, 0.08, 0.48, 3.4),
			_akkord(523.0, 0.08, 0.5, 3.4),
			_stack([
				_stotter(_akkord(659.0, 0.34, 0.55, 2.8), 22.0, 0.66),
				_verzerre(_supersaw(659.0, 1050.0, 0.34, 0.3, 5, 0.03, 2.2), 3.0, 2),
				_wumms(165.0, 55.0, 0.2, 0.75)])]), 0.9))
	return s


## Powerchord: Grundton, Quinte und Oktave mehrstimmig und verzerrt - das
## Rueckgrat der lauten Klaenge.
func _akkord(grundton: float, dur: float, vol: float,
		drive: float = 3.0) -> PackedFloat32Array:
	return _verzerre(_stack([
			_supersaw(grundton, grundton * 0.99, dur, vol * 0.55, 3, 0.03, 3.0),
			_supersaw(grundton * 1.5, grundton * 1.49, dur, vol * 0.4, 2, 0.03, 3.0),
			_supersaw(grundton * 2.0, grundton * 1.99, dur, vol * 0.3, 2, 0.03, 3.2),
			_supersaw(grundton * 0.5, grundton * 0.5, dur, vol * 0.45, 2, 0.02, 3.0)]),
			drive, 0)


## Eigene Aufnahmen laufen zusaetzlich mit: liegt in assets/sfx/ eine Datei
## mit dem Namen eines Klangs (.ogg, .wav oder .mp3), wird sie bei jedem
## Abspielen leise unter den erzeugten Klang gelegt.  Der synthetische Klang
## bleibt also erhalten, die Aufnahme gibt ihm nur Koerper.
##
## Ausnahme sind die Dauerklaenge (roll, rakete): die haengen an einem eigenen
## Spieler mit geregelter Lautstaerke und Tonhoehe.  Dort ersetzt die Datei.
func _lade_sfx_dateien() -> void:
	for snd in _streams.keys():
		var s := _load_stream("res://assets/sfx/" + str(snd))
		if s == null:
			continue
		if str(snd) in DAUERKLAENGE:
			_setze_schleife(s)
			_streams[snd] = s
		else:
			_aus_datei[snd] = s
	if not _aus_datei.is_empty():
		var namen := _aus_datei.keys()
		namen.sort()
		print("Sfx: Aufnahmen liegen unter %s" % ", ".join(PackedStringArray(namen)))


## Dauerklaenge muessen in Schleife laufen, sonst brechen sie nach einmal ab.
func _setze_schleife(s: AudioStream) -> void:
	if s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / (2 if s.format == AudioStreamWAV.FORMAT_16_BITS else 1)


## Alles einsammeln, was in assets/voice/ liegt - flach abgelegte Dateien
## genauso wie ganze Ordner mit mehreren Fassungen.  Zugeordnet wird ueber den
## Namen: erst die Datei, dann ersatzweise der Ordner darum.
func _load_optional_audio() -> void:
	var gefunden := {}
	_stimme_offen.clear()
	_sammle_stimmen("res://assets/voice", gefunden, 0)
	for fach in gefunden:
		var pfade: Array = gefunden[fach]
		# Sortiert, damit Fassung 1 auch die erste ist - das Wuerfeln kommt
		# spaeter und soll nicht schon von der Dateireihenfolge abhaengen.
		pfade.sort()
		for p in pfade:
			var st := _lade_datei(str(p))
			if st == null:
				continue
			if not _voice.has(fach):
				_voice[fach] = []
			_voice[fach].append(st)
	_stimme_bericht()
	var m := _load_stream("res://assets/music/loop")
	if m != null:
		if m is AudioStreamOggVorbis:
			m.loop = true
		elif m is AudioStreamMP3:
			m.loop = true
		_music_player.stream = m
		_music_player.play()


func _load_stream(base: String) -> AudioStream:
	for e in ["ogg", "wav", "mp3"]:
		if FileAccess.file_exists(base + "." + e):
			return _lade_datei(base + "." + e)
	return null


## Eine einzelne Tondatei laden - an der Endung entscheidet sich, wie.  Die
## Dateien gehen nicht durch den Import des Editors, sie werden beim Start
## direkt gelesen; deshalb genuegt es, sie ins Verzeichnis zu legen.
func _lade_datei(pfad: String) -> AudioStream:
	match pfad.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(pfad)
		"wav":
			return AudioStreamWAV.load_from_file(pfad)
		"mp3":
			var f := FileAccess.open(pfad, FileAccess.READ)
			if f:
				var mp3 := AudioStreamMP3.new()
				mp3.data = f.get_buffer(f.get_length())
				return mp3
	return null


## Verzeichnis samt Unterordnern durchgehen und die Tondateien den Faechern
## zuordnen.  Geladen wird erst spaeter und nur, was zugeordnet werden konnte -
## eine 30-MB-Rohaufnahme, die hier herumliegt, kostet so keinen Speicher.
func _sammle_stimmen(pfad: String, gefunden: Dictionary, tiefe: int) -> void:
	var d := DirAccess.open(pfad)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n != "." and n != "..":
			var voll := pfad + "/" + n
			if d.current_is_dir():
				if tiefe < 3:
					_sammle_stimmen(voll, gefunden, tiefe + 1)
			elif n.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
				# Erst der Dateiname, dann der Ordner darum: manche Werkzeuge
				# schreiben in einen schoen benannten Ordner eine Datei mit
				# kryptischem Namen.
				var fach := _fach_zu(_texthaken(n.get_basename()))
				if fach == "":
					fach = _fach_zu(_texthaken(pfad.get_file()))
				if fach == "":
					_stimme_offen.append(n)
					n = d.get_next()
					continue
				if not gefunden.has(fach):
					gefunden[fach] = []
				gefunden[fach].append(voll)
		n = d.get_next()
	d.list_dir_end()


## Aus einem Datei- oder Ordnernamen den Satz herausschaelen: klein schreiben,
## Umlaute aufloesen, Satzzeichen und Leerzeichen zu Unterstrichen, die
## angehaengte Nummer der Fassung abschneiden.  "Ich bin die beste2" und
## "ich_bin_die_beste (2)" ergeben beide "ich_bin_die_beste".
func _texthaken(name: String) -> String:
	var t := name.to_lower()
	t = t.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue")
	t = t.replace("ß", "ss").replace("é", "e")
	const ERLAUBT := "abcdefghijklmnopqrstuvwxyz0123456789"
	var roh := ""
	for c in t:
		roh += c if ERLAUBT.contains(c) else "_"
	while roh.contains("__"):
		roh = roh.replace("__", "_")
	roh = roh.trim_prefix("_").trim_suffix("_")
	# Nummer der Fassung am Ende weg
	while roh.length() > 0 and roh[-1] >= "0" and roh[-1] <= "9":
		roh = roh.substr(0, roh.length() - 1)
	return roh.trim_suffix("_")


## Welcher Satz gehoert in welches Fach?  Erst genau, dann nachsichtig: wer
## seinen Ordner "kein Plan oder was" nennt, landet trotzdem bei "kein_plan".
func _fach_zu(haken: String) -> String:
	if haken == "":
		return ""
	if VOICE_TEXTE.has(haken):
		return VOICE_TEXTE[haken]
	# Auch die Fachnamen selbst gelten - "spott_3.mp3" liegt dann richtig.
	for key in VOICE_FILES:
		if haken == key or haken == VOICE_FILES[key]:
			return key
	# Nachsichtig ueber den gemeinsamen Anfang: wer beim Tippen ein Wort
	# auslaesst ("das bestimmt schoen" statt "das war bestimmt schoen"), landet
	# trotzdem richtig.  14 Zeichen sind genug, um Verwechslungen zu
	# vermeiden - "kein_plan" und "kein_skill" teilen nur fuenf.
	const MINDEST := 14
	var treffer := ""
	var laenge := MINDEST - 1
	for k in VOICE_TEXTE:
		var s := str(k)
		var i := 0
		while i < s.length() and i < haken.length() and s[i] == haken[i]:
			i += 1
		if i > laenge:
			treffer = VOICE_TEXTE[k]
			laenge = i
	return treffer


## Was gefunden wurde, steht beim Start in der Ausgabe - und ebenso, was
## danebenlag und zu keinem Satz passte.
func _stimme_bericht() -> void:
	if not _voice.is_empty():
		var zeilen := PackedStringArray()
		var faecher := _voice.keys()
		faecher.sort()
		for f in faecher:
			zeilen.append("%s %d" % [f, (_voice[f] as Array).size()])
		print("Stimme: " + ", ".join(zeilen))
	if not _stimme_offen.is_empty():
		_stimme_offen.sort()
		print("Stimme: ohne Fach liegen geblieben: " + ", ".join(
				PackedStringArray(_stimme_offen)))

