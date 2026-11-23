# Dead End Town project guidance

Read `README.md`, `docs/01-game-design.md`, `docs/11-decisions-and-questions.md` and `docs/PROGRESS.md` before implementation.

- A continuous top-down street, cooperative named survivors, physical home defence, connected property reclamation and equipment-led growth are the foundations. Avoid relationship drama, XP grind or colony micromanagement.
- The Last Hearth supplies the project-layout template only. Its BDI, recruitment and turn-based combat rules do not apply to this game.
- Godot 4.7.2, Compatibility renderer, desktop keyboard/mouse first. Laid out at 1920x1080 with screen fit (`addons/hatchery/settings/screen_fit.gd`): 1280x720 to 1920x1080 windows get one layout unit per pixel; place HUD controls by anchors, never by a 1280 edge. Current art is original procedural greybox drawing.
- `scripts/sim/` owns authoritative state and fixed-step rules without scene-tree dependencies. `scripts/presentation/` reads state and issues commands. `scripts/core/` owns content validation and save mapping. Balance and map content live in `data/street/*.json` (zombie kinds in `data/zombies.json`).
- Use `../godot_toolkit` through the ignored `addons/hatchery` junction. Recreate it with `../godot_toolkit/tools/Link-Toolkit.ps1 -ProjectDir .`. Do not edit shared toolkit code as a side effect.
- Verification commands: `.\tools\Check.ps1` runs everything (parse, editor import, every `tools/checks/check_*.gd`; `-Only save,travel` for a subset, `-Bot` adds the scripted run to the ending). Singly: `--headless --path . --script res://tools/parse_all.gd`, `--headless --editor --path . --quit`, `--headless --path . --script res://tools/checks/check_<topic>.gd`. Use the installed console executable in `C:/Program Files/Godot/`.
- Authoritative game rules under `scripts/sim/` are runtime gameplay and must remain.
- Analytics: the toolkit's `telemetry/signals_client.gd` (see `GODOT_TOOLKIT.md`), started in `scripts/presentation/town.gd`'s `_ready`, sends anonymous play stats to Hatchery Signals (`apps/game_analytics`, live at `https://webhatchery.au/game_analytics`, the same endpoint for every build; the source is tagged per build). Config and the build's intake key are in `data/analytics.json`; the key is the one registered for `dead_end_town` on the portal's Games page (`https://webhatchery.au/game_analytics/games`); rotating it there means rebuilding with the new key. One continuous world, so no run reports: only once-per-install milestones read from the world (`scripts/presentation/street_milestones.gd`) and `game_completed` when the campaign ends in play. Nothing sent holds free text. It is off headless, under any tools/ script, with `--no-save`/`--no-analytics` (Capture.ps1 passes `--no-save`), and when the player switches off "Share anonymous play stats" (Settings, Display). `tools/analytics_check.gd` checks the config and milestones (seconds; `-- --endpoint=http://127.0.0.1:<port>/events` also sends a batch to a local server and expects 202; never point it at the live portal).
- Test headless by default. Features, rules, saves and data are verified with `--headless` scripts and scenarios through `scripts/sim/` (nothing opens, nothing touches the user's input). `--headless` has a dummy renderer and cannot produce screenshots.
- Screenshots come from `tools/Capture.ps1`: a rendering Godot with the window placed off-screen, input fed to the game as engine events (`Input.action_press`, `parse_input_event`), frames saved by `tools/capture.gd` (toolkit `capture_runner.gd`) to `docs/verification/`. Add tours as `tools/capture_<topic>.gd` and pass `-Tour`. Look at the image before saying a visual change works.
- Never use `Run.ps1` or `tools/capture_window.ps1` unless the user asks to watch the real window: they take focus and inject OS-level mouse/keyboard input into the user's session. Keep checks proportionate: a text-only or data-only change needs script loading (and `tools/checks/check_catalog.gd` for data), not a capture.
- Verification tools live in `tools/` and are committed (`parse_all.gd`, `tools/checks/check_catalog.gd`, `capture.gd`, `Capture.ps1`, `capture_window.ps1`). Do not leave throwaway scripts in a scratchpad. Save captures worth keeping in `docs/verification/`; delete the rest.
- `docs/PROGRESS.md` records implementation and evidence separately. The design documents describe intended scope, not completed features.
- No pushing or publication without a user request. Web and Windows publishing is configured for `/public_html/games/dead_end_town/` on webhatchery.au; credentials stay in the external environment file.

## Shared WebHatchery Godot standards

Identical in every WebHatchery Godot project's AGENTS.md; change all together. Project-specific rules go above.

### Working

- Stay inside this project unless the user broadens the task; preserve user changes; never overwrite original art.
- No installing/upgrading Godot, export templates, tools, plugins or GDExtensions without approval; prefer built-in features.

### Code

- Godot **4.7.2** GDScript, statically typed everywhere (variables, parameters, returns). `const X = preload("res://...")`. Tabs, LF, UTF-8, final newline.
- Simulation/rules code never touches the scene tree, `Time`, `OS` or global `randi()`/`randf()`; randomness comes from an owned `RandomNumberGenerator` (same seed, same result). Presentation reads state and sends commands, nothing else.
- Balance and catalogs (upgrades, parts, miracles, blocks, ...) live in JSON under `data/` with stable ids (and `schema_version` where present), validated at startup, holding only implemented effects. Missing or mistyped data fails fast and is reported; never default silently in code.
- Persistent state lives under `user://` with schema validation, staged writes and backup recovery. A failed save never loses progress or spends anything.

### Verification

- No `tests/` directory, frameworks or addons. Any automated checks are headless scripts in `tools/`, kept out of the export.
- Checks don't gate commits. At a major feature or milestone, run all checks (plus `--headless --editor --quit`) and fix findings.
- Headless checks can't verify visuals, audio, input or feel: run the game and look. State plainly what was and wasn't checked.

### Verification images

- Only `docs/verification/` (flat; keep its `.gdignore` and `docs/`'s). Reference art: `docs/reference/` or `docs/art/`.
- Capture via the toolkit's `testing/capture_runner.gd` or `testing/capture_paths.gd` (`CapturePaths.file(label)`); never pass an output directory or write elsewhere (`builds/`, `exports/`, OS temp, `user://`).
- Stable names `<label>.png`: no subfolders, timestamps, run/revision/size suffixes, `-final`/`-fix` variants or backups. Recapturing a screen or state overwrites; new labels only for genuinely new ones.
- One window size and UI scale per game. Look at the image before saying a visual change works.

### Size limits (hard rule)

- **Functions ≤ 400 lines; files ≤ 800 lines** (scripts, scenes, data, docs, catalogs). Check: `git ls-files -co --exclude-standard | grep -E '\.(gd|tscn|json|md)$' | xargs wc -l | sort -n | tail`.
- Split scripts by responsibility before they grow. A change that would cross a limit, or touches something already over, brings it under in the same change: split functions into named helpers; move a cohesive responsibility (HUD, settings wiring, area building, save validation, layout, a catalog section, ...) into its own file the original delegates to or loads. Keep public members other scripts use working.
- **Never shrink by deleting blank lines, joining statements, removing comments, minifying or packing entries onto one line.** Move content; don't squeeze it.

### Commits

- **ALWAYS commit each feature slice and bug fix the moment it works. Mandatory.** One slice per commit; never batch, never leave finished work uncommitted, never end a turn with an uncommitted feature or fix. Don't wait to be asked or offer instead of doing it; a later request ("also tweak X") is a new slice.
- Commit **all pending changes**, including modified, added and deleted files you didn't make: review and preserve them, include them in validation, finish with a clean tree.
- **Before the final reply of any turn that touched files:** run `git status --short`; if it prints anything, commit and rerun until empty. A dirty tree means unfinished; the closing summary says the tree is clean.
- Ignore rules still apply; never force-add ignored files or commit secrets. Don't push or publish unless asked.

Message: one present-tense line, no trailing period, under ~100 characters before the tag, saying what changed **as the player feels it** (for the toolkit, as the games using it feel it), then a plain lowercase tag in parentheses for what it technically is (the system touched, `docs`, `refactor` for structural changes, or a milestone id such as `M25`). Fixes and refactors are still described by effect. Add a body only when the reason isn't obvious.

```
The Lantern Fair opens: be more interesting than the fair (third map)
A prayer at the tree now feeds the god's Favour (shrine favour)
Builders no longer wall themselves into the cottage they are raising (site reservation fix)
No script over 800 lines: split main and the ritual screen (refactor)
Every game's saves now survive a torn write (json save)
Scribes set down the covenant: design and building plan (docs)
```
