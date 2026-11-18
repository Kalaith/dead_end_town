extends "res://addons/hatchery/settings/settings_bundle.gd"
## Dead End Town's preferences and settings page: sound volumes, full screen, interface size (on top of screen fit)
## and rebindable keys, in one file with the HUD's own preferences (tips, the chosen save slot and slot names).
const KeyBindings = preload("res://addons/hatchery/input/key_bindings.gd")
const SaveSlots = preload("res://scripts/core/save_slots.gd")
## A fraction of 0.25 on the 0.8..1.6 interface size range is 100 %.
const DEFAULTS: Dictionary = {
	"master": 0.8, "effects": 0.9, "ambience": 0.6, "muted": false, "fullscreen": false, "ui_scale": 0.25,
	"tips": true, "slot": 1, "slot_name_1": "", "slot_name_2": "", "slot_name_3": "",
}
## Rebindable actions in the order the Controls tab lists them.
const ACTIONS: Dictionary = {
	"move_up": "Move up", "move_down": "Move down", "move_left": "Move left", "move_right": "Move right",
	"attack": "Swing", "interact": "Interact / carry", "work": "Work / repair",
	"salvage": "Strip timber", "road_guard": "Post road guard", "team": "Team orders", "work_board": "Work board",
	"town_map": "Town map", "order_follow": "Team: follow", "order_hold": "Team: hold",
	"order_engage": "Team: engage", "order_home": "Team: guard home",
}


func _init(scene_tree: SceneTree) -> void:
	super(DEFAULTS, scene_tree, {"Master": "master", "Effects": "effects", "Ambience": "ambience"})
	store.ranges["slot"] = Vector2(1, SaveSlots.COUNT)
	store.keys = KeyBindings.new(ACTIONS)
	# With no preferences file yet (or saving off) the page still needs the project's keys to show and rebind.
	store.key_bindings = store.keys.defaults()
	engine.scale_min = 0.8
	engine.scale_max = 1.6
	sections = [
		{"title": "Sound", "sliders": ["master", "effects", "ambience"], "toggles": ["muted"]},
		{"title": "Display", "sliders": ["ui_scale"], "toggles": ["fullscreen"]},
	]
	words = {"setting_master": "Master volume", "setting_effects": "Effects", "setting_ambience": "Ambience", "setting_muted": "Mute", "setting_fullscreen": "Full screen", "setting_ui_scale": "Interface size"}
	panel_size = Vector2(820, 760)
