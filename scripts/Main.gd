extends Control

const SAVE_PATH := "user://bottom_empire_v1.json"
const C_BG := Color("#101827")
const C_PANEL := Color("#1d2b3d")
const C_GOLD := Color("#ffd36a")
const C_TEXT := Color("#e8f2ff")
const C_MINT := Color("#6de0c2")
var gold: float = 0.0
var gems: int = 0
var total_earned: float = 0.0
var tap_level: int = 1
var worker_level: int = 0
var drill_level: int = 1
var depth: int = 1
var rebirths: int = 0
var relics: int = 0
var rock_hp: float = 20.0
var rock_max: float = 20.0
var active_tab := 0
var elapsed := 0.0
var save_elapsed := 0.0
var floaters: Array = []
var ui: Dictionary = {}
var hero_bob := 0.0
var last_time: int = 0

func _ready() -> void:
	load_game()
	build_ui()
	refresh()
	set_process(true)

func fmt(n: float) -> String:
	if n >= 1e15: return "%.2fQ" % (n / 1e15)
	if n >= 1e12: return "%.2fT" % (n / 1e12)
	if n >= 1e9: return "%.2fB" % (n / 1e9)
	if n >= 1e6: return "%.2fM" % (n / 1e6)
	if n >= 1e3: return "%.1fK" % (n / 1e3)
	return str(int(n))

func bonus() -> float:
	return 1.0 + relics * 0.25

func tap_power() -> float:
	return (3.0 + pow(tap_level, 1.4) * 2.0) * bonus()

func income() -> float:
	return worker_level * (2.0 + worker_level * 0.6) * bonus()

func tap_cost() -> float:
	return floor(15.0 * pow(1.19, tap_level - 1))

func worker_cost() -> float:
	return floor(50.0 * pow(1.22, worker_level))

func drill_cost() -> float:
	return floor(35.0 * pow(1.26, drill_level - 1))

func rock_health() -> float:
	return 20.0 * pow(1.22, depth - 1)

func mine_power() -> float:
	return (5.0 + pow(drill_level, 1.5) * 3.0) * bonus()

func earn(amount: float) -> void:
	gold += amount
	total_earned += amount

func _process(delta: float) -> void:
	elapsed += delta
	save_elapsed += delta
	hero_bob += delta * 3.0
	if worker_level > 0:
		earn(income() * delta)
	if save_elapsed > 12.0:
		save_elapsed = 0.0
		save_game()
	for i in range(floaters.size() - 1, -1, -1):
		floaters[i].life -= delta
		floaters[i].pos.y -= delta * 65.0
		if floaters[i].life <= 0.0: floaters.remove_at(i)
	if ui.has("hero"):
		ui.hero.queue_redraw()
	if ui.has("mineart"):
		ui.mineart.queue_redraw()
	if ui.has("money"):
		ui.money.text = "✦ " + fmt(gold)
		ui.rate.text = "+" + fmt(income()) + " / sec"
		ui.gems.text = "◆ " + str(gems)
	if ui.has("floater"):
		ui.floater.queue_redraw()

func label(text_value: String, size: int = 25, color: Color = C_TEXT) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", style)
	return p

func button(txt: String, callback: Callable, color: Color = Color("#304b67")) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size.y = 76
	b.add_theme_font_size_override("font_size", 23)
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	b.add_theme_stylebox_override("normal", s)
	b.pressed.connect(callback)
	return b

func build_ui() -> void:
	for child in get_children(): child.queue_free()
	ui.clear()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := label("BOTTOM EMPIRE  •  밑바닥 제국", 31, C_GOLD)
	root.add_child(title)
	var currency := panel()
	root.add_child(currency)
	var stats := VBoxContainer.new()
	currency.add_child(stats)
	ui.money = label("", 44, C_GOLD)
	ui.gems = label("", 24, C_MINT)
	ui.rate = label("", 22, Color("#b6d2e7"))
	stats.add_child(ui.money)
	stats.add_child(ui.gems)
	stats.add_child(ui.rate)
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	ui.content = content
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 5)
	root.add_child(nav)
	var names := ["거리", "광산", "강화", "환생"]
	for i in range(names.size()):
		var index := i
		var b := button(names[i], func(): change_tab(index))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	change_tab(active_tab)

func change_tab(index: int) -> void:
	active_tab = index
	for child in ui.content.get_children(): child.queue_free()
	ui.erase("hero")
	ui.erase("mineart")
	ui.erase("floater")
	var box := ui.content
	if index == 0: street_tab(box)
	elif index == 1: mine_tab(box)
	elif index == 2: upgrade_tab(box)
	else: rebirth_tab(box)
	refresh()

