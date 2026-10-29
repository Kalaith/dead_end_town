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
- Checked: catalog 0 problems and the save, pressure, boss, travel, ring and passage checks pass; the street is visibly crowded (`docs/verification/street_walk.png`). Not tested: how a real player fares against the doubled yards. (Correction, pass 10: this was wrong, existing saves were rejected as damaged; see below.)

## 29 October 2026: review pass 9 (can the doubled yards be cleared?)

- Scratch simulation (not kept): the player walks at the nearest zombie in the yard and swings, no retreat or gate use, no armour, bat only. Garden (14 zombies): alone the player falls in 3 s with 12 left; with Mara on Engage the yard is cleared in 8 s with the player at 28 health. Library (14): alone dead in 4 s; with Mara dead with 5 left. Residence (6): cleared alone (73 health) and with Mara (100).
- Reading: charging into a 14-zombie yard is lost, while a smaller yard or a team win comfortably. That matches the intent of a struggle, with pulling zombies to the gate, sword/armour and Mara as the real tools. Not checked: a gate-fighting player, a team with armour, or whether the first lots are fun. If the first lots feel hopeless, trim the largest yards (garden, library, garage) before touching the numbers elsewhere.

## 29 October 2026: review pass 10 (saves from before the doubled yards), schema 39

- Mistake found: I had said existing saves would keep their old residents. They would not: the resident list is validated against the catalog, so a schema 38 save from before the doubling failed to load as damaged and blocked saving.
- Fix: schema 39. `resident_state.gd` renumbers each lot's old starting zombies into the first slots of its new numbering (`z%d` ids shifted when each lot doubled), short-term memories are cleared since they are keyed by id, and every missing resident (the new zombies, reinforcements, the boss and escorts) is added from a fresh world at its authored position. Older saves pass through the same step. Old saves now load with the doubled, refilled yards.
- Checked: `tools/check_save.gd` builds a save shaped like the old one (half the residents, old numbering, schema 38) and restores it to the full 124 plus boss; catalog, pressure, boss and travel checks pass. Not tried with a real old save file on disk.
- Follow-up: there is no save file on this machine (`user://` holds no `suburb.json`), so the schema 39 upgrade could only be exercised by the constructed old-style save in `check_save.gd`, not a real one.

## 29 October 2026: facilities as data, slice A

- Decision (user): option 2 for the area-2 prerequisite. Slice A: every lot in `properties*.json` has a `facility` kind; `scripts/sim/facility.gd` looks facilities up by kind (`id`, `has`, `kind_of`, `definition`, `state`, `saved`, an inert record for a missing facility); `town_content.gd` validates that each kind is known and unique and that `home` is the lot with id home. Behaviour is unchanged: nothing reads the field yet. Catalog 0 problems.
- Slice B: all 42 direct `world.properties.<facility>` / `data.properties.<facility>` reads now go through `Facility.state` / `Facility.saved` (23 files). `EquipmentState.valid` takes the catalog. Behaviour in the suburb is unchanged: catalog, save, pressure, boss, travel, ring, passage and rear-build checks all pass. Remaining: string-literal ids in comparisons (C), the roster/equipment/firearm couplings in validators (D), presentation (E).
- Slice C: lot lookups understand facilities. `Facility.resolve` maps a facility kind to the lot that declares it (kinds are reserved words: they never match a lot id, and a lot named after a kind must hold it); `world.definition`, `remaining`, `connected`, `safe_connected`, `player_at_worksite`, `garden_tended`, `Neighbourhood.safe_connected`, the roster (rescue sites are kinds) and job validation all take either a lot id or a kind, and a missing facility reads as unclaimed and unlooted instead of crashing. The ammunition bench step returns early when the area has none.
- New `tools/check_facilities.gd`: for each of the eight non-home facilities it removes that facility from the catalog and runs the sim, every lot's prompt and a save round trip; it also moves the clinic facility to another lot and checks June is recruited there. All pass. This found the firearms step crashing without a bench, now fixed. It is shallow (no survivors assigned to missing facilities), and the suites for the suburb are unchanged and pass.
- Still to do: D) validators that tie survivors, equipment and firearm to the first area's flags beyond what `unlocks` covers, plus remaining literal-id comparisons in `tasks.gd`, `jobs.gd`, `food_growing.gd`, `work_order_state.gd`; E) presentation (`town_view`, `hud`, `town_map`) and an end-to-end second area.

## 29 October 2026: facilities as data finished, and the office district (step 9, first slice)

