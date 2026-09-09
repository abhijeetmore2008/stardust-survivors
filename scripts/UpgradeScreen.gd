extends CanvasLayer

const MenuSkin = preload("res://scripts/MenuSkin.gd")

@onready var buttons: Array = [$Panel/Button1, $Panel/Button2, $Panel/Button3]

var upgrade_pool := [
	"move_speed", "damage", "fire_rate", "beam_width", "beam_range", "max_hp",
	"louder", "darkroom", "lighthouse", "overclock_leak", "battery_cell", "second_wind", "moth_ward",
]
var unique := ["louder", "darkroom", "lighthouse", "overclock_leak", "moth_ward"]
var upgrade_names := {
	"move_speed": "Quickstep — Move faster",
	"damage": "Hot shot — Gun hits harder",
	"fire_rate": "Rapid fire — Gun cycles faster",
	"beam_width": "Wide Signal — Cone opens wider",
	"beam_range": "Long Signal — Cone reaches farther",
	"max_hp": "Iron hull — One extra heart",
	"louder": "Louder — Combo fades slow. Roamers while combo > 5",
	"darkroom": "Darkroom — Gun is dead outside the cone, 2.4× inside",
	"lighthouse": "Lighthouse — Stand still to grow the radius, walk to shrink it",
	"overclock_leak": "Leaky chest — Overclock also pops every bush and draws moths",
	"battery_cell": "Battery cell — Wider safe radius",
	"second_wind": "Second wind — Another dash charge",
	"moth_ward": "Moth ward — Take less chip, moths hurt less",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel.add_theme_stylebox_override("panel", MenuSkin.cream_panel())
	$Panel/Title.add_theme_color_override("font_color", MenuSkin.TERRACOTTA)
	$Panel/Title.text = "Choose an upgrade"
	for b in buttons:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_stylebox_override("normal", MenuSkin.card(false))
		b.add_theme_stylebox_override("hover", MenuSkin.card(true))
		b.add_theme_color_override("font_color", MenuSkin.INK)
		b.pressed.connect(_on_pick.bind(b))
	GameManager.wave_cleared.connect(show_upgrades)

func show_upgrades() -> void:
	visible = true
	get_tree().paused = true
	var choices := _choices()
	for i in range(buttons.size()):
		var id: String = choices[i]
		buttons[i].text = upgrade_names.get(id, id)
		buttons[i].set_meta("upgrade_id", id)

func _choices() -> Array:
	var player := get_tree().get_first_node_in_group("player")
	var owned: Array = []
	if player != null and "acquired_upgrades" in player:
		owned = player.acquired_upgrades
	var pool: Array = []
	for id in upgrade_pool:
		if unique.has(id) and owned.has(id):
			continue
		pool.append(id)
	pool.shuffle()
	while pool.size() < 3:
		pool.append("damage")
	return [pool[0], pool[1], pool[2]]

func _on_pick(button: Button) -> void:
	var id: String = button.get_meta("upgrade_id")
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(id)
	visible = false
	GameManager.upgrade_picked.emit()
