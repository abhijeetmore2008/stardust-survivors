extends CanvasLayer

@onready var wave_label: Label = $WaveLabel
@onready var score_label: Label = $ScoreLabel
@onready var combo_fill: ColorRect = $ComboBar/Fill
@onready var combo_label: Label = $ComboLabel
@onready var gun_slot: Panel = $GunSlot
@onready var signal_slot: Panel = $SignalSlot
@onready var signal_caption: Label = $SignalSlot/Caption
@onready var signal_timer_bar: ColorRect = $SignalTimer/Fill
@onready var pause_btn: Button = $PauseButton

var battery_fill: ColorRect
var mote_label: Label
var biome_label: Label
var prompt_label: Label
var hold_bg: ColorRect
var hold_fill: ColorRect
var dash_label: Label
var coach_label: Label

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.score_changed.connect(_on_score)
	_on_wave_changed(GameManager.current_wave)
	_on_score(GameManager.score)
	pause_btn.pressed.connect(_on_pause)
	$SignalSlot/Button.pressed.connect(_on_signal)
	if has_node("GunSlot"):
		$GunSlot.visible = false
	if has_node("SignalSlot"):
		$SignalSlot.visible = false
	if has_node("UpgradeSlots"):
		$UpgradeSlots.visible = false
	if has_node("PauseButton"):
		$PauseButton.position = Vector2(1188, 56)
	_build_extras()

func _build_extras() -> void:
	var bat_bg := ColorRect.new()
	bat_bg.name = "BatteryBar"
	bat_bg.position = Vector2(20, 84)
	bat_bg.size = Vector2(180, 8)
	bat_bg.color = Color(0.12, 0.14, 0.16, 0.9)
	add_child(bat_bg)
	battery_fill = ColorRect.new()
	battery_fill.size = Vector2(180, 8)
	battery_fill.color = Color(0.45, 0.85, 1.0, 1)
	bat_bg.add_child(battery_fill)
	if has_node("UpgradeSlots"):
		$UpgradeSlots.position = Vector2(20, 118)
	combo_label.position = Vector2(190, 36)
	combo_label.add_theme_color_override("font_color", Color("fff6e8"))
	wave_label.position = Vector2(20, 72)
	wave_label.add_theme_color_override("font_color", Color("fff6e8"))
	mote_label = Label.new()
	mote_label.position = Vector2(190, 76)
	mote_label.size = Vector2(220, 24)
	mote_label.add_theme_font_size_override("font_size", 14)
	mote_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	add_child(mote_label)
	dash_label = Label.new()
	dash_label.position = Vector2(190, 96)
	dash_label.size = Vector2(220, 22)
	dash_label.add_theme_font_size_override("font_size", 13)
	add_child(dash_label)
	biome_label = Label.new()
	biome_label.position = Vector2(20, 148)
	biome_label.size = Vector2(360, 24)
	biome_label.add_theme_font_size_override("font_size", 14)
	biome_label.add_theme_color_override("font_color", Color("fff6e8"))
	biome_label.position = Vector2(20, 100)
	add_child(biome_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(240, 640)
	prompt_label.size = Vector2(800, 28)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.8))
	add_child(prompt_label)
	coach_label = Label.new()
	coach_label.position = Vector2(240, 118)
	coach_label.size = Vector2(800, 36)
	coach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coach_label.add_theme_font_size_override("font_size", 18)
	coach_label.add_theme_color_override("font_color", Color("fff6e8"))
	add_child(coach_label)
	hold_bg = ColorRect.new()
	hold_bg.position = Vector2(390, 606)
	hold_bg.size = Vector2(500, 22)
	hold_bg.color = Color(0.08, 0.10, 0.12, 0.92)
	hold_bg.visible = false
	add_child(hold_bg)
	hold_fill = ColorRect.new()
	hold_fill.size = Vector2(500, 22)
	hold_fill.color = Color(0.55, 0.92, 1.0, 1)
	hold_bg.add_child(hold_fill)
	var hold_lab := Label.new()
	hold_lab.name = "HoldLabel"
	hold_lab.position = Vector2(390, 582)
	hold_lab.size = Vector2(500, 24)
	hold_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hold_lab.add_theme_font_size_override("font_size", 15)
	hold_lab.add_theme_color_override("font_color", Color(0.85, 0.98, 1.0))
	hold_lab.text = "Locking the gate"
	hold_lab.visible = false
	add_child(hold_lab)
	if has_node("GunSlot/Label"):
		$GunSlot/Label.text = "GUN"
	var vig := TextureRect.new()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.texture = _vignette_tex()
	vig.modulate = Color(1, 1, 1, 0.55)
	vig.position = Vector2.ZERO
	vig.size = Vector2(1280, 720)
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(vig)
	move_child(vig, 0)