- Slice D/E in practice: the office district proved the refactor. Loading it found and fixed these first-area assumptions: claim effects tested lot ids (`id == "garage"`, `"residence"`, `"munitions"`, `"library"`), now `Facility.kind_of`; `p.id == <kind>` in the home-world drawing, now `p.facility`; direct `properties[...]` reads for facility kinds in food growing, jobs, restoration, salvage, slice and companion-rescue state; the greenhouse validator required a lot named `greenhouse`; the roster validator required each survivor's rescue lot to exist (rescue sites are now facility kinds, required only where the area has the facility); and the search-reward identity tested lot ids. One slice B miss in `world.gd` is fixed.
- New area `office` (see `19-areas-and-suburb.md`): 12 lots, own ids and names, facilities by kind, one pressure route from the south-east, the Warden boss at the west road with a service-stair exit, and an `entrance` at the south-west corner. Registered after the suburb. `AreaTravel` arrives at the entrance going forward and at the used exit going back; E at an entrance asks, then goes to the previous area. New boss kind `warden`; both boss kinds are marked `boss` and drawn by one generic routine; entrances are drawn.
- Checks: `check_catalog` now validates every registered area (both 0 problems); `check_ring` and `check_passages` run on every area (the walk check now accepts a grid path where its straight-line follower clips a corner); `check_travel` uses the real office; new `tools/check_office.gd` (boots and simulates the office, saves and loads it, real suburb exit -> office entrance -> back -> forward again restoring the frozen office). Screenshots: `office_warden.png`, `office_home_street.png`, `office_entrance.png`.
- Not done: the office has not been played. Pressure bands, the Warden's balance, the ranged and ambush pressure the design asks for (Spitter does not exist), area-specific survivors and the plaza are open. Area 3 (industrial) is not started. The suburb's exit now leads to the office instead of saying nothing lies beyond.

## 29 October 2026: review pass 11 (the office's pressure)

- The office district's pressure was a copy of the suburb's. It now has its own templates: four bands of Screecher- and Runner-heavy waves ("office_call", "lobby_chorus", "floor_ambush", "tower_surge", one with a Brute and two Screechers), and higher special caps (Runner 6, Screecher 4). Kinds the community has learned (`pressure.taught`) now travel with it, so those templates are eligible on arrival.
- Simulated 20 minutes with the kinds taught: waves are the expected compositions with 0-2 skipped spawns. Not tuned against play; the Spitter the design names still does not exist.

## 29-30 October 2026: the industrial works (step 9, second slice)

- New last area `industrial` (see `19-areas-and-suburb.md`): eight lots, five facilities by kind, a south-east pressure route of Brute and Breaker waves, a resident Breaker in the depot so the kind can be taught, the Foreman boss at the west road and a `final` main gate whose closing line ends the campaign, plus a "Service road" entrance back to the office. The office exit now leads here. New zombie kinds `breaker` (420 health, from the catalogue) and `foreman` (3,200 health, boss); Breakers draw heavy.
- Checks: `check_catalog`, `check_ring` and `check_passages` cover all three areas (all pass); `check_travel` expects office -> industrial; new `tools/check_industrial.gd` (boot and simulate, save and load, resident Breaker, Breaker template eligible only when taught, office exit -> works entrance, final gate message). Screenshots `works_entrance.png`, `works_foreman.png`, `works_home_street.png`.
- Not done: the area has not been played; power, vehicles and the 18-vehicle design are not mechanics here; the closing line is a text note, not an ending screen. All three areas are generated from the suburb's street grammar, so they share a layout vocabulary and differ mainly in shape, names, facilities and pressure. Step 9 is otherwise complete; step 11 (play the real game proportionate to each change) is where tuning of all three areas belongs.

## 30 October 2026: area 1 doubled again (schema 40)

User feedback: the suburb was still too easy. Every suburb lot now starts with twice its residents again (124 -> 248): the new Shamblers are appended to each lot's `zombies`, placed by a seeded scatter over walkable yard at least 80 px from the gate and 38 px (26 px late) from any other resident. `living_cap` 200 -> 400 (the validator's maximum). Schema 40: schema 39 saves go through the same renumber-and-refill upgrade as 38. The office and industrial areas are untouched.

- Checked: catalog (all three areas 0 problems), save (new schema 39 case), pressure, boss, travel, ring, passages, rear-build, facilities, office and industrial checks pass. `check_rear_build` now clears the claimed lots' yards first, since the larger yards killed its stationary player.
- Not checked: how the 248-resident street plays or performs in the running game, and whether the largest yards (garden, garage, library, now 28 to 32 residents) can be cleared at all; pass 9 found 14 already lost to a lone player.

## 30 October 2026: survivor retreat, lifting under threat, and the Spitter

