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
- Added `tools/checks/check_save.gd` (round trip, schema-35 upgrade, bad area records) alongside `tools/checks/check_catalog.gd`. All pass; 87 scripts load; editor import is clean.
- Played the real game: it starts from the moved data, Save writes schema 36 with area `suburb`, and Load reports "Street restored" (`docs/verification/area_layer_save_load.png`).
- Not done: switching areas, carrying people and stock between them, and loading a save for a non-first area (step 8). The suburb grid itself is step 4.

## 29 October 2026: the cul-de-sac suburb (step 4)

- The interim strip is replaced by a 14-lot cul-de-sac in `data/areas/suburb/` (see `19-areas-and-suburb.md`): home at the west dead end, nine original lots with unchanged IDs and positions, four new loot houses and a half-built house with 48 Materials. Columns 7–11 (Civic/Works lots, their passages, crossings and barriers) are removed. Bounds are 5,840 × 1,160; 19 links.
- Pressure has two authored routes, the north-east and south-east alleys at the east end. Route validation is generic (any unique ids, spread follows the nearest map edge). Search rewards are allowed on any available site; passage/crossing counts come from the town links.
- Saves now use `user://suburb.json`. The old `street.json` is never read or touched, so there is no damaged-save error and saving stays on. The schema stays 36.
- Checks: catalog 0 problems (including each route's physical approach to the road), 87 scripts load, `tools/checks/check_save.gd` 6/6, editor import clean. The real game launches and the home end renders as before.
- Not seen: the east end, new houses, half-built house and alley mouths in the running game. A manual walk was impractical (closed gate, residents on every lot). The migration scheduler's route and band logic is untouched beyond validation; its rework onto this layout (step 5) and the baboon and exit (steps 7-8) remain.

## 29 October 2026: ring-road suburb (step 4, redone)

User feedback: the straight cul-de-sac was still one long street. Reference: Sanctuary Hills (`docs/reference/sanctuary_hills_map.webp`). Replaced it with a ring.

- `data/areas/suburb/` now holds 16 lots in four rows (outer north, island north, island south, outer south) around a rectangular ring road with a plaza at the east, 3,360 × 2,180. Files are consolidated to `area`, `town`, `pressure`, `properties`, `roads`, `passages`. Existing lot identities and names are kept; home moved to the north-east corner. 24 links, including four rear gates between the island rows. One pressure route enters from the south-west bridge.
- Engine: fence cutting now handles horizontal (back) fences so passages can join lots back to back; streets draw vertical roads and a plaza; recovery-pile and shelter validators check "open road near home" instead of the old strip's coordinates; search rewards, route ids and link counts are generic.
- Checks: catalog 0 problems (including the bridge route's physical path), 87 scripts load, `tools/checks/check_save.gd` 6/6. In the running game: home in the north-east corner, the ring road corner and east side road render, the island rows sit back to back with a double fence, and centre-line paint stops at the corner.
- Not seen: the plaza's planted centre after a draw-order fix, the bridge end, the west road and the rear gates working (a passage there has never been built in play). Simulated movement into the street was unreliable, so the south and west of the ring were not walked. Rear passage building, link reasons for rear gates and the pressure tuning remain to be checked.

## 29 October 2026: pressure on the ring road (step 5)

- The scheduler needed no engine change: bands already follow held core lots (`town.json` `bands`), routes are the area's authored entrances, and enemy statistics are untouched. The single south-west bridge route is validated for a physical path into the road.
- Added `tools/checks/check_pressure.gd` (headless): home alone is band 0; the first claim schedules an event from the bridge route only; zombies are admitted within ten minutes at the bridge entry and a minute later have moved most of the way up the west road toward the settlement. All pass.
- Not tuned: band budgets and intervals have not been balanced against play on this layout, and only the first event was run. The baboon (step 7) will sit on the road the horde uses.

## 29 October 2026: advisory readiness summary (step 6)

- `scripts/sim/readiness.gd` summarises food (and meal cost), medicine, bullets, barricades standing/damaged and able defenders. The pause menu's Street tab shows it under the stockpile as "READINESS / advisory". Nothing is gated on it.
- Checked: all scripts load, and `tools/checks/check_pressure.gd` asserts the summary content. Not seen: the label's layout in the real pause menu (no capture taken).

## 29 October 2026: the undead baboon and the bridge exit (step 7)

- New kind `baboon` (first pass 700 health, later raised to 1500: speed 70, damage 26, breach 3) in `data/zombies.json`. It reuses the Runner's telegraphed charge generalised to any kind with `lunge_*` data: 1.1 s tell with a drawn lane, a 260-pixel dash at 420 px/s, 1.8 s recovery, 5 s cooldown. Its charge is `uninterruptible`, so ordinary hits cannot cancel it; a collision still ends it. Tells, phases and health are first-pass values and are not balanced against play.
- The suburb's `area.json` gains `boss` (post at the bridge road, leash 320, two shambler escorts) and `exit` (the bridge rectangle at the south-west corner). `scripts/sim/boss.gd` places them, leashes the baboon (a target beyond the leash is ignored and it walks back to its post), and tracks the kill. Death is permanent and opens the exit with a radio note. The pressure entry moved east to (380, 2140) so the exit corner is clear of spawns.
- Save schema 37: the boss and escorts are validated as the area's non-property residents; schema 36 saves are upgraded by adding them at their posts. Position, health and charge phase ride in the existing zombie record.
- Drawing: a large dark-furred baboon with a health bar, a wreck roadblock labelled BLOCKED while it lives and a green arrow labelled EXIT once it is down (`docs/verification/boss_baboon_post.png`, `boss_exit_open.png`).
- Checks: `tools/checks/check_boss.gd` (post and escorts, stays put, tell then dash, leash, round trip, schema 36 upgrade, death opens the exit and survives a save), catalog 0 problems, `tools/checks/check_save.gd` and `tools/checks/check_pressure.gd` pass.
- Not done: the fight itself has not been played, so the baboon's difficulty, whether the leash feels right and whether the horde crossing its post causes odd behaviour are unknown. The roadblock is visual only; nothing is physically blocked. Using the exit is step 8.

## 29 October 2026: area transition (step 8), schema 38

- At the exit with the baboon dead, E asks ("Leave The Suburb? Your team and gear come too, and up to 40 of each stock. Press E again to confirm."); a second press within six seconds travels. With the boss alive the exit says it is blocked; with no later area it says nothing lies beyond yet (the case today).
- `scripts/core/area_travel.gd` builds the destination world: the area left is frozen whole in `frozen` (with the stock that was not carried), the destination is a fresh world or the restored frozen record, and the team, equipment, firearm, health and stock up to `area_carry_cap` (40 in `balance.json`) arrive with the player. People arrive on Follow with duties reset. The same exit works back: the player arrives at the exit they used.
- Items and the firearm unlocked in one area stay unlocked: save schema 38 adds `unlocks`, and the equipment, firearm and roster validators no longer require the first area's property flags once the player has travelled.
- Town: `_travel` loads the destination catalog and swaps world, save state and view, then shows the pause menu titled with the area's name; Load opens the area named in the save first; New street always starts the first area.
- Checks: `tools/checks/check_travel.gd` (blocked while the boss lives, confirmation lapses, second press requests travel, team/gear/capped stock arrive, area frozen with its surplus, destination saves and loads, a clean world goes out and comes back with its state and arrives at the exit). The second area in that check is the suburb relabelled in memory. Catalog, save, pressure and boss checks pass. Real game: the exit prompt reads correctly (`docs/verification/boss_exit_prompt.png`).
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

- Added `tools/checks/check_ring.gd`: with the home gate opened, the same waypoint walking the game uses reaches the bridge approach, the exit, the boss post and every lot's site from the start, and the horde's bridge entry reaches its approach point. All pass, which covers the west road and the south of the ring that nobody had walked. Still not walked by a person: the plaza, the rear gates in use, and a real fight at the post.
- Found: walking to a gate point exactly on a lot's front fence line (for example `house_a` at 600,680) from the street stalls, because the waypoint step returns the walker's own position beside the fence. Sites inside lots, which tasks actually use, are fine. Left alone; if survivors report "Route blocked" at those gates, aim their approach at a point just off the fence.

## 29 October 2026: review pass 4 (horde past the baboon)

- Scratch simulation, 15 minutes after the first claim with the player kept alive at home: four waves entered at the bridge and walked past the baboon's post up the west road (6 of 8 living raiders were beyond it at the end); the baboon never left its post (drift 0) and its health was untouched, so raiders and the boss ignore each other as intended. Not kept as a check, since there is nothing to assert beyond "no drift".
- Observation: living raider counts (2-8) are well under each band's budget (5-8 at band 0), so something removes or skips raiders before they arrive (spawn overlap skips, Mara fighting, or both). Worth reading `event.skipped` when tuning pressure.

## 29 October 2026: review pass 5 (spawn overlap thinned every wave)

- Cause of the short waves: raiders entering at the bridge walk east along the spur beside lot house_e, straight into the next spawn slot half a second later, and a slot within 22 pixels of a living zombie is skipped. Waves lost 3-5 of their 5-8 raiders (`last.skipped`).
- Fix: `entry_seconds` 0.5 -> 1.2 in the suburb's `pressure.json`. Over 15 simulated minutes the four waves now admit 5-6 each and skip 0-2 (was 2-3 admitted, 3-5 skipped). `tools/checks/check_pressure.gd` asserts the first event skips nothing.
- Consequence for tuning: the suburb now receives the full authored budget, so it is harder than it was; with the player idle, 21 raiders were alive after 15 minutes. Band numbers were authored for the old layout and have not been balanced against play.
- Still open: why raiders at the bridge head east along a dead-end spur before turning back (a path-target question for `raiding.gd`), and everything that needs real play.

## 29 October 2026: review pass 6 (raiders took the wrong road)

- Cause: `raiding.gd` sends a raider at the nearest lot needing zombies by straight-line distance. From the bridge entry that is the house_e/b/f row directly above the spur, behind a back fence, so raiders walked east along the fence instead of up the west road (which also made the next spawn slot collide, see pass 5).
- Fix: a raider in the migration `inward` phase first walks to its route's `approach` point, then switches to `seeking` and hunts as before. The save validator accepts `seeking` with no destination. No schema change: `inward` raiders in old saves behave the same way.
- Checked in simulation: over 15 minutes every raider passes the baboon's post and enters the settlement (19 of 19 at the end, with an idle player); `tools/checks/check_pressure.gd` asserts none is left on the spur. I did not confirm the new assertion fails on the old code. Waves now also accumulate faster when nobody fights them, so pressure is harder than before; still untuned against real play.

## 29 October 2026: review pass 7 (passages and rear gates)

- Added `tools/checks/check_passages.gd`: for each of the 16 authored passages, with its state set to built, the walk between its two sites is about straight when the gate is open (29 steps for 30 straight; 11 for 12 on the rear gates) and much longer or impossible when shut (150 steps, or stalled). All pass, so the four rear gates between the island rows (house_a/clinic, munitions/greenhouse, garage/No. 12, library/corner house) connect their back-to-back lots.
- This covers geometry only; `tools/checks/check_rear_build.gd` (pass 8) covers the build flow.

## 29 October 2026: review pass 8 (building a rear gate)

- Added `tools/checks/check_rear_build.gd`: with both lots claimed and materials in hand, standing at the library/corner-house rear gate offers the passage, E approves it, holding work finishes the build, and E then opens it. All pass. Not seen in play: the drawn rear gate and its link text.

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
- Checked: `tools/checks/check_save.gd` builds a save shaped like the old one (half the residents, old numbering, schema 38) and restores it to the full 124 plus boss; catalog, pressure, boss and travel checks pass. Not tried with a real old save file on disk.
- Follow-up: there is no save file on this machine (`user://` holds no `suburb.json`), so the schema 39 upgrade could only be exercised by the constructed old-style save in `tools/checks/check_save.gd`, not a real one.

## 29 October 2026: facilities as data, slice A

- Decision (user): option 2 for the area-2 prerequisite. Slice A: every lot in `properties*.json` has a `facility` kind; `scripts/sim/facility.gd` looks facilities up by kind (`id`, `has`, `kind_of`, `definition`, `state`, `saved`, an inert record for a missing facility); `town_content.gd` validates that each kind is known and unique and that `home` is the lot with id home. Behaviour is unchanged: nothing reads the field yet. Catalog 0 problems.
- Slice B: all 42 direct `world.properties.<facility>` / `data.properties.<facility>` reads now go through `Facility.state` / `Facility.saved` (23 files). `EquipmentState.valid` takes the catalog. Behaviour in the suburb is unchanged: catalog, save, pressure, boss, travel, ring, passage and rear-build checks all pass. Remaining: string-literal ids in comparisons (C), the roster/equipment/firearm couplings in validators (D), presentation (E).
- Slice C: lot lookups understand facilities. `Facility.resolve` maps a facility kind to the lot that declares it (kinds are reserved words: they never match a lot id, and a lot named after a kind must hold it); `world.definition`, `remaining`, `connected`, `safe_connected`, `player_at_worksite`, `garden_tended`, `Neighbourhood.safe_connected`, the roster (rescue sites are kinds) and job validation all take either a lot id or a kind, and a missing facility reads as unclaimed and unlooted instead of crashing. The ammunition bench step returns early when the area has none.
- New `tools/checks/check_facilities.gd`: for each of the eight non-home facilities it removes that facility from the catalog and runs the sim, every lot's prompt and a save round trip; it also moves the clinic facility to another lot and checks June is recruited there. All pass. This found the firearms step crashing without a bench, now fixed. It is shallow (no survivors assigned to missing facilities), and the suites for the suburb are unchanged and pass.
- Still to do: D) validators that tie survivors, equipment and firearm to the first area's flags beyond what `unlocks` covers, plus remaining literal-id comparisons in `tasks.gd`, `jobs.gd`, `food_growing.gd`, `work_order_state.gd`; E) presentation (`town_view`, `hud`, `town_map`) and an end-to-end second area.

## 29 October 2026: facilities as data finished, and the office district (step 9, first slice)

- Slice D/E in practice: the office district proved the refactor. Loading it found and fixed these first-area assumptions: claim effects tested lot ids (`id == "garage"`, `"residence"`, `"munitions"`, `"library"`), now `Facility.kind_of`; `p.id == <kind>` in the home-world drawing, now `p.facility`; direct `properties[...]` reads for facility kinds in food growing, jobs, restoration, salvage, slice and companion-rescue state; the greenhouse validator required a lot named `greenhouse`; the roster validator required each survivor's rescue lot to exist (rescue sites are now facility kinds, required only where the area has the facility); and the search-reward identity tested lot ids. One slice B miss in `world.gd` is fixed.
- New area `office` (see `19-areas-and-suburb.md`): 12 lots, own ids and names, facilities by kind, one pressure route from the south-east, the Warden boss at the west road with a service-stair exit, and an `entrance` at the south-west corner. Registered after the suburb. `AreaTravel` arrives at the entrance going forward and at the used exit going back; E at an entrance asks, then goes to the previous area. New boss kind `warden`; both boss kinds are marked `boss` and drawn by one generic routine; entrances are drawn.
- Checks: `check_catalog` now validates every registered area (both 0 problems); `check_ring` and `check_passages` run on every area (the walk check now accepts a grid path where its straight-line follower clips a corner); `check_travel` uses the real office; new `tools/checks/check_office.gd` (boots and simulates the office, saves and loads it, real suburb exit -> office entrance -> back -> forward again restoring the frozen office). Screenshots: `office_warden.png`, `office_home_street.png`, `office_entrance.png`.
- Not done: the office has not been played. Pressure bands, the Warden's balance, the ranged and ambush pressure the design asks for (Spitter does not exist), area-specific survivors and the plaza are open. Area 3 (industrial) is not started. The suburb's exit now leads to the office instead of saying nothing lies beyond.

## 29 October 2026: review pass 11 (the office's pressure)

- The office district's pressure was a copy of the suburb's. It now has its own templates: four bands of Screecher- and Runner-heavy waves ("office_call", "lobby_chorus", "floor_ambush", "tower_surge", one with a Brute and two Screechers), and higher special caps (Runner 6, Screecher 4). Kinds the community has learned (`pressure.taught`) now travel with it, so those templates are eligible on arrival.
- Simulated 20 minutes with the kinds taught: waves are the expected compositions with 0-2 skipped spawns. Not tuned against play; the Spitter the design names still does not exist.

## 29-30 October 2026: the industrial works (step 9, second slice)

- New last area `industrial` (see `19-areas-and-suburb.md`): eight lots, five facilities by kind, a south-east pressure route of Brute and Breaker waves, a resident Breaker in the depot so the kind can be taught, the Foreman boss at the west road and a `final` main gate whose closing line ends the campaign, plus a "Service road" entrance back to the office. The office exit now leads here. New zombie kinds `breaker` (420 health, from the catalogue) and `foreman` (3,200 health, boss); Breakers draw heavy.
- Checks: `check_catalog`, `check_ring` and `check_passages` cover all three areas (all pass); `check_travel` expects office -> industrial; new `tools/checks/check_industrial.gd` (boot and simulate, save and load, resident Breaker, Breaker template eligible only when taught, office exit -> works entrance, final gate message). Screenshots `works_entrance.png`, `works_foreman.png`, `works_home_street.png`.
- Not done: the area has not been played; power, vehicles and the 18-vehicle design are not mechanics here; the closing line is a text note, not an ending screen. All three areas are generated from the suburb's street grammar, so they share a layout vocabulary and differ mainly in shape, names, facilities and pressure. Step 9 is otherwise complete; step 11 (play the real game proportionate to each change) is where tuning of all three areas belongs.

## 30 October 2026: area 1 doubled again (schema 40)

User feedback: the suburb was still too easy. Every suburb lot now starts with twice its residents again (124 -> 248): the new Shamblers are appended to each lot's `zombies`, placed by a seeded scatter over walkable yard at least 80 px from the gate and 38 px (26 px late) from any other resident. `living_cap` 200 -> 400 (the validator's maximum). Schema 40: schema 39 saves go through the same renumber-and-refill upgrade as 38. The office and industrial areas are untouched.

