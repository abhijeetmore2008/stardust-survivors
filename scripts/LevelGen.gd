class_name LevelGen
extends Object

const TILE := 48
const MAP_W := 34
const MAP_H := 22
const MAX_LEVEL := 20

static func biome(id: String, level: int = 1) -> Dictionary:
	match id:
		"gold":
			return {
				"id": "gold", "name": "Gold hour", "sky": Color("c47a3a"),
				"cone_mul": 1.0, "radius_mul": 0.95, "jam_gun": false, "flicker": false,
				"hold_time": 2.5, "moth_bias": 0.08, "bush_n": 3 + mini(6, int(level * 0.4)),
				"roam": maxi(3, 2 + int(level * 0.35)), "lantern_step": 8, "blooms": 2,
				"extra_chest": true, "flanker_from_dark": true,
				"blurb": "Long shadows. Flankers crawl out of unlit grass. Extra chest.",
			}
		"grove":
			return {
				"id": "grove", "name": "Deep grove", "sky": Color("2d5a3a"),
				"cone_mul": 0.78, "radius_mul": 0.88, "jam_gun": false, "flicker": false,
				"hold_time": 2.6, "moth_bias": 0.18, "bush_n": 6 + mini(10, 1 + int(level * 0.6)),
				"roam": maxi(2, 2 + int(level * 0.3)), "lantern_step": 6, "blooms": 3,
				"extra_chest": false, "flanker_from_dark": false,
				"blurb": "Short cone. Bushes everywhere. Ping before you walk in.",
			}
		"harvest":
			return {
				"id": "harvest", "name": "Harvest", "sky": Color("8a5a32"),
				"cone_mul": 1.0, "radius_mul": 1.05, "jam_gun": false, "flicker": false,
				"hold_time": 2.7, "moth_bias": 0.05, "bush_n": 3 + mini(6, int(level * 0.35)),
				"roam": maxi(3, 2 + int(level * 0.35)), "lantern_step": 5, "blooms": 1,
				"extra_chest": false, "flanker_from_dark": false,
				"blurb": "Brutes and jammers. Lantern chains shut the Giant up.",
			}
		"dusk":
			return {
				"id": "dusk", "name": "Static dusk", "sky": Color("3a2a48"),
				"cone_mul": 0.86, "radius_mul": 0.82, "jam_gun": true, "flicker": true,
				"hold_time": 3.2, "moth_bias": 0.22, "bush_n": 4 + mini(8, int(level * 0.4)),
				"roam": maxi(3, 3 + int(level * 0.3)), "lantern_step": 5, "blooms": 2,
				"extra_chest": false, "flanker_from_dark": true,
				"blurb": "Cone flickers. Gun jams outside a lit radius. Hold the crystal longer.",
			}
		_:
			return {
				"id": "meadow", "name": "Meadow dawn", "sky": Color("4a8a48"),
				"cone_mul": 1.15, "radius_mul": 1.12, "jam_gun": false, "flicker": false,
				"hold_time": 2.4, "moth_bias": 0.04, "bush_n": 2 + mini(4, int(level * 0.3)),
				"roam": maxi(2, 2 + int(level * 0.3)), "lantern_step": 7, "blooms": 3,
				"extra_chest": false, "flanker_from_dark": false,
				"blurb": "Wide radius, gentle shades, extra blooms. The kind road.",
			}

static func biome_for_level(level: int) -> String:
	if level >= 17:
		return "dusk"
	var t := (level - 1) % 4
	if t == 0:
		return "meadow"
	if t == 1:
		return "gold"
	if t == 2:
		return "grove"
	return "harvest"

static func stats(level: int) -> Dictionary:
	return {
		"hp": 1.0 + (level - 1) * 0.16,
		"spd": 1.0 + (level - 1) * 0.07,
		"dmg": 1.0 + (level - 1) * 0.1,
		"max_alive": mini(7, 3 + int(level * 0.28)),
		"interval": maxf(1.15, 1.65 - level * 0.025),
	}

static func _rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r

static func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < MAP_W and y < MAP_H

static func _autotile(path: Array, x: int, y: int) -> String:
	var n: bool = _in(x, y - 1) and bool(path[y - 1][x])
	var e: bool = _in(x + 1, y) and bool(path[y][x + 1])
	var s: bool = _in(x, y + 1) and bool(path[y + 1][x])
	var w: bool = _in(x - 1, y) and bool(path[y][x - 1])
	if n and e and s and w: return "c"
	if not n and e and s and w: return "n"
	if n and not e and s and w: return "e"
	if n and e and not s and w: return "s"
	if n and e and s and not w: return "w"
	if not n and not w and s and e: return "nw"
	if not n and not e and s and w: return "ne"
	if not s and not w and n and e: return "sw"
	if not s and not e and n and w: return "se"
	return "c"

