extends SceneTree

func _init() -> void:
	var errs := 0
	errs += _weapons()
	errs += _biomes()
	errs += _levels()
	errs += _forks()
	print("SELFTEST_DONE errs=", errs)
	quit(errs)

func _fail(msg: String) -> int:
	push_error("SELFTEST " + msg)
	print("FAIL ", msg)
	return 1

func _weapons() -> int:
	var n := 0
	if Weapons.all_ids().size() != 4:
		n += _fail("weapon count")
	for id in Weapons.all_ids():
		var w: Dictionary = Weapons.def(id)
		if str(w.id) != id and id != "pulse":
			n += _fail("weapon id " + id)
		if float(w.fire_rate) <= 0.0 or float(w.damage) <= 0.0:
			n += _fail("weapon stats " + id)
		if not w.has("pair"):
			n += _fail("weapon pair " + id)
	return n

func _biomes() -> int:
	var n := 0
	for id in ["meadow", "gold", "grove", "harvest", "dusk"]:
		var b: Dictionary = LevelGen.biome(id, 8)
		if str(b.id) != id:
			n += _fail("biome id " + id)
		if float(b.hold_time) < 1.0:
			n += _fail("hold time " + id)
		if int(b.bush_n) < 1:
			n += _fail("bushes " + id)
	if LevelGen.biome_for_level(1) != "meadow":
		n += _fail("level1 biome")
	if LevelGen.biome_for_level(18) != "dusk":
		n += _fail("dusk biome")
	return n

func _levels() -> int:
	var n := 0
	for biome_id in ["meadow", "gold", "grove", "harvest", "dusk"]:
		for lv in range(1, 21):
			var d: Dictionary = LevelGen.build(lv, biome_id, 12345)
			if d.start.distance_to(d.exit) < 80.0:
				n += _fail("start/exit too close %s %d" % [biome_id, lv])
			if d.lanterns.size() < 1:
				n += _fail("no lanterns %s %d" % [biome_id, lv])
			if d.spawns.size() < 1:
				n += _fail("no spawns %s %d" % [biome_id, lv])
			if d.tiles.size() != LevelGen.MAP_H:
				n += _fail("tiles h")
			if lv >= 4 and not d.giant:
				n += _fail("missing giant flag %d" % lv)
			var kinds := {}
			for s in d.spawns:
				kinds[s.kind] = true
				if s.hidden and str(s.kind) == "":
					n += _fail("empty hidden kind")
			if lv >= 4:
				var g := false
				for s in d.spawns:
					if str(s.kind) == "giant":
						g = true
				if not g:
					n += _fail("no giant spawn %s %d" % [biome_id, lv])
	return n

func _forks() -> int:
	var n := 0
	var f2: Array = LevelGen.fork_options(2, 99)
	if f2.size() < 2:
		n += _fail("fork 2 size")
	var f20: Array = LevelGen.fork_options(20, 99)
	if f20.size() != 1 or str(f20[0].id) != "dusk":
		n += _fail("fork 20")
	var f17: Array = LevelGen.fork_options(17, 7)
	if f17.size() < 1 or str(f17[0].id) != "dusk":
		n += _fail("fork 17")
	return n
