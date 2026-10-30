extends RefCounted
## Three save slots. Slot 1 keeps the original file name so existing saves stay where they were.
const COUNT: int = 3


static func path(slot: int) -> String:
	return "user://suburb.json" if slot == 1 else "user://street_%d.json" % slot


static func next(slot: int) -> int:
	return slot % COUNT + 1


## One line for the button: which area the slot holds and how long it has been played, or that it is empty.
static func summary(slot: int, file: String = "") -> String:
	var where: String = file if not file.is_empty() else path(slot)
	if not FileAccess.file_exists(where):
		return "Slot %d · empty" % slot
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(where))
	if not raw is Dictionary or not raw.get("area") is String:
		return "Slot %d · unreadable" % slot
	var seconds: float = float(raw.get("elapsed", 0.0))
	if raw.get("frozen") is Dictionary:
		for record: Variant in raw.frozen.values():
			if record is Dictionary:
				seconds += float(record.get("elapsed", 0.0))
	return "Slot %d · %s %dm" % [slot, raw.area, int(seconds / 60.0)]
