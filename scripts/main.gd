extends Node2D
## Spielsteuerung: Ballfluss, Disziplinen/Modi, Plunger, Blackout, Match-Report.

const SPAWN := Vector2(495, 905)

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
var drops: Array = []
var standups: Array = []
var locked_balls: Array = []
var dim: CanvasModulate

var charge := 0.0
var charging := false

var streak_letters := {}
var streak_time := 0.0

var hurry_active := false
var hurry_value := 0
var hurry_time := 0.0

var frenzy_time := 0.0
var wizard_time := 0.0
var wizard_line_time := 0.0
var wizard_line_idx := 0
var blackout_time := 0.0
var next_blackout := 90.0

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
	throne = refs["throne"]
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
	if event is InputEventScreenTouch:
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
	if autotest:
		_at_launch_cool = maxf(0.0, _at_launch_cool - delta)
		if lane_ball != null and _at_launch_cool <= 0.0:
			_at_launch_cool = 1.5
			lane_ball.apply_central_impulse(Vector2(0, -1900))
			Game.emit("launch")
		hud.set_power(0.0, false)
		return
	if lane_ball != null:
		var pressed := Input.is_action_pressed("launch") or not _touch_launch.is_empty()
		if pressed:
			charging = true
			charge = minf(1.0, charge + delta * 0.8)
		elif charging:
			lane_ball.apply_central_impulse(Vector2(0, -(750.0 + 1350.0 * charge)))
			Sfx.play("launch", -4.0)
			Game.emit("launch")
			charging = false
			charge = 0.0
	else:
		charging = false
		charge = 0.0
	hud.set_power(charge, charging)


func _update_timers(delta: float) -> void:
	if streak_time > 0.0:
		streak_time -= delta
		if streak_time <= 0.0:
			streak_letters.clear()
	if hurry_active:
		hurry_time -= delta
		hurry_value = maxi(5000, hurry_value - int(1600.0 * delta))
		if hurry_time <= 0.0:
			_end_hurry()
			hud.show_sub("Hurry-Up vorbei. Zu langsam.", 1.5)
	if frenzy_time > 0.0:
		frenzy_time -= delta
		if frenzy_time <= 0.0:
			Game.frenzy = false
			hud.show_sub("Frenzy vorbei.", 1.5)
	if Game.wizard:
		wizard_time -= delta
		wizard_line_time -= delta
		if wizard_line_time <= 0.0 and wizard_line_idx < WIZARD_LINES.size():
			hud.show_message(WIZARD_LINES[wizard_line_idx], "", 3.0)
			wizard_line_idx += 1
			wizard_line_time = 4.0
		if wizard_time <= 0.0:
			_end_wizard()
	if Game.blackout:
		blackout_time -= delta
		if blackout_time <= 0.0:
			_end_blackout()
	elif not (Game.frenzy or Game.wizard or Game.multiball or hurry_active):
		next_blackout -= delta
		if next_blackout <= 0.0:
			_start_blackout()


func _cleanup_lost_balls() -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		if b is PinBall and not b.is_queued_for_deletion() and b.global_position.y > 1100:
			b.queue_free()
			call_deferred("_after_drain")


func _on_event(kind: String, data: Dictionary) -> void:
	if autotest and kind in ["spinner", "scoop", "ramp"]:
		print("AUTOTEST event ", kind)
	match kind:
		"bumper":
			_on_bumper(data.get("letter", ""))
		"drop_target":
			_check_bank()
		"standup":
			_check_ich()
		"all_disciplines":
			_start_wizard()
		"scoop":
			hud.show_message("ZURUECK INS SPIEL.", "Gern geschehen.", 1.8)
		"ramp":
			if randf() < 0.5:
				hud.show_sub("Ueberflug. Natuerlich elegant.", 1.4)


func _on_bumper(letter: String) -> void:
	if letter == "":
		return
	streak_letters[letter] = true
	streak_time = 6.0
	if streak_letters.size() >= 4:
		streak_letters.clear()
		Game.kills += 1
		var pts := Game.add_score(3000)
		Sfx.play("jackpot", -6.0)
		hud.show_message("KILL BESTAETIGT (%d)" % Game.kills, "+" + Hud.fmt(pts), 1.6)
		Game.emit("kill")
		if Game.kills >= 3:
			Game.discipline_done("KILLS")


