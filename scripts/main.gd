extends Node2D
## Spielsteuerung: Ballfluss, Disziplinen/Modi, Plunger, Ruhe-Modus,
## Match-Report.

const SPAWN := Vector2(495, 854)

## Der Carry-Save gilt nur die ersten Sekunden eines Balls - danach spottet
## die Queen.
const SAVE_WINDOW := 20.0
## Laufzeit des Wizard-Modus "Der Bericht"
const WIZARD_TIME := 40.0
## Laufzeit der Damage-Frenzy
const FRENZY_TIME := 20.0

const QUEEN_SPOTT := [
	"Warst du nicht gut genug?",
	"Einfach mal besser sein.",
	"Skill-Issue. Nicht meins.",
	"Ich haette den gehalten. Locker.",
	"Reflexe wie ein Ladebildschirm.",
	"Soll ich das auch noch fuer dich machen?",
	"Uebung. Ganz viel Uebung.",
	"War bestimmt der Ping, ne?",
]

const WIZARD_LINES := [
	"WER MACHT DEN SCHADEN? ICH.",
	"WER HOLT DIE KILLS? ICH.",
	"WER RETTET DEN KAMPF? ICH.",
	"WER SEID IHR? NICHTS.",
]

var hud: Hud
var flipper_l: Flipper
var flipper_r: Flipper
var throne: Throne
var plunger: Plunger
var gate: PassGate
var drops: Array = []
var standups: Array = []
var ggez: Array = []
var ego_bank: Array = []
var lane_chevrons: Array = []
var bumpers: Dictionary = {}
var locked_balls: Array = []
var dim: CanvasModulate

var charge := 0.0
var charging := false
var _crank_step := 0

var streak_letters := {}

var hurry_active := false
var hurry_value := 0
var hurry_time := 0.0

var save_time := 0.0
## I-C-H und E-G-O gibt es je einmal pro Ball
var _ich_done := false
var _ego_done := false

## Test-Hilfe: Strg+Umschalt+G schaltet unendlich viele Baelle ein.
var god_mode := false

var frenzy_time := 0.0
var wizard_time := 0.0
var wizard_line_time := 0.0
var wizard_line_idx := 0
## Ruhe-Modus: der Tisch dimmt nach dem Spielende und nach 120 Sekunden
## ohne Eingabe; die naechste Eingabe bzw. das naechste Spiel weckt ihn.
const IDLE_DIM_AFTER := 120.0
const DIM_COLOR := Color(0.38, 0.33, 0.48)

var idle_time := 0.0
var dimmed := false

var _touch_flip := {}
var _touch_launch := {}

var nudge_heat := 0.0
var _shake_tween: Tween

# Nur fuer automatisierte Tests (Start mit "-- --autotest")
var autotest := false
var _at_l := false
var _at_r := false
var _at_launch_cool := 0.0


func _ready() -> void:
	_setup_env()
	var refs := Table.build(self)
	flipper_l = refs["flipper_l"]
	flipper_r = refs["flipper_r"]
	drops = refs["drops"]
	standups = refs["standups"]
	ggez = refs.get("ggez", [])
	ego_bank = refs.get("ego_bank", [])
	lane_chevrons = refs.get("lane_chevrons", [])
	bumpers = refs.get("bumpers", {})
	throne = refs.get("throne", null)
	plunger = refs["plunger"]
	gate = refs.get("gate", null)
	if throne:
		throne.captured.connect(_on_throne_captured)
	_make_drain()
	hud = Hud.new()
	add_child(hud)
	hud.continue_pressed.connect(_on_continue)
	Game.event.connect(_on_event)
	Game.reset_game()
	_start_ball(true)
	if "--shot" in OS.get_cmdline_user_args():
		_take_shot()
	if "--autotest" in OS.get_cmdline_user_args():
		autotest = true
		# Ohne randomize() wuerfelt Godot in jedem Lauf gleich - fuer
		# Messreihen brauchen wir unterschiedliche Spielverlaeufe.
		randomize()
		var t := Timer.new()
		t.wait_time = 0.4
		t.process_mode = Node.PROCESS_MODE_ALWAYS
		t.timeout.connect(_autotest_pulse)
		add_child(t)
		t.start()


