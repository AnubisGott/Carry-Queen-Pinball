class_name Hud
extends CanvasLayer
## Stream-Overlay: Scores, Ego-Meter, Fake-Twitch-Chat, Queen-Sprueche, Popups.

signal continue_pressed

## Spielfeldbreite, Chat-Spalte und Gesamtbreite - muessen zu
## Table.FIELD_W / CHAT_W und der Viewport-Breite passen.
const FIELD_W := 540
const CHAT_W := 120
const TOTAL_W := FIELD_W + CHAT_W
const CHAT_LINES := 17

const PINK := Color(1.0, 0.24, 0.62)
const GREEN := Color(0.35, 0.95, 0.25)
const CYAN := Color(0.2, 0.85, 0.95)
const GOLD := Color(0.98, 0.78, 0.15)
const DIM := Color(0.45, 0.4, 0.55)

const CHAT_USERS := ["xX_NoScope_Xx", "HealPlsThx", "TeamPlayer04", "OP_Fanboy88", "Rndm4ndy", "ClipItNow", "MidOrFeed", "SaltyMate", "Zuschauer2000", "ping_war_schuld"]
const USER_COLORS := [Color(1.0, 0.35, 0.7), Color(0.4, 0.9, 0.4), Color(0.35, 0.8, 0.95), Color(0.95, 0.75, 0.25), Color(0.75, 0.55, 0.95), Color(0.95, 0.55, 0.35)]

const CHAT := {
	"bumper": ["WASD spam lol", "POG", "schneller als mein Ping", "W = Content"],
	"sling": ["die Schulterpolster leben", "autsch", "F"],
	"spinner": ["OP OP OP", "clip it!!", "der Spinner dreht durch"],
	"drop_target": ["DAMAGE geht hoch", "tank diff", "98% dmg incoming"],
	"standup": ["I-C-H, wer wohl", "sie meint sich selbst lol"],
	"kill": ["KILL BESTAETIGT", "gg ez", "REPORTED lol", "adc diff"],
	"lock": ["Ball im Thron geparkt", "sie sammelt uns ein..."],
	"multiball": ["VIER BAELLE WTF", "wir sind nur Deko", "der pinke macht eh alles"],
	"jackpot": ["JACKPOT POGGERS", "Clip. Es. Jetzt.", "unfassbar (sie halt)"],
	"drain": ["F", "ball diff", "mein Ping war schuld", "classic Team-Moment"],
	"save": ["CARRY RETTET LOL", "nichts zu danken ;)", "sie hat schon wieder recht"],
	"frenzy": ["FRENZY!! alles x2", "DAMAGE MODUS AN"],
	"wizard": ["DER BERICHT. Gaensehaut.", "ihr Name steht schon drauf"],
	"blackout": ["licht aus lol", "kein heal? kein plan?", "wer zahlt die Stromrechnung"],
	"gameover": ["war bestimmt schoen fuer euch", "gern geschehen und tschuess", "98% waren ihre, wie immer"],
	"launch": ["da fliegt er", "neuer Ball, gleiche Queen"],
	"tilt": ["RAGEQUIT lmaooo", "er schuettelt den Tisch, peinlich", "tilt wie im Ranked"],
	"scoop": ["die Mulde carried", "Taxi zurueck ins Spiel", "Heal? nein. Wurf? ja."],
	"pocket": ["rechts geparkt lol", "3.. 2.. 1.. tschuess", "die Fang-Mulde zaehlt runter"],
	"ego_level": ["ihr EGO skaliert besser als wir", "x-fach?? okay"],
}
const CHAT_PROB := {"bumper": 0.06, "sling": 0.15, "spinner": 0.3, "drop_target": 0.25, "standup": 0.4, "ego_level": 0.5}

var popup_kind := ""

var _score_label: Label
var _ego_label: Label
var _ball_label: Label
var _save_label: Label
var _disc_labels := {}
var _chat_vbox: VBoxContainer
var _msg_label: Label
var _sub_label: Label
var _power_fill: ColorRect
var _power_bg: ColorRect
var _go_label: Label
var _popup: PanelContainer
var _popup_title: Label
var _popup_body: Label
var _popup_hint: Label
var _overlay: ColorRect
var _msg_tween: Tween
var _sub_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_bar()
	_build_controls()
	_build_chat()
	_build_messages()
	_build_power()
	_build_popup()
	Game.event.connect(_on_game_event)
	_update_stats()
	_update_disciplines()


static func fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out


