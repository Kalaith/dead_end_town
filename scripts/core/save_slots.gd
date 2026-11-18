extends RefCounted
## Three save slots. Slot 1 keeps the original file name so existing saves stay where they were. A slot's name is a
## player preference kept beside the other preferences, not in the save.
const AtomicFile = preload("res://addons/hatchery/storage/atomic_file.gd")
const COUNT: int = 3
const NAME_LENGTH: int = 24
## Where the slot files live. Capture tours point it at a folder of their own so they never touch real saves.
static var root: String = "user://"


static func path(slot: int) -> String:
	return root + ("suburb.json" if slot == 1 else "street_%d.json" % slot)


## The preference key holding a slot's name.
static func name_key(slot: int) -> String:
	return "slot_name_%d" % slot


## A name as the player typed it, trimmed and cut to a button's width.
static func clean_name(text: String) -> String:
	return text.strip_edges().substr(0, NAME_LENGTH)


## Removes a slot's save with its backup and any kept or damaged copies. True when anything was removed.
static func remove(slot: int) -> bool:
	var removed: bool = false
	for suffix: String in ["", AtomicFile.BAK, AtomicFile.TMP, AtomicFile.CORRUPT, AtomicFile.PREVIOUS]:
		var file: String = path(slot) + suffix
		if FileAccess.file_exists(file) and DirAccess.remove_absolute(ProjectSettings.globalize_path(file)) == OK:
			removed = true
	return removed


static func next(slot: int) -> int:
	return slot % COUNT + 1


## One line for the button: which area the slot holds and how long it has been played, or that it is empty.
static func summary(slot: int, file: String = "", label: String = "") -> String:
	var where: String = file if not file.is_empty() else path(slot)
	var title: String = "Slot %d" % slot + ((" · " + label) if not label.is_empty() else "")
	if not FileAccess.file_exists(where):
		return title + " · empty"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(where))
	if not raw is Dictionary or not raw.get("area") is String:
		return title + " · unreadable"
	return "%s · %s %dm" % [title, raw.area, int(seconds(where) / 60.0)]


## Seconds played in the run a file holds across every area; 0 when it is missing or unreadable.
static func seconds(file: String) -> float:
	if not FileAccess.file_exists(file):
		return 0.0
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not raw is Dictionary:
		return 0.0
	var total: float = float(raw.get("elapsed", 0.0))
	if raw.get("frozen") is Dictionary:
		for record: Variant in raw.frozen.values():
			if record is Dictionary:
				total += float(record.get("elapsed", 0.0))
	return total