func _setup_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	we.environment = env
	add_child(we)
	dim = CanvasModulate.new()
	dim.color = Color.WHITE
	add_child(dim)


func _make_drain() -> void:
	var area := Area2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(700, 140)
	cs.shape = sh
	area.position = Vector2(270, 1040)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_drain)


func _input(event: InputEvent) -> void:
	if event.is_pressed() and (event is InputEventKey
			or event is InputEventMouseButton or event is InputEventScreenTouch):
		_wake()
	# God-Modus zum Testen: Strg + Umschalt + G
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_G and event.ctrl_pressed and event.shift_pressed:
		god_mode = not god_mode
		hud.set_god(god_mode)
		hud.show_message("GOD-MODUS " + ("AN" if god_mode else "AUS"),
				"Unendlich Baelle." if god_mode else "Wieder drei Baelle.", 2.0)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		# Tippen in der Chat-Spalte rechts steuert nichts
		if event.position.x >= Table.FIELD_W:
			return
		if event.pressed:
			if event.position.x > 430 and event.position.y > 700:
				_touch_launch[event.index] = true
			elif event.position.x < 270:
				_touch_flip[event.index] = "l"
			else:
				_touch_flip[event.index] = "r"
		else:
			_touch_flip.erase(event.index)
			_touch_launch.erase(event.index)


func _physics_process(delta: float) -> void:
	if Game.game_over:
		return
	_update_flippers()
	_update_nudge(delta)
	_update_plunger(delta)
	_update_timers(delta)
	_cleanup_lost_balls()


func _update_flippers() -> void:
	var lp := Input.is_action_pressed("flip_left")
	var rp := Input.is_action_pressed("flip_right")
	if autotest:
		lp = _at_l
		rp = _at_r
	for v in _touch_flip.values():
		if v == "l":
			lp = true
		elif v == "r":
			rp = true
	if Game.tilted:
		lp = false
		rp = false
	flipper_l.set_pressed(lp)
	flipper_r.set_pressed(rp)


func _update_nudge(delta: float) -> void:
	nudge_heat = maxf(0.0, nudge_heat - delta * 0.6)
	if Game.tilted:
		return
	var dir := 0.0
	if Input.is_action_just_pressed("nudge_left"):
		dir = 1.0
	elif Input.is_action_just_pressed("nudge_right"):
		dir = -1.0
	if dir == 0.0:
		return
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and not b.freeze:
			b.apply_central_impulse(Vector2(dir * 110.0, -70.0))
	Sfx.play("target", -8.0)
	_shake(dir)
	nudge_heat += 1.0
	if nudge_heat > 3.0:
		_tilt()
	elif nudge_heat > 2.0:
		hud.show_sub("Vorsicht. Gleich gibt's einen RAGEQUIT.", 1.2)


func _shake(dir: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	position.x = 0.0
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "position:x", dir * 7.0, 0.05)
	_shake_tween.tween_property(self, "position:x", 0.0, 0.12)


func _tilt() -> void:
	Game.tilted = true
	Sfx.play("over", -2.0)
	hud.show_message("RAGEQUIT!", "Tilt. Flipper tot, Punkte tot. Wie dein Team.", 3.0)
	Game.emit("tilt")


func _update_plunger(delta: float) -> void:
	var lane_ball: PinBall = null
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and not b.freeze and not b.is_queued_for_deletion():
			if b.global_position.x > Table.DIVIDER and b.global_position.y > 780:
				lane_ball = b
				break
	# Lane-Pfeile blinken, solange ein Ball abschussbereit liegt
	for c in lane_chevrons:
		c.set_blink(lane_ball != null)
	if autotest:
		_at_launch_cool = maxf(0.0, _at_launch_cool - delta)
		if lane_ball != null and _at_launch_cool <= 0.0:
			_at_launch_cool = 1.5
			lane_ball.apply_central_impulse(Vector2(0, -randf_range(1570.0, 1920.0)))
			Game.emit("launch")
		hud.set_power(0.0, false)
		return
	if lane_ball != null:
		var pressed := Input.is_action_pressed("launch") or not _touch_launch.is_empty()
		if pressed:
			charging = true
			charge = minf(1.0, charge + delta * 0.8)
			plunger.compress(charge)
			# Die Feder faehrt hoch wie ein Triebwerk: das Brausen wird lauter
			# und hoeher, je weiter gespannt ist.
			Sfx.rakete(0.06 + 0.94 * charge)
			# Ratschen-Klicks, waehrend sich die Feder spannt
			var step := int(charge * 12.0)
			if step != _crank_step:
				_crank_step = step
				Sfx.play("crank", -15.0)
		elif charging:
			_crank_step = 0
			Sfx.rakete(0.0)
			plunger.release()
			# Volle Ladung landet im Streu-Fenster des Bogens: mal haelt der
			# Ball den Scheitel bis zum Trichter links, mal reisst er ab und
			# faellt in eine der G-G-E-Z-Gassen, mal kommt er rechts zurueck.
			# Maximalkraft zweimal um 5 Prozent angehoben (voll: 1819 statt
			# urspruenglich 1650), der Antipp-Wert bleibt bei 700.  Der
			# Zufallsfaktor von plus minus 5 Prozent sorgt weiter fuer
			# wechselnde Einwurfwege.
			var power := (700.0 + 1119.0 * charge) * randf_range(0.95, 1.05)
			lane_ball.apply_central_impulse(Vector2(0, -power))
			Sfx.play("launch", -7.0)
			# Dazu der Wisch eines vorbeischiessenden Jets, nach Ladung dosiert
			Sfx.play("wisch", lerpf(-17.0, -3.0, charge))
			Game.emit("launch")
			charging = false
			charge = 0.0
	else:
		if charging:
			Sfx.rakete(0.0)
			plunger.release()
		charging = false
		charge = 0.0
	hud.set_power(charge, charging)


func _update_timers(delta: float) -> void:
	# Der Durchlauf blinkt nur waehrend eines laufenden Hurry-Up
	if gate:
		gate.set_armed(hurry_active)
	# Carry-Save laeuft nach SAVE_WINDOW Sekunden ab - danach haelt sie nichts
	# mehr, kommentiert es aber gerne.
	if Game.ball_save_armed and save_time > 0.0:
		save_time -= delta
		if save_time <= 0.0:
			Game.ball_save_armed = false
			Game.emit("save_armed")
			hud.show_sub("Carry-Save vorbei. " + spott(), 2.2)
	if hurry_active:
		hurry_time -= delta
		hurry_value = maxi(5000, hurry_value - int(1600.0 * delta))
		if hurry_time <= 0.0:
			_end_hurry()
			hud.show_sub("Hurry-Up vorbei. " + spott(), 1.8)
	if frenzy_time > 0.0:
		frenzy_time -= delta
		# Die DAMAGE-Bank blinkt, solange die Frenzy laeuft - und zwar umso
		# schneller, je weniger Zeit uebrig ist.
		var hektik := 5.0 + 12.0 * (1.0 - frenzy_time / FRENZY_TIME)
		for d in drops:
			d.set_pulsing(frenzy_time > 0.0, hektik)
		hud.set_frenzy(true, frenzy_time / FRENZY_TIME)
		if frenzy_time <= 0.0:
			Game.frenzy = false
			hud.set_frenzy(false)
			# Bank wieder aufstellen: dunkel und damit erneut abraeumbar
			for d in drops:
				d.reset()
			hud.show_sub("Frenzy vorbei. " + spott(), 1.8)
	if Game.wizard:
		wizard_time -= delta
		hud.set_wizard(true, wizard_time / WIZARD_TIME)
		wizard_line_time -= delta
		if wizard_line_time <= 0.0 and wizard_line_idx < WIZARD_LINES.size():
			hud.show_message(WIZARD_LINES[wizard_line_idx], "", 3.0)
			wizard_line_idx += 1
			wizard_line_time = 4.0
		if wizard_time <= 0.0:
			_end_wizard()
	# Ruhe-Modus: lange keine Eingabe -> Tisch dimmt.  Gedrueckt gehaltene
	# Tasten zaehlen mit (die liefern kein neues Eingabe-Ereignis), ebenso
	# der Autotest.
	if autotest or Input.is_action_pressed("flip_left") \
			or Input.is_action_pressed("flip_right") \
			or Input.is_action_pressed("launch"):
		_wake()
	idle_time += delta
	if idle_time >= IDLE_DIM_AFTER:
		_set_dimmed(true)