- Checked: catalog (all three areas 0 problems), save (new schema 39 case), pressure, boss, travel, ring, passages, rear-build, facilities, office and industrial checks pass. `check_rear_build` now clears the claimed lots' yards first, since the larger yards killed its stationary player.
- Not checked: how the 248-resident street plays or performs in the running game, and whether the largest yards (garden, garage, library, now 28 to 32 residents) can be cleared at all; pass 9 found 14 already lost to a lone player.

## 30 October 2026: survivor retreat, lifting under threat, and the Spitter

- Survivors below 40% health with a zombie within 90 px now fall back (away from it, else to the home respawn) instead of fighting on. Lifting a downed person now needs no zombie within 60 px (was 170 of either party), and the prompt says "Zombie too close to lift <name>" instead of silently stalling.
- New zombie kind `spitter` (85 health, notice 340 px): it stands at 140-340 px with a clear shot, aims 0.9 s at a committed point, and lobs a 240 px/s glob (8 damage) that leaves a 42 px pool lasting 4 s (4 damage per second, one shared one-second cooldown per person so pools never stack). Walls stop globs, low barriers do not; a hit during the aim cancels it with a 3 s retry. Drawn with an aim ring, dashed pool edge and a throat sac.
- Office district: a resident Spitter in the Bank Branch teaches the kind; templates `lobby_spit` and `floor_spit`; special cap 2. New `tools/checks/check_spitter.gd` (11 checks) passes; catalog, save, office, pressure, boss, travel, industrial and passage checks pass.
- Not done: globs and pools are transient (not saved; a load drops any in flight). Armour and a facing shield reduce the direct hit; only armour reduces pool ticks, as designed. Survivor guards do not step aside from pools, and workers do not flee marked areas. None of this has been played, and the retreat/lift changes have only been checked by the existing suites, not a dedicated test.

