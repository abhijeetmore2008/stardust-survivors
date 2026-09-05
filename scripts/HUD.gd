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

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.score_changed.connect(_on_score)
	_on_wave_changed(GameManager.current_wave)
	_on_score(GameManager.score)
	pause_btn.pressed.connect(_on_pause)
	$SignalSlot/Button.pressed.connect(_on_signal)

func _process(_delta: float) -> void:
	visible = GameManager.started and GameManager.state != GameManager.State.GAME_OVER
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var combo: float = player.combo
	combo_fill.scale.x = clampf(combo / 8.0, 0.0, 1.0)
	combo_label.text = "combo %d/8" % int(combo)
	var ready: bool = combo >= 8.0 and player.signal_t <= 0.0
	signal_slot.modulate = Color(0.55, 1.0, 0.7) if ready else Color.WHITE
	if player.signal_t > 0.0:
		signal_caption.text = "%.1fs" % player.signal_t
		$SignalTimer.visible = true
		signal_timer_bar.scale.x = clampf(player.signal_t / 7.0, 0.0, 1.0)
	else:
		signal_caption.text = "Signal"
		$SignalTimer.visible = false

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave

func _on_score(score: int) -> void:
	score_label.text = str(score)

func _on_signal() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("try_signal"):
		player.try_signal()

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
