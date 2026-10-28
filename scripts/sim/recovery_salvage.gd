extends RefCounted
## Slow player-only recovery work. Refundable inputs remain part of its stock cap.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"home": 0.0, "west": 0.0}


static func held(world: RefCounted) -> int:
	var total: int = world.materials
	for order: Dictionary in world.orders.sites.values():
		if WorkOrders.pending(order):
			total += int(WorkOrders.refund(order).get("materials", 0))
	return total


static func nearby(world: RefCounted) -> String:
	var config: Dictionary = world.catalog.recovery_salvage
	for id: String in config.sites:
		if id == "home" and not world.properties.home.claimed:
			continue
		if world.player.pos.distance_to(Routes.point(config.sites[id])) < float(config.range):
			return id
	return ""


static func safe(world: RefCounted, id: String) -> bool:
	return not Combat.danger(world, world.player.pos, 170) and not Combat.danger(world, Routes.point(world.catalog.recovery_salvage.sites[id]), 170)


static func step(world: RefCounted, dt: float) -> void:
	var id: String = nearby(world)
	if id.is_empty() or not world.working or float(world.player.hp) <= 0 or world.defeat_pending or not str(world.carry.patient).is_empty() or not safe(world, id):
		return
	var config: Dictionary = world.catalog.recovery_salvage
	if held(world) >= int(config.cap):
		return
	world.recovery_salvage[id] = minf(float(config.seconds), float(world.recovery_salvage[id]) + dt)
	if float(world.recovery_salvage[id]) >= float(config.seconds):
		# Stock/commitments may change during a partial cycle; check again at payment.
		var room: int = maxi(0, int(config.cap) - held(world))
		world.materials += mini(int(config.batch), room)
		world.recovery_salvage[id] = 0.0


static func context(world: RefCounted) -> String:
	var id: String = nearby(world)
	if id.is_empty() or held(world) >= int(world.catalog.recovery_salvage.cap):
		return ""
	if not safe(world, id):
		return "Clear nearby threats"
	var config: Dictionary = world.catalog.recovery_salvage
	var text: String = "R Recovery salvage · +%d materials" % mini(int(config.batch), int(config.cap) - held(world))
	if float(world.recovery_salvage[id]) > 0:
		text += " · %d%%" % int(100 * float(world.recovery_salvage[id]) / float(config.seconds))
	return text
