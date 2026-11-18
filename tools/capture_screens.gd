extends "res://addons/hatchery/testing/capture_runner.gd"
## Screen-fit tour: every screen (title, each pause tab, settings and its keys, credits, the street,
## the rescue, defeat and ending overlays) at one window size, plus a resize
## mid-screen. Pick the size with --size (Capture.ps1 passes 1920x1080):
##
##     .\tools\Capture.ps1 -Tour res://tools/capture_screens.gd
##
## Other sizes are for looking only; keep the 1920x1080 set.
const CreditsPage = preload("res://addons/hatchery/ui/credits_page.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	await seconds(0.4)
	await shot("screen_title")
	for tab: String in ["Team", "Work", "Loadouts", "Town", "Help"]:
		town.world.clinic.done = true
		town.hud.refresh(town.world, true)
		town.hud.show_section(tab)
		await seconds(0.3)
		await shot("screen_pause_" + tab.to_lower())
	town.hud.open_settings()
	await seconds(0.3)
	await shot("screen_settings")
	town.hud.settings_host.page.tabs.current_tab = 1
	await seconds(0.3)
	await shot("screen_settings_keys")
	town.hud.settings_host.close()
	await seconds(0.2)
	var page: Control = CreditsPage.open(town.hud, town.hud.kit)
	await seconds(0.3)
	await shot("screen_credits")
	page.queue_free()
	town.hud.show_section("Street")
	town.command("resume")
	await seconds(1.0)
	await shot("screen_street")
	for d: Dictionary in town.world.catalog.survivors:
		if not str(d.get("intro", "")).is_empty():
			town.world.rescue_intro = str(d.id)
			break
	await seconds(0.4)
	await shot("screen_rescue")
	town.world.rescue_intro = ""
	town.world.defeat_pending = true
	await seconds(0.4)
	await shot("screen_defeat")
	town.world.defeat_pending = false
	town.command("resume")
	town.command("menu")
	# A resize mid-screen: the menu and pinned controls must follow it.
	var before: Vector2i = root.size
	root.size = Vector2i(1280, 800)
	await seconds(0.4)
	await shot("screen_resized")
	root.size = before
	await seconds(0.3)
	# The ending only closes the last area.
	var works: Dictionary = Catalog.read("industrial")
	town._enter(World.new(works), works)
	town.command("resume")
	town.world.campaign_ended = true
	await seconds(0.4)
	await shot("screen_ending")
