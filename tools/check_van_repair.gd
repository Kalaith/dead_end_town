extends SceneTree
## Van repair on the work board: R beside the van approves it, an assigned survivor finishes it, it saves, cancels
## with a refund, and a schema 44 save paid the old way is refunded. Run:
## Godot --headless --path . --script res://tools/check_van_repair.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
const VanRepair = preload("res://scripts/sim/van_repair.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const ConstructionMenu = preload("res://scripts/presentation/construction_menu.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read("office")
	var saves := SaveState.new(data, "user://check_van_repair.json")
	saves.store.enabled = false
	var world := _damaged(data)
	world.working = true
	world.step(0.5)
	world.working = false
	_expect("R beside the van approves a repair for 4 materials", world.materials == 6 and VanRepair.pending(world) and bool(world.vehicle.repair_paid))
	_expect("the repair is on the work board", ConstructionMenu.available(world))
	world.player.pos = Vehicle.pos(world) - Vector2(400, 0)
	var mara: Dictionary = world.survivors[0]
	_expect("Mara can be assigned from the board", Jobs.assign_order(world, VanRepair.SOCKET, str(mara.id)) and mara.order == VanRepair.ORDER)
	var mid: RefCounted = null
	for i: int in range(600):
		world.step(0.1)
		if mid == null and float(world.vehicle.repair_progress) > 2.0:
			mid = saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world))))
		if not VanRepair.pending(world):
			break
	_expect("a save in the middle of the repair loads", mid != null and VanRepair.pending(mid))
	var repaired: float = minf(float(data.vehicle.hull), 50.0 + float(data.vehicle.repair_hull))
	_expect("Mara finishes the repair with no second charge (hull %d)" % int(world.vehicle.hull), float(world.vehicle.hull) == repaired and world.materials == 6 and not bool(world.vehicle.repair_paid))
	world.step(0.1)
	_expect("Mara goes back to what she was doing", mara.order != VanRepair.ORDER)
	var refund := _damaged(data)
	refund.working = true
	refund.step(0.5)
	refund.working = false
	var back: int = refund.materials + int(WorkOrders.refund(WorkOrders.current(refund, VanRepair.SOCKET)).materials)
	var cancelled: bool = VanRepair.cancel(refund, VanRepair.SOCKET)
	_expect("cancelling from the board refunds like any project (%d)" % refund.materials, cancelled and refund.materials == back and back >= 9 and not bool(refund.vehicle.repair_paid))
	var old := _damaged(data)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(old)))
	raw.schema_version = 44
	raw.vehicle.repair_paid = true
	raw.vehicle.repair_progress = 3.0
	raw.materials = 6
	var up: RefCounted = saves.restore(raw)
	_expect("a schema 44 repair paid the old way is refunded", up != null and up.materials == 10 and not bool(up.vehicle.repair_paid) and not VanRepair.pending(up))
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## An office street with nothing hostile, the van at 50 hull and the player beside it with 10 materials.
func _damaged(data: Dictionary) -> RefCounted:
	var world := World.new(data)
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	Vehicle.hit(world, float(data.vehicle.hull) - 50.0)
	world.player.pos = Vehicle.pos(world) + Vector2(0, 40)
	world.materials = 10
	return world


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
