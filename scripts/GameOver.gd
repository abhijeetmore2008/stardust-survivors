extends CanvasLayer

@onready var stats_label: Label = $Panel/StatsLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.game_over.connect(show_game_over)
	$Panel/RestartButton.pressed.connect(_on_restart)

func show_game_over() -> void:
	visible = true
	get_tree().paused = true
	var best := _save_best(GameManager.score)
	stats_label.text = "Waves survived: %d\nScore: %d\nBest: %d" % [GameManager.current_wave, GameManager.score, best]

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.start_run()
	get_tree().reload_current_scene()

func _save_best(score: int) -> int:
	var cfg := ConfigFile.new()
	cfg.load("user://signal_radius.cfg")
	var best := int(cfg.get_value("run", "best", 0))
	if score > best:
		best = score
		cfg.set_value("run", "best", best)
		cfg.save("user://signal_radius.cfg")
	return best
