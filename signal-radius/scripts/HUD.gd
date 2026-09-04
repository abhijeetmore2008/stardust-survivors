extends CanvasLayer

@onready var wave_label: Label = $WaveLabel

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	_on_wave_changed(GameManager.current_wave)

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave