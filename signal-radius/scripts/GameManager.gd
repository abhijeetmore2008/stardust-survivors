extends Node

enum State { PLAYING, PAUSED, GAME_OVER }

var state: State = State.PLAYING
var current_wave: int = 0
var score: int = 0 

signal wave_changed(wave: int)
signal score_changed(score: int)
signal game_over 

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func next_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)

func trigger_game_over() -> void:
	state = State.GAME_OVER
	game_over.emit()

func reset() -> void:
	state = State.PLAYING
	current_wave = 0
	score = 0 