func street_tab(box: VBoxContainer) -> void:
	box.add_child(label("CHAPTER 01  /  THE STREETS", 21, C_MINT))
	var scene := Control.new()
	scene.custom_minimum_size.y = 410
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scene)
	scene.draw.connect(func(): draw_street(scene))
	ui.hero = scene
	var hit := button("구걸하기  +%s GOLD" % fmt(tap_power()), func(): do_tap(), Color("#92602f"))
	hit.name = "tap_button"
	box.add_child(hit)
	box.add_child(label("작은 동전에서 거대한 제국까지", 21))

func mine_tab(box: VBoxContainer) -> void:
	box.add_child(label("DEEP MINE  /  지하 %d층" % depth, 27, C_GOLD))
	var scene := Control.new()
	scene.custom_minimum_size.y = 400
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scene)
	scene.draw.connect(func(): draw_mine(scene))
	ui.mineart = scene
	ui.rock = label("", 25, C_MINT)
	box.add_child(ui.rock)
	box.add_child(button("곡괭이 휘두르기  ⚒  %s DAMAGE" % fmt(mine_power()), func(): mine(), Color("#396477")))
	box.add_child(label("광석을 깨면 골드와 보석을 얻는다", 20))

func upgrade_tab(box: VBoxContainer) -> void:
	box.add_child(label("WORKSHOP  /  성장 연구소", 28, C_GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 18)
	scroll.add_child(v)
	ui.tap_upgrade = button("", func(): buy_upgrade("tap"))
	ui.worker_upgrade = button("", func(): buy_upgrade("worker"))
	ui.drill_upgrade = button("", func(): buy_upgrade("drill"))
	v.add_child(ui.tap_upgrade)
	v.add_child(ui.worker_upgrade)
	v.add_child(ui.drill_upgrade)
	v.add_child(label("강화 비용은 단계에 따라 증가한다.", 20))

func rebirth_tab(box: VBoxContainer) -> void:
	box.add_child(label("ASCENSION  /  환생의 제단", 29, C_GOLD))
	var p := panel()
	box.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	ui.rebirth_text = label("", 24)
	v.add_child(ui.rebirth_text)
	v.add_child(label("환생 시 골드, 강화 단계, 광산 층수는 초기화된다.\n영구 유물과 보석은 유지된다.", 21, C_MINT))
	box.add_child(button("새로운 삶 시작하기", func(): rebirth(), Color("#704a8c")))

func do_tap() -> void:
	earn(tap_power())
	floaters.append({"pos": Vector2(randf_range(190, 520), randf_range(130, 250)), "life": 0.8, "text": "+" + fmt(tap_power())})
	refresh()

func mine() -> void:
	rock_hp -= mine_power()
	if rock_hp <= 0:
		earn(12.0 * pow(1.18, depth - 1) * bonus())
		if randi_range(1, 100) <= 24: gems += 1
		depth += 1
		rock_max = rock_health()
		rock_hp = rock_max
		change_tab(1)
	refresh()

func buy_upgrade(kind: String) -> void:
	var cost := 0.0
	if kind == "tap": cost = tap_cost()
	elif kind == "worker": cost = worker_cost()
	else: cost = drill_cost()
	if gold < cost: return
	gold -= cost
	if kind == "tap": tap_level += 1
	elif kind == "worker": worker_level += 1
	else: drill_level += 1
	refresh()
	save_game()

func rebirth_gain() -> int:
	return int(floor(sqrt(total_earned / 250000.0)))

func rebirth() -> void:
	var gain := rebirth_gain()
	if gain < 1: return
	relics += gain
	rebirths += 1
	gold = 0.0
	total_earned = 0.0
	tap_level = 1
	worker_level = 0
	drill_level = 1
	depth = 1
	rock_max = rock_health()
	rock_hp = rock_max
	save_game()
	change_tab(0)

func refresh() -> void:
	if ui.has("tap_upgrade"):
		ui.tap_upgrade.text = "터치 훈련  Lv.%d\n+ 터치 파워  |  %s GOLD" % [tap_level, fmt(tap_cost())]
		ui.worker_upgrade.text = "동료 고용  Lv.%d\n+ 자동 수익  |  %s GOLD" % [worker_level, fmt(worker_cost())]
		ui.drill_upgrade.text = "굴착 장비  Lv.%d\n+ 채굴 데미지  |  %s GOLD" % [drill_level, fmt(drill_cost())]
	if ui.has("rock"):
		ui.rock.text = "암석 내구도  %s / %s" % [fmt(rock_hp), fmt(rock_max)]
	if ui.has("rebirth_text"):
		ui.rebirth_text.text = "환생 횟수: %d\n영구 유물: %d\n전체 수익: %s\n다음 환생 획득: %d 유물\n영구 수익 배율: x%.2f" % [rebirths, relics, fmt(total_earned), rebirth_gain(), bonus()]

func draw_street(c: Control) -> void:
	var w := c.size.x
	var h := c.size.y
	c.draw_rect(Rect2(0, 0, w, h), Color("#263b54"))
	c.draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color("#4a4d54"))
	for i in range(9):
		var x := float(i) * w / 8.0
		var bh := 120.0 + float((i * 73) % 110)
		c.draw_rect(Rect2(x, h * 0.64 - bh, w / 9.0, bh), Color("#36465b"))
		for j in range(3):
			c.draw_rect(Rect2(x + 12, h * 0.64 - bh + 25 + j * 37, 13, 18), Color("#edb968"))
	var x := w * 0.5
	var y := h * 0.67 + sin(hero_bob) * 4.0
	c.draw_rect(Rect2(x - 35, y - 102, 70, 70), Color("#a66d4e"))
	c.draw_rect(Rect2(x - 42, y - 116, 84, 24), Color("#51452d"))
	c.draw_rect(Rect2(x - 31, y - 77, 12, 9), Color("#1a2533"))
	c.draw_rect(Rect2(x + 19, y - 77, 12, 9), Color("#1a2533"))
	c.draw_rect(Rect2(x - 45, y - 31, 90, 80), Color("#62806b"))
	c.draw_rect(Rect2(x - 35, y + 47, 28, 44), Color("#293345"))
	c.draw_rect(Rect2(x + 7, y + 47, 28, 44), Color("#293345"))
	c.draw_circle(Vector2(x + 80, y + 12), 19, C_GOLD)
	c.draw_circle(Vector2(x + 80, y + 12), 12, Color("#d38b36"))
	for f in floaters:
		c.draw_string(ThemeDB.fallback_font, f.pos, f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, C_GOLD)

