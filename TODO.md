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

## 3. Missing basics (G09 has not started)

- [ ] **Listen to the sounds.** Synthesised cues and beds exist
  (`street_audio.gd`, `street_sounds.gd`) but nobody has heard them: a
  person should judge levels and character.
- [ ] **Try a real gamepad.** Bindings and menu focus were driven by
  injected events only; a person with a pad should play a few minutes
  (right-stick aim, trigger to shoot, Start/Back, d-pad orders).
- [ ] **Wording once pilot art lands**: drop "work-in-progress greybox"
  from `publish.json`.
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

- [ ] In Chrome, try a small (un-maximised) window and full screen
  (Settings): the automated pass could only use a maximised 1920x911
  window, which laid out correctly.

## Rules that still hold

Verification is headless scripts and `Capture.ps1` captures; look at the
image before saying a visual change works. Commit each slice. See
`AGENTS.md`.