func _cleanup_lost_balls() -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and not b.is_queued_for_deletion() and b.global_position.y > 1100:
			b.queue_free()
			call_deferred("_after_drain")


func _on_event(kind: String, data: Dictionary) -> void:
	if autotest and kind in ["spinner", "gate", "save", "pocket", "ggez",
			"rollover", "standup", "kill", "frenzy", "wizard", "multiball",
			"jackpot", "discipline", "all_disciplines", "ego_level", "tilt",
			"wheel", "wheel_hit"]:
		var extra := ""
		if data.has("letter"):
			extra = " " + str(data["letter"])
		elif data.has("rang"):
			extra = " " + str(data["rang"]) + " " + str(data.get("roh", 0))
		elif data.has("name"):
			extra = " " + str(data["name"])
		elif data.has("mult"):
			extra = " x" + str(data["mult"])
		print("AUTOTEST event %s%s t=%.1f ball=%d" % [kind, extra,
				_at_pulses * 0.4, Game.ball_number])
	match kind:
		"launch":
			# Erst ab dem Abschuss laeuft das Zeitfenster des Carry-Save
			if Game.ball_save_armed:
				save_time = SAVE_WINDOW
		"bumper":
			_on_bumper(data.get("letter", ""))
		"drop_target":
			_check_bank()
		"standup":
			_check_ich()
			_check_ego_bank()
		"rollover":
			_check_ggez()
		"wheel":
			_gluecksrad_zahlt(data)
		"all_disciplines":
			_start_wizard()
		"gate":
			# Der Durchlauf hat genau eine Sonderfunktion: das Hurry-Up der
			# Kill-Serie abholen.  Dafuer blinken die Hoerner.
			if hurry_active:
				var pts := Game.add_score(hurry_value)
				_end_hurry()
				hud.show_message("KILL KASSIERT.", "+" + Hud.fmt(pts), 2.2)
				Sfx.play("jackpot")
				Sfx.say("beste")
				Game.emit("jackpot")


func _on_bumper(letter: String) -> void:
	if letter == "":
		return
	streak_letters[letter] = true
	# Keine 6-Sekunden-Regel: die Markierungen bleiben bis zum Ballverlust.
	# Der Kill zuendet beim vierten Bumper genau einmal pro Ball.
	if streak_letters.size() >= 4:
		# Serie sofort wieder freigeben - ein Kill ist beliebig oft pro Ball
		# moeglich.
		streak_letters.clear()
		Game.kills += 1
		# Alle vier Bumper einmal getroffen - das ist die Disziplin, die oben
		# in der Leiste als WSAD steht.  Sie bleibt an bis zum Spielende oder
		# bis der Bericht durch ist (dort setzt _end_wizard sie zurueck).
		Game.discipline_done("CARRY")
		var pts := Game.add_score(3000)
		# Der Kill ist die einzige Quelle fuer den Ego-Multiplikator.
		Game.ego_level_up()
		Sfx.play("ego_up", -3.0)
		Game.emit("kill")
		if hurry_active:
			hud.show_message("KILL BESTAETIGT (%d)" % Game.kills,
					"EGO x%d. +%s" % [Game.ego_mult, Hud.fmt(pts)], 2.2)
		else:
			# Zusaetzlich startet die Serie das Hurry-Up; kassiert wird es am
			# blinkenden Durchlauf in der Mitte (siehe _on_event "gate").
			hurry_active = true
			hurry_value = 25000
			hurry_time = 12.0
			hud.show_message("KILL BESTAETIGT (%d)" % Game.kills,
					"EGO x%d - Hurry-Up: ab durch die MITTE!" % Game.ego_mult, 2.5)
	_update_bumper_marks()


## Goldene Markierung an allen Bumpern, die in der laufenden Kill-Serie
## schon getroffen wurden.  Solange das Hurry-Up laeuft und die Hoerner
## blinken, bleiben alle vier an: die Serie ist ja komplett und wartet nur
## noch darauf, am Durchlauf kassiert zu werden.  Aus gehen sie erst, wenn
## das Hurry-Up vorbei ist - kassiert oder abgelaufen.
func _update_bumper_marks() -> void:
	for letter in bumpers:
		bumpers[letter].set_marked(hurry_active or streak_letters.has(letter))


