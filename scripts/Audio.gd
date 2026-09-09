extends Node

var music: AudioStreamPlayer
var hum: AudioStreamPlayer
var pool: Array = []
var streams: Dictionary = {}
var step_cd: float = 0.0
var gate_cd: float = 0.0
var hum_on: bool = false

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -16.0
	add_child(music)
	hum = AudioStreamPlayer.new()
	hum.volume_db = -14.0
	add_child(hum)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	_load_all()
	music.finished.connect(_play_music)
	hum.finished.connect(_hum_again)
	_play_music()

func _hum_again() -> void:
	if hum_on and hum.stream:
		hum.play()

func _load_all() -> void:
	var names := ["music", "hum", "step", "fire", "hit", "hurt", "dash", "lantern", "ping", "spark", "kill", "mote", "gate", "lock", "ui", "overcharge"]
	for n in names:
		var path := "res://audio/%s.wav" % n
		var s: AudioStream = null
		if ResourceLoader.exists(path):
			s = load(path)
		if s == null:
			continue
		if s is AudioStreamWAV:
			var w: AudioStreamWAV = (s as AudioStreamWAV).duplicate()
			if n == "music" or n == "hum":
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_begin = 0
				var bytes: int = w.data.size()
				w.loop_end = int(bytes / 2)
			streams[n] = w
		else:
			streams[n] = s
	if streams.has("music"):
		music.stream = streams["music"]
	if streams.has("hum"):
		hum.stream = streams["hum"]

func _play_music() -> void:
	if music.stream and not music.playing:
		music.play()

func play(id: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(id):
		return
	for p in pool:
		var sp: AudioStreamPlayer = p
		if sp.playing:
			continue
		sp.stream = streams[id]
		sp.volume_db = db
		sp.pitch_scale = clampf(pitch, 0.7, 1.4)
		sp.play()
		return

func ui() -> void:
	play("ui", -8.0)

func set_hum(on: bool) -> void:
	if on == hum_on:
		return
	hum_on = on
	if on:
		if hum.stream and not hum.playing:
			hum.play()
	else:
		hum.stop()

func _process(delta: float) -> void:
	step_cd = maxf(0.0, step_cd - delta)
	gate_cd = maxf(0.0, gate_cd - delta)
	_play_music()
	if not GameManager.started or GameManager.state != GameManager.State.PLAYING:
		set_hum(false)
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	set_hum(bool(player.get("broadcasting")) or float(player.get("signal_t")) > 0.0)
	if player.get("velocity") != null and player.velocity.length() > 20.0 and step_cd <= 0.0:
		step_cd = 0.32
		play("step", -18.0, 0.92 + randf() * 0.16)
	if GameManager.holding_gate and gate_cd <= 0.0:
		gate_cd = 0.48
		play("gate", -10.0)
