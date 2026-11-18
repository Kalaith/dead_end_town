extends HBoxContainer
## The pause menu's second save row: a name for the chosen slot and a Delete that asks for a second press.
const Confirm = preload("res://addons/hatchery/ui/confirm.gd")
const SaveSlots = preload("res://scripts/core/save_slots.gd")
signal named(text: String)
signal delete_confirmed
var name_edit: LineEdit
var delete_button: Button


func build(kit: RefCounted) -> void:
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Name this slot (Enter)"
	name_edit.max_length = SaveSlots.NAME_LENGTH
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(func(text: String) -> void: named.emit(text))
	name_edit.focus_exited.connect(func() -> void: named.emit(name_edit.text))
	add_child(name_edit)
	delete_button = kit.button("Delete slot")
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Confirm.press_twice(delete_button, "Press again to delete it", func() -> void: delete_confirmed.emit())
	add_child(delete_button)


## Shows the chosen slot's name without raising `named`.
func show_name(text: String) -> void:
	if not name_edit.has_focus():
		name_edit.text = text
