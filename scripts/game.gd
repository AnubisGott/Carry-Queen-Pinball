extends Node
## Zentraler Spielzustand + Event-Bus. Autoload "Game".

signal event(kind: String, data: Dictionary)

const SAVE_PATH := "user://carry_queen_highscore.json"

var score: int = 0
var ego: int = 0
var ego_mult: int = 1
var ball_number: int = 1
var balls_per_game: int = 3
var ball_save_armed: bool = true
var multiball: bool = false
var frenzy: bool = false
var wizard: bool = false
var blackout: bool = false
var locks: int = 0
var kills: int = 0
var damage_points: int = 0
var disciplines := {"DAMAGE": false, "KILLS": false, "CARRY": false, "ICH": false}
var best_score: int = 0
var game_over: bool = false
var tilted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_actions()
	_load_best()


func reset_game() -> void:
	score = 0
	ego = 0
	ego_mult = 1
	ball_number = 1
	ball_save_armed = true
	multiball = false
	frenzy = false
	wizard = false
	blackout = false
	locks = 0
	kills = 0
	damage_points = 0
	game_over = false
	tilted = false
	for k in disciplines:
		disciplines[k] = false
	emit("reset")


func emit(kind: String, data: Dictionary = {}) -> void:
	event.emit(kind, data)


func add_score(base: int, source_ball: Node = null) -> int:
	if game_over or tilted:
		return 0
	var mult := ego_mult
	if frenzy:
		mult *= 2
	if wizard:
		mult *= 5
	if blackout:
		mult = 1
	if multiball and source_ball != null and source_ball.get("is_carry") == true:
		mult *= 10
	var pts := base * mult
	score += pts
	emit("score", {"points": pts})
	return pts


## Nur der EGO-Knopf hebt den Multiplikator - genau eine Stufe pro Treffer.
func ego_level_up() -> void:
	if blackout or game_over or tilted:
		return
	if ego_mult < 10:
		ego_mult += 1
		emit("ego_level", {"mult": ego_mult})
	emit("ego")


## Ballverlust setzt den Multiplikator auf x1 zurueck.
func reset_ego() -> void:
	ego = 0
	ego_mult = 1
	emit("ego")


func discipline_done(disc: String) -> void:
	if disciplines.get(disc, true):
		return
	disciplines[disc] = true
	emit("discipline", {"name": disc})
	for k in disciplines:
		if not disciplines[k]:
			return
	emit("all_disciplines")


func reset_disciplines() -> void:
	for k in disciplines:
		disciplines[k] = false
	kills = 0
	emit("disciplines_reset")


func _load_best() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY and d.has("best"):
				best_score = int(d["best"])


func save_best() -> void:
	if score > best_score:
		best_score = score
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best": best_score}))


func _setup_actions() -> void:
	_add_action("flip_left", [KEY_LEFT, KEY_A])
	_add_action("flip_right", [KEY_RIGHT, KEY_D])
	_add_action("launch", [KEY_SPACE, KEY_DOWN, KEY_ENTER])
	_add_action("nudge_left", [KEY_Q])
	_add_action("nudge_right", [KEY_E])


func _add_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action_name, ev)
