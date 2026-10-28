extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const RosterState = preload("res://scripts/core/roster_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func check_authored_rescues_are_once_only_and_keep_original_gifts_and_duties() -> String:
	var w := World.new(Catalog.read())
	if Roster.recruit(w, "paige") or Roster.recruit(w, "ellis") or Roster.recruit(w, "unknown"):
		return "A rescue appeared before its discovery."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "residence"]:
		w.claim(id)
	w.firearms.bullets = 2
	Firearms.rescue(w)
	if Roster.recruit(w, "paige") or w.survivors.size() != 3 or w.firearms.bullets != 2:
		return "Repeated rescue duplicated a person or replaced ammunition."
	if Roster.person(w, "paige").order != "Follow" or Roster.person(w, "ellis").duty.role != "hold":
		return "Original rescue orders changed."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	return "Authored roster failed JSON reload" if loaded == null or loaded.survivors.size() != 3 else ""


func check_roster_rejects_unknown_duplicate_and_unsearched_people_on_load() -> String:
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var data: Dictionary = save.snapshot(w)
	var a: Dictionary = data.survivors[0].duplicate(true)
	a.id = "unrescued"
	data.survivors.append(a)
	if save.valid(data):
		return "Save accepted an unauthorised roster member."
	data.survivors[1].id = "mara"
	if save.valid(data):
		return "Save accepted a duplicate roster member."
	var c: Dictionary = w.catalog.duplicate(true)
	c.survivors[2].duty = "home"
	var errors: Array[String] = []
	RosterState.content(c, errors)
	return "Civilian starting duty was not validated" if errors.is_empty() else ""
