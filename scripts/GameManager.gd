extends Node

enum State { PLAYING, PAUSED, GAME_OVER }

var state: State = State.PLAYING
var current_wave: int = 1
var score: int = 0
var kills_this_wave: int = 0
var kills_to_clear_wave: int = 10
var total_kills: int = 0
var started: bool = false

signal wave_changed(wave: int)
signal wave_cleared
signal score_changed(score: int)
signal game_over
signal kill_registered
signal run_started

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func register_kill() -> void:
	kills_this_wave += 1
	total_kills += 1
	kill_registered.emit()
	if kills_this_wave >= kills_to_clear_wave:
		_clear_wave()

func _clear_wave() -> void:
	kills_this_wave = 0
	kills_to_clear_wave += 5
	state = State.PAUSED
	wave_cleared.emit()

func start_next_wave() -> void:
	current_wave += 1
	state = State.PLAYING
	wave_changed.emit(current_wave)

func trigger_game_over() -> void:
	state = State.GAME_OVER
	game_over.emit()

func start_run() -> void:
	reset()
	started = true
	state = State.PLAYING
	run_started.emit()

func reset() -> void:
	state = State.PLAYING
	current_wave = 1
	score = 0
	kills_this_wave = 0
	kills_to_clear_wave = 10
	total_kills = 0