func draw_mine(c: Control) -> void:
	var w := c.size.x
	var h := c.size.y
	c.draw_rect(Rect2(0, 0, w, h), Color("#211e35"))
	for i in range(42):
		var px := float((i * 83 + 21) % 701) / 701.0 * w
		var py := float((i * 127 + 17) % 409) / 409.0 * h
		c.draw_rect(Rect2(px, py, 11, 9), Color("#39445d"))
	var center := Vector2(w / 2, h / 2)
	var radius := min(w, h) * 0.28
	var points := PackedVector2Array()
	for i in range(9):
		var a := TAU * float(i) / 9.0
		points.append(center + Vector2(cos(a), sin(a)) * radius * (0.82 + 0.15 * sin(float(i * 13))))
	c.draw_colored_polygon(points, Color("#5c667f"))
	c.draw_circle(center + Vector2(-30, -25), 32, Color("#75d6e3"))
	c.draw_circle(center + Vector2(34, 34), 24, Color("#a780e4"))
	c.draw_circle(center + Vector2(55, -28), 14, C_GOLD)
	c.draw_arc(center, radius + 18, -PI / 2, -PI / 2 + TAU * clamp(rock_hp / rock_max, 0.0, 1.0), 48, C_MINT, 12)

func save_game() -> void:
	var data := {"gold":gold,"gems":gems,"total_earned":total_earned,"tap_level":tap_level,"worker_level":worker_level,"drill_level":drill_level,"depth":depth,"rebirths":rebirths,"relics":relics,"rock_hp":rock_hp,"last_time":int(Time.get_unix_time_from_system())}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_game() -> void:
	rock_max = rock_health()
	rock_hp = rock_max
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	var d: Dictionary = parsed
	gold = float(d.get("gold", 0))
	gems = int(d.get("gems", 0))
	total_earned = float(d.get("total_earned", 0))
	tap_level = int(d.get("tap_level", 1))
	worker_level = int(d.get("worker_level", 0))
	drill_level = int(d.get("drill_level", 1))
	depth = int(d.get("depth", 1))
	rebirths = int(d.get("rebirths", 0))
	relics = int(d.get("relics", 0))
	rock_max = rock_health()
	rock_hp = clamp(float(d.get("rock_hp", rock_max)), 1.0, rock_max)
	var seconds := clampi(int(Time.get_unix_time_from_system()) - int(d.get("last_time", 0)), 0, 28800)
	earn(income() * seconds * 0.5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
