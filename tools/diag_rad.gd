extends Node
## Prueft das Gluecksrad:
##  1. Kugel stoesst an -> es dreht, Punkte laufen mit
##  2. es wird langsamer und bleibt stehen
##  3. beim Stillstand wird der Sektor unter der Krone ausgezahlt
##  4. ein Treffer waehrend des Drehens setzt wieder aufs Anfangstempo
##  5. es prallt ab statt zu schlucken
##   godot --headless --path . res://tools/diag_rad.tscn

const MAIN := preload("res://scenes/main.tscn")

var _main: Node2D
var _rad: FortuneWheel
var _letzte_auszahlung := {}


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	Game.event.connect(_on_event)
	await get_tree().create_timer(1.0).timeout
	_rad = _main.table_refs["wheel"] if "table_refs" in _main else null
	if _rad == null:
		for k in ["wheel"]:
			_rad = _main.get_node_or_null("%FortuneWheel") as FortuneWheel
	if _rad == null:
		_rad = _finde_rad(_main)
	print("Rad steht bei (%.0f,%.0f), Radius %.0f" % [
			_rad.global_position.x, _rad.global_position.y, FortuneWheel.RADIUS])

	print("--- Anstoss und Auslauf ---")
	var punkte_vor := Game.score
	await _ein_anstoss()
	print("  direkt danach: Tempo %.1f rad/s (Start %.0f)" % [
			_rad._speed, FortuneWheel.START_SPEED])
	var tempo_start := _rad._speed
	# Punktestand im Takt des Tickens mitschreiben: er muss waehrend des
	# Drehens immer wieder steigen, nicht erst am Ende springen.
	var stand := Game.score
	var stufen := 0
	for i in 10:
		await get_tree().create_timer(0.2).timeout
		if Game.score > stand:
			stufen += 1
			stand = Game.score
	print("  waehrend des Drehens stieg der Punktestand in %d von 10 Abschnitten" % stufen)
	print("  nach 2 s: Tempo %.1f rad/s -> %s" % [_rad._speed,
			"wird langsamer OK" if _rad._speed < tempo_start else "BREMST NICHT"])
	# ausdrehen lassen
	var t := 2.0
	while _rad._speed > 0.0 and t < 15.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	print("  Stillstand nach %.1f s, Auszahlung: %s" % [t, str(_letzte_auszahlung)])
	print("  Punkte insgesamt dazu: %d" % (Game.score - punkte_vor))
	var oben := _rad._sektor_oben()
	var soll: Dictionary = FortuneWheel.SEKTOREN[oben]
	print("  Sektor unter der Krone: %s (%d) -> %s" % [soll["rang"],
			soll["punkte"], "passt" if str(_letzte_auszahlung.get("rang", "")) == str(soll["rang"]) else "FALSCHER SEKTOR"])

	print("--- Nachtreffer im Auslauf ---")
	await _ein_anstoss()
	await get_tree().create_timer(2.0).timeout
	var vorher := _rad._speed
	await _ein_anstoss()
	print("  Tempo vor dem Nachtreffer %.1f, danach %.1f -> %s" % [
			vorher, _rad._speed,
			"wieder auf Start OK" if _rad._speed >= FortuneWheel.START_SPEED - 0.5 else "KEIN NEUSTART"])

	print("--- welcher Klang bei welcher Auszahlung ---")
	# Frueher lieh sich das Rad je nach Hoehe die Jingles von Jackpot, Ego und
	# Countdown.  Jetzt soll nur der Hauptgewinn den Jackpot bekommen.
	for stufe in [[25000, "CHALLENGER"], [10000, "MASTER"], [2000, "GOLD"], [500, "BRONZE"]]:
		_main._gluecksrad_zahlt({"punkte": stufe[0], "rang": stufe[1], "roh": stufe[0]})
		await get_tree().process_frame
		await get_tree().process_frame
		var laufen := []
		for p in Sfx._players:
			if not p.playing:
				continue
			for n in Sfx._streams:
				if p.stream == Sfx._streams[n]:
					laufen.append(n)
		print("  %-12s %6d -> %s" % [stufe[1], stufe[0], str(laufen)])
		await get_tree().create_timer(1.2).timeout

	print("--- prallt ab, schluckt nicht ---")
	var ball := PinBall.new()
	ball.position = _rad.global_position + Vector2(-55, -45)
	_main.add_child(ball)
	ball.linear_velocity = Vector2(520, 420)
	var min_abstand := 999.0
	for i in 90:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
		min_abstand = minf(min_abstand,
				ball.global_position.distance_to(_rad.global_position))
	var weg := ball.global_position.distance_to(_rad.global_position) if is_instance_valid(ball) else 999.0
	print("  naechster Abstand %.0f (Scheibe %.0f + Kugel 13), danach %.0f -> %s" % [
			min_abstand, FortuneWheel.RADIUS, weg,
			"abgeprallt OK" if weg > FortuneWheel.RADIUS + 20.0 else "HAENGT AM RAD"])
	get_tree().quit()


func _finde_rad(n: Node) -> FortuneWheel:
	if n is FortuneWheel:
		return n
	for c in n.get_children():
		var r := _finde_rad(c)
		if r != null:
			return r
	return null


## Genau ein Anstoss: Feld raeumen, eine Kugel von oben fallen lassen, bis das
## Rad anlaeuft, und sie dann wegnehmen.  Sonst dopst dieselbe Kugel weiter auf
## der Scheibe und setzt das Tempo staendig neu - dann waere nicht zu sehen,
## ob es ueberhaupt bremst.
func _ein_anstoss() -> void:
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().physics_frame
	var vorher := _rad._speed
	_stosse_an(Vector2(-55, -45), Vector2(520, 420))
	for i in 90:
		await get_tree().physics_frame
		if _rad._speed > vorher:
			break
	for b in get_tree().get_nodes_in_group("balls"):
		b.queue_free()
	await get_tree().physics_frame


func _stosse_an(versatz: Vector2, tempo: Vector2) -> void:
	var ball := PinBall.new()
	ball.position = _rad.global_position + versatz
	_main.add_child(ball)
	ball.linear_velocity = tempo


func _on_event(kind: String, data: Dictionary) -> void:
	if kind == "wheel":
		_letzte_auszahlung = data.duplicate()