func _check_bank() -> void:
	for d in drops:
		if not d.dropped:
			return
	var pts := Game.add_score(3000)
	Game.discipline_done("DAMAGE")
	Game.frenzy = true
	frenzy_time = FRENZY_TIME
	Sfx.play("mode", -3.0)
	hud.show_message("DAMAGE-FRENZY!", "Alles zaehlt doppelt. +" + Hud.fmt(pts), 2.5)
	Game.emit("frenzy")
	# Die volle Bank bleibt bis zum Ballverlust an (Reset in _start_ball)


## E-G-O komplett: reine Punktebank, der Multiplikator kommt allein aus der
## Kill-Serie.  Wie I-C-H nur einmal pro Ball - die Bank bleibt danach stehen.
func _check_ego_bank() -> void:
	if _ego_done or ego_bank.is_empty():
		return
	for s in ego_bank:
		if not s.lit:
			return
	_ego_done = true
	var pts := Game.add_score(5000)
	Game.discipline_done("EGO")
	Sfx.play("jackpot", -6.0)
	hud.show_message("E-G-O KOMPLETT.", "+" + Hud.fmt(pts), 2.0)


## Das Gluecksrad ist ausgedreht und hat einen Rang ausgezahlt.  Die Queen
## kommentiert das Ergebnis - nach oben hin gnaediger.
func _gluecksrad_zahlt(data: Dictionary) -> void:
	var rang := str(data.get("rang", ""))
	var roh := int(data.get("roh", 0))
	var pts := int(data.get("punkte", roh))
	# Nur der Hauptgewinn wird gefeiert.  Alles darunter bekommt den eigenen
	# kurzen Auszahl-Klang des Rades - vorher lieh es sich je nach Hoehe die
	# Jingles von Jackpot, Ego und Countdown und blies den Jubel im Spiel auf.
	var spruch := "Immerhin gedreht."
	if roh >= 25000:
		spruch = "CHALLENGER. Also mein Niveau."
		Sfx.play("jackpot", -4.0)
		Sfx.say("beste")
		Game.emit("jackpot")
	elif roh >= 5000:
		spruch = "Geht doch. Fast wie ich."
		Sfx.play("rad_zahlt", -3.0)
	elif roh >= 2000:
		spruch = "Solide. Also unterdurchschnittlich."
		Sfx.play("rad_zahlt", -7.0)
	else:
		spruch = "Hardstuck. Wer haette das gedacht."
		Sfx.play("rad_zahlt", -12.0)
	# Die Chat-Zeile holt sich der HUD selbst aus dem Ereignis
	hud.show_message(rang + "!", "+" + Hud.fmt(pts) + "  " + spruch, 2.4)


func _check_ggez() -> void:
	if ggez.is_empty():
		return
	for r in ggez:
		if not r.lit:
			return
	Game.add_score(5000)
	Sfx.play("jackpot", -4.0)
	Game.emit("ggez")
	if Game.multiball:
		# Laeuft schon einer, gibt es nur die Punkte - und die Bank ist danach
		# wieder frei.
		hud.show_message("G-G-E-Z.", "Waren ja auch nur vier Gassen.", 2.2)
		await get_tree().create_timer(1.0, false).timeout
		for r in ggez:
			r.set_lit(false)
	else:
		# Komplette Bank ersetzt das Thron-Parken: Ko-op-Multiball + CARRY.
		# Die vier Lampen bleiben an, solange der Multiball laeuft - sie zeigen
		# damit, woher er kommt.  Geloescht werden sie in _end_multiball.
		_start_ggez_multiball()


## Multiball ohne Thron: die komplette G-G-E-Z-Bank ruft das "Team" aufs
## Feld - nur die pinke Carry-Kugel zaehlt richtig (x10).
func _start_ggez_multiball() -> void:
	Game.multiball = true
	Sfx.play("mode")
	Sfx.say("koop")
	hud.show_message("G-G-E-Z: KO-OP-MULTIBALL!", "Vier Spieler. Ein Carry. Ich.", 3.0)
	Game.emit("multiball")
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and not b.freeze and not b.is_queued_for_deletion():
			b.set_carry(true)
			break
	for i in 2:
		await get_tree().create_timer(0.5, false).timeout
		_spawn_ball(Vector2(270, 185), false, Vector2(randf_range(-60, 60), 300))


