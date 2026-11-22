# Dead End Town: agent TODO

Updated 16 November 2026. Only outstanding work an agent can do alone belongs
here: bug fixes, required improvements and next steps. Playing the three
areas, tuning from that run and deciding the plaza's richer purpose need a
person and are left out on purpose (see the
[playtest checklist](docs/playtest-checklist.md)). Remove a task when it is done;
history is in [PROGRESS](docs/PROGRESS.md). The area model is in
[19](docs/19-areas-and-suburb.md).

Review basis (16 November): `parse_all`, the headless editor import and all
19 `tools/checks/check_*.gd` scripts exit 0. Nothing was looked at or played. Since
the last version of this list, supply caches, away medicine and the battered
home gate were built.

## 1. Required

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

## Analytics: anonymous play stats to Hatchery Signals (from one_more_upgrade, 22 Nov 2026)

one_more_upgrade (commits `57848cc` and `19a5af8`) now sends anonymous play
stats to Hatchery Signals, the WebHatchery analytics portal
(`D:\WebHatchery\apps\game_analytics`, live at
`https://webhatchery.au/game_analytics`). The client lives in the toolkit:
`res://addons/hatchery/telemetry/signals_client.gd` (toolkit commit `acd98a2`;
documented under "telemetry" in `godot_toolkit/GODOT_TOOLKIT.md`; the event
contract is `apps/game_analytics/docs/EVENT_CONTRACT.md`). It sends session
start, a heartbeat per minute of active play, session end, once-per-install
milestones and, for run-based games, `run_started` / `run_ended` reports.
Events go out in batches in the background and never block the game. Reports,
milestones and the session end are kept in `user://` until they are delivered.
Every build (editor, local preview, itch, webhatchery.au) sends to the live
portal and tags its source. Reporting is off headless, with `--no-save` or
`--no-analytics`, and when the player turns off "Share anonymous play stats".
Use the toolkit files; do not copy one_more_upgrade's. For a working example,
read one_more_upgrade's `scripts/presentation/main.gd` (search for
`analytics`), `scripts/presentation/settings_flow.gd`,
`scripts/presentation/run_report.gd`, `tools/analytics_check.gd` and the
Analytics line in its `AGENTS.md`.

- [ ] **Register the game (the user's step).** Intake keys come from the
  portal's game registry, not from the game. Ask the user to register the slug
  `dead_end_town` on the Hatchery Signals dashboard's Games page
  (`https://webhatchery.au/game_analytics/games`, admin login) and to give you
  the key it shows (`hs-` and 48 hex digits). The page also shows the finished
  `data/analytics.json`. Do not make up a key. A batch with an unregistered or
  wrong key gets HTTP 403 and is dropped; the game is not affected. If the key
  is not available yet, do the other steps with
  `"write_key": "unregistered-dead_end_town"` and leave this box unticked.
- [ ] **Config.** Add `data/analytics.json` with the key from the Games page:
  ```json
  {
  	"schema_version": 1,
  	"endpoint": "https://webhatchery.au/game_analytics/api/v1/events",
  	"game": "dead_end_town",
  	"write_key": "<the key from the Games page>"
  }
  ```
  The key ships in the build. It identifies the game and is not a secret.
  Check that each preset's `include_filter` in `export_presets.cfg` takes it
  (`data/*.json` or `*.json` already does).
- [ ] **Mount the client.** Start it in `scripts/presentation/town.gd`'s
  `_ready` (the main scene `scenes/town.tscn`, which lives for the whole
  launch). The pattern:
  ```gdscript
  const SignalsClient = preload("res://addons/hatchery/telemetry/signals_client.gd")
  const SignalsConfig = preload("res://addons/hatchery/telemetry/signals_config.gd")
  var analytics: SignalsClient
  # in _ready, once settings are loaded:
  analytics = SignalsClient.new()
  add_child(analytics)
  analytics.is_playing = func() -> bool: return <in gameplay>
  analytics.start("res://data/analytics.json", SignalsConfig.allowed(),
  		bool(<settings>.value(SignalsClient.SETTING_KEY)), false)  # false: no Steam bridge
  ```
  `is_playing`: true while the town is running and not paused or behind a
  menu. The client counts active time only while the window has focus and
  either `is_playing` is true or the player gave input in the last 45 s. The
  session end is sent automatically on quit.
- [ ] **Opt-out setting.** Settings are
  `scripts/presentation/game_settings.gd` (extends the toolkit's
  `settings_bundle.gd`; sections Sound, Display, Accessibility). Add
  `SignalsClient.SETTING_KEY: true` to the defaults, a toggle labelled
  `SignalsClient.SETTING_LABEL` ("Share anonymous play stats") in the Display
  section (or the nearest equivalent), and on a change call
  `analytics.set_enabled(bool(<settings>.value(SignalsClient.SETTING_KEY)))`.
  one_more_upgrade does this in `settings_flow.gd` (DEFAULTS, WORDS and
  sections) and in `main.gd`'s setting-changed handler.
- [ ] **Milestones.** Call `analytics.milestone_once("<name>")` at the first
  meaningful progression moments. Names are stable snake_case ids, sent once
  per installation, and each must answer a design question ("do players get
  past X?"). Do not report every action. Suggested: `first_gate_opened`,
  `first_yard_cleared`, `first_survivor_rescued`, `first_workshop`,
  `first_survivor_sent`, and `properties_<n>_held` at a few counts (3, 6, 10,
  16).
- [ ] **Run reports.** None: one continuous world, not runs. Skip run reports.
  Call `analytics.game_completed()` when the whole street is held.
- [ ] **Check.** Add `tools/analytics_check.gd` (headless, seconds,
  `extends SceneTree`, prints FAIL lines, exits 1). It must check that
  `SignalsConfig.read("res://data/analytics.json", errors)` gives no errors,
  that every milestone name the game uses is snake_case, and, if the game
  sends run reports, that reports built from scripted play pass
  `ReportRules.problems()` (`addons/hatchery/telemetry/report_rules.gd`) and
  survive `JsonIo.whole_numbers(JsonIo.from_bytes(JsonIo.bytes(...)))` with
  their counts still ints. Copy the optional
  `-- --endpoint=http://127.0.0.1:<port>/events` path from one_more_upgrade's
  check, which sends one real batch to a local server and expects 202. Never
  point it at the live portal. Also run the project's parse check and
  `--headless --editor --path . --quit`.
- [ ] **Docs.** Add an Analytics line to `AGENTS.md`, modelled on
  one_more_upgrade's: the client and where it starts, `data/analytics.json`
  and that its key comes from the portal's Games page, what the reports hold
  (ids, counts and flags only, never free text), when reporting is off, and
  the check command. Add the check to the checks list. Capture the settings
  screen with the new toggle and look at it.

## Rules that still hold

Verification is headless scripts and `Capture.ps1` captures; look at the
image before saying a visual change works. Commit each slice. See
`AGENTS.md`.