func _label(text: String, pos: Vector2, size: int, col: Color, parent: Node = self) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _build_bar() -> void:
	var bar := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.02, 0.08, 0.94)
	sb.border_color = Color(1.0, 0.24, 0.62, 0.8)
	sb.border_width_bottom = 2
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2.ZERO
	bar.size = Vector2(540, 84)
	add_child(bar)
	_label("● EMPRESS LIVE!", Vector2(10, 4), 13, PINK, bar)
	_score_label = _label("0", Vector2(100, 20), 30, Color.WHITE, bar)
	_score_label.size = Vector2(340, 36)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ego_label = _label("EGO x1", Vector2(10, 28), 16, GREEN, bar)
	_ball_label = _label("BALL 1/3", Vector2(10, 52), 12, Color(0.8, 0.8, 0.9), bar)
	_save_label = _label("CARRY-SAVE ●", Vector2(10, 68), 10, GREEN, bar)
	var disc_names := {"DAMAGE": "DMG", "KILLS": "KILLS", "CARRY": "CARRY", "ICH": "ICH"}
	var xs := {"DAMAGE": 285, "KILLS": 325, "CARRY": 378, "ICH": 432}
	for k in disc_names:
		_disc_labels[k] = _label(disc_names[k], Vector2(xs[k], 62), 11, DIM, bar)
	_try_avatar(bar)


func _try_avatar(bar: Panel) -> void:
	var tex: Texture2D = null
	var p := "res://assets/queen.png"
	if ResourceLoader.exists(p):
		tex = load(p)
	elif FileAccess.file_exists(p):
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = Vector2(464, 6)
	tr.size = Vector2(72, 72)
	bar.add_child(tr)


## Tasten-Legende in der Ecke oben rechts, ueber der Chat-Spalte.
func _build_controls() -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.028, 0.012, 0.050, 0.94)
	sb.border_color = Color(0.72, 0.20, 0.95, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(FIELD_W + 6, 4)
	panel.size = Vector2(CHAT_W - 12, 80)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var head := _label("TASTEN", Vector2(0, 4), 11, GREEN, panel)
	head.size = Vector2(CHAT_W - 12, 14)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rows := [["A/D", "Flipper"], ["Q/E", "Stupsen"], ["LEER", "Abschuss"]]
	for i in rows.size():
		_label(rows[i][0], Vector2(8, 24 + i * 18), 10, GOLD, panel)
		_label(rows[i][1], Vector2(44, 24 + i * 18), 10, Color(0.8, 0.78, 0.9), panel)


## Chat als eigene Spalte rechts neben dem Spielfeld - der Stream-Look.
func _build_chat() -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.028, 0.012, 0.050, 0.94)
	sb.border_color = Color(0.72, 0.20, 0.95, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(FIELD_W + 6, 88)
	panel.size = Vector2(CHAT_W - 12, 868)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var head := _label("LIVE CHAT", Vector2(0, 6), 12, GREEN, panel)
	head.size = Vector2(CHAT_W - 12, 16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var rule := ColorRect.new()
	rule.color = Color(0.72, 0.20, 0.95, 0.5)
	rule.position = Vector2(8, 26)
	rule.size = Vector2(CHAT_W - 28, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rule)

	_chat_vbox = VBoxContainer.new()
	_chat_vbox.position = Vector2(7, 32)
	_chat_vbox.size = Vector2(CHAT_W - 26, 826)
	_chat_vbox.add_theme_constant_override("separation", 5)
	panel.add_child(_chat_vbox)
	chat("gleich geht's los!!", "mod_bot")


func chat(msg: String, user: String = "") -> void:
	if user == "":
		user = CHAT_USERS[randi() % CHAT_USERS.size()]
	var col: Color = USER_COLORS[user.hash() % USER_COLORS.size()]
	var l := Label.new()
	l.text = user + ": " + msg
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.92))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(CHAT_W - 26, 0)
	_chat_vbox.add_child(l)
	# Die Spalte laeuft von oben nach unten voll; oben faellt das Aelteste raus.
	while _chat_vbox.get_child_count() > CHAT_LINES:
		var first := _chat_vbox.get_child(0)
		_chat_vbox.remove_child(first)
		first.queue_free()


func _build_messages() -> void:
	_msg_label = _label("", Vector2(0, 395), 26, PINK)
	_msg_label.size = Vector2(540, 44)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.add_theme_constant_override("outline_size", 8)
	_msg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_msg_label.modulate.a = 0.0
	_sub_label = _label("", Vector2(0, 442), 15, CYAN)
	_sub_label.size = Vector2(540, 26)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.add_theme_constant_override("outline_size", 6)
	_sub_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_sub_label.modulate.a = 0.0
	_go_label = _label("GAME OVER", Vector2(0, 370), 56, PINK)
	_go_label.size = Vector2(540, 90)
	_go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_label.add_theme_constant_override("outline_size", 14)
	_go_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_go_label.visible = false


func show_message(big: String, sub: String = "", dur: float = 2.5) -> void:
	_msg_label.text = big
	_msg_label.modulate.a = 1.0
	if _msg_tween:
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(dur)
	_msg_tween.tween_property(_msg_label, "modulate:a", 0.0, 0.5)
	show_sub(sub, dur + 0.3)


func show_sub(sub: String, dur: float = 2.0) -> void:
	if sub == "":
		return
	_sub_label.text = sub
	_sub_label.modulate.a = 1.0
	if _sub_tween:
		_sub_tween.kill()
	_sub_tween = create_tween()
	_sub_tween.tween_interval(dur)
	_sub_tween.tween_property(_sub_label, "modulate:a", 0.0, 0.5)