## 30 October 2026: an ending screen

- Pressing E at the works' final gate now sets `world.campaign_ended` (transient, not saved) and the HUD shows `ending_menu.gd`: the closing line, how many survivors came through, minutes played and times downed. "Keep exploring" resumes; "New street" starts over. All other commands are blocked while it is up, like the defeat panel.
- `check_industrial` now expects the flag instead of a message. Scripts load (110) and the industrial and boss checks pass. The screen itself has not been seen in the running game.

## 30 October 2026: the van (driving slice), schema 41

- Rewrote the head of `18-vehicle.md` to the area model and built a first slice (see its "Current state"). The office has a van parked beside its start; E boards, W/S/A/D drive it, E leaves when stopped. Hull 300, damaged by adjacent zombies (7 x breach) and Spitter globs; a wrecked van ejects the driver. Engine noise draws zombies. New `data/street/vehicle.json`, `scripts/sim/vehicle.gd`, `scripts/core/vehicle_state.gd`; save schema 41 (older saves, including frozen areas, gain an undriven van) and an `engine` attention event.
- `tools/checks/check_vehicle.gd` (15 checks) and `tools/checks/check_rescue_feel.gd` (6 checks) pass, as do the catalog, save, office, pressure, boss, travel, industrial, passage and spitter checks.
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