func _vignette_tex() -> ImageTexture:
	var img := Image.create(160, 90, false, Image.FORMAT_RGBA8)
	var c := Vector2(80, 45)
	for y in 90:
		for x in 160:
			var d := Vector2(x - c.x, y - c.y) / c
			var a := clampf(d.length() - 0.55, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.02, 0.03, 0.05, a * a * 0.85))
	return ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	visible = GameManager.started and GameManager.state != GameManager.State.GAME_OVER and GameManager.state != GameManager.State.VICTORY
	if has_node("PauseMenu") and $PauseMenu.visible:
		visible = true
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var combo: float = player.combo
	combo_fill.scale.x = clampf(combo / 8.0, 0.0, 1.0)
	combo_label.text = "combo %d/8" % int(combo)
	var ready: bool = combo >= 8.0 and player.signal_t <= 0.0
	signal_slot.modulate = Color(0.55, 1.0, 0.7) if ready else Color.WHITE
	if player.broadcasting:
		signal_slot.modulate = Color(0.7, 0.95, 1.0)
	if player.signal_t > 0.0:
		signal_caption.text = "%.1fs" % player.signal_t
		$SignalTimer.visible = true
		signal_timer_bar.scale.x = clampf(player.signal_t / 7.0, 0.0, 1.0)
	elif player.broadcasting:
		signal_caption.text = "ON AIR"
		$SignalTimer.visible = false
	else:
		signal_caption.text = "Signal"
		$SignalTimer.visible = false
	if battery_fill:
		battery_fill.scale.x = clampf(float(player.battery) / 100.0, 0.0, 1.0)
		if player.broadcasting:
			battery_fill.color = Color(1.0, 0.88, 0.45, 0.75 + 0.25 * absf(sin(Time.get_ticks_msec() * 0.008)))
		else:
			battery_fill.color = Color(0.45, 0.85, 1.0, 1)
	if coach_label:
		coach_label.text = str(player.get("teach_id"))
		coach_label.visible = coach_label.text != ""
	if mote_label:
		var spark := "ready"
		if float(player.get("spark_cd")) > 0.0:
			spark = "%.1fs" % float(player.spark_cd)
		mote_label.text = "spark %s" % spark
	if dash_label:
		dash_label.text = "dash %d/%d" % [int(player.dash_charges), int(player.dash_charges_max)]
	if biome_label:
		var nm := str(GameManager.biome.get("name", ""))
		biome_label.text = "%s  ·  lamps %d" % [nm, GameManager.lit_count()]
	if prompt_label:
		prompt_label.text = str(player.prompt)
	if hold_bg:
		var show_hold := GameManager.near_gate and GameManager.gate_open
		hold_bg.visible = show_hold
		hold_fill.scale.x = clampf(GameManager.hold_progress, 0.0, 1.0)
		if has_node("HoldLabel"):
			$HoldLabel.visible = show_hold
			$HoldLabel.text = "Locking the gate" if GameManager.holding_gate else "Sweep the beam across the arch"
	if has_node("GunSlot/Color") and player.weapon.has("color"):
		$GunSlot/Color.color = player.weapon.color
	if has_node("GunSlot/Label") and player.weapon.has("name"):
		$GunSlot/Label.text = str(player.weapon.get("tag", "GUN"))

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Road %d/%d" % [wave, GameManager.MAX_LEVEL]

func _on_score(score: int) -> void:
	score_label.text = str(score)

func _on_signal() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.combo >= 8.0:
		player.try_signal()
	elif player.combo >= 1.0:
		player.try_ping()
	else:
		player.broadcasting = not player.broadcasting

func _on_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING:
		GameManager.state = GameManager.State.PAUSED
		get_tree().paused = true
		$PauseMenu.visible = true

func _on_resume() -> void:
	get_tree().paused = false
	GameManager.state = GameManager.State.PLAYING
	$PauseMenu.visible = false

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.start_run()
	get_tree().reload_current_scene()
