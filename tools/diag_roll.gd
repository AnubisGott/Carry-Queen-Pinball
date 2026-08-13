extends Node
## Diagnose des Rollgeraeuschs und der Banden-Ticks:
##  1. folgt die Lautstaerke/Tonhoehe der Rollschleife dem Kugeltempo?
##  2. tickt es beim Bandenkontakt - und schweigt es bei Bumpern, die einen
##     eigenen Klang mitbringen?
##  3. wird es still, wenn keine Kugel mehr unterwegs ist?
##   godot --headless --path . res://tools/diag_roll.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	while Sfx._streams.is_empty():
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	if "--feder" in OS.get_cmdline_user_args():
		await _feder_test()
		get_tree().quit()
		return

	_klangcheck()
	print("--- Rollen folgt dem Tempo ---")
	var ball := PinBall.new()
	ball.position = Vector2(52, 300)
	_main.add_child(ball)
	for i in 12:
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(ball):
			break
		print("  Tempo %5.0f px/s -> %6.1f dB, Tonhoehe %.2f" % [
				ball.linear_velocity.length(), Sfx._roll_player.volume_db,
				Sfx._roll_player.pitch_scale])
	if is_instance_valid(ball):
		ball.queue_free()

	print("--- Ticks ---")
	await _tick_probe("Bande links, 700 px/s", Vector2(120, 300), Vector2(-700, 0), true)
	await _tick_probe("Bande links, ganz langsam", Vector2(60, 300), Vector2(-70, 0), false)
	# Dicht vor den S-Bumper gesetzt und nur wenige Bilder beobachtet: nach dem
	# Bumper-Stoss fliegt die Kugel sonst in eine Bande und tickt dort zu Recht.
	await _tick_probe("Bumper S (hat eigenen Klang)", Vector2(245, 445), Vector2(0, -500), false, 10)

	await _dauerlauf(60.0)

	print("--- Stille ohne Kugel ---")
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().create_timer(1.2).timeout
	print("  ohne Kugel: %.1f dB" % Sfx._roll_player.volume_db)
	get_tree().quit()


## Feder spannen und loslassen: faehrt das Raketenbrausen mit der Ladung hoch,
## kommt beim Loslassen der Wisch, und wird das Brausen danach wieder still?
func _feder_test() -> void:
	print("--- Feder spannen ---")
	Input.action_press("launch")
	for i in 6:
		await get_tree().create_timer(0.25).timeout
		print("  Ladung %.2f -> %6.1f dB, Tonhoehe %.2f" % [
				_main.charge, Sfx._rakete_player.volume_db,
				Sfx._rakete_player.pitch_scale])
	var wisch: AudioStream = Sfx._streams["wisch"]
	Input.action_release("launch")
	var gewischt := false
	for i in 40:
		await get_tree().physics_frame
		for p in Sfx._players:
			if p.stream == wisch and p.playing:
				gewischt = true
	print("  Loslassen: Wisch gespielt: %s, Brausen nach 0.33 s bei %.1f dB" % [
			str(gewischt), Sfx._rakete_player.volume_db])
	await get_tree().create_timer(1.0).timeout
	print("  eine Sekunde danach: Brausen %.1f dB" % Sfx._rakete_player.volume_db)


## Klangcharakter der Schleife: das Zischmass ist der Anteil hoher Frequenzen
## (Effektivwert der Sample-Differenzen bezogen auf den des Signals).  Je
## kleiner, desto dunkler und weniger rauschig.  Der Nahtsprung zeigt, ob die
## Schleife an der Stossstelle knackt.
func _klangcheck() -> void:
	var wav: AudioStreamWAV = Sfx._streams["roll"]
	var d := wav.data
	var n := d.size() / 2
	var summe := 0.0
	var diff := 0.0
	var vor := 0.0
	for i in n:
		var v := float(d.decode_s16(i * 2)) / 32767.0
		summe += v * v
		if i > 0:
			diff += (v - vor) * (v - vor)
		vor = v
	var erstes := float(d.decode_s16(0)) / 32767.0
	print("--- Klangcharakter der Rollschleife ---")
	print("  Zischmass %.3f (klein = dunkel), Nahtsprung %.4f" % [
			sqrt(diff / maxf(1.0, float(n))) / maxf(0.0001, sqrt(summe / float(n))),
			absf(vor - erstes)])


## Echtes Spiel mit Zufallsflippern: wie oft tickt es pro Sekunde, und wie
## laut steht die Rollschleife im Schnitt?  Zu viele Ticks waeren Dauerfeuer.
func _dauerlauf(dauer: float) -> void:
	print("--- Dauerlauf %.0f s ---" % dauer)
	var rail: AudioStream = Sfx._streams["rail"]
	var lief := {}
	var ticks := 0
	var db_summe := 0.0
	var bilder := 0
	var t := 0.0
	var flip := 0.0
	while t < dauer:
		await get_tree().physics_frame
		t += 1.0 / 120.0
		flip -= 1.0 / 120.0
		if flip <= 0.0:
			flip = 0.35
			for a in ["flip_left", "flip_right", "launch"]:
				if randf() < 0.5:
					Input.action_press(a)
				else:
					Input.action_release(a)
		for i in Sfx._players.size():
			var p: AudioStreamPlayer = Sfx._players[i]
			var an: bool = p.stream == rail and p.playing
			if an and not bool(lief.get(i, false)):
				ticks += 1
			lief[i] = an
		db_summe += Sfx._roll_player.volume_db
		bilder += 1
	for a in ["flip_left", "flip_right", "launch"]:
		Input.action_release(a)
	print("  %d Ticks in %.0f s = %.1f je Sekunde" % [ticks, dauer, ticks / dauer])
	print("  Rollschleife im Mittel %.1f dB" % (db_summe / maxf(1.0, float(bilder))))


## Kugel mit Anfangstempo losschicken und pruefen, ob binnen 0.4 s ein
## Banden-Tick abgespielt wurde.
func _tick_probe(name: String, start: Vector2, v0: Vector2, erwartet: bool,
		bilder: int = 48) -> void:
	var rail: AudioStream = Sfx._streams["rail"]
	var ball := PinBall.new()
	ball.position = start
	_main.add_child(ball)
	ball.linear_velocity = v0
	var getickt := false
	for i in bilder:
		await get_tree().physics_frame
		for p in Sfx._players:
			if p.stream == rail and p.playing:
				getickt = true
	print("  %-30s Tick: %-5s erwartet: %-5s  %s" % [
			name, str(getickt), str(erwartet),
			"OK" if getickt == erwartet else "ABWEICHUNG"])
	if is_instance_valid(ball):
		ball.queue_free()
	# Pool leerlaufen lassen, sonst zaehlt der naechste Lauf den alten Tick mit
	await get_tree().create_timer(0.4).timeout
