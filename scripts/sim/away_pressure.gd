extends RefCounted
## What a long absence costs an area beyond its home gate (battered in AreaTravel): raiders wear down the standing
## street barricades, and after a much longer absence they take the outlying lot nobody could have held, the claimed
## lot farthest from home without a protected route to it. Lots joined to home by safe routes always hold.
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func run(world: RefCounted, away: float) -> void:
	if away < float(world.balance.away_siege_seconds):
		return
	_barricades(world)
	if away >= float(world.balance.away_loss_seconds):
		_outlying_lot(world)


static func _barricades(world: RefCounted) -> void:
	var worn: int = 0
	var broken: int = 0
	for d: Dictionary in world.catalog.barricades:
		var state: Dictionary = world.roadworks[d.id]
		if not Roadworks.active(state):
			continue
		state.hp = floorf(float(state.hp) * float(world.balance.away_siege_factor))
		worn += 1
		if float(state.hp) <= 0:
			Repairs.destroy(world, "road:" + str(d.id))
			WorkOrders.cancel(world, "road:" + str(d.id), true)
			world.roadworks[d.id] = Roadworks.empty()
			broken += 1
	if broken > 0:
		world.rebuild_routes()
	if worn > 0:
		world.note("While you were away raiders wore down %d street barricade%s%s." % [worn, "" if worn == 1 else "s", (", %d broke" % broken) if broken > 0 else ""])


static func _outlying_lot(world: RefCounted) -> void:
	var home: Vector2 = Routes.point(world.definition("home").site)
	var lost: Dictionary = {}
	var farthest: float = -1.0
	for p: Dictionary in world.catalog.properties:
		if p.id == "home" or not world.properties[p.id].claimed or world.safe_connected(p.id):
			continue
		var distance: float = home.distance_to(Routes.point(p.site))
		if distance > farthest:
			farthest = distance
			lost = p
	if lost.is_empty():
		return
	world.properties[lost.id].claimed = false
	world.properties[lost.id].occupation = 0.0
	world.rebuild_routes()
	world.note("While you were away %s fell: nobody could hold it without a protected route home. Reclaim it at its porch." % str(lost.name))
