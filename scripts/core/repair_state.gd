extends RefCounted
const Repairs = preload("res://scripts/sim/repairs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func valid_site(order: Dictionary, data: Dictionary, catalog: Dictionary) -> bool:
	var d: Dictionary = Repairs.describe(catalog, str(order.get("target", "")))
	if d.is_empty() or order.socket != "repair:" + str(order.target):
		return false
	var s: Dictionary = data.properties[d.id] if d.group == "gate" else (data.passages[d.id] if d.group == "passage" else data.roadworks[d.id])
	if WorkOrders.pending(order):
		if (d.group == "road" and s.phase != "ready") or (d.group == "passage" and not s.done):
			return false
		var hp: float = Repairs.health(s, d)
		if order.recipe == "repair_line" and hp <= 0:
			return false
		if order.recipe == "gate_rebuild" and (d.group == "road" or hp != 0):
			return false
	return true


static func valid(data: Dictionary) -> bool:
	var gates: Array[String] = []
	for id: String in data.properties:
		if WorkOrders.pending(data.orders.sites.get("repair:gate:" + id, {})):
			gates.append(id)
	if data.repair_reserved != (not gates.is_empty()):
		return false
	if data.repair_reserved and str(data.gate_repair_target) not in gates:
		return false
	for pair: Array in [["passages", "passage"], ["roadworks", "road"]]:
		for id: String in data[pair[0]]:
			if data[pair[0]][id].repair_reserved != WorkOrders.pending(data.orders.sites.get("repair:" + str(pair[1]) + ":" + id, {})):
				return false
	return true


static func migrate(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("orders") is Dictionary or not data.orders.get("sites") is Dictionary or not Rules.integer_in(data.orders.get("sequence"), 0, 1000000000):
		return false
	if not data.get("properties") is Dictionary or not data.get("passages") is Dictionary or not data.get("roadworks") is Dictionary or not data.get("repair_reserved") is bool:
		return false
	if data.repair_reserved:
		if not data.get("gate_repair_target") is String or not data.properties.has(data.gate_repair_target):
			return false
		if not _migrate_one(data, catalog, "gate:" + str(data.gate_repair_target), data.properties[data.gate_repair_target]):
			return false
	for pair: Array in [["passages", "passage"], ["roadworks", "road"]]:
		for id: String in data[pair[0]]:
			var s: Variant = data[pair[0]][id]
			if not s is Dictionary or not s.get("repair_reserved") is bool:
				return false
			if s.repair_reserved and not _migrate_one(data, catalog, str(pair[1]) + ":" + id, s):
				return false
	return true


static func _migrate_one(data: Dictionary, catalog: Dictionary, target: String, state: Dictionary) -> bool:
	var d: Dictionary = Repairs.describe(catalog, target)
	if d.is_empty():
		return false
	var value: Variant = state.get("gate_hp" if d.group == "gate" else "hp")
	if not Rules.finite(value) or float(value) < 0 or float(value) > float(d.max):
		return false
	data.orders.sequence = int(data.orders.sequence) + 1
	var order: Dictionary = WorkOrders.record(int(data.orders.sequence), "repair:" + target, target, WorkRecipes.recipe(catalog, "legacy_repair"), Routes.point(d.points[0]))
	# Old repair paid for the whole gap. Preserve that exact remaining work once.
	var remaining: float = (float(d.max) - float(value)) / float(catalog.balance.gate_repair_rate)
	order.work_done = float(order.work_required) - remaining
	data.orders.sites[order.socket] = order
	return order.work_done >= 0