## I-C-H komplett: zaehlt sofort als Disziplin.  Die Bank bleibt danach
## stehen und laesst sich erst mit dem naechsten Ball erneut abraeumen.
func _check_ich() -> void:
	if _ich_done:
		return
	for s in standups:
		if not s.lit:
			return
	_ich_done = true
	var pts := Game.add_score(5000)
	Game.discipline_done("ICH")
	Sfx.play("jackpot", -4.0)
	Sfx.say("beste")
	hud.show_message("ICH. WER SONST.", "+" + Hud.fmt(pts), 2.2)


## Hurry-Up beendet - ob kassiert oder abgelaufen.  Erst jetzt gehen die
## vier Bumper-Markierungen aus (siehe _update_bumper_marks).
func _end_hurry() -> void:
	hurry_active = false
	_update_bumper_marks()


func _on_throne_captured(ball: PinBall) -> void:
	_resolve_throne.call_deferred(ball)


func _resolve_throne(ball: PinBall) -> void:
	if Game.wizard:
		var pts := Game.add_score(20000)
		hud.show_message("MEGA-JACKPOT!", "+" + Hud.fmt(pts), 2.0)
		Sfx.play("jackpot")
		Game.emit("jackpot")
		await _eject_after(ball, 0.7)
	elif hurry_active:
		var pts := Game.add_score(hurry_value)
		_end_hurry()
		Game.discipline_done("ICH")
		hud.show_message("ICH. WER SONST.", "+" + Hud.fmt(pts), 2.2)
		Sfx.play("jackpot")
		Sfx.say("beste")
		Game.emit("jackpot")
		await _eject_after(ball, 0.8)
	elif Game.multiball:
		var pts := Game.add_score(10000, ball)
		hud.show_message("JACKPOT!", "+" + Hud.fmt(pts), 2.0)
		Sfx.play("jackpot")
		Game.emit("jackpot")
		await _eject_after(ball, 0.6)
	else:
		Game.locks += 1
		if Game.locks >= 3:
			await _start_multiball(ball)
		else:
			locked_balls.append(ball)
			Game.add_score(2500)
			hud.show_message("BALL GEPARKT (%d/3)" % Game.locks, "Der Thron sammelt euch ein.", 2.0)
			Game.emit("lock")
			await get_tree().create_timer(0.8, false).timeout
			_spawn_ball(SPAWN)
			throne.release_ready()


func _eject_after(ball: PinBall, t: float) -> void:
	await get_tree().create_timer(t, false).timeout
	throne.eject(ball)
	await get_tree().create_timer(0.4, false).timeout
	throne.release_ready()


func _start_multiball(ball: PinBall) -> void:
	Game.multiball = true
	Game.locks = 0
	Sfx.play("mode")
	Sfx.say("koop")
	hud.show_message("VIER SPIELER. EIN CARRY.", "ICH.", 3.0)
	Game.emit("multiball")
	ball.set_carry(true)
	await get_tree().create_timer(0.9, false).timeout
	throne.eject(ball)
	for lb in locked_balls:
		await get_tree().create_timer(0.5, false).timeout
		throne.eject(lb)
	locked_balls.clear()
	await get_tree().create_timer(0.5, false).timeout
	_spawn_ball(Vector2(270, 185), false, Vector2(randf_range(-60, 60), 300))
	throne.release_ready()


func _end_multiball() -> void:
	Game.multiball = false
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall:
			b.set_carry(false)
	# Erst jetzt ist die G-G-E-Z-Bank wieder frei.  Solange der Multiball lief,
	# blieb sie an und zeigte, woher er kam.
	for r in ggez:
		r.set_lit(false)
	hud.show_sub("Multiball vorbei. Ihr wart Deko.", 2.0)


func _start_wizard() -> void:
	Game.wizard = true
	wizard_time = WIZARD_TIME
	wizard_line_idx = 0
	wizard_line_time = 0.5
	Sfx.play("mode")
	Sfx.say("bericht")
	hud.show_message("DER BERICHT.", "40 Sekunden lang zaehlt alles fuenffach.", 3.0)
	Game.emit("wizard")


