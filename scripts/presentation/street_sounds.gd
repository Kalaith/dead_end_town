extends RefCounted
## The street's placeholder sounds, synthesised at start from one seed (no audio files): what each cue sounds like,
## its level and cooldown, and each area's ambient bed. Which moment plays which cue is StreetAudio's.
const Synth = preload("res://addons/hatchery/audio/synth.gd")
const SEED: int = 1987


## Registers every cue on `bank` (a CueBank).
static func register(bank: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# A sharp crack: mostly noise with a fast decay over a low thump.
	bank.add("gunshot", Synth.tone(rng, [[90.0, 0.6], [180.0, 0.3]], 0.45, 0.85, 16.0, 0.9), -4.0, 0.05)
	bank.add("swing", Synth.tone(rng, [[220.0, 0.2]], 0.16, 0.7, 26.0, 0.35), -14.0, 0.12)
	bank.add("hit", Synth.tone(rng, [[110.0, 0.7], [165.0, 0.3]], 0.22, 0.45, 22.0, 0.8), -8.0, 0.08)
	# A low, wavering moan.
	bank.add("groan", Synth.tone(rng, [[82.0, 0.5], [123.0, 0.35], [164.0, 0.15]], 1.3, 0.25, 1.6, 0.55), -12.0, 0.0)
	bank.add("strike", Synth.tone(rng, [[140.0, 0.6], [70.0, 0.4]], 0.3, 0.55, 14.0, 0.85), -7.0, 0.25)
	bank.add("work", Synth.tone(rng, [[660.0, 0.4], [990.0, 0.2]], 0.12, 0.35, 30.0, 0.4), -16.0, 0.45)
	bank.add("built", Synth.tone(rng, [[392.0, 0.5], [587.0, 0.4]], 0.7, 0.05, 4.0, 0.5), -10.0, 0.5)
	bank.add("engine", Synth.tone(rng, [[55.0, 0.6], [110.0, 0.3], [165.0, 0.1]], 0.32, 0.3, 3.0, 0.6), -11.0, 0.0)
	bank.add("tip", Synth.tone(rng, [[880.0, 0.5], [1320.0, 0.3]], 0.9, 0.0, 3.0, 0.4), -14.0, 1.0)


## The looping layers for an area's bed: wind in the suburb, a building hum in the office, machinery in the works.
static func bed(area: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + area.hash() % 1000
	match area:
		"office":
			return [{"stream": Synth.drone_loop(60.0, [1.0, 2.0, 3.0], 4.0, 0.2), "db": -24.0}, {"stream": Synth.wind_loop(rng, 5.0, 0.015, 0.3), "db": -26.0}]
		"industrial":
			return [{"stream": Synth.drone_loop(48.0, [1.0, 1.5, 2.0], 4.0, 0.25), "db": -22.0}, {"stream": Synth.hiss_loop(rng, 4.0, 0.2), "db": -30.0}]
	return [{"stream": Synth.wind_loop(rng, 6.0, 0.02, 0.37), "db": -20.0}]