static func _shuffle(arr: Array, r: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

static func _kind(level: int, r: RandomNumberGenerator, giant: bool, biome_id: String) -> String:
	if giant:
		return "giant"
	var v := r.randf()
	match biome_id:
		"gold":
			if level >= 6 and v < 0.16: return "wraith"
			if level >= 5 and v < 0.42: return "flanker"
			if level >= 3 and v < 0.62: return "rusher"
			return "walker"
		"grove":
			if level >= 6 and v < 0.14: return "mimic"
			if level >= 4 and v < 0.28: return "mite"
			if v < 0.44: return "moth"
			if level >= 3 and v < 0.62: return "rusher"
			return "walker"
		"harvest":
			if level >= 7 and v < 0.16: return "jammer"
			if level >= 8 and v < 0.34: return "brute"
			if level >= 3 and v < 0.52: return "rusher"
			return "walker"
		"dusk":
			if level >= 14 and v < 0.10: return "giant"
			if v < 0.22: return "moth"
			if v < 0.34: return "wraith"
			if v < 0.46: return "mite"
			if v < 0.58: return "jammer"
			if level >= 8 and v < 0.72: return "brute"
			return "rusher"
		_:
			if level >= 14 and v < 0.10: return "giant"
			if level >= 8 and v < 0.16: return "brute"
			if level >= 5 and v < 0.28: return "flanker"
			if level >= 3 and v < 0.42: return "rusher"
			if level >= 2 and v < 0.22: return "rusher"
			if v < 0.08: return "moth"
			return "walker"

static func _world(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)

static func fork_options(next_level: int, run_seed: int) -> Array:
	var r := _rng(run_seed * 31 + next_level * 1337 + 9)
	var out: Array = []
	if next_level >= 19:
		out.append(biome("dusk", next_level))
		return out
	if next_level >= 17:
		out.append(biome("dusk", next_level))
		var extras := ["grove", "harvest", "gold"]
		_shuffle(extras, r)
		out.append(biome(str(extras[0]), next_level))
		return out
	var ids := ["meadow", "gold", "grove", "harvest"]
	_shuffle(ids, r)
	var n := 3 if next_level % 2 == 0 else 2
	for i in n:
		out.append(biome(str(ids[i]), next_level))
	return out

static func build(level: int, biome_id: String = "meadow", run_seed: int = 42) -> Dictionary:
	if biome_id == "":
		biome_id = biome_for_level(level)
	var b := biome(biome_id, level)
	var r := _rng(run_seed * 17 + level * 9973 + 42)
	var path: Array = []
	for y in MAP_H:
		var row: Array = []
		row.resize(MAP_W)
		row.fill(false)
		path.append(row)
	var x := 1
	var y := int(MAP_H / 2.0)
	var start_t := Vector2i(x, y)
	var mark := func(px: int, py: int) -> void:
		for dy in 2:
			for dx in 2:
				var nx := px + dx
				var ny := py + dy
				if _in(nx, ny):
					path[ny][nx] = true
	mark.call(x, y)
	var guard := 0
	while x < MAP_W - 4 and guard < 800:
		guard += 1
		var v := r.randf()
		if v < 0.58:
			x += 1
		elif v < 0.74 and y > 3:
			y -= 1
		elif v < 0.9 and y < MAP_H - 5:
			y += 1
		else:
			x += 1
		x = clampi(x, 1, MAP_W - 4)
		y = clampi(y, 2, MAP_H - 5)
		mark.call(x, y)
	var end_t := Vector2i(mini(MAP_W - 3, x + 1), y)
	var tiles: Array = []
	for ty in MAP_H:
		var row: Array = []
		for tx in MAP_W:
			if path[ty][tx]:
				row.append(_autotile(path, tx, ty))
			else:
				row.append((tx * 5 + ty * 3 + level) % 4)
		tiles.append(row)
	var start := _world(start_t.x, start_t.y)
	var exit := _world(end_t.x, end_t.y)
	var on_edge := func(tx: int, ty: int) -> bool:
		if path[ty][tx]:
			return false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				if _in(tx + dx, ty + dy) and path[ty + dy][tx + dx]:
					return true
		return false
	var bushes: Array = []
	var bush_n: int = int(b.bush_n)
	var tries := 0
	while bushes.size() < bush_n and tries < 400:
		tries += 1
		var tx := 3 + r.randi_range(0, MAP_W - 7)
		var ty := 2 + r.randi_range(0, MAP_H - 5)
		if not on_edge.call(tx, ty):
			continue
		if Vector2(tx - start_t.x, ty - start_t.y).length() < 4:
			continue
		bushes.append({"pos": _world(tx, ty), "kind": _kind(level, r, false, biome_id)})
	var trees: Array = []
	tries = 0
	while trees.size() < 18 + level and tries < 500:
		tries += 1
		var tx := r.randi_range(0, MAP_W - 1)
		var ty := r.randi_range(0, MAP_H - 1)
		if path[ty][tx]:
			continue
		trees.append({"pos": _world(tx, ty), "cell": r.randi_range(0, 2)})
	var path_cells: Array = []
	for ty in MAP_H:
		for tx in MAP_W:
			if path[ty][tx]:
				path_cells.append(Vector2i(tx, ty))
	if path_cells.is_empty():
		path_cells.append(start_t)
	var spawns: Array = []
	for bush in bushes:
		if r.randf() > 0.45:
			continue
		var hk: String = str(bush.kind)
		if hk == "mite" or hk == "moth" or hk == "wraith":
			hk = "walker" if r.randf() < 0.5 else "rusher"
		if biome_id == "grove" and r.randf() < 0.18:
			hk = "mimic"
		spawns.append({"pos": bush.pos, "kind": hk, "hidden": true})
	var roam: int = int(b.roam)
	var start_idx := int(path_cells.size() * 0.28)
	for i in roam:
		var idx := r.randi_range(start_idx, path_cells.size() - 1)
		var cell: Vector2i = path_cells[idx]
		spawns.append({"pos": _world(cell.x, cell.y), "kind": _kind(level, r, false, biome_id), "hidden": false})
	var has_giant := level >= 4
	if has_giant:
		var n := 2 if level >= 16 else 1
		for i in n:
			var gx := int(MAP_W * (0.62 + i * 0.12))
			var gy := clampi(end_t.y, 3, MAP_H - 4)
			spawns.append({"pos": _world(gx, gy), "kind": "giant", "hidden": false})
	if str(b.id) == "gold" or (str(b.id) == "dusk" and level >= 12):
		for i in 2:
			var cell: Vector2i = path_cells[r.randi_range(0, path_cells.size() - 1)]
			spawns.append({"pos": _world(cell.x, cell.y), "kind": "flanker", "hidden": false})
	var lanterns: Array = []
	var step: int = maxi(4, int(b.lantern_step))
	for i in range(0, path_cells.size(), step):
		var c: Vector2i = path_cells[i]
		lanterns.append(_world(c.x, c.y))
	if lanterns.is_empty():
		lanterns.append(start)
	var flowers: Array = []
	tries = 0
	while flowers.size() < 14 + level and tries < 300:
		tries += 1
		var tx := r.randi_range(0, MAP_W - 1)
		var ty := r.randi_range(0, MAP_H - 1)
		if path[ty][tx]:
			continue
		flowers.append(_world(tx, ty))
	var rocks: Array = []
	tries = 0
	while rocks.size() < 8 + int(level / 2.0) and tries < 200:
		tries += 1
		var tx := r.randi_range(0, MAP_W - 1)
		var ty := r.randi_range(0, MAP_H - 1)
		if path[ty][tx]:
			continue
		rocks.append(_world(tx, ty))
	var motes: Array = []
	var mote_n := 8 + int(level / 2.0)
	if biome_id == "grove":
		mote_n += 4
	for i in mote_n:
		var c: Vector2i = path_cells[r.randi_range(0, path_cells.size() - 1)]
		motes.append(_world(c.x, c.y))
	var blooms: Array = []
	var bn: int = int(b.blooms)
	for i in bn:
		var idx := int(path_cells.size() * (0.25 + i * 0.28))
		idx = clampi(idx, 0, path_cells.size() - 1)
		var c: Vector2i = path_cells[idx]
		blooms.append(_world(c.x, c.y))
	var mid: Vector2i = path_cells[int(path_cells.size() * 0.48)]
	var chest_c: Vector2i = path_cells[int(path_cells.size() * 0.78)]
	var chests: Array = [_world(chest_c.x, maxi(2, chest_c.y - 1))]
	if b.extra_chest:
		var c2: Vector2i = path_cells[int(path_cells.size() * 0.38)]
		chests.append(_world(c2.x, maxi(2, c2.y + 1)))
	return {
		"level": level,
		"biome_id": biome_id,
		"biome": b,
		"tiles": tiles,
		"path": path,
		"start": start,
		"exit": exit,
		"bushes": bushes,
		"trees": trees,
		"spawns": spawns,
		"giant": has_giant,
		"lanterns": lanterns,
		"flowers": flowers,
		"rocks": rocks,
		"motes": motes,
		"blooms": blooms,
		"waystone": _world(mid.x, mid.y),
		"chest": chests[0],
		"chests": chests,
		"hold_time": float(b.hold_time),
	}