func _end_wizard() -> void:
	Game.wizard = false
	hud.set_wizard(false)
	# Neue Runde fuer die Disziplinen - I-C-H und E-G-O sind wieder frei
	_ich_done = false
	_ego_done = false
	for s in ego_bank:
		s.reset()
	Game.reset_disciplines()
	for d in drops:
		d.reset()
	for s in standups:
		s.reset()
	hud.show_message("AM ENDE STEHT MEIN NAME.", "Eure Namen stehen nicht.", 3.0)


## Ein zufaelliger Spott-Spruch der Queen.
func spott() -> String:
	return QUEEN_SPOTT[randi() % QUEEN_SPOTT.size()]


## Tisch dunkel bzw. wieder hell schalten (Ruhe-Modus).
func _set_dimmed(on: bool) -> void:
	if dimmed == on:
		return
	dimmed = on
	var tw := create_tween()
	tw.tween_property(dim, "color", DIM_COLOR if on else Color.WHITE, 0.8)


## Jede Eingabe weckt den Tisch und setzt die Ruhe-Uhr zurueck.
func _wake() -> void:
	idle_time = 0.0
	if dimmed and not Game.game_over:
		_set_dimmed(false)


func _on_drain(body: Node2D) -> void:
	if not body is PinBall:
		return
	# Aufwaerts fliegende Baelle sind der Carry-Save-Einwurf von unten -
	# die duerfen die Drain-Zone nach oben durchqueren.
	if body.linear_velocity.y < -100.0:
		return
	body.queue_free()
	call_deferred("_after_drain")


func _free_ball_count() -> int:
	var n := 0
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and is_instance_valid(b) and not b.is_queued_for_deletion() and not b.freeze:
			n += 1
	return n


func _after_drain() -> void:
	if Game.game_over or hud.popup_kind != "":
		return
	var n := _free_ball_count()
	if n >= 1:
		if Game.multiball and n == 1:
			_end_multiball()
		return
	if Game.multiball:
		_end_multiball()
	if hurry_active:
		_end_hurry()
	if Game.ball_save_armed:
		Game.ball_save_armed = false
		# Kein Jubel-Jingle beim Carry-Save: die Rettung kuendigt sich ohnehin
		# mit Grollen und Countdown an, der Jubel davor war zu viel.
		Sfx.say("carry_rettet")
		hud.show_message("MEIN CARRY RETTET.", "Gern geschehen.", 2.5)
		Game.emit("save")
		_save_return()
		return
	# Der Ballverlust ist der lauteste Moment im Spiel - er soll wehtun.
	Sfx.play("drain", 4.0)
	Sfx.say("kein_skill")
	Game.emit("drain")
	if god_mode:
		# Ball kostenlos nachlegen, die Ballnummer bleibt stehen
		_start_ball()
	elif Game.ball_number >= Game.balls_per_game:
		_game_over()
	else:
		# Naechster Ball wird automatisch rechts unten eingelegt
		Game.ball_number += 1
		_start_ball()