## 30 October 2026: review after step 8 (what still needs development)

Delivery steps 1-10 in `19-areas-and-suburb.md` are all done; only step 11 (play the real game) is open. Review of the logged "not done" items, most important first:

1. **Nothing has been played end to end.** The area transition, office, works, ending screen, van, Spitter and the carry guidance have only headless checks. Step 11 is the real gap.
2. **Pressure is untuned in all three areas.** Bands and intervals were authored for the old layout; with an idle player 21 raiders were alive after 15 minutes in the suburb.
3. **Boss balance is provisional.** `sim_boss` shows all three are beatable with the bat if the lunge is read; real feel, armour, shield and ammunition are untested. The baboon's east approach is wall-shielded.
4. **Survivors lack awareness of hazards.** They do not step aside from Spitter pools or flee marked areas, and globs are not saved.
5. **Van is a first slice.** Followers cannot ride or keep up, no passengers, repair or reason to drive; handling and drawing are unseen.
6. **Areas share one layout vocabulary.** Plaza, car parks and area-specific survivors (Theo, Nia, Rowan) are unbuilt; 15 shell lots were dropped; there is no reason to return to an earlier area.
7. **Clean-up debt.** Inert `slice_state` and `catalog.slice` remain; `save_state.gd` is at 771 lines (limit 800); raider spur path-target question in `raiding.gd`; fence-line gate points stall walkers.
8. **Rescue/casualty loop** has no dedicated test beyond `check_rescue_feel`, and the new drop-off guidance is unseen.

## 30 October 2026: carry guidance seen in the running game

- `tools/capture_carry.gd` (run with `Capture.ps1 -Tour`) stages a downed Mara, lifts her with a real E event, walks to the porch and drops her; frames in `docs/verification/carry_*.png`. The prompt, the teal drop-off ring and dashed guide, the DOWN ring and the casualty roll all read correctly.
- Found by looking: the roll had literal line breaks in its source (a blank line under CASUALTIES); fixed. Also, `Input.action_press` alone never starts a lift because the game reads the press as an event: captures send an `InputEventAction`.
- Not checked: hurt-but-standing rings, several casualties at once, a rescue carried by another survivor, the map view.

## 30 October 2026: van, Spitter and ending seen in the running game

- `tools/capture_late.gd` stages the office van (parked, boarded and driven), a resident Spitter, and the ending screen in the works; frames `van_*`, `spitter_*`, `ending_screen` in `docs/verification/`. The van is drawn as a small box, boards with E and shows its prompt and hull; the Spitter's glob is drawn; the ending panel shows the closing line and its two buttons.
- Not seen: the van's handling over distance, a Spitter pool landing on a person, and the ending after a real run (the staged panel reads "0 minutes"). The ending menu reads `exit.line`, which only the works' exit has: it must stay set only by the final gate.
- Areas' entrances, bosses and home streets were already captured (`office_*`, `works_*`); a full play-through of each area by a person is still outstanding.

## 30 October 2026: tutorial tips

- New `scripts/sim/tips.gd`, `scripts/core/tips_content.gd` and `data/street/tips.json`: nine state-driven tips (move, swing near a zombie, lift, drop-off, rest, repair gate, open gate, reclaim a yard, arrivals), one at a time, in a HUD box and under Help with a Tips on/off button. No schema change: nothing is saved, session-only memory covers walking, swinging and lifting, and a world past 60 s counts the basics as taught. `world.tips` is stepped at the end of each fixed step.
- `tools/checks/check_tips.gd` (13 checks) passes, as do parse (120 scripts), catalog, save, pressure, boss, travel, rescue-feel, vehicle, spitter, office, industrial, passages, ring, rear-build and facilities checks. `tools/capture_tips.gd` frames `tip_move`, `tip_gate_repair` and `tip_help_tab` were looked at: the box reads cleanly and does not cover the context prompt.
- Not done: the tips have not been played through by a person. The Tips on/off choice resets each session; no tips yet for timber, the field bag, team orders (1-4), the work board, the workshop, firearms and noise, or the second and third areas. The wording is first-pass.

## 30 October 2026: code-review fixes and a second development review

- Guard combat no longer uses suburb-only coordinates: the barricade strike and the guard's chase line are measured from each area's `mara_start` and `home_alert_center` (the old numbers matched neither the suburb nor the other areas, so the strike never fired).
- `load` handles a save that cannot be restored and refreshes the HUD; dropping a casualty always succeeds inside a valid shelter; a downed survivor in a gateway says so.
- Save code: migrations moved to `save_migrations.gd` (save_state.gd 797 -> ~290 lines); `STATE_KEYS` is built from `COPIED_KEYS` + `SCALAR_KEYS` and `rescue_intro` is now validated. The Tips on/off choice is stored in `user://settings.json` (toolkit `SettingsStore`), apart from the street.
- `world.gd` facility prompts and interactions use `facility_context` / `facility_interact` tables instead of if-chains.
- Boss and objective messages use the area's boss name instead of "baboon".
- Parse (122 scripts), `--headless --editor --quit`, a headless boot and the catalog, save, travel, boss, pressure, vehicle, spitter, tips, rescue-feel, facilities, passages, office, industrial and ring checks pass. Nothing here was seen in a running window.

Still needing development (second look, most important first):
1. **Objective and readiness are suburb-only.** `slice_objective.readiness` hard-codes home/garden/library/garage and harvest goals, so in the office and works the HUD goal and READINESS panel describe the suburb. Each area needs its own objective list in data.
2. **Nothing played end to end** (unchanged): areas 2-3, ending after a real run, van handling, Spitter pools on people.
3. **Pressure untuned** in all three areas; boss feel provisional.
4. **Survivors ignore hazards** (Spitter pools); globs unsaved.
5. **Van** first slice only (no riders, repair, reason to drive).
6. **Areas lack identity**: area-specific survivors, plaza/car parks, a reason to go back.
7. **Tips** cover the suburb basics only (no timber, field bag, orders 1-4, work board, workshop, firearms, noise, areas 2-3).
8. **Debt**: inert `slice_state`/`catalog.slice` timing fields, raider spur targets, fence-line gate stalls, `migrate` upgrades still call `World.new(catalog)` (content-dependent), no save slots.

