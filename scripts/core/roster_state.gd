extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Roster = preload("res://scripts/sim/roster.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "survivors")
	if not rules.list(data, "survivors", false):
		return
	var ids: Array = rules.unique_ids(data.survivors)
	if ids != ["mara", "paige", "ellis", "june", "oliver", "theo", "nia", "rowan"]:
		errors.append("The roster must contain the eight named survivors.")
	var sites: Array[String] = []
	for d: Variant in data.survivors:
		if not d is Dictionary:
			continue
		rules.text(d, "name")
		rules.text(d, "site")
		rules.vec2(d, "offset")
		if not d.get("intro") is String or (d.id not in ["mara", "paige", "ellis"] and str(d.intro).is_empty()):
			errors.append("Survivors need their implemented introduction text.")
		if not d.get("line") is String or (d.id != "mara" and str(d.line).is_empty()):
			errors.append("Rescues need a discovery line.")
		if d.get("order") not in ["Guard", "Follow", "Hold"] or d.get("duty") not in ["home", "hold"]:
			errors.append("Invalid starting survivor assignment.")
		# A rescue site is a facility kind, shared by every area; an area that has the facility must have it available.
		if d.get("site") == "search":
			continue
		var lot: Dictionary = {}
		for p: Dictionary in data.properties:
			if p.id == Facility.resolve(data, str(d.get("site"))):
				lot = p
		if str(d.get("site")) not in Facility.KINDS or (not lot.is_empty() and not lot.get("available", false)) or str(d.get("site")) in sites:
			errors.append("Each survivor needs a unique implemented rescue site.")
		else:
			sites.append(d.site)
		if d.id == "ellis" and (d.order != "Follow" or d.duty != "hold"):
			errors.append("Ellis starts following and returns to shelter, never guard duty.")
	if sites != ["home", "library", "residence", "clinic", "greenhouse"]:
		errors.append("Preserve the authored home, library, east-house and clinic rescues.")


## People recruited in an earlier area travel with the player, so after travel the team may exceed this area's rescues.
static func _people(data: Dictionary, catalog: Dictionary, expected: Array[String], actual: Array[String]) -> bool:
	if data.get("frozen", {}).is_empty():
		return actual == expected
	var known: Array[String] = []
	for d: Dictionary in catalog.survivors:
		known.append(str(d.id))
	for id: String in expected:
		if id not in actual:
			return false
	for id: String in actual:
		if id not in known:
			return false
	return true


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var expected: Array[String] = []
	for d: Dictionary in catalog.survivors:
		# Search-found survivors may be absent (a lot searched before they existed) or have come from another area.
		var at: String = Roster.lot(catalog, d) if d.site != "search" else ""
		if at == "home" or (not at.is_empty() and data.properties[at].looted):
			expected.append(d.id)
	var actual: Array[String] = []
	var found_by_search: Array[String] = []
	for d: Dictionary in catalog.survivors:
		if d.site == "search":
			found_by_search.append(str(d.id))
	for a: Dictionary in data.survivors:
		if a.id not in found_by_search:
			actual.append(a.id)
	expected.sort()
	actual.sort()
	if not data.get("rescue_intro") is String or not _people(data, catalog, expected, actual):
		return false
	return data.rescue_intro == "" or (data.rescue_intro in ["june", "oliver", "theo", "nia", "rowan"] and data.survivors.any(func(a: Dictionary) -> bool: return a.id == data.rescue_intro))