## Carry-Save-Inszenierung: der Ball bleibt sichtbar in der Drain-Oeffnung
## liegen, zittert mit Grollen, Countdown 3-2-1 - und erst dann kommt er
## zwischen den Flippern hochgeschossen.
func _save_return() -> void:
	var b := _spawn_ball(Vector2(247, 946))
	b.freeze = true
	# Hoerbar machen, dass die Kugel festgehalten wird - vorher lag sie eine
	# halbe Sekunde stumm da, bevor das Grollen einsetzte.
	Sfx.play("klack", -4.0)
	var home := b.position
	await get_tree().create_timer(0.55, false).timeout
	if not is_instance_valid(b):
		return
	Sfx.play("rumble", -2.0)
	var tw := create_tween()
	for i in 10:
		tw.tween_property(b, "position",
				home + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)), 0.06)
	tw.tween_property(b, "position", home, 0.06)
	await tw.finished
	if not is_instance_valid(b):
		return
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.22, 0.9, 0.2))
	lbl.add_theme_constant_override("outline_size", 7)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.position = Vector2(207, 894)
	lbl.size = Vector2(80, 32)
	lbl.pivot_offset = Vector2(40, 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 60
	add_child(lbl)
	for n in [3, 2, 1]:
		if not is_instance_valid(b):
			break
		lbl.text = str(n)
		lbl.scale = Vector2(1.4, 1.4)
		var tw2 := create_tween()
		tw2.tween_property(lbl, "scale", Vector2.ONE, 0.2)
		# Im Carry-Save nur erzeugte Klaenge: die echten Aufnahmen gehoeren zu
		# Score-Reel und Feder und haben hier nichts zu suchen.
		Sfx.play("count", -3.0, true)
		b.position = home + Vector2(randf_range(-2.0, 2.0), 0)
		await get_tree().create_timer(0.5, false).timeout
	lbl.queue_free()
	if is_instance_valid(b):
		b.position = home
		b.freeze = false
		b.linear_velocity = Vector2(randf_range(-35, 35), randf_range(-1400, -1250))
		Sfx.play("count_go", -2.0, true)
		Sfx.play("launch", -4.0, true)


func _on_continue() -> void:
	if hud.popup_kind == "gameover":
		hud.hide_popup()
		get_tree().paused = false
		_restart()


func _game_over() -> void:
	Game.game_over = true
	hud.set_wizard(false)
	# Nach dem Spielende bleibt der Tisch gedimmt, bis das naechste losgeht
	_set_dimmed(true)
	Game.save_best()
	Sfx.play("over")
	Sfx.say("outro")
	Game.emit("gameover")
	hud.show_big_gameover()
	await get_tree().create_timer(2.2, false).timeout
	get_tree().paused = true
	hud.show_gameover(Game.score, Game.best_score)


func _restart() -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	locked_balls.clear()
	for d in drops:
		d.reset()
	for s in standups:
		s.reset()
	for r in ggez:
		r.set_lit(false)
	for s in ego_bank:
		s.reset()
	if throne:
		throne.release_ready()
	streak_letters.clear()
	_update_bumper_marks()
	hurry_active = false
	frenzy_time = 0.0
	wizard_time = 0.0
	hud.set_wizard(false)
	# Das neue Spiel weckt den Tisch wieder auf
	dimmed = true
	_set_dimmed(false)
	idle_time = 0.0
	Game.reset_game()
	_start_ball(true)


func _start_ball(first: bool = false) -> void:
	Game.ball_save_armed = true
	# Der Save-Countdown startet erst mit dem Abschuss (siehe _on_event)
	save_time = SAVE_WINDOW
	Game.damage_points = 0
	Game.tilted = false
	nudge_heat = 0.0
	# Der Ballverlust loescht nichts: alle Baenke, die Kill-Markierungen und
	# der EGO-Multiplikator bleiben, wie sie sind.  Zurueckgesetzt wird nur
	# beim neuen Spiel und nach dem Wizard.
	plunger.release()
	Game.emit("save_armed")
	_spawn_ball(SPAWN)
	if first:
		hud.show_message("KO-OP MODUS.", "Vier Spieler. Ein Carry. Ich.", 3.0)
		Sfx.say("koop")
	else:
		hud.show_message("BALL %d" % Game.ball_number, spott(), 2.5)


func _spawn_ball(pos: Vector2, carry: bool = false, impulse: Vector2 = Vector2.ZERO) -> PinBall:
	var b := PinBall.new()
	b.position = pos
	add_child(b)
	if carry:
		b.set_carry(true)
	if impulse != Vector2.ZERO:
		b.apply_central_impulse(impulse)
	return b


var _at_pulses := 0


func _autotest_pulse() -> void:
	_at_pulses += 1
	if _at_pulses % 12 == 0:
		var b0: Node2D = null
		for b in get_tree().get_nodes_in_group("balls"):
			b0 = b
			break
		var bpos := b0.global_position if b0 != null else Vector2.ZERO
		print("AUTOTEST state ball=%d score=%d free=%d pos=%s popup=%s" % [Game.ball_number, Game.score, _free_ball_count(), str(bpos), hud.popup_kind])
	if hud.popup_kind != "":
		if Game.game_over:
			print("AUTOTEST gameover score=", Game.score)
		hud.continue_pressed.emit()
		return
	_at_l = randf() < 0.5
	_at_r = randf() < 0.5


func _take_shot() -> void:
	await get_tree().create_timer(1.5).timeout
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://shot.png")
	img.save_png(path)
	print("SHOT_SAVED ", path)
	get_tree().quit()