## 30 October 2026: survivors dodge spit, hazards saved, van riders/repair/ambulance (schema 42)

- Survivors (`Combat._survivor`) step out of Spitter pools, landing globs and spitters' committed aim points before doing anything else (`Spitter.escape`, activity "Dodging spit"). Globs, pools and the shared pool cooldowns are now saved (`spits`, `spit_hits`) and validated.
- Van: up to two nearby Follow-order survivors ride with the driver (immune to hits, do not block the van, set down beside it on exit or wreck); hold R beside the van to repair it (4 materials prepaid once, 10 s, +200 hull, progress kept); a carried casualty can board the van away from any shelter, so it doubles as an ambulance. Saves from schema 41 gain empty riders, repair state and hazards.
- `check_vehicle` (riders, rider immunity, exit placement, ambulance, repair, 41 migration) and `check_spitter` (dodging, hazard save/reject) extended and passing, as do parse (122 scripts), catalog, save, travel, boss, pressure, tips, rescue-feel, facilities, passages, ring, rear-build, office and industrial checks.
- Not seen in a window: the dodge, riders drawn in the van, the repair prompt. Not done: survivors repairing the van, van between areas, riders ordering. Survivors do not avoid zombies' other hazards (none exist).

## 30 October 2026: objective and readiness per area

- `objective.reclaim` in each `area.json` lists the lots that area asks the player to hold (suburb: home, garden, library, garage; office: home, maintenance, atrium, car park; works: home, parts store, gatehouse, yard office), validated by the catalog. `slice_objective.gd` derives the HUD goal and READINESS from it: garden, harvest and workshop/equipment steps apply only where a lot of that kind is listed, so the office and works no longer ask for a garden.
- Parse, catalog, save, tips, boss, travel, office and industrial checks pass. Not seen in the HUD of the other areas.

## 30 October 2026: the bridge is a real arena

- The suburb's map grew from 2180 to 3300 tall: a 640 x 1080 bridge deck (new street kind `bridge`, parapets, lanes, expansion joints) runs south from the estate's south-west corner over open water (`terrain.water` in `area.json`: impassable on foot and for the van, but not for globs or sight). The baboon holds the middle of the deck (post 360,2760, leash 420, escorts either side), the blocked exit is a full-width roadblock at the far end, and migrations now enter at the far end of the bridge and walk the length of the deck past the baboon.
- Existing saves still load (positions all fall inside the old bounds; the boss walks back to its new post). `check_pressure` now asserts no raider strays east of x=700 instead of using the old spur height. Parse, catalog, boss, pressure, save, travel, ring, spitter and sim_boss run; frames `boss_bridge_approach` and `boss_baboon_post` were looked at.
- Not done: the office and works exits are still short roads; the fight on the wider deck has not been played, and the baboon may now be easy to circle (its lunge was tuned for a narrow post).

## 30 October 2026: more tips

- Four new session-only tips in `tips.gd`/`tips.json`: team orders 1-4 (a fight with a team and no order given yet), the pistol (owned, loaded, in a fight, not yet fired), timber with Q (beside a held yard), and the van (beside it; also names riders, casualties and repair). Orders and pistol rank right after the swing tip so they appear in a fight rather than behind gate and reclaim guidance. `check_tips` covers orders and pistol (0 failures); timber and van are untested.
- Still without tips: field bag, work board (J), workshop loadouts (F), noise, areas 2-3 specifics. Wording is first-pass and unplayed.

## 30 October 2026: retired the inert slice state (schema 43)

- `slice_state` (phase, held, downs) and `slice.hold_seconds` belonged to the removed neighbourhood-watch ending and did nothing. They are gone from the world, the save and the data; schema 43 drops the key from older saves. `slice.harvest_food` and `start_range` stay (readiness and timber still use them).
- Parse and the catalog, save, vehicle (including the 40 and 41 upgrade paths), spitter, travel, boss, tips, office and industrial checks pass.
- Still open debt: raider spur targets in `raiding.gd`, fence-line gate points that stall walkers, `migrate` upgrades that build a World, no save slots.

## 30 October 2026: office and works exits get their own arena

- The empty pocket north of the west-road corner (x 40-310, y 0-500) is now a road room holding the Warden's and Foreman's posts and the wide roadblock/exit at its top (posts 175,300 / 175,260; leashes 290 / 380; escorts either side). Players reach it from the top street, so the boss still guards the only way out, but the fight has a room rather than a strip of road. It is smaller than the suburb's bridge: the pocket is bounded by the lot fences, so a bigger arena would need moved lots or a larger map.
- `sim_boss`: the dodging bot still wins in all three areas (office 49 s at full health, works 81 s with 60 left); the non-dodging bot still loses. A first, tighter works layout made the dodging bot lose, hence the longer works leash. Parse, catalog, boss, office, industrial, travel, save and pressure checks pass; `office_warden` and `works_foreman` were looked at (the tour camera clips the roadblock at the top edge).
- Not played. Feel on both is unknown.

## 30 October 2026: pressure measured (not tuned)

- New `tools/sim_pressure.gd`: takes the lots beside home, stands still (player cannot die, survivors keep their guard orders) and logs living raiders and waves every two minutes for 20 minutes.
- Result (raiders/wave): suburb 6/w1 at 4 min, 17/w3 at 10, 26/w5 at 20; office 5/w1, 15/w2, 41/w5; works 8/w1, 13/w2, 32/w5. A wave lands about every four minutes in all three, nobody clears them, and the home gate barely drops (86-93 of 104) so raiders mostly gather rather than break in. The office and works are heavier than the suburb at the same minute, which suits later areas.
- Nothing was changed: there is no target to tune to without play. Questions this shows for a human run: do idle raiders that never breach feel like pressure, and is a wave every four minutes right once the player is fighting?

## 30 October 2026: Theo, Nia and Rowan join (area survivors)

- `survivors.json` now names all eight. Theo, Nia and Rowan use `site: "search"`: they join when the lot whose `search.survivor` names them is searched, so recruits are authored per area. Theo is in the office tower lobby; Nia in the works' tool crib; Rowan in the works' gatehouse. `Roster.lot` resolves where each lives; the rescue menu, save validation and discovery validation use it. They arrive with the same Hold/Follow/home choice as June and Oliver and have no exclusive role (as in doc 05). Drawn in orange, violet and cobalt.
- Saves: no schema change. Search-found survivors are optional in a save, so an office or works save whose lot was already searched stays valid but will not gain them retroactively.
- `tools/checks/check_recruits.gd` (search, intro, save per person; none in the suburb) passes with parse (124 scripts), catalog, save, travel, boss, office, industrial, vehicle, tips, rescue-feel and facilities.
- Not done: their introduction text is first-pass and unseen; no Theo-specific escort role, Nia power mechanic or Rowan reserve role beyond ordinary orders; not seen in a capture.

