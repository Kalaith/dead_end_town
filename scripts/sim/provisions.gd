extends RefCounted
const HomeRest = preload("res://scripts/sim/home_rest.gd")
## One community meal clock; no individual needs or offline progression.


static func initial() -> Dictionary:
	return {"clock": 0.0, "hungry": false, "warned": false, "harvested": 0}


static func meal_cost(world: RefCounted) -> int:
	return 1 + world.survivors.size()


static func work_rate(world: RefCounted) -> float:
	return float(world.balance.shortage_work_rate) if world.provisions.hungry else 1.0


static func step(world: RefCounted, dt: float) -> void:
	var s: Dictionary = world.provisions
	var cost: int = meal_cost(world)
	if s.hungry and world.food >= cost:
		world.food -= cost
		s.hungry = false
		s.warned = false
		s.clock = 0.0
		world.note("A shared meal restores normal work. The garden keeps everyone supplied.")
	if not s.hungry:
		s.clock += dt
		if float(s.clock) >= float(world.balance.meal_seconds):
			s.clock -= float(world.balance.meal_seconds)
			if world.food >= cost:
				world.food -= cost
			else:
				s.hungry = true
				s.warned = true
				s.clock = 0.0
				world.note("Food shortage. Work slows until there is a shared meal; nobody loses health to hunger.")
	if world.food < cost and not s.warned:
		s.warned = true
		world.note("Food running low. Tend the connected garden before the next shared meal.")
	elif world.food >= cost:
		s.warned = false


static func recover(world: RefCounted) -> void:
	HomeRest.start(world)


static func summary(world: RefCounted) -> String:
	if world.provisions.hungry:
		return "FOOD SHORTAGE / work %d%%; next meal needs %d food" % [int(float(world.balance.shortage_work_rate) * 100), meal_cost(world)]
	return "Shared meal: %d food in %ds / recovery: %d food" % [meal_cost(world), ceili(float(world.balance.meal_seconds) - float(world.provisions.clock)), int(world.balance.recovery_food)]
