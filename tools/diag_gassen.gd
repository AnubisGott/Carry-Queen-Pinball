extends Node
## Diagnose der G-G-E-Z-Gassen: eine Kugel darf immer nur einen Buchstaben
## auf einmal setzen.
##  1. laengs durch jede der vier Gassen -> genau dieser eine Buchstabe
##  2. quer ueber die Reihe (ober- und unterhalb der kurzen Stege) -> keiner
##   godot --headless --path . res://tools/diag_gassen.tscn

const MAIN := preload("res://scenes/main.tscn")
## Gassenmitten laut table.gd: GGEZ_CENTER 300, Abstand 38, y=212
const LANE_X := [243.0, 281.0, 319.0, 357.0]
const LANE_Y := 212.0
const LANE_DIR := Vector2(0.483, -0.877)

var _main: Node2D
var _gassen := []


func _ready() -> void:
	_main = MAIN.instantiate()
	add_child(_main)
	_main.god_mode = true
	await get_tree().create_timer(1.0).timeout
	_gassen = _main.ggez

	print("--- laengs durch jede Gasse ---")
	for i in LANE_X.size():
		# Die Gassenrichtung zeigt nach oben rechts - die Kugel kommt also von
		# oben rechts und faellt nach unten links hindurch.
		var start := Vector2(LANE_X[i], LANE_Y) + LANE_DIR * 60.0
		await _lauf("Gasse %d (%s)" % [i + 1, _buchstabe(i)], start,
				-LANE_DIR * 520.0, 1)

	print("--- an der Reihe entlang statt hindurch ---")
	await _lauf("quer oberhalb der Stege (y=190)", Vector2(215, 190),
			Vector2(650, 0), 0)
	await _lauf("schraeg unter der Reihe hindurch", Vector2(215, 250),
			Vector2(620, -320), 1)
	# Von rechts unten nach links oben laeuft die Kugel quer zur Gassenrichtung
	# (Skalarprodukt 0.03) - das ist kein Durchgang und zaehlt zu Recht nicht.
	await _lauf("schraeg gegen die Gassenrichtung", Vector2(390, 250),
			Vector2(-620, -320), 0)
	get_tree().quit()


func _buchstabe(i: int) -> String:
	return ["G", "G", "E", "Z"][i]


## Kugel losschicken und zaehlen, wie viele Buchstaben dabei angehen.
func _lauf(name: String, start: Vector2, v0: Vector2, erwartet: int) -> void:
	for g in _gassen:
		g.set_lit(false)
	var ball := PinBall.new()
	ball.position = start
	_main.add_child(ball)
	ball.linear_velocity = v0
	for i in 60:
		await get_tree().physics_frame
		if not is_instance_valid(ball):
			break
	var an := []
	for i in _gassen.size():
		if _gassen[i].lit:
			an.append(_buchstabe(i) + str(i + 1))
	print("  %-34s %d Buchstabe(n) %-14s erwartet %d  %s" % [
			name, an.size(), str(an), erwartet,
			"OK" if an.size() == erwartet else "ABWEICHUNG"])
	if is_instance_valid(ball):
		ball.queue_free()
	await get_tree().create_timer(0.3).timeout
