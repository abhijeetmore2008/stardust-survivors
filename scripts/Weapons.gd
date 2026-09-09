class_name Weapons
extends Object

static func all_ids() -> PackedStringArray:
	return PackedStringArray(["pulse", "bow", "scatter", "coil"])

static func def(id: String) -> Dictionary:
	match id:
		"bow":
			return {
				"id": "bow", "name": "Shard Bow", "tag": "PIERCE",
				"pair": "GLASS ECHO",
				"blurb": "Slow glass arrows that punch two shades.",
				"pair_blurb": "Broadcast leaves a pierce line on the far edge of the cone.",
				"fire_rate": 1.55, "damage": 36.0, "speed": 760.0, "life": 0.85,
				"spread": 0.01, "count": 1, "pierce": 2, "homing": 0.0,
				"color": Color("c9e87e"),
			}
		"scatter":
			return {
				"id": "scatter", "name": "Ember Scatter", "tag": "CLOSE",
				"pair": "FLOODLIGHT",
				"blurb": "Five-ember burst. Mean in the face.",
				"pair_blurb": "Huge cone, weaker tick. Moths love you.",
				"fire_rate": 1.85, "damage": 10.0, "speed": 470.0, "life": 0.32,
				"spread": 0.34, "count": 5, "pierce": 0, "homing": 0.0,
				"color": Color("e89a6a"),
			}
		"coil":
			return {
				"id": "coil", "name": "Coil Lance", "tag": "SEEK",
				"pair": "LOCK",
				"blurb": "A hungry bolt that curves toward painted shades.",
				"pair_blurb": "Homing only tracks enemies the cone has painted.",
				"fire_rate": 2.35, "damage": 22.0, "speed": 640.0, "life": 0.7,
				"spread": 0.02, "count": 1, "pierce": 0, "homing": 4.2,
				"color": Color("b89cff"),
			}
		_:
			return {
				"id": "pulse", "name": "Pulse Rifle", "tag": "BALANCED",
				"pair": "RESONANCE",
				"blurb": "Steady cyan bolts. Reliable at any range.",
				"pair_blurb": "While you broadcast, the rifle auto-fires cone targets.",
				"fire_rate": 5.1, "damage": 15.0, "speed": 560.0, "life": 0.62,
				"spread": 0.05, "count": 1, "pierce": 0, "homing": 0.0,
				"color": Color("7ee7f0"),
			}
