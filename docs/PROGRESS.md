# Dead End Town implementation progress

Entries up to 28 October 2026 are in [progress-2026-10-28.md](progress-2026-10-28.md).

## 29 October 2026: area direction and a layout-neutral map model (step 2)

Direction (user): the campaign becomes bounded areas (suburb, office district, industrial area). The suburb boss is an undead baboon guarding its only exit; areas can be revisited, reason to come later. See `19-areas-and-suburb.md` and F28. The unfinished migration scheduler was committed as-is beforehand.

Implementation (no gameplay change intended):
- `town.json` drops `columns` and `districts`. It now holds `core`, explicit `links`, a pressure `bands` map and `streets` rectangles. Validation no longer requires 12 columns, 18 core sites, 24 lots or the original six; it checks known unique IDs, links against neighbours, one passage/crossing per link, core sites reaching home without optional sites, bands and street shapes.
- Barricade IDs derive from the crossings; the scheduler's band comes from `bands`; camera, ground and streets use `bounds`, and the paused overview fits each lot's rectangle into its panel.

Evidence and limits:
- All 85 scripts load; catalog validates with 0 errors; four deliberate corruptions (extra link, missing link, broken core route, missing barricade) are rejected; headless editor import succeeds.
- Not seen in the running game: street drawing, the camera at the strip ends and the paused overview map need a direct look. Overview lots are now drawn from their rectangles (flatter than before). The local preview still assumes a 580-pixel view. No save schema change yet.
- 29 October 2026: the 28 October restriction on automated simulations and scripted staging is lifted at the user's direction. `AGENTS.md`, the README, the roadmap and TODO no longer forbid them; checks stay proportionate to the change.

## 29 October 2026: area layer (step 3)

- Content is split into shared rules (`data/street/`, `data/zombies.json`) and per-area maps (`data/areas/<id>/`). `data/areas.json` lists areas in campaign order. Each area's `area.json` supplies its id, bounds, start and shelter points and recovery-salvage sites, merged into the catalog. `Catalog.read(area_id)` loads one area; no argument starts the first. The original strip is now the interim `suburb` area, unchanged in content.
- Save schema 36 adds the current `area` and a `frozen` registry for areas the player has left (empty for now). Older saves upgrade to the first area. Loading rejects an area other than the loaded one, an unknown area, or a frozen copy of the current one.
- Added `tools/check_save.gd` (round trip, schema-35 upgrade, bad area records) alongside `check_catalog.gd`. All pass; 87 scripts load; editor import is clean.
- Played the real game: it starts from the moved data, Save writes schema 36 with area `suburb`, and Load reports "Street restored" (`docs/verification/area_layer_save_load.png`).
- Not done: switching areas, carrying people and stock between them, and loading a save for a non-first area (step 8). The suburb grid itself is step 4.

## 29 October 2026: the cul-de-sac suburb (step 4)

