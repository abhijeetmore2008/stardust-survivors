extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var wave_label: Label = $WaveLabel

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = player.max_hp
		hp_bar.value = player.hp

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave