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
	"gameover": ["war bestimmt schoen fuer euch", "gern geschehen und tschuess", "98% waren ihre, wie immer"],
	"launch": ["da fliegt er", "neuer Ball, gleiche Queen"],
	"tilt": ["RAGEQUIT lmaooo", "er schuettelt den Tisch, peinlich", "tilt wie im Ranked"],
	"gate": ["mitten durch lol", "einfach durchgerollt", "Durchlauf. Wie immer sie."],
	"pocket": ["kurz geparkt lol", "rein und sofort wieder raus", "die Fang-Mulde carried"],
	"ggez": ["gg ez", "EZ Clap", "vier Gassen, null Gegenwehr"],
	"ego_level": ["ihr EGO skaliert besser als wir", "x-fach?? okay"],
	# Der Kanal wird im Chat beworben - von "Zuschauern", versteht sich.
	"kanal": [
		"youtube.com/@djanubis5223 - LIVE",
		"@djanubis5223, Link ist oben in der Leiste",
		"abonniert oder heult",
		"sie streamt das grad, oben der Knopf",
		"DJ Anubis hat den Sound gemacht, YT-Knopf oben",
		"ich guck das lieber im Stream als hier",
	],
	"wheel_hit": ["RAD DREHT", "ranked roulette lol", "sie spinnt es an"],
	"wheel": ["gerankt lmao", "das Rad hat gesprochen", "PAY2WIN vibes",
			"kein Skill, nur Rad"],
}
const CHAT_PROB := {"bumper": 0.06, "sling": 0.15, "spinner": 0.3, "drop_target": 0.25, "standup": 0.4, "ego_level": 0.5, "wheel_hit": 0.35}

var popup_kind := ""

## Wizard-Anzeige: die vier Disziplinen pulsieren, darunter laeuft ein
## Zeitbalken ab.
var _wizard := false
var _wizard_t := 0.0
var _wizard_frac := 0.0
var _frenzy := false
var _frenzy_frac := 0.0
## Zeit bis zur naechsten Kanal-Erwaehnung im Chat
var _kanal_t := randf_range(30.0, 50.0)
var _wizard_bar: ColorRect
var _wizard_label: Label

var _score_display: SegmentDisplay
var _ego_label: Label
var _ball_label: Label
var _save_label: Label
var _god_label: Label
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
	# Anklickbares YouTube-Abzeichen neben dem Schriftzug
	var yt := YoutubeBadge.new()
	yt.position = Vector2(126, 3)
	bar.add_child(yt)
	# Punktestand als Segmentanzeige wie bei den Flippern der Achtziger.
	# Sie zeichnet sich um ihren Mittelpunkt, deshalb sitzt sie mittig ueber
	# der Leiste statt in einem Kasten.
	_score_display = SegmentDisplay.new()
	_score_display.position = Vector2(270, 22)
	bar.add_child(_score_display)
	_ego_label = _label("EGO x1", Vector2(10, 28), 16, GREEN, bar)
	_ball_label = _label("BALL 1/3", Vector2(10, 52), 12, Color(0.8, 0.8, 0.9), bar)
	_save_label = _label("CARRY-SAVE ●", Vector2(10, 68), 10, GREEN, bar)
	_god_label = _label("GOD", Vector2(78, 50), 13, GOLD, bar)
	_god_label.visible = false
	# Die Disziplin heisst intern weiter CARRY, in der Leiste steht aber, was
	# man dafuer tun muss: die vier Bumper.
	var disc_names := {"DAMAGE": "DMG", "EGO": "EGO", "CARRY": "WSAD", "ICH": "ICH"}
	var xs := {"DAMAGE": 285, "EGO": 330, "CARRY": 375, "ICH": 432}
	for k in disc_names:
		_disc_labels[k] = _label(disc_names[k], Vector2(xs[k], 62), 11, DIM, bar)
	# Titel des laufenden Modus, rechtsbuendig links neben dem Zeitbalken - mit
	# etwas Abstand dazu, sonst klebt die Zeile am Balken.
	_wizard_label = _label("", Vector2(75, 64), 12, GOLD, bar)
	_wizard_label.size = Vector2(168, 16)
	_wizard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wizard_label.visible = false
	# Zeitbalken des Wizard-Modus, direkt unter der Disziplinen-Reihe
	_wizard_bar = ColorRect.new()
	_wizard_bar.position = Vector2(285, 78)
	_wizard_bar.size = Vector2(167, 3)
	_wizard_bar.color = GOLD
	_wizard_bar.visible = false
	bar.add_child(_wizard_bar)
	_try_avatar(bar)


## Kennzeichnung fuer den God-Modus (unendlich Baelle).
func set_god(on: bool) -> void:
	_god_label.visible = on


## Wizard-Modus anzeigen: `frac` ist die verbleibende Zeit (1 = voll).
func set_wizard(on: bool, frac: float = 0.0) -> void:
	if _wizard != on:
		_wizard = on
		_wizard_t = 0.0
		if not on:
			_update_disciplines()
	if on:
		_wizard_frac = frac
	_update_modus()


## Damage-Frenzy anzeigen - dieselbe Zeile und derselbe Balken wie beim
## Bericht, nur in Rot.  Laufen beide, hat der Bericht den laengeren Atem und
## bekommt den Balken; die Frenzy haengt sich an den Text an.
func set_frenzy(on: bool, frac: float = 0.0) -> void:
	_frenzy = on
	if on:
		_frenzy_frac = frac
	_update_modus()


func _update_modus() -> void:
	var an := _wizard or _frenzy
	_wizard_bar.visible = an
	_wizard_label.visible = an
	if not an:
		return
	if _wizard:
		_wizard_bar.color = GOLD
		_wizard_bar.size = Vector2(167.0 * clampf(_wizard_frac, 0.0, 1.0), 3)
		_wizard_label.text = "DER BERICHT x%d" % Game.WIZARD_MULT
		if _frenzy:
			_wizard_label.text += " + DMG x%d" % Game.FRENZY_MULT
	else:
		_wizard_bar.color = PINK
		_wizard_bar.size = Vector2(167.0 * clampf(_frenzy_frac, 0.0, 1.0), 3)
		_wizard_label.text = "DAMAGE x%d" % Game.FRENZY_MULT


## Ab und zu erwaehnt der Chat den Kanal, und die Queen legt nach.
const KANAL_QUEEN := [
	"Oben ist der Kanal. Klicken. Jetzt.",
	"Abonnieren kostet nichts. Skill schon.",
	"Im Stream mache ich das mit einer Hand.",
	"Zuschauen kannst du ja wenigstens.",
	"Der Knopf oben links. Nicht so schwer.",
]


func _kanal_werbung(delta: float) -> void:
	if Game.game_over:
		return
	_kanal_t -= delta
	if _kanal_t > 0.0:
		return
	_kanal_t = randf_range(55.0, 100.0)
	var zeilen: Array = CHAT["kanal"]
	chat(zeilen[randi() % zeilen.size()])
	# Die Queen antwortet im Chat, nicht mitten auf dem Spielfeld - dort ist
	# Platz fuer Spielereignisse, nicht fuer Werbung.  Gesprochen wird genau
	# die Zeile, die sie schreibt (Fach "kanal_1" bis "kanal_5").
	if randf() < 0.5:
		var i := randi() % KANAL_QUEEN.size()
		chat(KANAL_QUEEN[i], "CarryQueen")
		Sfx.say("kanal_%d" % (i + 1))


func _process(delta: float) -> void:
	_kanal_werbung(delta)
	if not _wizard and not _frenzy:
		return
	_wizard_t += delta * 5.0
	# Beim Bericht pulsiert die ganze Disziplinen-Reihe mit, bei der Frenzy
	# nur die Zeile darunter - und in Rot statt Gold.
	var col := (GOLD if _wizard else PINK).lerp(
			Color(1.0, 1.0, 1.0), 0.5 + 0.5 * sin(_wizard_t))
	_wizard_label.add_theme_color_override("font_color", col)
	if not _wizard:
		return
	for k in _disc_labels:
		_disc_labels[k].add_theme_color_override("font_color", col)


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
	_go_label = _label("GAME OVER", Vector2(0, 360), 76, PINK)
	_go_label.size = Vector2(540, 110)
	_go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_label.add_theme_constant_override("outline_size", 18)
	_go_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	# Bleibt auch ueber dem abdunkelnden Overlay des Endstand-Popups hell
	_go_label.z_index = 30
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
	# Das fette GAME OVER bleibt stehen und rueckt ueber das Endstand-Popup
	_go_label.visible = true
	_go_label.position = Vector2(0, 120)
	popup_kind = "gameover"
	var top: int = maxi(score, best)
	_popup_title.text = "STREAM BEENDET."
	_popup_body.text = "DEIN SCORE  " + fmt(score) + "\n\nHIGHSCORES\n1.  ICH  ...............  " + fmt(top + 1) + "\n2.  TEAM (DU)  ...  " + fmt(top) + "\n3.  TEAM (DU)  ...  " + fmt(mini(score, best)) + "\n\n\"Ihr wart auch dabei.\nDas war bestimmt schoen fuer euch.\nNichts zu danken.\nGERN GESCHEHEN.\""
	_popup_hint.text = "BELIEBIGE TASTE = NEUER RUN"
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
	elif event is InputEventKey and event.pressed and not event.echo:
		ok = true
	elif event is InputEventMouseButton and event.pressed:
		ok = true
	elif event is InputEventScreenTouch and event.pressed:
		ok = true
	if ok:
		get_viewport().set_input_as_handled()
		continue_pressed.emit()


func _update_stats() -> void:
	_score_display.text = fmt(Game.score)
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
				_go_label.position = Vector2(0, 360)
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