func _check_bank() -> void:
	for d in drops:
		if not d.dropped:
			return
	var pts := Game.add_score(3000)
	Game.discipline_done("DAMAGE")
	Game.frenzy = true
	frenzy_time = 20.0
	Sfx.play("mode", -3.0)
	hud.show_message("DAMAGE-FRENZY!", "Alles zaehlt doppelt. +" + Hud.fmt(pts), 2.5)
	Game.emit("frenzy")
	await get_tree().create_timer(1.2, false).timeout
	for d in drops:
		d.reset()


func _check_ich() -> void:
	for s in standups:
		if not s.lit:
			return
	if hurry_active:
		return
	Game.add_score(2000)
	hurry_active = true
	hurry_value = 25000
	hurry_time = 12.0
	Sfx.play("mode", -3.0)
	hud.show_message("I-C-H KOMPLETT!", "Hurry-Up: Triff den THRON!", 2.5)


func _end_hurry() -> void:
	hurry_active = false
	for s in standups:
		s.reset()


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
	Game.discipline_done("CARRY")
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
	hud.show_sub("Multiball vorbei. Ihr wart Deko.", 2.0)


func _start_wizard() -> void:
	Game.wizard = true
	wizard_time = 40.0
	wizard_line_idx = 0
	wizard_line_time = 0.5
	Sfx.play("mode")
	Sfx.say("bericht")
	hud.show_message("DER BERICHT.", "Alles x5. Der Thron zahlt Mega-Jackpots.", 3.0)
	Game.emit("wizard")


func _end_wizard() -> void:
	Game.wizard = false
	Game.reset_disciplines()
	for d in drops:
		d.reset()
	for s in standups:
		s.reset()
	hud.show_message("AM ENDE STEHT MEIN NAME.", "Eure Namen stehen nicht.", 3.0)


func _start_blackout() -> void:
	Game.blackout = true
	blackout_time = 15.0
	Sfx.play("over", -8.0)
	var tw := create_tween()
	tw.tween_property(dim, "color", Color(0.38, 0.33, 0.48), 0.6)
	hud.show_message("KEIN HEAL. KEIN PLAN.", "KEIN SKILL. KEIN SIEG.", 3.0)
	Game.emit("blackout")


func _end_blackout() -> void:
	Game.blackout = false
	next_blackout = randf_range(75.0, 115.0)
	var tw := create_tween()
	tw.tween_property(dim, "color", Color.WHITE, 0.8)
	hud.show_sub("Licht an. Gern geschehen.", 2.0)


func _on_drain(body: Node2D) -> void:
	if not body is PinBall:
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
	if Game.ball_save_armed and not Game.blackout:
		Game.ball_save_armed = false
		Sfx.play("save", -2.0)
		Sfx.say("carry_rettet")
		hud.show_message("MEIN CARRY RETTET.", "Gern geschehen.", 2.5)
		Game.emit("save")
		_spawn_ball(SPAWN)
		return
	Sfx.play("drain", -2.0)
	if Game.blackout:
		Sfx.say("ohne_mich")
		hud.show_message("OHNE MICH.", "", 2.0)
		_end_blackout()
	else:
		Sfx.say("kein_skill")
	Game.emit("drain")
	if Game.ball_number >= Game.balls_per_game:
		_game_over()
	else:
		# Naechster Ball wird automatisch rechts unten eingelegt
		Game.ball_number += 1
		_start_ball()


func _on_continue() -> void:
	if hud.popup_kind == "gameover":
		hud.hide_popup()
		get_tree().paused = false
		_restart()


func _game_over() -> void:
	Game.game_over = true
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
	throne.release_ready()
	streak_letters.clear()
	hurry_active = false
	frenzy_time = 0.0
	wizard_time = 0.0
	next_blackout = 90.0
	dim.color = Color.WHITE
	Game.reset_game()
	_start_ball(true)


func _start_ball(first: bool = false) -> void:
	Game.ball_save_armed = true
	Game.damage_points = 0
	Game.tilted = false
	nudge_heat = 0.0
	Game.emit("save")
	_spawn_ball(SPAWN)
	if first:
		hud.show_message("KO-OP MODUS.", "Vier Spieler. Ein Carry. Ich.", 3.0)
		Sfx.say("koop")
	else:
		hud.show_message("BALL %d" % Game.ball_number, "Liegt rechts unten bereit. Dein Anteil bisher: 2 %.", 2.5)


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