func _build_power() -> void:
	_power_bg = ColorRect.new()
	_power_bg.position = Vector2(524, 700)
	_power_bg.size = Vector2(10, 240)
	_power_bg.color = Color(0.1, 0.05, 0.15, 0.8)
	add_child(_power_bg)
	_power_fill = ColorRect.new()
	_power_fill.color = Color(1.0, 0.24, 0.62)
	add_child(_power_fill)
	set_power(0.0, false)


func set_power(p: float, show_bar: bool) -> void:
	_power_bg.visible = show_bar
	_power_fill.visible = show_bar and p > 0.0
	var h := 236.0 * p
	_power_fill.position = Vector2(526, 702 + 236.0 - h)
	_power_fill.size = Vector2(6, h)


func _build_popup() -> void:
	_overlay = ColorRect.new()
	_overlay.position = Vector2.ZERO
	_overlay.size = Vector2(TOTAL_W, 960)
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.visible = false
	add_child(_overlay)
	_popup = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.07, 0.97)
	sb.border_color = PINK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	_popup.add_theme_stylebox_override("panel", sb)
	add_child(_popup)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_popup.add_child(vbox)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 21)
	_popup_title.add_theme_color_override("font_color", PINK)
	_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_popup_title)
	_popup_body = Label.new()
	_popup_body.add_theme_font_size_override("font_size", 15)
	_popup_body.add_theme_color_override("font_color", Color(0.92, 0.9, 0.98))
	_popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_popup_body)
	_popup_hint = Label.new()
	_popup_hint.add_theme_font_size_override("font_size", 12)
	_popup_hint.add_theme_color_override("font_color", DIM)
	_popup_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_popup_hint)
	_popup.visible = false
	_popup.set_anchors_preset(Control.PRESET_CENTER)
	_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_popup.grow_vertical = Control.GROW_DIRECTION_BOTH


func show_big_gameover() -> void:
	_go_label.visible = true
	_go_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_go_label, "modulate:a", 1.0, 0.5)


func show_gameover(score: int, best: int) -> void:
	_go_label.visible = false
	popup_kind = "gameover"
	var top: int = maxi(score, best)
	_popup_title.text = "STREAM BEENDET."
	_popup_body.text = "DEIN SCORE  " + fmt(score) + "\n\nHIGHSCORES\n1.  ICH  ...............  " + fmt(top + 1) + "\n2.  TEAM (DU)  ...  " + fmt(top) + "\n3.  TEAM (DU)  ...  " + fmt(mini(score, best)) + "\n\n\"Ihr wart auch dabei.\nDas war bestimmt schoen fuer euch.\nNichts zu danken.\nGERN GESCHEHEN.\""
	_popup_hint.text = "LEERTASTE = NEUER RUN"
	_overlay.visible = true
	_popup.visible = true


func hide_popup() -> void:
	popup_kind = ""
	_popup.visible = false
	_overlay.visible = false


func _input(event: InputEvent) -> void:
	if not _popup.visible:
		return
	var ok := false
	if event.is_action_pressed("launch"):
		ok = true
	elif event is InputEventMouseButton and event.pressed:
		ok = true
	elif event is InputEventScreenTouch and event.pressed:
		ok = true
	if ok:
		get_viewport().set_input_as_handled()
		continue_pressed.emit()


func _update_stats() -> void:
	_score_label.text = fmt(Game.score)
	_ego_label.text = "EGO x%d" % Game.ego_mult
	_ball_label.text = "BALL %d/%d" % [Game.ball_number, Game.balls_per_game]
	if Game.ball_save_armed:
		_save_label.text = "CARRY-SAVE ●"
		_save_label.add_theme_color_override("font_color", GREEN)
	else:
		_save_label.text = "CARRY-SAVE ○"
		_save_label.add_theme_color_override("font_color", DIM)


func _update_disciplines() -> void:
	for k in _disc_labels:
		var done: bool = Game.disciplines.get(k, false)
		_disc_labels[k].add_theme_color_override("font_color", PINK if done else DIM)


func _on_game_event(kind: String, _data: Dictionary) -> void:
	match kind:
		"score", "ego", "ego_level", "save", "save_armed", "reset", "drain", "launch":
			_update_stats()
			if kind == "reset":
				_go_label.visible = false
		"discipline", "disciplines_reset", "all_disciplines":
			_update_disciplines()
			_update_stats()
	if kind == "ego_level":
		show_sub("EGO-LEVEL x%d – und noch besser bin ich" % Game.ego_mult, 1.6)
		Sfx.play("tick", -4.0)
	if CHAT.has(kind):
		var prob: float = CHAT_PROB.get(kind, 0.9)
		if randf() < prob:
			var lines: Array = CHAT[kind]
			chat(lines[randi() % lines.size()])