- Survivors below 40% health with a zombie within 90 px now fall back (away from it, else to the home respawn) instead of fighting on. Lifting a downed person now needs no zombie within 60 px (was 170 of either party), and the prompt says "Zombie too close to lift <name>" instead of silently stalling.
- New zombie kind `spitter` (85 health, notice 340 px): it stands at 140-340 px with a clear shot, aims 0.9 s at a committed point, and lobs a 240 px/s glob (8 damage) that leaves a 42 px pool lasting 4 s (4 damage per second, one shared one-second cooldown per person so pools never stack). Walls stop globs, low barriers do not; a hit during the aim cancels it with a 3 s retry. Drawn with an aim ring, dashed pool edge and a throat sac.
- Office district: a resident Spitter in the Bank Branch teaches the kind; templates `lobby_spit` and `floor_spit`; special cap 2. New `tools/check_spitter.gd` (11 checks) passes; catalog, save, office, pressure, boss, travel, industrial and passage checks pass.
- Not done: globs and pools are transient (not saved; a load drops any in flight). Armour and a facing shield reduce the direct hit; only armour reduces pool ticks, as designed. Survivor guards do not step aside from pools, and workers do not flee marked areas. None of this has been played, and the retreat/lift changes have only been checked by the existing suites, not a dedicated test.

## 30 October 2026: an ending screen

- Pressing E at the works' final gate now sets `world.campaign_ended` (transient, not saved) and the HUD shows `ending_menu.gd`: the closing line, how many survivors came through, minutes played and times downed. "Keep exploring" resumes; "New street" starts over. All other commands are blocked while it is up, like the defeat panel.
- `check_industrial` now expects the flag instead of a message. Scripts load (110) and the industrial and boss checks pass. The screen itself has not been seen in the running game.

## 30 October 2026: the van (driving slice), schema 41

- Rewrote the head of `18-vehicle.md` to the area model and built a first slice (see its "Current state"). The office has a van parked beside its start; E boards, W/S/A/D drive it, E leaves when stopped. Hull 300, damaged by adjacent zombies (7 x breach) and Spitter globs; a wrecked van ejects the driver. Engine noise draws zombies. New `data/street/vehicle.json`, `scripts/sim/vehicle.gd`, `scripts/core/vehicle_state.gd`; save schema 41 (older saves, including frozen areas, gain an undriven van) and an `engine` attention event.
- `tools/check_vehicle.gd` (15 checks) and `tools/check_rescue_feel.gd` (6 checks) pass, as do the catalog, save, office, pressure, boss, travel, industrial, passage and spitter checks.
- Not done: how it handles in a real window (stopping distance numbers are right on paper, 49 px from top speed), followers do not ride along and cannot keep up, passengers, repair, recovery and any reason to drive beyond speed. The van has not been seen drawn.

## 30 October 2026: scripted boss fights (`tools/sim_boss.gd`)

A kiting bot with the starting bat, alone, against each boss with its escorts removed (not a human, and without followers, armour or firearms). It attacks from about 60 px, backs off inside 52 px and, when "dodging", sidesteps across the lunge lane during the tell and dash.

| Area | Boss | Dodging | Not dodging |
| --- | --- | --- | --- |
| suburb | baboon, 1500 | won in 29 s, no damage | died at 21 s with 270 left |
| office | Warden, 2200 | won in 53 s, 32 health left | died at 17 s with 1210 left |
| industrial | Foreman, 3200 | won in 71 s, 60 health left | died at 17 s with 2180 left |

- All three are beatable with the bat alone if the lunge is read, and punishing if it is not, which is the intended shape. The baboon costs a perfect dodger nothing, so it may be easy for a skilled player; the Warden is the harshest on the bat. Real feel is still a human question.
- Found while writing it: at the baboon's post the straight line from the east side is blocked by a wall, so a player approaching from there cannot hit it and it cannot hit them (the bot picks an open side). Whether the post is meant to be that shielded is not decided.

## 30 October 2026: carry guidance and a casualty roll

- While carrying, the prompt names the nearest clear held property with distance and compass direction (`Carrying Mara · take them to Home (24m NE)`); every valid drop-off is ringed and labelled in the world and the nearest has a dashed guide line. Dropping now says where the person is and how to recover them (home porch E, or the clinic).
- A HUD roll lists up to four hurt or downed survivors, downed first then nearest, with distance and direction (or who is carrying them). Downed and hurt survivors get a pulsing ring labelled DOWN or hurt.
- Parse (115 scripts), `--headless --editor --quit` and `check_rescue_feel` pass. The new prompt, rings, guide line and roll have not been seen in a capture or played.
