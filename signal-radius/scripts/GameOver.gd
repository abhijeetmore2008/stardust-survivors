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
	stats_label.text = "Waves survived: %d\nScore: %d" % [GameManager.current_wave, GameManager.score]

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()