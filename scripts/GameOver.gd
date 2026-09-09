extends CanvasLayer

const MenuSkin = preload("res://scripts/MenuSkin.gd")

@onready var stats_label: Label = $Panel/StatsLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel.add_theme_stylebox_override("panel", MenuSkin.cream_panel())
	$Panel/Title.add_theme_color_override("font_color", MenuSkin.TERRACOTTA)
	$Panel/StatsLabel.add_theme_color_override("font_color", MenuSkin.INK)
	$Panel/RestartButton.add_theme_stylebox_override("normal", MenuSkin.wood_btn())
	$Panel/RestartButton.add_theme_color_override("font_color", Color("f6efe0"))
	GameManager.game_over.connect(show_game_over)
	if GameManager.has_signal("victory"):
		GameManager.victory.connect(show_victory)
	$Panel/RestartButton.pressed.connect(_on_restart)

func show_game_over() -> void:
	visible = true
	get_tree().paused = true
	var best := _close_run()
	stats_label.text = "Roads walked: %d\nScore: %d\nBest: %d\nDust: %d" % [GameManager.current_level, GameManager.score, best, Meta.dust]

func show_victory() -> void:
	visible = true
	get_tree().paused = true
	if has_node("Panel/Title"):
		$Panel/Title.text = "The crystal holds"
	var best := _close_run()
	stats_label.text = "All 20 roads.\nScore: %d\nBest: %d\nDust: %d" % [GameManager.score, best, Meta.dust]

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.started = false
	get_tree().reload_current_scene()

func _close_run() -> int:
	return Meta.award_run(GameManager.score, GameManager.ghost_log)
