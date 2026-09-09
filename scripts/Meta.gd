extends Node

const PATH := "user://signal_radius.cfg"

const COSTS := {
	"warm_lantern": 40,
	"spare_dash": 70,
	"second_kit": 90,
	"hound": 110,
}

const LABELS := {
	"warm_lantern": "Warm lantern — first lamp on every road is already lit",
	"spare_dash": "Spare dash — a second dash charge",
	"second_kit": "Second kit — pick two guns at deploy",
	"hound": "Hound — barks at mimic bushes",
}

var dust: int = 0
var best: int = 0
var owned: Dictionary = {
	"warm_lantern": false,
	"spare_dash": false,
	"second_kit": false,
	"hound": false,
}
var ghost: Array = []
var ghost_score: int = 0
var taught: bool = false

func _ready() -> void:
	load_cfg()

func load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	dust = int(cfg.get_value("meta", "dust", 0))
	best = int(cfg.get_value("run", "best", 0))
	taught = bool(cfg.get_value("meta", "taught", false))
	ghost_score = int(cfg.get_value("ghost", "score", 0))
	for k in owned.keys():
		owned[k] = bool(cfg.get_value("outpost", k, false))
	ghost.clear()
	var xs: Array = cfg.get_value("ghost", "x", [])
	var ys: Array = cfg.get_value("ghost", "y", [])
	var n: int = mini(xs.size(), ys.size())
	for i in n:
		ghost.append(Vector2(float(xs[i]), float(ys[i])))

func save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("meta", "dust", dust)
	cfg.set_value("meta", "taught", taught)
	cfg.set_value("run", "best", best)
	cfg.set_value("ghost", "score", ghost_score)
	for k in owned.keys():
		cfg.set_value("outpost", k, owned[k])
	var xs: Array = []
	var ys: Array = []
	for p in ghost:
		xs.append(p.x)
		ys.append(p.y)
	cfg.set_value("ghost", "x", xs)
	cfg.set_value("ghost", "y", ys)
	cfg.save(PATH)

func award_run(score: int, path: Array) -> int:
	if score > best:
		best = score
	dust += maxi(0, int(round(float(score) / 8.0)))
	if score >= ghost_score and path.size() > 4:
		ghost_score = score
		ghost = path.duplicate()
	save_cfg()
	return best

func buy(id: String) -> bool:
	if not COSTS.has(id):
		return false
	if owned.get(id, false):
		return false
	var cost: int = int(COSTS[id])
	if dust < cost:
		return false
	dust -= cost
	owned[id] = true
	save_cfg()
	return true

func has(id: String) -> bool:
	return bool(owned.get(id, false))

static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)
