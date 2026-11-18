# Dead End Town: agent TODO

Updated 16 November 2026. Only outstanding work an agent can do alone belongs
here: bug fixes, required improvements and next steps. Playing the three
areas, tuning from that run and deciding the plaza's richer purpose need a
person and are left out on purpose (see the
[playtest checklist](docs/playtest-checklist.md)). Remove a task when it is done;
history is in [PROGRESS](docs/PROGRESS.md). The area model is in
[19](docs/19-areas-and-suburb.md).

Review basis (16 November): `parse_all`, the headless editor import and all
19 `tools/check_*.gd` scripts exit 0. Nothing was looked at or played. Since
the last version of this list, supply caches, away medicine and the battered
home gate were built.

## 1. Required

- [ ] **The ending bot only rushes the bosses.** `tools/bot_ending.gd`
  reaches the ending but skips the reclaim objective. Teach it to search,
  claim and connect each area's `objective.reclaim` lots before the boss,
  so blockers in that part of the campaign show up too.

## 2. Known gaps (buildable)

- [ ] **Tips are missing** for the work board (J) and for areas 2 and 3.
- [ ] **Save slots cannot be deleted or named.** Add both, and capture the
  overwrite prompt, which has never been seen (`tools/capture_slots.gd`).

## 3. Missing basics (G09 has not started)

- [ ] **Sound.** No audio code was found. Synthesise with the toolkit:
  gunshot, melee hit, zombie groan by distance, barricade strike, build
  and repair, the van, a tip chime, an area bed.
- [ ] **Settings page**: volume, fullscreen, interface size and key
  bindings with the toolkit's `SettingsStore` and `ui/settings_panel.gd`.
- [ ] **Accessibility**: a colour-safe palette for threat and health,
  captions for the sounds that carry information (noise draws zombies),
  and reduced motion.
- [ ] **Gamepad.** No pad bindings were found; add them with the toolkit's
  `input/pad_bindings.gd` and drive the pause menu and work board by pad.
- [ ] **Credits, icon, wording.** Add a credits page with Godot's licence
  text, set the Windows icon and product details
  (`application/modify_resources=false` today), and drop "work-in-progress
  greybox" from `publish.json` once pilot art lands.
- [ ] **Browser pass.** `.\publish.ps1 -BuildOnly`, serve the web build
  locally, and in Chrome start a run, save to a slot, reload and continue.

## 4. Housekeeping

- [ ] **`tools/checks/` and `tools/scratch/` are empty** while 19 check
  scripts sit flat in `tools/`. Either move the checks into `tools/checks/`
  behind one runner on the toolkit's `testing/check_runner.gd`, or remove
  the empty folder. One command should run them all.

## Screen fit: a real 1920x1080 layout (from spiritwright, 18 Nov 2026)

Spiritwright (commit `4a335a1`) now lays out at 1920x1080 on a 1080p screen
instead of stretching a 1280x720 layout by 1.5x, so bigger screens show more
room, not bigger text. How it works: `project.godot` has a 1920x1080 viewport
with `stretch/mode="canvas_items"` and `stretch/aspect="expand"`, and
`scripts/ui/screen_fit.gd` (started from `main.gd`'s `_ready` with
`ScreenFit.watch(get_tree().root)`) sets `root.content_scale_size` on every
resize. Windows between 1280x720 and 1920x1080 get one layout unit per
pixel. Larger screens are scaled up so the layout stays at least 1920x1080
(4K doubles), and smaller ones are shrunk to a 1280x720 layout. The Interface
size setting (`content_scale_factor`) still multiplies on top. Use the
toolkit's `res://addons/hatchery/settings/screen_fit.gd` (it also handles
high-DPI screens and takes the smallest layout as an argument) rather than
copying spiritwright's file.

- [ ] There is no Interface size setting; add one through the toolkit's
  `settings_bundle.gd` with the settings page (it multiplies on top of
  screen fit).
- [ ] Play the web build in Chrome at a full-screen 1080p window and a
  small one (with the browser pass), and toggle full screen mid-screen once
  the settings page has the control.

## Rules that still hold

Verification is headless scripts and `Capture.ps1` captures; look at the
image before saying a visual change works. Commit each slice. See
`AGENTS.md`.
