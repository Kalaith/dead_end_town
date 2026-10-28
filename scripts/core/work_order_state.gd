extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var policy: Variant = data.get("production")
	if not policy is Dictionary or policy.get("mode") not in ["stopped", "once", "repeat"]:
		return false
	if not Rules.integer_in(policy.get("target"), 0, 999) or not Rules.integer_in(policy.get("material_reserve"), 0, 999) or not policy.get("reason") is String:
		return false
	if policy.mode != "stopped" and not data.properties.munitions.looted:
		return false
	var ledger: Variant = data.get("orders")
	if not ledger is Dictionary or not Rules.integer_in(ledger.get("sequence"), 0, 1000000000) or not ledger.get("sites") is Dictionary:
		return false
	var ids: Array[String] = []
	for socket: Variant in ledger.sites:
		if socket != "munitions" or not data.properties.munitions.looted:
			return false
		var order: Variant = ledger.sites[socket]
		if not order is Dictionary or not _valid_order(order, catalog):
			return false
		if int(order.sequence) > int(ledger.sequence) or ids.has(order.id) or order.socket != socket:
			return false
		ids.append(order.id)
	return true


static func _valid_order(o: Dictionary, catalog: Dictionary) -> bool:
	if not Rules.integer_in(o.get("sequence"), 1, 1000000000) or o.get("id") != "work_%d" % int(o.sequence):
		return false
	if o.get("recipe") != "bullets" or o.get("kind") != "production" or o.get("target") != "munitions":
		return false
	if o.get("phase") not in ["approved", "working", "blocked", "completed", "cancelled", "destroyed"]:
		return false
	if not _bundle(o.get("inputs"), "materials", int(catalog.firearm.material_cost)):
		return false
	if not _bundle(o.get("outputs"), "bullets", int(catalog.firearm.batch_bullets)):
		return false
	if not Rules.finite(o.get("work_required")) or float(o.work_required) != float(catalog.firearm.craft_seconds):
		return false
	if not Rules.finite(o.get("work_done")) or float(o.work_done) < 0 or float(o.work_done) > float(o.work_required):
		return false
	if not o.get("executor") is String or not o.get("blocked_reason") is String or not Rules.is_vec2(o.get("stand")):
		return false
	if not o.get("priority") is bool or not o.get("output_granted") is bool or not o.get("salvage_paid") is bool:
		return false
	if o.output_granted != (o.phase == "completed") or o.salvage_paid != (o.phase == "cancelled"):
		return false
	if o.phase == "completed" and float(o.work_done) != float(o.work_required):
		return false
	if o.phase == "blocked" and o.blocked_reason.is_empty():
		return false
	return true


static func _bundle(value: Variant, key: String, count: int) -> bool:
	return value is Dictionary and value.size() == 1 and Rules.integer_in(value.get(key), count, count)