- The interim strip is replaced by a 14-lot cul-de-sac in `data/areas/suburb/` (see `19-areas-and-suburb.md`): home at the west dead end, nine original lots with unchanged IDs and positions, four new loot houses and a half-built house with 48 Materials. Columns 7–11 (Civic/Works lots, their passages, crossings and barriers) are removed. Bounds are 5,840 × 1,160; 19 links.
- Pressure has two authored routes, the north-east and south-east alleys at the east end. Route validation is generic (any unique ids, spread follows the nearest map edge). Search rewards are allowed on any available site; passage/crossing counts come from the town links.
- Saves now use `user://suburb.json`. The old `street.json` is never read or touched, so there is no damaged-save error and saving stays on. The schema stays 36.
- Checks: catalog 0 problems (including each route's physical approach to the road), 87 scripts load, `tools/check_save.gd` 6/6, editor import clean. The real game launches and the home end renders as before.
- Not seen: the east end, new houses, half-built house and alley mouths in the running game. A manual walk was impractical (closed gate, residents on every lot). The migration scheduler's route and band logic is untouched beyond validation; its rework onto this layout (step 5) and the baboon and exit (steps 7-8) remain.

## 29 October 2026: ring-road suburb (step 4, redone)

User feedback: the straight cul-de-sac was still one long street. Reference: Sanctuary Hills (`docs/reference/sanctuary_hills_map.webp`). Replaced it with a ring.

- `data/areas/suburb/` now holds 16 lots in four rows (outer north, island north, island south, outer south) around a rectangular ring road with a plaza at the east, 3,360 × 2,180. Files are consolidated to `area`, `town`, `pressure`, `properties`, `roads`, `passages`. Existing lot identities and names are kept; home moved to the north-east corner. 24 links, including four rear gates between the island rows. One pressure route enters from the south-west bridge.
- Engine: fence cutting now handles horizontal (back) fences so passages can join lots back to back; streets draw vertical roads and a plaza; recovery-pile and shelter validators check "open road near home" instead of the old strip's coordinates; search rewards, route ids and link counts are generic.
- Checks: catalog 0 problems (including the bridge route's physical path), 87 scripts load, `check_save.gd` 6/6. In the running game: home in the north-east corner, the ring road corner and east side road render, the island rows sit back to back with a double fence, and centre-line paint stops at the corner.
- Not seen: the plaza's planted centre after a draw-order fix, the bridge end, the west road and the rear gates working (a passage there has never been built in play). Simulated movement into the street was unreliable, so the south and west of the ring were not walked. Rear passage building, link reasons for rear gates and the pressure tuning remain to be checked.

## 29 October 2026: pressure on the ring road (step 5)

- The scheduler needed no engine change: bands already follow held core lots (`town.json` `bands`), routes are the area's authored entrances, and enemy statistics are untouched. The single south-west bridge route is validated for a physical path into the road.
- Added `tools/check_pressure.gd` (headless): home alone is band 0; the first claim schedules an event from the bridge route only; zombies are admitted within ten minutes at the bridge entry and a minute later have moved most of the way up the west road toward the settlement. All pass.
- Not tuned: band budgets and intervals have not been balanced against play on this layout, and only the first event was run. The baboon (step 7) will sit on the road the horde uses.

## 29 October 2026: advisory readiness summary (step 6)

- `scripts/sim/readiness.gd` summarises food (and meal cost), medicine, bullets, barricades standing/damaged and able defenders. The pause menu's Street tab shows it under the stockpile as "READINESS / advisory". Nothing is gated on it.
- Checked: all scripts load, and `tools/check_pressure.gd` asserts the summary content. Not seen: the label's layout in the real pause menu (no capture taken).

## 29 October 2026: the undead baboon and the bridge exit (step 7)

- New kind `baboon` (first pass 700 health, later raised to 1500: speed 70, damage 26, breach 3) in `data/zombies.json`. It reuses the Runner's telegraphed charge generalised to any kind with `lunge_*` data: 1.1 s tell with a drawn lane, a 260-pixel dash at 420 px/s, 1.8 s recovery, 5 s cooldown. Its charge is `uninterruptible`, so ordinary hits cannot cancel it; a collision still ends it. Tells, phases and health are first-pass values and are not balanced against play.
- The suburb's `area.json` gains `boss` (post at the bridge road, leash 320, two shambler escorts) and `exit` (the bridge rectangle at the south-west corner). `scripts/sim/boss.gd` places them, leashes the baboon (a target beyond the leash is ignored and it walks back to its post), and tracks the kill. Death is permanent and opens the exit with a radio note. The pressure entry moved east to (380, 2140) so the exit corner is clear of spawns.
- Save schema 37: the boss and escorts are validated as the area's non-property residents; schema 36 saves are upgraded by adding them at their posts. Position, health and charge phase ride in the existing zombie record.
- Drawing: a large dark-furred baboon with a health bar, a wreck roadblock labelled BLOCKED while it lives and a green arrow labelled EXIT once it is down (`docs/verification/boss_baboon_post.png`, `boss_exit_open.png`).
- Checks: `tools/check_boss.gd` (post and escorts, stays put, tell then dash, leash, round trip, schema 36 upgrade, death opens the exit and survives a save), catalog 0 problems, `check_save.gd` and `check_pressure.gd` pass.
- Not done: the fight itself has not been played, so the baboon's difficulty, whether the leash feels right and whether the horde crossing its post causes odd behaviour are unknown. The roadblock is visual only; nothing is physically blocked. Using the exit is step 8.

## 29 October 2026: area transition (step 8), schema 38

- At the exit with the baboon dead, E asks ("Leave The Suburb? Your team and gear come too, and up to 40 of each stock. Press E again to confirm."); a second press within six seconds travels. With the boss alive the exit says it is blocked; with no later area it says nothing lies beyond yet (the case today).
- `scripts/core/area_travel.gd` builds the destination world: the area left is frozen whole in `frozen` (with the stock that was not carried), the destination is a fresh world or the restored frozen record, and the team, equipment, firearm, health and stock up to `area_carry_cap` (40 in `balance.json`) arrive with the player. People arrive on Follow with duties reset. The same exit works back: the player arrives at the exit they used.
- Items and the firearm unlocked in one area stay unlocked: save schema 38 adds `unlocks`, and the equipment, firearm and roster validators no longer require the first area's property flags once the player has travelled.
- Town: `_travel` loads the destination catalog and swaps world, save state and view, then shows the pause menu titled with the area's name; Load opens the area named in the save first; New street always starts the first area.
- Checks: `tools/check_travel.gd` (blocked while the boss lives, confirmation lapses, second press requests travel, team/gear/capped stock arrive, area frozen with its surplus, destination saves and loads, a clean world goes out and comes back with its state and arrives at the exit). The second area in that check is the suburb relabelled in memory. Catalog, save, pressure and boss checks pass. Real game: the exit prompt reads correctly (`docs/verification/boss_exit_prompt.png`).
- Not seen: the actual move in the running game (there is no second area to move to), the transition menu, and Load of a non-first-area save. Fabricated mid-game states fail validation on purpose, so the round trip check uses a clean world. Several validators and `World` still assume the first area's property ids (home, garden, library, garage...); a second area must reuse them or those need generalising before step 9.

## 29 October 2026: review pass 1 (size limits and docs)

- `PROGRESS.md` (over 760 lines) is split: entries through 28 October moved to `progress-2026-10-28.md`. `properties.json` (986 lines) is split into `properties.json` and `properties_additional.json` (listed in `AREA_FILES`; every area needs both, the second may hold an empty list). All repository files are now under 800 lines (largest `save_state.gd` at 771: split it before adding more).
- The baboon's first-pass design is recorded in `14-zombie-catalogue.md`.
- Found but not yet addressed: the baboon fight has never been played or simulated with a player and team (a bare-handed player is expected to lose); pressure bands and intervals are untuned on the ring layout; the retired slice/watch UI is still in the menu (step 10); the plaza, rear gates and the west/south of the ring have never been walked; and a second area needs the property-id and validator generalisation noted under step 8.
- Review pass 1b, baboon health 700 -> 1500. A scripted fight (player swinging a bat and walking at it, escorts removed, no dodging, scratch script not kept) killed the 700-health baboon in about 6 s with Mara engaging and lost to it alone in 8 s. At 1500 health the player alone still loses (1020 left when they fall) and player plus Mara win in about 13 s with the player at 74 health, because the baboon mostly attacks the nearer person. Still easy for a prepared team; real play, armour, shield and ammunition are untested, so the number is provisional.

## 29 October 2026: retire the slice and watch (step 10)

- The neighbourhood watch is gone: the pause-menu button, the `watch` command, the completion screen and the slice's per-step update (and its call from defeat). `slice_objective.gd` keeps only `readiness` and `next`. The objective line now guides to the baboon once the yards are reclaimed ("Prepared. When you choose, face the baboon at the bridge...") and to the exit once it is down.
- `slice_state` stays in the world and save as an inert record (phase stays "preparing") so schemas and old saves are unchanged; `catalog.slice` data is unused. Removing both is a later clean-up.
- Checked: scripts load, catalog, save, pressure, boss and travel checks pass; the pause menu renders without the button (`docs/verification/street_start.png`). Not checked: the objective text in each state in play.
- Remaining review items: second-area generalisation (step 9 prerequisite), pressure tuning, real play of the baboon fight and an unwalked ring.

## 29 October 2026: review pass 2 (area 2 prerequisite)

- Measured the first area's hard-coded lot ids (about 300 references in about 50 scripts) and wrote up three options in `19-areas-and-suburb.md` ("Prerequisite for area 2"). No code changed: the choice shapes areas 2 and 3 and is the user's to make, so step 9 waits on it.

## 29 October 2026: review pass 3 (ring reachability)

- Added `tools/check_ring.gd`: with the home gate opened, the same waypoint walking the game uses reaches the bridge approach, the exit, the boss post and every lot's site from the start, and the horde's bridge entry reaches its approach point. All pass, which covers the west road and the south of the ring that nobody had walked. Still not walked by a person: the plaza, the rear gates in use, and a real fight at the post.
- Found: walking to a gate point exactly on a lot's front fence line (for example `house_a` at 600,680) from the street stalls, because the waypoint step returns the walker's own position beside the fence. Sites inside lots, which tasks actually use, are fine. Left alone; if survivors report "Route blocked" at those gates, aim their approach at a point just off the fence.

## 29 October 2026: review pass 4 (horde past the baboon)

- Scratch simulation, 15 minutes after the first claim with the player kept alive at home: four waves entered at the bridge and walked past the baboon's post up the west road (6 of 8 living raiders were beyond it at the end); the baboon never left its post (drift 0) and its health was untouched, so raiders and the boss ignore each other as intended. Not kept as a check, since there is nothing to assert beyond "no drift".
- Observation: living raider counts (2-8) are well under each band's budget (5-8 at band 0), so something removes or skips raiders before they arrive (spawn overlap skips, Mara fighting, or both). Worth reading `event.skipped` when tuning pressure.

## 29 October 2026: review pass 5 (spawn overlap thinned every wave)

- Cause of the short waves: raiders entering at the bridge walk east along the spur beside lot house_e, straight into the next spawn slot half a second later, and a slot within 22 pixels of a living zombie is skipped. Waves lost 3-5 of their 5-8 raiders (`last.skipped`).
- Fix: `entry_seconds` 0.5 -> 1.2 in the suburb's `pressure.json`. Over 15 simulated minutes the four waves now admit 5-6 each and skip 0-2 (was 2-3 admitted, 3-5 skipped). `tools/check_pressure.gd` asserts the first event skips nothing.
- Consequence for tuning: the suburb now receives the full authored budget, so it is harder than it was; with the player idle, 21 raiders were alive after 15 minutes. Band numbers were authored for the old layout and have not been balanced against play.
- Still open: why raiders at the bridge head east along a dead-end spur before turning back (a path-target question for `raiding.gd`), and everything that needs real play.

## 29 October 2026: review pass 6 (raiders took the wrong road)

- Cause: `raiding.gd` sends a raider at the nearest lot needing zombies by straight-line distance. From the bridge entry that is the house_e/b/f row directly above the spur, behind a back fence, so raiders walked east along the fence instead of up the west road (which also made the next spawn slot collide, see pass 5).
- Fix: a raider in the migration `inward` phase first walks to its route's `approach` point, then switches to `seeking` and hunts as before. The save validator accepts `seeking` with no destination. No schema change: `inward` raiders in old saves behave the same way.
- Checked in simulation: over 15 minutes every raider passes the baboon's post and enters the settlement (19 of 19 at the end, with an idle player); `tools/check_pressure.gd` asserts none is left on the spur. I did not confirm the new assertion fails on the old code. Waves now also accumulate faster when nobody fights them, so pressure is harder than before; still untuned against real play.

## 29 October 2026: review pass 7 (passages and rear gates)

- Added `tools/check_passages.gd`: for each of the 16 authored passages, with its state set to built, the walk between its two sites is about straight when the gate is open (29 steps for 30 straight; 11 for 12 on the rear gates) and much longer or impossible when shut (150 steps, or stalled). All pass, so the four rear gates between the island rows (house_a/clinic, munitions/greenhouse, garage/No. 12, library/corner house) connect their back-to-back lots.
- This covers geometry only; `tools/check_rear_build.gd` (pass 8) covers the build flow.

## 29 October 2026: review pass 8 (building a rear gate)

- Added `tools/check_rear_build.gd`: with both lots claimed and materials in hand, standing at the library/corner-house rear gate offers the passage, E approves it, holding work finishes the build, and E then opens it. All pass. Not seen in play: the drawn rear gate and its link text.

## 29 October 2026: double the resident zombies

User feedback: the zombies were not a real danger; taking space should feel like a struggle.

- Every lot's starting zombies and reinforcements are doubled (62 -> 124 residents): each new one is a plain Shambler placed in open yard away from buildings, the gate and its neighbours (seeded, so the layout is stable). Runners and Screechers were not doubled, so no extra call or lunge pressure. `hidden_zombies` (the population raiders refill a lot to) is doubled too, so retaken lots stay twice as full.
- `living_cap` 96 -> 200, and the validator's upper bound 100 -> 400, to hold the larger population plus migrants.
- Checked: catalog 0 problems and the save, pressure, boss, travel, ring and passage checks pass; the street is visibly crowded (`docs/verification/street_walk.png`). Not tested: how a real player fares against the doubled yards. Existing saves keep their old residents, since residents are saved; start a new street to see the change.