## 30 October 2026: stores left behind give a reason to go back

- Stock above the 40-per-kind carry cap already stayed in the area you left. It is now visible: arrival says "Left behind in <area>: ...", and at an area's entrance the prompt reads "E Go back · stores waiting: 60 materials, ..." (`Boss.stored` / `Boss.waiting`). No schema change; nothing is added to the stock, so this is a reminder, not a reward.
- `check_travel` asserts both texts. Not done: anything that accrues while away (a garden that keeps growing, pressure on the area you left), and the prompt only names the previous area's stores, not the next one's. Whether a stockpile alone is a real reason to return is a design question for play.

## 30 October 2026: gardens keep growing while you are away

- Time played in other areas counts as time away (`AreaTravel._played`: this area's clock plus every frozen area's). A frozen record remembers `left_total`; on return a finished garden yields one food per `away_food_seconds` (90, `balance.json`) of absence, never pushing food above the carry cap (40), and the arrival note says how much. Records from older saves lack `left_total` and grow nothing. No schema change.
- `check_travel` covers it (900 s away gives 10 food). Not done: production by clinic, workshop or ammunition bench while away, and pressure on an area left behind; both stay frozen. Rates are unplayed guesses.

## 30 October 2026: tips for loadouts and the field bag

- Two more session-only tips: `loadout` (the workshop's armour cache is done and nobody wears iron or a shield: F, Loadouts) and `field_bag` (the bag is unlocked, unassigned, and someone is hurt). Both go away once the thing is done. `check_tips` covers them (0 failures); the rest tip correctly outranks the field-bag tip at the home porch.
- Still without tips: the work board (J), noise, areas 2-3 specifics. First-pass wording, unplayed.

## 30 October 2026: the ending counts the whole campaign

- The closing screen read only the last area's clock and falls, so a real run ended at "0 minutes". It now uses `AreaTravel.played` and `AreaTravel.downs` (this area plus every frozen one). `check_travel` covers the time (the downs total is asserted only as 0).
- Still unplayed: the ending after a real run.

## 30 October 2026: fence-line gate stalls not reproduced

- A probe walked every lot in all three areas with gates open: each gate point is walkable and has a path to its own site and to home. The earlier "gate points stall walkers" note is therefore not reproducible from the data; if it happens in play, it needs the lot and what was assigned. The probe was thrown away (not committed).

## 30 October 2026: three save slots

- `scripts/core/save_slots.gd`: slot 1 keeps `user://suburb.json` (existing saves are untouched); slots 2 and 3 use `user://street_2.json` and `street_3.json`. The pause menu's Street tab has a slot button that cycles the slot and shows its summary ("Slot 2 · empty", "Slot 1 · suburb 34m", minutes counting every area); Save and Load then use that slot. The slot is per session and starts at 1; "New street" keeps the current slot's save until you save.
- `tools/checks/check_slots.gd` (paths, summary, isolation) passes with parse (125 scripts), save and travel checks; a headless boot runs; `pause_save_slots` was looked at. Not done: remembering the last slot between sessions, deleting or naming a slot, loading from another slot automatically on start (the game still opens on slot 1's area), and a confirmation before overwriting a slot.

## 30 October 2026: slot memory and overwrite guard

- The chosen slot is kept in `user://settings.json` (`slot`) and used on the next start. Saving into a slot that holds a longer run (more seconds played across every area) than the current one asks first: the first Save press explains, a second Save press overwrites; any other command cancels the ask. Re-saving the same run never asks.
- `check_slots` covers the seconds read (0 failures); parse and a headless boot pass. The prompt flow itself is unchecked: captures run with saving disabled (`--no-save`), so it needs a real session. Still not done: deleting or naming slots.

## 30 October 2026: clinics make medicine while you are away

- A restored clinic now yields one medicine per `away_medicine_seconds` (240, `balance.json`) of absence on return, beside the garden's food, capped at the carry cap (40); the arrival note says how much. `check_travel` covers it (960 s gives 4). Workshop output and ammunition crafting still stay frozen (they spend materials, so away output needs a rule for what they consume). Rates are unplayed guesses.

## 30 October 2026: noise tip

- A `noise` tip appears while a gunshot or engine noise is alive and goes after twelve seconds: loud things pull zombies from far off. `check_tips` covers it (0 failures). Tips are still missing for the work board (J) and areas 2-3 specifics; wording unplayed.

## 30 October 2026: supply caches (schema 44)

- Because the plaza and car parks had no purpose and no answer came, I gave them the smallest one: a one-time supply cache in the open of each area, searched with E when no zombie is within 170 px (`scripts/sim/caches.gd`, `caches` in `area.json`, `caches_taken` in the save). Suburb: market stalls on the plaza (20 materials, 4 food, 2 medicine); office: abandoned cars on the east road (24/5/3); works: freight pallets on the east road (28/6/4). Drawn as crates with a ring; they stay as empty crates once searched. Saves from schema 43 have taken none.
- `tools/checks/check_caches.gd` (reachable, refused near a zombie, pays once, saves, schema 43 upgrade, unknown id rejected) passes with parse (129 scripts), catalog, save, vehicle, spitter, travel, boss, tips, office, industrial and recruits checks. Frames `cache_market` and `cache_market_searched` were looked at.
- This is a placeholder decision, easy to change or remove (data plus one script). Still not designed: a defensive role for the plaza, and what the car parks should be as lots.

## 30 October 2026: being away has a cost

- Returning to an area after at least `away_siege_seconds` (600) elsewhere finds the home gate at `away_siege_factor` (0.6) of its health, with a note; shorter absences change nothing. Together with the away garden and clinic, an area left behind now both pays and costs. `check_travel` covers long and short absences. No schema change. Rates are unplayed guesses; raiders in the area itself stay frozen.

## 18 November 2026: a real 1920x1080 layout (screen fit)

- `project.godot` lays out at 1920x1080 (`stretch/aspect="expand"`, window 1600x900) and `town.gd` mounts the toolkit's `ScreenFit.watch`: windows from 1280x720 to 1920x1080 get one layout unit per pixel, bigger ones scale up, smaller ones shrink to a 1280x720 layout. A bigger screen now shows more street, not bigger text.
- The camera clamp uses half the visible rect, not 640x360. The HUD pins the pause button and tip to the top right and the radio line to the bottom left by anchors; the pause menu grows from 880 to 1240 wide and follows `resized`. Rescue, defeat and ending panels are centred by anchors. The town map's drawing and preview grow with the menu and re-place their site buttons on resize.
- `tools/capture_screens.gd` (title, each pause tab, credits, street, rescue, defeat, ending, and a resize to 1280x800 mid-screen) was run and looked at at 1920x1080, 1600x900, 1280x800 and 1280x720; the 1920 set is kept as `screen_*`. `Capture.ps1` now captures at 1920x1080. Parse (132 scripts) and editor import are clean.
- Not checked: the web build in Chrome and full-screen toggling (no full-screen control exists yet; it comes with the settings page). The toolkit credits page sizes itself once when opened.

## 18 November 2026: suburb lots split by row

- The suburb's lots move into four files by row: `properties.json` (north side of the main street), `properties_south.json` (south side), `properties_additional.json` and `properties_back.json` (the back rows). The catalog reads the two new names when an area has them (`OPTIONAL_AREA_FILES`), in the original order, so ids and order are unchanged. No file is over 800 lines now (largest: `passages.json` 709). `check_catalog`, `check_save` and `check_travel` pass.

## 18 November 2026: survivors owed by an early search

- A lot searched in a save from before its survivor was written in (Theo, Nia, Rowan; schema 43 and earlier) no longer stays empty. `Roster.catch_up` recruits anyone whose lot is searched but who never joined, at their lot with their introduction, after a save is restored and after arriving back in an area (travel replaces the team, so it looks again then). A current save never needs it; no schema change. `check_recruits` covers loading such an office save and returning to the office from the works (0 failures); save, travel, slots and tips checks pass.

## 18 November 2026: migrations read plain data

- No migration step builds a `World` any more. `SaveState.authored()` snapshots today's starting state for the area once, as plain save data, and the steps that add residents, lots or passages (schemas 4, 11, 20, 21, 29, 38-39) copy from it; `ResidentState.renumber` takes that list. An old save is no longer read through today's world, only topped up from today's authored content (past catalogs are not kept, so content a step adds is still today's). `check_save` adds: the reference is plain data, a step cannot change it, and the same old save upgrades identically twice. Save, travel, recruits, slots, caches and vehicle checks pass.

## 18 November 2026: raids reach a gate in every area

- `raiding.gd` already takes every target from area data (route entry and approach, lot site, gate and yard). The new `tools/checks/check_raids.gd` runs the first raid after a claim in each area and asserts it enters on an authored route and a raider reaches a held gate within 20 minutes. It failed in the office: raiders pressed against tower_lobby's fence sat in a grid cell the pathfinder marks solid, `waypoint` gave up, and they walked into the fence for good.
- `Routes.waypoint` now paths from and to the nearest open cell (within two cells) when the start or target cell is solid, as a spot on a fence line or gate is. Every area passes; raids also arrive sooner (suburb 497 s to 295 s, office never to 229 s, works 1063 s to 210 s), so pressure is harder than before, untuned. This likely also helps the listed "fence-line gate points stall walkers" debt; not separately checked. All 18 earlier checks pass.

## 18 November 2026: a scripted run to the ending

- `tools/bot_ending.gd` plays a new street headless through all three areas: it opens home's gate, walks the route grid to each boss, fights whatever is in the open in reach, kills the boss, confirms the exit and travels on until the works' main gate ends the campaign. It fails on a stall (no progress for 120 simulated seconds, and a fight only counts as progress when it lands blows), out of time (30 minutes an area) or a failed travel. `--seeds=`, `--fair` (no health top-ups, stop at the first defeat) and `--trace` (once a minute) are options.
- Result: seeds 1-3 reach the ending with no blocker, about 3 simulated minutes each (suburb 53-72 s, office 56 s, works about 60 s), topping the player up 15-20 times. With `--fair` each seed is downed in the suburb. So nothing blocks the route, and nothing stops a run that ignores the reclaim objective except the player's health. Whether a boss rush should be possible is a design question for the person playing.
- Not covered: the reclaim objective, survivors, building and raids beyond what happens on the way. It is not a playtest.

## 18 November 2026: the workshop and ammunition bench work while you are away

- `scripts/sim/away_work.gd` runs on return to an area (from `AreaTravel._regrow`, after the garden and clinic): a workshop or gear restoration already paid for advances by the time away and finishes when it can; the ammunition bench keeps its policy (once or repeat, target, material reserve) and crafts whole batches, each paid from the stock left in that area through the normal work board. Part-done work is left with no worker named. No schema change.
- `tools/checks/check_away_work.gd`: 900 s away finishes the workshop, makes 24 bullets for a repeat-24 policy and charges 8 materials from the stock left behind; an unset bench makes nothing (0 failures). Travel, save and facilities checks pass. Rates are the bench's own; unplayed.

## 18 November 2026: a long absence costs more than the gate

- `scripts/sim/away_pressure.gd` runs on return after the home gate rule: from `away_siege_seconds` (600) away every standing street barricade is worn to `away_siege_factor` (0.6) of its health (a broken one is cleared and routes rebuilt), and from the new `away_loss_seconds` (1800, `balance.json`) the claimed lot farthest from home with no protected route to it falls and must be reclaimed. Lots joined to home by safe routes always hold, which is what the absent survivors could have defended. No schema change.
- `check_away_work` adds 700 s (barricade worn, outlying lot held) and 2000 s (barricade worn, house_e lost, home held) cases; 0 failures. Travel, catalog, save and boss checks pass. Numbers are unplayed guesses.

## 18 November 2026: the van repair is a work-board job (schema 45)

- Holding R beside the stopped, damaged van approves a `van_repair` work order (4 materials, 10 s, from `vehicle.json`); the player or a survivor assigned from the board (new `Van` order, standing at the van's flank) works it off, and cancelling refunds like any project. `scripts/sim/van_repair.gd` owns it; `vehicle.repair_paid`/`repair_progress` stay as projections of the order, and saves require a pending order whenever a repair is paid. Schema 45 refunds a repair paid the old way.
- `tools/checks/check_van_repair.gd` (approve, on the board, Mara assigned and finishing, mid-repair save, cancel refund, schema 44 refund) passes; all 21 checks pass and the editor import is clean. Not looked at in the running game.

## 18 November 2026: the van follows the team between areas

- Decision taken without an answer, easy to change: the van comes through an exit or entrance with the team when it is parked within 320 px of the player as they leave, not being driven and with no repair under way. It is parked beside the arrival door (the first nearby spot it fits), keeps its hull, and the area left behind no longer has it. There is still one van; it starts in the office. A van too far away, or with nowhere to park, stays where it is. Saves now allow a van in any area (`present` is a plain flag), so no schema change.
- `check_van_repair` adds: the van follows from the office to the works, that save loads, and a van left far away stays in the works (0 failures). Vehicle, travel, save, office, industrial, away-work and recruits checks pass. Not seen in the running game.

## 18 November 2026: tips for the work board and the later areas

- New tips: `work_board` (paid-for work and a team: press J; learned when the board is opened with J), `area_office` and `area_industrial` (on first arrival, in the area's first two minutes, for 12 s: who holds the way out and where, and what lies behind). The `van` tip now mentions the repair job and that a van parked by an exit comes along. `check_tips` covers both welcomes and the board tip (0 failures); catalog passes. Wording is unplayed.

## 18 November 2026: save slots can be named and deleted

- The pause menu's Street page has a second save row (`scripts/presentation/slot_controls.gd`): a name for the chosen slot (Enter or leaving the field; up to 24 characters, kept with the preferences, shown on the slot button) and Delete slot, which asks for a second press and removes the save with its backup and any kept or damaged copies. A run with saving off deletes nothing. `SaveSlots.root` lets tours and checks use their own folder.
- Bug found on the way: the chosen slot was never remembered past slot 1, because the preference accepted only 0 to 1. The HUD now gives it the 1-3 range.
- The overwrite prompt was seen for the first time (`pause_overwrite_prompt`), with `pause_delete_armed` and `pause_save_slots`, from `tools/capture_slots.gd` in its own folder. `check_slots` adds names, delete and the remembered slot (0 failures). The `screen_*` set was recaptured with the new row.

## 18 November 2026: synthesised sound

- `scripts/presentation/street_audio.gd` watches the shown world each frame (the simulation knows nothing of audio) and plays cues from `street_sounds.gd`, all synthesised at start from one seed with the toolkit's `Synth` on a `CueBank` (Effects bus): gunshot, swing, melee hit, zombie groan from the nearest zombie within 700 px (quieter with distance, every 2-3 s), gate or barricade struck, work ticks for building and repair, a finished project, the van engine (pitch by speed), and a tip chime. Each area has an `Ambience` bed (suburb wind; office hum and draught; works machinery drone and hiss). Paused, no new cues play. A `heard` signal carries captions for gunshots, strikes, groans and the engine.
- `tools/checks/check_audio.gd` (headless, so cues are counted, not heard) passes. Not heard by anyone: levels and character are guesses. Volume controls come with the settings page.

## 18 November 2026: settings page and rebindable keys

- Help → Settings opens the toolkit's settings page (`scripts/presentation/game_settings.gd`, a `settings_bundle`): master, effects and ambience volume, mute, full screen and Interface size (80-160 %, multiplying on top of screen fit), and a Controls tab rebinding 16 actions. The shortcuts that were hard-coded keys (1-4, Q, G, F, J, M, Esc/Tab) are now project actions (`order_*`, `salvage`, `road_guard`, `team`, `work_board`, `town_map`, `pause`). The HUD's tips, slot and slot-name preferences live in the same store and file. With no preferences file the bindings start from the project's keys (the toolkit store leaves them empty otherwise).
- `tools/checks/check_settings.gd` (defaults, rebind, refused duplicate, effects bus, interface size, slot preference) passes; slots, tips and audio checks pass. Frames `screen_settings` and `screen_settings_keys` were looked at. Not checked: the help text still names the default keys after a rebind; the aim helper in `player_controls.gd` still watches WASD/arrows/Space directly.

## 18 November 2026: accessibility

- Settings → Accessibility: Colour-safe threat and health (`access.gd` swaps the teal/rust pair for blue `#56b4e9` / orange `#e69f00`, the live health bar too), Captions for sounds (`captions.gd`, bottom right on a dark backing: gunshot, engine, a struck gate or barricade, a groan nearby, each with left/right/nearby, 3 s, repeats refresh their line), and Reduce motion (pulsing rings held still, no white hit flash, the camera snaps). `check_settings` covers the palette swap and still pulse; `access_off` and `access_on` were looked at. Not judged by anyone with colour blindness.

## 18 November 2026: gamepad

- Every action has a pad binding (left stick moves, right stick aims, right trigger shoots through a new `shoot` action that also holds right mouse, X swings, A interacts, B works, Y team orders, Back the work board, LB the town map, RB posts a road guard, left stick press strips timber, the d-pad gives the four team orders, Start pauses). The 12 button actions can be rebound on the settings page (`PadBindings`, Start reserved). The project now adds A to `ui_accept` and B to `ui_cancel`: Godot's defaults have no pad button for them, so A could not press a focused menu button.
- `tools/capture_pad.gd` drives the game only with joypad events: Start pauses (`pad_pause`), the d-pad moves focus and A presses a tab (`pad_tab_pressed`, the Town page opened), Start resumes, and the settings page lists the buttons (`pad_bindings`); all looked at. Settings, slots, tips and audio checks pass. No real pad was used.

## 18 November 2026: icon and Windows product details

- `icon.png` (256 px) is drawn by `tools/make_icon.gd` in the greybox palette: a lit house behind a fence and gate, a striped dead-end bar across the road. It is the project icon (`config/icon`, the web export's icon) and the Windows icon; the Windows preset now sets `application/modify_resources=true` with product name, description, company, copyright and file/product version 0.1.0.0. A release export was made to `builds/windows/` (ignored): Windows reports the product details and the extracted icon is the new one. Credits were already in Help. The "work-in-progress greybox" wording stays in `publish.json` until pilot art lands.

## 18 November 2026: browser pass

- `.\publish.ps1 -BuildOnly` built web and Windows; the web build was served from `builds/publish/.../web` on 127.0.0.1 and played in Chrome (viewport 1920x911, one layout unit per pixel): Begin, walk, pause, Save ("Street saved to slot 1"), reload the page (slot still shows "suburb 0m"), Load ("Street restored"), resume and walk. No errors seen. Not done: a small window (the window was maximised and resizing had no effect) and browser full screen.

## 18 November 2026: one command runs every check

- The 23 check scripts moved into `tools/checks/` and the empty `tools/scratch/` is gone. `tools/Check.ps1` runs `parse_all`, the editor import and every `tools/checks/check_*.gd`, each in its own headless Godot, and fails on a non-zero exit, a FAIL line or a SCRIPT ERROR (`-Only <names>` for a subset, `-Bot` adds `bot_ending.gd`). Each check stays its own SceneTree script rather than being rewritten as toolkit `check_runner` modules. First full run: all 25 pass in about two minutes. Paths in AGENTS and the progress notes were updated.

## 18 November 2026: the ending bot reclaims each area first

- `tools/bot_ending.gd` now reclaims each area's `objective.reclaim` lots before the boss: it takes the first listed lot that borders held ground (the office lists `maintenance` before the `atrium` it needs), clears the yard, searches and claims at the porch (`--rush` keeps the old boss rush). Seeds 1-3 reach the ending; reclaiming takes about 100 s in the suburb, 78 s in the office and 45 s in the works, with 63-77 health top-ups a run. At each boss readiness is still unmet: the suburb and office want fenced passages and crossings built, and in the works raiders were back in a reclaimed yard. No blocker found.
