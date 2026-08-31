extends CanvasLayer

@onready var buttons: Array = [$Panel/Button1, $Panel/Button2, $Panel/Button3]
var upgrade_pool := ["move_speed", "damage", "fire_rate", "beam_width", "beam_range", "max_hp"]

func _ready() -> void:
	visible = false
	for b in buttons:
		b.pressed.connect(_on_pick.bind(b))

func show_upgrades() -> void:
	visible = true
	get_tree().paused = true
	var choices := upgrade_pool.duplicate()
	choices.shuffle()
	for i in range(buttons.size()):
		buttons[i].text = choices[i]
		buttons[i].set_meta("upgrade_id", choices[i])

func _on_pick(button: Button) -> void:
	var id: String = button.get_meta("upgrade_id")
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(id)
	visible = false
	get_tree().paused = false

