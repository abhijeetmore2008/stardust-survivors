extends Node

enum State { PLAYING, PAUSED, GAME_OVER, VICTORY }

const MAX_LEVEL := 20
const GATE_NEAR := 150.0
const GATE_LOCK_R := 100.0
const GATE_FACE := 96.0

var state: State = State.PLAYING
var current_wave: int = 1
var current_level: int = 1
var score: int = 0
var kills_this_wave: int = 0
var kills_to_clear_wave: int = 9999
var total_kills: int = 0
var started: bool = false
var gate_open: bool = true
var weapon_id: String = "pulse"
var weapon_b_id: String = ""
var biome_id: String = "meadow"
var biome: Dictionary = {}
var run_seed: int = 42
var daily: bool = false
var holding_gate: bool = false
var hold_progress: float = 0.0
var near_gate: bool = false
var ghost_log: Array = []
var puffs: Array = []
var shake: float = 0.0
var shake_mag: float = 0.0

signal wave_changed(wave: int)
signal wave_cleared
signal score_changed(score: int)
signal game_over
signal kill_registered
signal run_started
signal victory
signal level_applied(level: int)
signal upgrade_picked
signal lantern_changed

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func register_kill() -> void:
	kills_this_wave += 1
	total_kills += 1
	kill_registered.emit()

func bump(mag: float = 5.0) -> void:
	shake = 0.18
	shake_mag = mag

func add_puff(pos: Vector2) -> void:
	puffs.append({"p": pos, "t": 0.42})

func complete_level() -> void:
	holding_gate = false
	hold_progress = 0.0
	if current_level == 1 and not Meta.taught:
		Meta.taught = true
		Meta.save_cfg()
	Audio.play("lock", -6.0)
	bump(8.0)
	if current_level >= MAX_LEVEL:
		state = State.VICTORY
		victory.emit()
		return
	state = State.PAUSED
	wave_cleared.emit()

func start_next_wave(p_biome: String = "") -> void:
	current_wave += 1
	current_level = current_wave
	if p_biome != "":
		biome_id = p_biome
	holding_gate = false
	hold_progress = 0.0
	near_gate = false
	state = State.PLAYING
	wave_changed.emit(current_wave)
	level_applied.emit(current_level)

func trigger_game_over() -> void:
	if state == State.GAME_OVER or state == State.VICTORY:
		return
	state = State.GAME_OVER
	game_over.emit()

func start_run(p_weapon: String = "pulse", p_daily: bool = false, p_weapon_b: String = "") -> void:
	weapon_id = p_weapon
	weapon_b_id = p_weapon_b
	daily = p_daily
	if p_daily:
		run_seed = Meta.daily_seed()
	else:
		randomize()
		run_seed = randi()
	reset()
	started = true
	state = State.PLAYING
	run_started.emit()
	level_applied.emit(1)

func reset() -> void:
	state = State.PLAYING
	current_wave = 1
	current_level = 1
	score = 0
	kills_this_wave = 0
	kills_to_clear_wave = 9999
	total_kills = 0
	gate_open = true
	biome_id = "meadow"
	biome = LevelGen.biome("meadow", 1)
	holding_gate = false
	hold_progress = 0.0
	near_gate = false
	ghost_log.clear()
	puffs.clear()
	shake = 0.0

func lit_count() -> int:
	return get_tree().get_nodes_in_group("lit_lights").size()

func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta)
	var i := 0
	while i < puffs.size():
		puffs[i].t = float(puffs[i].t) - delta
		if float(puffs[i].t) <= 0.0:
			puffs.remove_at(i)
		else:
			i += 1
