# Dead End Town implementation progress

## 28 October 2026: first playable street

The Last Hearth provided a local project-layout template: engine configuration, Compatibility renderer, launcher/tooling shape and toolkit integration. Dead End Town has its own rules and original procedural greybox visuals. The other game and shared toolkit were not modified. No external assets, engine packages or plugins were installed.

The runtime links `../godot_toolkit/addons/hatchery` into `addons/hatchery` using the toolkit's junction script. That link is deliberately ignored by Git. Recreate it after cloning using the README command. JSON reads/validation, staged saves with backup recovery, UI styling, parse checks, scenario checks and capture paths all use the toolkit.

## Implemented

- One continuous authored street: home and garden to the north, library and garage across the east-west road. Buildings are solid footprints with porch interactions. Yard fences and gates physically block both the player and AI routes.
- WASD/arrow movement, mouse aim, repeatable bat swings, range/cone/line checks, cooldowns, knockback, damage flashes and health bars. A basic zombie acquires visible nearby people and attacks in physical space.
- Mara begins guarding home. The small squad supports Follow, Hold, Engage and Return home; Home becomes Guard on arrival. Pursuit is bounded around the order anchor. A guard can strike an attacker leaning over the low barricade.
- A single three-zombie approach originates on the east road after 60 active seconds and walks to home. Zombies damage a closed gate, enter after a breach, or use an already-open entrance. Guards and combat stay simulated off camera. Alerts distinguish safe, threatened and breached home conditions.
- Hold R near the home gate to pay one repair commitment and contribute work. Interrupting or saving keeps that commitment until the repair completes. Rebuilding a broken gate leaves it open to avoid trapping actors; close it explicitly when clear.
- Clearing and claiming are separate. E at a cleared porch claims only a property adjacent to the home-connected ownership graph. The claim and loot reward happen once. Fences stay physical and gates remain explicit entrances.
- E at a claimed garden porch reserves eight materials once. Player work and Mara's assigned Build order advance one shared progress value without doubling labour when both are present. Threats pause work; Mara attempts shelter. Completed rows become visible crops, producing two food per 20 safe seconds.
- Securing the library rescues Paige once and adds her to the cooperative squad. Securing the garage awards extra materials and a tools discovery message. The subsequent workshop/equipment step is recorded below.
- Esc/Tab and the opening menu pause all rules. Explicit save/load uses a validated versioned snapshot under `user://street.json` through toolkit `JsonSave`. State includes actor positions, health, orders, remaining enemies, property gates, discoveries, work commitment, production clock and approach timing. No offline progression or autosave.
- Protagonist defeat returns them home with full health and preserved progress. Downed companions can recover at the safe home porch. These are intentionally forgiving prototype defaults.

## Verification performed

With the installed standard Godot 4.7.2 console editor:

- Every project/tool script loaded through the toolkit parse runner.
- `--headless --editor --path . --quit` completed successfully.
- Eleven headless scenarios passed: catalog validation; authored movement speed and closed-gate collision; occupied/disconnected claim refusal and unique rewards; work handoff across a JSON save round trip; a home guard holding a routine approach while the player is away; malformed-save rejection; deterministic repeated runs; physical builder routing and a blocked gate; breach collision and interrupted repair accounting; on-disk damaged-save recovery; and a garden loop using movement, melee and porch commands without fixture enemy deaths or protagonist defeat.
- Ran the real game window through `Run.ps1` and the toolkit capture runner at 1280x720. Inspected `verification/opening.png`, `verification/home.png` and `verification/garden.png`. These are staged presentation states; the garden capture deliberately clears its fixture occupants and advances work. They do not demonstrate human input, combat feel or a real rescue run.

The routing check found and fixed a no-path fallback that made a blocked survivor walk toward a fence. Home return now changes into guard duty on arrival. Property names were moved clear of the boarded windows after inspecting captures.

## Milestone boundary and next work

> Historical (first playable). Several "still absent" items below were built in later sections: recurring pressure, territory loss and recovery, food upkeep, transferable equipment and a slice ending. Use the latest sections and the review at the end for the current boundary.

M0 is implemented technically; traversal scale and readability still need human review. M1â€“M7 have initial examples, not completed acceptance gates. M8 is not complete. This prototype is shorter and much narrower than the proposed 20â€“30 minute slice.

The user has since confirmed a human playtest of basic combat and territory capture; see the feedback and development step below. Next, replace graph-only adjacency with explicit secured road crossings and exposed-boundary accounting, extend repair and work to general sockets, and review combat/crowd separation and the new equipment in human play.

Still absent: explorable interiors, general blueprint placement/cancellation, general repair targets beyond home and road barricades, job leases/hauling, general equipment inventory/recipes, firearm, noise-driven migration, recurring horde pressure, contested territory loss/recovery, ending, food upkeep, settings/remapping, gamepad/touch, audio and production art. The ownership graph does not yet prove physically safe street corridors: claiming does not magically secure the road. Alerts cover home and built road defences; other property alerts remain future work. The guard's barricade strike is a provisional low-fence combat rule.

During the initial implementation verification, no human playtest, recorded audio, browser/device check, export build, performance benchmark, deployment or publishing was performed. Publishing wrappers are standard boilerplate without destination configuration or export presets. The initial saves were schema 1; the new progression uses schema 2 with validated migration, as recorded below.


## 28 October 2026: playtest feedback and workshop progression

### Human evidence and direction

The user reports that a human playtest has happened: they could fight zombies and take over territory in the basic slice. They cautioned against too much screen information and suggested the bottom panel should probably be removed. This establishes basic loop playability, without claiming specific AI, save, defeat, balance or full milestone acceptance results.

### Implemented in response

- Removed the persistent bottom panel and full-width title/objective header. A small health/home strip and pause button remain. Interaction prompts only appear nearby; messages expire after seven active seconds. Objectives, stockpile, team activities, equipment and controls live in the pause menu. A companion going down produces a brief message so the hidden roster does not conceal that event.
- Claiming the garage discovers its tools and a single cached iron armour/shield set. Restoring the bench costs 10 materials and 16 seconds of work. Restoring the set then costs 12 materials and 18 seconds. E approves each commitment; R contributes work and F near the garage assigns Mara. Away from the garage, unfinished garden work retains priority. Workshop-only unfinished work can also be assigned remotely with F.
- Mara routes physically through the existing gates. Threats pause workshop work; committed materials and partial labour persist. Player and Mara together contribute only one work rate. Finishing a workshop task sends Mara home to guard, rather than leaving the gate unstaffed. No new work order starts without E approval.
- A restored bench and the cached set are drawn in the garage yard. Fitting requires the player and living, rescued Paige at the safe bench. The unique set moves from bench to Paige visibly. It halves incoming zombie damage, reduces movement speed to 80%, and adds a further half-damage shield reduction from the front. Fitting does not restore health. This is one fixed prototype loadout; transferable inventory, unequipping, other wearers and recipe menus remain future work.
- Snapshot schema 2 stores workshop commitments, progress, equipment and Mara's work destination. Schema-1 snapshots migrate without spending materials, granting equipment or changing actors. Invalid old saves remain rejected. Staged writes and backup recovery still use the shared toolkit.

### Verification and remaining work

- All 17 headless scenarios pass: the original eleven plus workshop shared labour/cost/unique fitting, unsafe work and insufficient materials, physical workshop travel and armour reload handoff, schema-1 migration, invalid workshop-state rejection, and real zombie damage/directional shield/movement effects.
- Ran the Godot 4.7.2 parse runner and headless editor/import check successfully.
- Ran `Run.ps1` and inspected staged 1280x720 captures: `opening.png`, `home.png`, `garden.png`, `workshop.png`, `armour.png` and `planning.png` in `docs/verification/`. These show the reduced live HUD, paused details, bench work and fitted equipment. Capture staging uses fixture clearances and accelerated work; it does not prove human progression feel.
- At this implementation step, the new progression and revised HUD had not received a human playtest; the user subsequently reported another game playtest below. The approach remains the original single authored group, so equipment does not yet have a dedicated defensive encounter. No exports, audio, performance benchmark, deployment or publication were added.
- Explicit safe street corridors/perimeter accounting remain the next territory step. Workshop eligibility still uses the existing claimed graph plus local threat clearance; physical actors use the existing route collision, but safe road connectivity is not yet modelled. Do not treat this as complete M4, M6 or M8 acceptance.


## 28 October 2026: temporary road defence and a moving line

### Human feedback

The user reports that the game has been playtested again. They want to defend the street from both directions after controlling both houses, and recover materials from temporary barricades when moving deeper into town. No additional specific combat, equipment or save observations were supplied. The new road feature below still awaits human playtesting.

### Implemented

- Home/library and garden/garage each unlock two authored road sockets, one at either end of their shared road block. Ownership only unlocks them. Dashed blueprints appear nearby; building requires an explicit E commitment, R labour or Mara assigned with F. No construction panel or persistent bottom information was added.
- Each barricade costs 8 materials and 8 seconds of shared work. Final collision waits until living actors clear its footprint. All actors use the same blocked road geometry, including after reload.
- Zombies attack blocking barricades from either direction, then enter when damage breaches one. Player and survivor melee can reach over these low road defences without ignoring property walls. Street warnings use the existing status strip and brief messages; home danger takes priority.
- G posts one living survivor inside the nearby barricade, preferring someone without another road post. Repeating G at that post does not pull away another defender. Posted survivors physically route, stop at the line, and defend over it. Normal team orders override posts. Breach or removal releases that line's guard; repairs preserve it.
- E on a built barricade approves 4 seconds of dismantling. Hold R or assign Mara; collision remains until completion. Full-health salvage is 6 materials, reduced by damage. E again keeps the barricade without payout. Unworked blueprint cancellation returns all 8 materials; part-built cancellation returns the unused/remaining salvage amount. Destruction returns none. Completion/cancellation pays once.
- A damaged standing barricade can be repaired with R/F for one 3-material commitment. Interrupted labour, repair commitments, construction, removal, work assignment and guard posts persist in save schema 3. Schema-1/2 migration preserves existing progress and supplies, and starts road sockets empty.

### Evidence and limits

- All 24 headless scenarios pass. Seven new scenarios cover facing-property unlocks and affordability; occupied construction footprint and collision; cancellation, damage-scaled salvage and interrupted repair; raiders from both directions and breach; physical Mara work and low-barrier melee; two guard posts through reload and one-sided removal; and moving the defensive line plus schema-2 migration/invalid-state rejection. Existing schema-1 migration and backup recovery checks still pass.
- Godot 4.7.2 parse/import checks pass. No script/file exceeds 800 lines or function exceeds 400 lines.
- Ran `Run.ps1` and inspected 1280x720 captures in `docs/verification/`: `street_barricades.png`, `street_attack.png`, `street_salvage.png` and `street_frontier.png`, alongside refreshed existing states. Fixtures clear occupants, accelerate work and stage an attacker; these are visual evidence, not human playtest results.
- Road barriers and guard posts are implemented. Full exposed-boundary accounting, safe road connectivity for facilities, general freeform construction, town expansion and recurring attacks remain open. The original authored approach still comes from the east; the west approach is covered by a staged automated scenario.
- No toolkit changes, packages, exports, deployment or publication were added.


## 28 October 2026: keyboard attack facing fix

The user reports that attacks do not face the same way as the character and confirms using Space while moving with WASD. The presentation previously aimed every player swing at the mouse, including keyboard-only attacks. Its head artwork also always faced down, and turning could redirect a displayed swing arc after the instantaneous hit had already resolved.

- Keyboard movement now sets facing; Space uses that movement direction, retaining it when stopped. Explicit pointer movement switches to mouse aim; clicking follows the cursor while moving. Holding Space gives keyboard facing priority over incidental pointer movement. Key repeat does not unexpectedly steal explicit mouse aim.
- Aim is resolved from the current actor/camera transform before attacking, even on a frame shorter than one fixed step. Turning waits until the current swing animation ends; hit direction, face, bat and arc stay together. The bat and facial features now point in the same direction. Arc reach/cone now match the existing hit rules, with the unchanged cone value moved into validated balance data.
- Restore initialises aim from the saved facing, avoiding a snap to the default direction on resuming. The save schema remains 3; no actor fields or migration changes are needed.
- All 27 scenarios pass, including keyboard facing with a conflicting cursor, stopped facing, mouse/keyboard switching, zero cursor offset, four-direction hit selection, swing lock and restored facing. Parse and editor/import checks pass.
- Ran `Run.ps1` with `tools/capture_aim.gd`, injecting actual keyboard/mouse input events through Godot and asserting each swing direction. Inspected 1280x720 `attack_up.png`, `attack_down.png`, `attack_left.png` and `attack_right.png`. Refreshed the regular capture tour after the artwork/control-text change. This is automated windowed input and visual verification, not a new human playtest.


## 28 October 2026: independent survivor assignments

The user reports that after recruiting Paige, work commands are still hardcoded to Mara. They want to order Mara to garden and Paige to work at the workshop while personally guarding the entrance.

- F now opens the paused team menu. Each recruited survivor has a named selector alongside health, equipment and activity. Garden, Workshop, individual Follow/Hold/Engage/Home, and relevant road work/guard posts are supported. Selecting one survivor's order does not change the other. Keys 1-4 remain explicit whole-team overrides. The live HUD stays sparse.
- Every actor stores a job target; simulation no longer uses one global Mara site or road-job slot. Either survivor routes to either facility or an approved road job. Different sites advance concurrently, while multiple contributors at one site still give only one work rate. Approve projects with E first: assignments never create work or spend supplies.
- Garden is a persistent build-and-tend role. Completed beds only advance their safe harvest clock while a living gardener is present or the player holds R nearby. An unattended garden pauses without losing partial harvest time. Workshop is a persistent role that finishes approved bench/armour work and then waits at the bench; it never approves another recipe itself. Legacy one-off Build orders still return home on completion.
- Workers retain roles through danger/sheltering, blocked gates, reassignment and save/load. Finishing a road task only releases workers assigned to that road. UI choices reject unrecruited/downed people and unapproved jobs. A few legacy scenario entry points delegate to named orders; live controls have no Mara-only work path.
- Save schema 4 stores individual job targets. Validated migration from schemas 1-3 maps old construction/road assignments to the correct actor and preserves resources, labour, equipment and actors. Invalid targets are rejected; toolkit backup/staged-write behavior is unchanged.
- All 34 headless scenarios pass. Seven new checks cover simultaneous physical garden/workshop work while the player guards; shared-site labour/untended production; independent orders through reload and invalid job fields; Paige doing road work while Mara gardens; unapproved/downed assignment refusal; threat isolation and swapping roles without repeated costs; and migration of legacy schema-3 workshop/road orders. Existing combat, territory, saves and guard checks still pass.
- Parse and headless editor/import checks pass. Ran `Run.ps1` with `tools/capture_tasks.gd`, exercised the connected order selectors and asserted both site progress values. Inspected `team_orders.png`, `team_working.png` and `team_choices.png` at 1280x720, then refreshed the regular capture tour. These fixtures use cleared occupants and accelerated simulation; they establish scripted UI/visual evidence, not human usability or playtest acceptance.
- General construction queues, hauling, safe road corridor accounting and full milestone acceptance remain open. No toolkit edits, installs, exports, deployment or publication were added.


## 28 October 2026: fight for every property

### Human feedback and implemented response

The user says the slice is going well but zombies are not threatening. They request more zombies, more raids and more attack directions so territory gains feel like an actual fight. No human balance acceptance is implied for the changes below.

- Increased resident populations from 3/3/4 to 7/7/10 in garden/library/garage. Original resident ids remain stable for save compatibility. Extra residents occupy authored walkable yard positions; clearing and claiming still require fighting actual occupants.
- Replaced the single three-zombie approach with recurring, deterministic migrations. The first enters at 45 active seconds. A 12-second directional radio warning and temporary countdown use the existing sparse HUD. Patterns cycle east; west; north + east; south + west; all four edges. The north/south alleys are now visually marked.
- Waves have 4 zombies plus 2 per extra claimed property, capped at 10. Intervals are 65 seconds minus 8 per extra property: 41 at full ownership (configured floor 40). The 36-living-zombie cap includes residents; arrivals beyond the available budget are skipped. Defeated migrants are pruned on subsequent arrivals so saves and actor storage remain bounded. Cleared residents never respawn.
- Migrants physically enter at the map edges and target the nearest claimed entrance, exposing newly acquired ground. Nearby people can divert them. Alley groups join the road before choosing a crossing. Physical barricades intercept them; gates can be breached. Street alerts also cover zombies inside claimed yards. A clear home gate no longer announces that all routine work can resume.
- Balance, population, edge routes, formations and cadence are validated JSON content. The simulation owns all timing; pause stops the clock. Save schema 5 records the wave clock, warning, destination and alley travel phase. Schemas 1â€“4 migrate while preserving claims, resources, people, work and legacy attackers. Claimed yards stay clear; unclaimed yards gain the new residents. Older runs get 65 active seconds of preparation before recurring pressure.

### Verification and limits

- All 42 headless scenarios pass: 34 existing checks and eight new pressure checks for resident counts/occupied claims, warnings and all four entry routes, territory scaling/targets, 80 scheduled arrivals under the population/storage cap, deterministic mid-warning reload and malformed-state refusal, a real old-layout schema-4 migration with legacy attackers, physical alley travel to both frontier barricades, and malformed pressure content. The existing command-driven garden fight still finishes without defeat, and Mara still holds the opening home-only approach. These establish functional constraints, not the desired human difficulty.
- Godot 4.7.2 parse and headless editor/import checks pass. New captures run through `Run.ps1` and the shared capture runner at 1280x720: `occupied_garden.png`, `raid_warning.png`, `raid_crossfire.png`. Inspected the increased yard population, sparse countdown/directional warning and simultaneous alley/street attack presentation. Fixtures clear and claim properties and advance the wave clock; attackers then travel through actual simulation. Refreshed the standard ten-state capture tour too; its facility and road-building fixtures defer raids so the armour example still completes, with an explicit equipment assertion. These are staged visual checks, not human playtesting.
- Recurring pressure is now implemented. Noise-driven migration, safe-corridor accounting, territory loss/recovery and a campaign ending remain open. No audio/device/browser/export checks, performance benchmark, toolkit changes, installation, deployment or publication were performed. Cadence and crowd/combat feel still need human playtesting.


## 28 October 2026: quieter streets and unspoiled discoveries

The user requests substantially less text on screen: remove CONNECTED, zombie counts and building-content labels, and keep Paige unknown until her rescue.

- Removed map property titles, CONNECTED/clear/count labels, reward previews, street/alley captions, the street slogan, gate numbers and permanent garden/workshop captions. Flags, boarded/lit windows, crops, equipment and progress/health bars carry the world feedback. Nearby action/cost prompts remain; porch and road E markers appear only within interaction range. Survivor names remain, but the redundant You label is gone. Raid messages retain directions without exact attacker counts.
- Unsearched porches offer a generic search/secure action without revealing loot or people. Garden/workshop order choices appear only after claiming their property. The pause introduction and objectives no longer advertise undiscovered contents or Paige. Workshop prompts, completion messages and failed fitting attempts also keep her identity hidden if the armour is restored before the library is searched. The actual rescue still reveals and recruits her normally; no save schema or combat/balance changes.
- All 42 simulation scenarios and the parse/import checks pass. The new windowed discovery tour asserts that opening/pause labels, local prompts and messages do not name Paige before rescue, including the armour-before-rescue route; it verifies that searching reveals and recruits her. Inspected `library_unsearched.png`, `armour_before_rescue.png` and `library_rescue.png` at 1280x720. Refreshed the standard and pressure capture tours and inspected their quieter presentation. Fixtures clear enemies and accelerate work; these are automated/staged checks, not human playtesting.
- No toolkit changes, installations, exports, device/audio checks, deployment or publication. The revised presentation and discovery experience still need human review.


## 28 October 2026: zombies retake undefended properties

The user reports that zombies cannot reclaim territory and requests rapid loss when no player or survivor protects a building and no added security stops entry.

- Claimed yards, including home, now fall after eight active seconds of living zombie occupation without a standing friendly actor inside. Absence alone never causes loss. Closed gates and built road barricades physically delay entry; zombies must breach or walk through an opening. Living defenders or removal of the last occupant reset occupation. Downed people do not protect control.
- A brief overrun warning and draining porch bar precede loss. Lost properties lower their flags and return to dark/boarded windows. Pause objectives direct recovery; home loss shows in the compact HUD. Clear occupants and press E at the porch to reclaim. Existing work, improvements, equipment, surviving barricades, rescued survivors and discoveries persist; resources and rescues cannot be farmed by recapturing. Lost or home-disconnected facilities pause.
- Save schema 6 separates permanent discoveries from present ownership and stores occupation progress. Schemas 1â€“5 migrate without changing supplies or discoveries. Saves accept lost home, built facilities and surviving road defences on lost ground, plus migrant targets whose properties fell.
- All 48 headless scenarios pass, including six new occupation checks: entry versus outside threats, living/downed defenders, warning interruption, partial-occupation reload, unique reward/work preservation on recapture, lost-home recovery, schema-5 migration/malformed occupation, physical gate breach and takeover, and surviving defence/raid target persistence. Parse and headless editor/import checks pass.
- Ran the windowed toolkit capture runner through Run.ps1 at 1280x720 and inspected property_overrun.png, property_lost.png and property_reclaimed.png. These are staged fixtures demonstrating warning, loss and restored ownership, not human playtesting or balance acceptance. No audio/device/export checks, toolkit edits, deployment or publication. Safe road corridor modelling and broader campaign territory behaviour remain open.


## 28 October 2026: aimless shamblers and single-target melee

The user reports that occupiers stop after taking a property and asks for all zombies to roam randomly without a clear goal. They also report that melee is too strong and request one zombie hit per player attack, with stronger weapon coverage left for future equipment.

- Residents, migrants and occupiers now use the same independent random wandering. Each selects a heading for 0.8â€“2.8 active seconds and picks again when obstructed. Zombies no longer pursue people, path to entrances, travel toward an alley junction or rally at porches. They can wander through open gates and away from lost yards. Contact bites and bump damage against gates/road barricades remain; physical walls, territory occupation and survivor defence still apply.
- Each basic melee swing selects the nearest living target passing reach, forward-cone and clear-line checks. Damage, stagger and knockback affect that zombie alone, including basic survivor melee. A swing never spills into another target after a kill. Damage and cadence are unchanged; no future weapon upgrade is implemented.
- The simulation owns a seeded RandomNumberGenerator. Schema 7 stores its full integer state as text to avoid JSON precision loss, plus heading/turn clocks. Schemas 1â€“6 migrate while preserving actors, occupation, equipment, resources and work. Existing migrant destination/lane metadata may remain in older actors but does not direct movement. Unused pursuit/alley travel tuning was removed from the active catalog.
- All 54 scenarios pass. Six new scenarios cover nearest single-target hits/cooldown/knockback, fence obstruction, continued movement and multiple headings after territory loss, identical motion despite nearby people, mid-wander JSON reload with preserved RNG sequence (small floating clock rounding tolerance), schema-6 migration and malformed wandering data. Earlier directed-raid checks now exercise local guards, staged collision headings/breach, and actual random alley arrivals; they no longer assert purposeful attacks. The command-driven garden check now seeks scattered occupants and returns to the porch rather than waiting for zombies to pursue. Existing armour, task, save-backup and territory checks pass.
- Godot 4.7.2 parse and headless editor/import checks pass. Ran Run.ps1 with the toolkit capture runner at 1280x720. Inspected wander_occupation.png and wander_dispersed.png across six seconds of real windowed simulation after staged loss, plus single_target_swing.png with an assertion that one shambler was damaged. Refreshed the standard capture tour. These are scripted visual/motion checks, not human playtesting or acceptance of the new difficulty. No audio/device/export checks, toolkit edits, installations, deployment or publication.


## 28 October 2026: physical neighbourhood passages

Implementation:
- Both northern yards and both southern yards can be joined by approved fenced passages (4 materials, 6 seconds). Player and named-worker labour shares progress. Completion explicitly opens the existing side fences and adds physical rails and a closable gate. Blueprints leave fences intact; cancellation refunds unused materials. Gate occupancy, breach and committed repair survive save/load.
- Safe home connectivity is now distinct from ownership adjacency. Protected street crossings need both end barricades, usable yard gates and a clear corridor. Passage links need held endpoints and an open intact gate. Alternate routes work around a lost corner; losing home or every valid route pauses garden delivery without erasing harvest progress. Local construction can still proceed before a protected connection exists.
- Pause lists known route conditions without revealing unsearched rewards. Passage work appears in individual orders. Movement now checks actor width before using a straight route, avoiding a fence-rail corner trap.
- Schema 8 migrates schemas 1â€“7 with empty passage construction; existing progress and resources remain. The shared toolkit is unchanged.

Evidence:
- All 60 headless scenarios pass, including six new passage/connection scenarios: cost/handoff/cancel/reload, real actor traversal and flank collision, crossing boundary/gate/hostile conditions, alternate routes and production pause/resume, occupancy/breach/repair, and migration/malformed data.
- Ran Run.ps1 with capture_neighbourhood.gd at 1280x720 and inspected yard_passage.png and neighbourhood_routes.png. These are staged visual checks, not human playtesting.

Remaining goal: equipment choices, useful food upkeep and the slice completion objective, plus the integrated verification/playtest handoff. General job queues, freeform building and full-town maps remain outside this step.


## 28 October 2026: choose and transfer recovered equipment

Implementation:
- F/pause now offers loadouts for the protagonist and every recruited survivor once the workshop is restored. Bring the player and wearer to the connected, clear bench. Unique items must be returned to storage before another wearer takes them. Invalid, remote, downed and unsafe changes preserve ownership. Equipping never heals or spends supplies.
- The garage supplies one crowbar; restoring its cache also restores one sword alongside the existing iron and shield. The bat remains the baseline. Crowbar: 50 damage, 82 reach, 0.85-second recovery, one target. Sword: 35 damage, 88 reach, 0.65-second recovery, up to two valid targets. Bat remains 30/76/0.48/one target. These initial values are validated content, not balance acceptance.
- Iron and shield are independent choices for anyone. Iron halves damage and slows movement to 80%; shields halve frontal damage. Visible weapon silhouettes, iron and shields follow their actual wearer. Paige's original nearby E fitting remains a convenience when both pieces are stored.
- Schema 9 migrates prior saves, assigning previously fitted armour/shield to Paige without generating extra items. Pause content scrolls rather than running outside the viewport.

Evidence:
- All 65 scenarios pass. Five new checks cover unique transfers and reload, refused changes, actual weapon target/damage/cadence differences, player/Mara protection and movement, and migration/malformed ownership.
- Ran Run.ps1 with capture_equipment.gd at 1280x720; its connected selectors issued loadout commands and assertions checked ownership. Inspected equipment_choices.png and shared_equipment.png. These are staged UI/visual checks, not human input or balance review.


## 28 October 2026: shared meals and recovery supplies

Implementation:
- One community meal every 60 active seconds consumes one food per person (two initially, three after rescue). Search caches contain food once; recapture never repeats them. Pause/loading consume no time.
- A missed meal slows construction, repairs, restoration and gardening to 60%, without hunger damage or death. A low-food warning precedes shortage. Enough new food pays one shared meal, restores normal work and restarts the clock; missed meals never become accumulating debt.
- Home recovery costs two food only when someone needs healing. Unsafe/insufficient attempts change nothing; repeated rest while healthy costs nothing. Garden delivery still needs a safe physical connection and records actual harvested portions for the coming slice objective.
- Schema 10 preserves meal timing, shortage/warning state and harvested food. Older saves keep their stock and start a fresh meal interval without retroactive cache rewards.

Evidence:
- All 70 scenarios pass; five new checks cover roster meal costs/no hunger injury, slowed actual workshop work and garden recovery, transactional recovery, unique caches and mid-meal reload, plus migration/malformed clocks.
- Ran Run.ps1 with capture_provisions.gd at 1280x720 and inspected food_shortage.png and food_recovery.png. Staged pause/recovery UI, not human balance acceptance.


## 28 October 2026: a street worth keeping, ready for user testing

Implementation:
- Added a clear slice objective: reclaim and clear all four yards, physically connect each to home, deliver four garden food, restore the equipment cache, deploy a recovered weapon/iron/shield, keep everyone standing and reserve a shared meal. Begin the neighbourhood watch from pause at the home porch, then maintain readiness for 60 active seconds. Loss, unsafe connectivity, a downed person, protagonist defeat or inadequate food resets the watch until readiness returns. Completion pauses with a visible Continue button; continued play preserves the earned finish.
- Added finite visible timber piles (Q near each secured non-home porch, ten materials once). This leaves original claim rewards unchanged and gives migrated saves the same new supply opportunity. A command-driven construction-economy scenario builds both passages, all four road barricades, garden/workshop/cache and repairs home using authored supplies, finishing with five materials. Its enemies are cleared and first raid delayed to isolate economy; this does not prove difficulty or a complete human-input run.
- Productive garden/workshop workers use an area-constrained route through the actual home-connected yards and clear protected corridors. A longer safe route wins over a short exposed street. Disconnection pauses production and reports its cause; local initial construction remains possible before integration. Armour restoration also requires the protected home route. Every property gate can now be rebuilt, with one saved repair commitment; player labour cannot simultaneously repair a gate and work a porch facility.
- Schema 11 preserves timber, objective phase/clock, last defeat count and gate repair target. Schemas 1â€“10 migrate without changing supplies or granting completed objectives. No publication, toolkit changes or installations.

Evidence:
- All 77 simulation scenarios pass. Five slice checks cover prerequisites/spoiler protection, setback resets, partial-watch reload/one-time completion, full construction accounting and old-save/malformed-state handling. Two additional neighbourhood checks prove a worker physically takes the longer protected route and a non-home gate repair resumes after reload without extra cost.
- All 55 project/tool scripts load; the Godot 4.7.2 headless editor/import check passes. File/function size limits pass.
- Ran Run.ps1 at 1280x720 with capture_slice.gd. Its actual watch button starts the objective, the process opens the completion screen, and Continue resumes without losing completion. Inspected neighbourhood_watch.png and slice_complete.png. Refreshed the standard ten-state tour, discovery tour and equipment tour and inspected the updated pause, equipment, armour and spoiler-free pre-rescue states.
- These are automated simulation and staged windowed UI/visual checks. The construction fixture uses enemy clearance and delayed raids; the completion capture stages the final fraction of its watch. Human playtesting of these four additions, full-run difficulty, exports/browser/device/audio and performance benchmarking remain unverified.

The requested implementation is ready for another user test. docs/09-mvp-roadmap.md records the suggested test route and feedback points. The larger campaign, interiors, firearm/audio and general job/recipe systems remain outside this completed slice step.


## 28 October 2026: nearby people override wandering

The user clarifies that zombies should wander only until someone is nearby, then head toward that person with priority over wandering. This supersedes the earlier rule that people never redirect movement.

Implementation:
- Every living zombie selects the nearest standing player or survivor within a validated, content-owned 240-pixel notice range each step. That person immediately overrides the current random heading. Downed people are ignored; wandering resumes when nobody is in range. Existing bite/stagger recovery still applies.
- Pursuit heads directly toward the person using the same physical movement and defence-bump rules as wandering. It cannot cross solid fences, gates or barricades, and only bites within clear contact reach. Zombies can damage blocking defences. No noise investigation, remembered targets or route finding was added.
- Awareness is derived from current positions, so save schema 11 and the existing saved wander/RNG state remain unchanged. Current movement documentation now reflects this clarification.

Evidence:
- All 80 simulation scenarios pass. Replaced the previous no-pursuit assertion with immediate heading override/nearest living target coverage, and added range exit/resumed wandering, closed-gate damage/open-gate contact bites/cooldown, and invalid awareness-content checks. The garden command scenario now brings Mara and actively clears attracted threats around the worksite before completing construction; no enemy removal or balance reduction is used.
- All 56 scripts load; Godot 4.7.2 headless editor/import and file/function size checks pass.
- Ran Run.ps1 with capture_pursuit.gd through the toolkit runner at 1280x720 and inspected pursuit_spotted.png and pursuit_approach.png. The staged zombie initially faces away, then advances toward the stationary player during two seconds of windowed simulation, with an assertion checking its movement and facing.
- These are automated and staged windowed checks. Human input, combat feel and balance acceptance remain unverified. No installation, toolkit edits, exports, deployment or publication.



## 28 October 2026: project review (structure, toolkit, size, code)

A cleanup pass before further work. No gameplay behaviour was changed. This section records findings; open follow-ups are in [TODO.md](TODO.md).

### Size limits

- Largest files: `scripts/sim/world.gd` 365 lines, `scripts/core/save_state.gd` 337, `data/street.json` 322, `tools/checks/checks_street.gd` 269, `docs/PROGRESS.md` about 270. No script, scene, data or doc file approaches 800 lines and no function approaches 400.
- `world.gd` and `save_state.gd` are the files to watch; both are the hub for every new system. Split them before they pass about 600 lines (see TODO).

### Structure against the shared standard

- Matches: `AGENTS.md` and `README.md` are the only root markdown; `.editorconfig`, `.gitattributes`, `Run.ps1`, `publish.ps1` and `publish-itch.ps1` are identical to `godot_toolkit/templates/`; `addons/hatchery` is an ignored junction and `Sync-Project.ps1 -DryRun` reports it already linked; `docs/`, `docs/verification/` and `tools/` carry `.gdignore`; verification images are flat `<label>.png`; there is no `tests/` directory; checks are headless scripts under `tools/`.
- `.gitignore` differs from the toolkit template only by the local-probe note and the `addons/hatchery/` entry.
- Intentional gaps: no `publish.json`, `export_presets.cfg` or `assets/` (procedural greybox art, no destination chosen). The publish wrappers cannot run until `publish.json` exists.
- Deviation: design docs are numbered `01` to `12` rather than a single `GAME_DESIGN.md`. Kept, since the README links to each.

### Toolkit use

Used: `JsonIO`, `DataRules`, `JsonSave` (staged writes, backup recovery, migration hook), `Palette`, `UiKit`, and the parse, check and capture runners (all captures land in `docs/verification/`). Not used, and candidates when the matching feature arrives: `Balance`/`DotTable` (balance is a hand-read dictionary), `TextCatalog` (player-facing strings are hard-coded in GDScript), `KeyBindings`/`SettingsStore`/`SettingsPanel` (inputs are fixed in `project.godot`, and the number keys and Space are polled by key code), `Shapes` (the 70 `draw_*` calls in `town_view.gd`), `ScreenSwitcher`/`Focus` (the menu is one overlay). None is a defect today.

### Code findings

- Simulation purity holds: no `randi`, `randf`, `Time` or `OS` in `scripts/sim` or `scripts/core`. Wandering uses the owned `roam_rng`, whose state is saved. `OS` appears once in presentation (the `--no-save` flag).
- Hard-coded values that belong in `data/street.json`: the garage bonus of 12 materials and the 0.65 starting home-gate health factor (`world.gd`), the home alert radius and centre, player and Mara start positions, and prompt text that restates costs ("3 materials", "8 materials") and will drift from `gate_repair_cost` and `garden_cost`.
- `assign_mara()` is a compatibility entry point for old scenarios; live controls do not use it.
- `save_state.gd` repeats the deep-copy key list in `snapshot` and `restore` and writes the schema number 11 in two places. A single constant would prevent drift when schema 12 lands. Migration of schemas 1 to 10 is one chain that will keep growing.
- Actor and state dictionaries are typed only at their signatures, not their fields. A typed actor class would help but is a large change.
- Documentation: mojibake in the README, `PROGRESS.md`, `07` and `11` was repaired, unresolvable `chatgpt-conversation://` links were removed, and stale statements in `10`, `12` and the first-playable section of this file were marked. The README still mixes controls, rule explanations and release-note prose (see TODO).

### Verification of this pass

Static review and file measurement only. The parse, simulation and editor checks were not re-run for this documentation-only change; the latest recorded results are in the preceding section.


## 28 October 2026: review fixes

- Moved the garage bonus, home gate starting factor, player/Mara start, home respawn and home alert centre/radius into validated `balance` content in `data/street.json`. Guard anchors and shelter positions now read the same values. Cost prompts for the garden and gate rebuild read balance instead of repeating numbers.
- `save_state.gd` now has `SCHEMA` and `COPIED_KEYS` constants in place of repeated literals. Save format is unchanged (schema 11).
- All 80 scenarios pass, all 56 scripts load and the headless editor check reports no errors. No gameplay values changed; windowed captures were not re-run.


## 28 October 2026: eastern buildings, Ellis's pistol and bullet crafting

Implementation:
- Extended the continuous street east to six properties: an east house beyond the garden and an ammunition workshop beyond the garage, with solid buildings, gates, resident zombies, connected claims, unique loot and occupation/loss. Two additional fenced passage projects connect the new yards to the previous block. Camera and road rendering follow the larger authored bounds. The raid east origin moves to the new map edge; the living cap is 48, allowing old streets near their former cap of 36 to receive seven new residents without losing actors.
- Claiming the cleared east house rescues Ellis once and hands the protagonist a pistol with exactly six bullets. Ellis never attacks, refuses individual Engage/home/road guard assignments, is skipped by G, and cannot receive guard duty through whole-team orders or automatic job completion/cancellation. Ellis follows, holds, works and attempts shelter from nearby danger; blocked shelter routes are reported as sheltering. Protective gear remains available, weapons cannot be assigned.
- Right click shoots toward the mouse; left click and Space retain melee. One bullet per successful discharge, including misses; 90 damage, 620 range, 0.65-second cooldown, nearest target along the shot. Solid fences/buildings/closed gates block fire; low road barriers permit shooting over them. Tracer/muzzle feedback and a bullet count appear. Empty shots spend nothing and leave melee available. Values are validated in data/street/firearm.json; no audio, noise investigation or magazine/reload system.
- Claiming the ammunition workshop directly unlocks Craft bullets in F for any survivor. Workers physically route to its porch. Each shared batch reserves two materials once, then produces six bullets over 15 work seconds. Hunger slows work. No worker, local danger, lost ownership connectivity or a lost workshop pauses production; shortages prevent the next batch. Assignment changes, losses and saving preserve committed materials and partial progress. Player R is not a bullet-crafting command.
- Save schema 12 migrates earlier versions, adding unclaimed sites, resident zombies and empty new passages without changing old actors, supplies or an earned finish. Gun ownership, bullets and partial crafting persist. Survivor validation accepts either rescue order. The original four-yard watch objective remains the same; the new properties are additional progression.

Evidence:
- All 91 simulation scenarios pass, including seven new firearm/expansion scenarios: actual porch rescue and unique handoff; shot targeting/misses/cooldown/empty ammo; range and closed/open gates; noncombatant order paths/no attacks/shelter/G; physical worker arrival/shared production; danger/loss/material shortage and mid-batch JSON reload; and a four-property schema-11 fixture plus malformed firearm content/state rejection. Existing population checks now use the content-owned cap, and old four-yard construction fixtures explicitly retain their original scope.
- All 63 project/tool scripts load; Godot 4.7.2 headless editor/import completes without errors. File and function size limits and git diff whitespace checks pass.
- Ran Run.ps1 with capture_firearms.gd at 1280x720 through the toolkit runner. The scripted real mouse-input path fires right click and asserts damage and ammo; the connected F selector issues the crafting order and asserts Ellis's disabled guard/engage choices. Inspected east_house_rescue.png, pistol_shot.png, bullet_workshop.png and bullet_orders.png. These are staged windowed input/UI/visual checks, not human playtesting or full-run balance acceptance.
- No toolkit changes, installations, exports, deployment or publication. Human combat feel, full expanded-street difficulty and save compatibility with a real user run remain unverified beyond the automated fixtures.


## 28 October 2026: full game design expansion (documentation only)

User direction: the slice is working well; spend one hour expanding game design documentation into a build reference, including more zombies, buildings and survivors, and make design decisions along the way. This is positive user feedback about the slice, not evidence that the full game exists.

Design work:
- Replaced the earlier open-ended proposals with a coherent full game specification: 24 authored properties in four districts, 18 core/six optional sites, seven named survivors plus the protagonist, eight zombie kinds and a finite relief-signal ending. Target core first run is 2â€“3 hours; optional exploration adds time without mandatory padding.
- Kept the original six property IDs, Mara at home, Paige's garage armour route, Ellis's no-combat/no-guard capability, pistol/six-bullet gift, bullet-workshop unlock and optional original slice watch. Defined future migration boundaries without claiming a save schema change.
- Added complete campaign/topology, zombie, property, equipment/recipe and acceptance/balance catalogues (13â€“17). Each new zombie has a tell, counter, attack phases, limits and persistence requirements; every property has finite rewards, encounter composition and purpose.
- Resolved roster, food/resources, direct shared-stock logistics, safe production, jobs/refunds/reserves, recovery, noise, pressure templates, interiors, art/input/accessibility and ending/retry/continuation. Roadmap G01â€“G10 sequences implementation and evidence gates.
- Updated the reading map and immediate work queue. Current runtime behaviour is still the six-property slice described in README; no game code/data, original art, captures, toolkit or project settings changed.

Documentation verification is recorded in the follow-up audit entry. No Godot parse/simulation/editor runs, visual captures, human playtest, audio, performance, export, deployment or publication is claimed for this documentation change. Existing game evidence remains in the preceding implementation entries.


### Documentation audit: initial complete specification

- Read-only checks pass for local Markdown links, table column counts, 24 property IDs, 18 core sites, 12 map columns, a continuous core northern route, 34 parcel links and the 89-resident manifest.
- Recomputed core finite supply: 272 searched Materials + 102 first-claim + 30 timber + 18 starting = 422. The worked preparation plan spends 361 and leaves 61, including the required 12-Material launch reserve. Core finite Food/Bullets/Shells/Medicine are 61/48/8/22 before starting stock/production.
- All tracked/unignored GDScript, scene, JSON and Markdown files remain below 800 lines; measured largest file is world.gd at 386. Largest detected top-level function span is 83 lines. Markdown tables and git diff whitespace checks pass.
- Review corrected the Market-stage subtotal to 20 Materials and removed a provisional optional-building route dependency. No runtime verification was run for these documentation changes.


### Documentation audit: finale and hostile intent

- A consistency review found that ordinary raider quota/exiting behaviour could let finale migrants leave a fully held town. Finale actors now retain explicit physical approaches and relay/power/assembly targets while preserving nearby-person priority.
- Clarified three physically present recruited launch guards (the player is at the console), the third wave's exact south/east split, 31 scheduled actors/threat cost 51, world-time outage grace versus watch-time events, cumulative grace through brief reconnects, explicit abort and all-attempt-enemies-defeated completion.
- Defined fixture damage/repair, settlement quotas and shared pool-damage cooldowns; confirmed an unavailable pre-attempt recovery save does not permanently prevent an explicit launch. These are documentation fixes, not newly implemented runtime features.


### Documentation audit: final geometry, funding and recovery pass

- Inspected current roads.json: home_east is at x=640 and garden_west at x=800. The 160-pixel alley makes them independent barriers, not one shared boundary. The final design preserves the four existing IDs/geometries and uses 24 separate road sockets, 22 yard passages and 34 parcel links. Finale alley posts have safe-side access clear of passage rails.
- Recomputed the core plan with twelve road barriers: 393 Materials spent from 422, leaving 29 (12 launch reserve plus 17 margin). All three Hearth crossings are funded before safe bullet crafting; stage balances remain nonnegative. This supersedes the earlier 361/61 shared-boundary calculation above.
- Preserved the protagonist's actual `you` ID and separated search/first-claim/timber flags for future migrations. Spitter notice now matches its range. Mere distant scouting no longer advances pressure bands. Radio/assembly operation and assembly destruction are explicit finale conditions.
- Raised emergency salvage's combined cap to 24 while no salvage yard operates: it can restore the sixteen-Material bench even after every finite cache is spent. A twelve-Material cap would have left that recovery path blocked. The future acceptance matrix includes this case; no gameplay scenario is claimed to have run.
- Final read-only checks pass: links/table structure for all 20 Markdown files; 24 sites/18 core connected without optional sites; 89 residents; eight kind costs and 19 routine threat templates; fixed finale 31 actors/cost 51; funding arithmetic; UTF-8/LF/final newline and size limits; git diff whitespace. All 20 changed paths since the starting commit are Markdown only.
- Three documentation slices are committed. The work stays within the requested documentation hour; no runtime/data/art/toolkit change, engine verification, installation, export or publication is included.


## 28 October 2026: one more survivor and a usable vehicle (design only)

- User requested one more character and a vehicle if absent. The existing design had seven companions and static firehall scenery, with driveable vehicles excluded. Added Rowan, a community-centre caretaker rescued at the core assembly yard; full roster is now eight companions plus the protagonist. Existing rescue/role rules apply, without a profession lock or extra follower slot.
- Added one optional recoverable depot utility van and its owning document, 18: restoration, two passengers, continuous driving/collision, noise, boarding/exits, hull damage, casualty recovery, repair, workshop retrieval and persistence. Replaced the blanket vehicle exclusion with this bounded exception. No fuel economy, hauling or mandatory vehicle gate.
- Updated roster/readiness/staffing, recipe, roadmap and acceptance owners. Nine people cost 4.5 Food/minute; pre-pump production at 70% uptime leaves only 0.17/minute above meals. Two finale meals now require 18 Food. The optional van costs 12 Materials outside the unchanged core plan; spending it from the 29-Material margin leaves 17.
- Documentation verification: local links, Markdown table structure, cross-document roster counts, food/material arithmetic, file sizes and whitespace checked. No runtime/data/art changes, engine checks, captures or human playtesting; these additions remain future design.


## 28 October 2026: G01 shared work ledger, first integration

Implementation:
- Added simulation-owned prepaid work records with stable sequence IDs, one executor lease per socket, block reasons, committed input/output bundles, progress and terminal completion/cancellation/destruction guards. Bullet production now uses this ledger; other construction still uses its original records and is the next G01 work.
- Schema 13 migrates schema-12 partial bullet batches without another debit. Earlier migration chains remain supported. JSON numeric fields are normalised when restored so deterministic simulation snapshots stay identical.
- No new live UI text. The existing workshop meter reads authoritative ledger progress.

Evidence:
- All 96 simulation scenarios pass, including five new migration, conservation, lease/handoff, terminal replay and malformed-ledger scenarios. All 66 scripts load; Godot 4.7.2 headless editor/import passes. File sizes and whitespace pass.
- Ran the four-state firearm capture tour at 1280x720; inspected bullet_workshop.png. The tour exercises real right-click shooting and the connected survivor assignment selector. These are staged checks, not human playtesting.
- Full G01, campaign expansion, balance, audio, performance and release verification remain outstanding. No installation, toolkit changes, export or publication.


## 28 October 2026: sparse street interface

Implementation:
- Replaced the large HEALTH/HOME SAFE/BULLETS banner with a compact health symbol/bar and a bullet icon/count only after pistol discovery. Safe status is silent; threatened/lost property, attacked defences and incoming raids still show actionable text. Pause access is one small icon with an Esc tooltip.
- Shortened nearby gate/workshop/garden/passage/barricade prompts to action, key and transaction cost/return. Removed repeated tutorials and percentages already shown by work bars. Undamaged gates do not advertise repair, and a healthy team does not advertise recovery. Nearby survivors retain their names; distant names no longer float over the world.
- Explanations, stock and full team/loadout controls remain paused. Brief notifications wrap within a bounded area; assignments issued while paused do not replay as live banners.

Evidence:
- All 96 simulation scenarios and all 67 script loads pass; headless Godot editor/import passes. No combat or economy values changed.
- Refreshed the standard ten-state tour and four firearm states at 1280x720. Inspected home, street_attack, bullet_workshop and planning; recaptured and inspected home after removing unnecessary full-health recovery text. Verified the existing staged shooting and assignment input tour.
- Captures are staged, not human usability/playtesting acceptance. Remaining paused-screen simplification, full-game implementation and accessibility settings are future work.


## 28 October 2026: G01 bounded production and focused pause pages

Implementation:
- Bullet bench now starts only after explicit one-batch/repeat choice, stops at a chosen stock target and keeps a configurable Materials reserve (default six). Stopping/lowering target never discards an already committed batch. Cancellation shows and pays its exact remaining return once. Discovery does not enable automatic spending.
- Productive bullet workers now require and physically use the protected home-route network, consistent with the full-game facility contract. Lost routes/danger preserve bundles; the paused production page reports the block. The older bullet fixture now stages completed protected routes explicitly, and the physical-arrival scenario starts in a connected yard rather than on the exposed east road.
- Paused Street, Team, Work, Loadouts, Town and Help pages replace the single long information column. F selects Team; J selects discovered bullet Work. Work exposes available stock, committed inputs, pending output and one relevant block. The live HUD receives no extra text.
- Save schema 14 adds policy/targets/reserve. Schema 13 and earlier retain partial work/stocks; an existing Ammo assignment becomes bounded repeat-to-24. No completed facility is rebilled.

Evidence:
- All 101 simulation scenarios pass. Five production cases cover once/repeat/resume, mid-batch target/stop, reserve/spend/cancellation, unsafe-route reload/resume, discovery and schema-13 migration/invalid policies. Schema-12 partial-batch and lower historical fixtures still pass.
- All 71 scripts load; Godot 4.7.2 headless editor/import passes. Windowed production capture exercises the connected mode/target controls and asserts stopped output at target. Inspected work_board.png, work_target_met.png and the simplified planning.png at 1280x720. Refreshed firearm and equipment captures for the separated pages.
- This remains staged simulation/input/visual verification, not human balance or usability acceptance. G01 construction/repair migration and primary-role resumption remain incomplete; full campaign and release work remain ahead. No toolkit change, installation, export or publication.


## 28 October 2026: G01 passage orders and occupied-footprint safety

Implementation:
- Passage construction now commits and advances through the shared ledger, with one effective executor, explicit block reasons and once-only completion/cancellation. Its existing passage fields are a validated projection for compatibility; saves reject drift or a missing pending ledger record.
- Player/AI handoff, target loss/reclaim and blocked final work retain the paid bundle. Construction cancellation now follows the full-game 25%-at-full-work loss formula instead of the old production-style refund. Repair is still the legacy implementation and is not claimed migrated here.
- New rails/gates wait for both standing and downed people to clear their footprint; dead zombies do not obstruct construction. A completed work bar cannot produce collision through a downed survivor.
- J/Work is available for approved passages before bullet discovery. It shows only pending known construction, progress, commitment, one block and exact cancellation return. The bullet form remains hidden before discovery. Cancellation is a simulation command.
- Schema 15 creates prepaid records for schema-14 and earlier unfinished passages without charging again. Completed legacy passages remain completed.

Evidence:
- All 106 simulation scenarios pass, including five new passage-ledger cases: player/AI/loss/reload takeover, downed final-tick footprint, exact once-only refund, concurrent sites/shared rate and schema-14 migration/projection rejection.
- All 74 scripts load and the Godot 4.7.2 headless editor/import passes. The windowed work-order tour checks hidden undiscovered bullet UI and the actual cancellation button; inspected passage_work_board.png and passage_work_blocked.png at 1280x720.
- These are staged automated/input/visual checks. Human playtesting, full-game balance and release verification remain outstanding. Next G01 work: remaining construction/restoration, bounded repairs, primary roles/resumption and queue policy. No toolkit edits, installations, exports or publication.


## 28 October 2026: G01 garden and bench restoration orders

Implementation:
- Garden beds, workshop restoration and recovered gear now use prepaid shared orders with stable identities, deterministic player/worker leases, loss/danger blocks, cancellation returns and once-only completion. Their former state fields are validated projections for compatibility.
- The existing paused Work page includes these projects without adding live HUD text or revealing unknown recipes. Cancelling releases invalid worker assignments; completed facilities/gear cannot be cancelled or approved again.
- Added validated data/street/work.json recipe metadata, referencing existing authoritative balance costs/times rather than copying numbers. Its catalogue contains only implemented work. New construction approvals respect the designed eight-pending-project limit and require a standing player at a clear held site.
- Schema 16 maps old unfinished garden/workshop/gear work into prepaid records without spending stock or removing completed improvements. Historical schemas 1â€“15 remain supported.

Evidence:
- All 111 simulation scenarios pass. Five new cases cover all three cancellation paths, loss/reclaim/final completion after reload, prepaid schema-15 migrations, board/remote/downed approval rejection, recipe validation and projection drift. Updated older fixtures that previously invented partial construction without a paid order; completed-fixture staging remains explicit.
- All 77 scripts load and Godot 4.7.2 headless editor/import passes. Ran the work-order capture tour and standard ten-state construction/equipment tour at 1280x720; inspected restoration_work_board.png and the restored workshop/equipment states. The work-board cancellation button is exercised through its connected command.
- Automated/staged evidence does not establish human feel or full-campaign balance. G01 road build/removal, bounded repairs and primary-role/queue resumption remain; full-game content and release gates remain incomplete. No toolkit edits, installations, exports or publication.


## 28 October 2026: G01 road construction and removal orders

Implementation:
- Road builds and removals use the shared ledger and recipe catalogue. Loss, nearby danger or absent workers suspend one paid project with a visible block reason. Player and AI share one site rate; new barriers wait for downed people as well as standing actors.
- Dismantling retains collision until its terminal tick. The return is calculated from current health at completion, so damage during the job reduces salvage. Keeping the barricade pays nothing; breach after keeping or during removal destroys the work without a second return.
- The existing paused Work page shows road progress and removal return, with a single Keep barricade action. No new live HUD fields. Removal is a zero-input explicit order; its time and cost reference validated JSON.
- Schema 17 maps old partial road builds/removals without debiting stock, changing progress or granting salvage. Completed legacy structures stay present.

Evidence:
- All 115 simulation scenarios pass. Four new road cases cover downed footprints/loss, damage and mid-removal JSON reload/once-only salvage, cancelled removal followed by breach, and schema-16 build/removal migration.
- All 78 scripts load; Godot 4.7.2 headless editor/import passes. Ran the work-order and standard ten-state tours at 1280x720; inspected road_removal_board.png and street construction/removal states. The connected Keep button is asserted to preserve the barrier without payment.
- Verification remains staged/automated, not human balance/feel acceptance. Bounded repairs, roles/resumption and queue policy remain G01 work before the full-town expansion. No toolkit edits, installations, exports or publication.


## 28 October 2026: G01 bounded repairs and distinct gate rebuilding

Implementation:
- Property gates, passage gates and road barriers now use prepaid ledger repair batches. New repair commits three Materials for at most 120 health at 24/second; reaching max health discards unused capacity. Further damage needs a new batch, rather than banked repair credit. Lost ownership/contested yards/danger/no worker pause the same bundle.
- A broken property/passage gate instead takes the documented seven-second rebuild: no partial gate health/collision, then full health and initially open. Both gate kinds also refuse to close through downed people.
- Routine AI repair spending respects the configurable Materials reserve and safe home route. A physically defended line below 40% may use the critical-repair reserve exception. Manual R remains explicit spending. Demolition or breach discards attached repair without a second return.
- Paused Work shows remaining repair capacity and exact cancellation return. No extra live HUD fields. Schema 18 migrates every older paid repair with its exact remaining full-gap capacity once; new bounded values never rebill old commitments. Repair validation/migration is in a separate core owner.

Evidence:
- All 122 simulation scenarios pass, including seven new bounded-capacity/no-banking, partial-loss/reload/reclaim, atomic rebuild, AI reserve/critical exception, demolition accounting, schema-17 prepaid migration/flag validation and downed gate-closure cases. The older breach scenario now explicitly reclaims home before starting work, as required by the full-game held-site contract.
- All 82 scripts load; Godot 4.7.2 headless editor/import passes. Ran the standard ten-state tour and repair tour at 1280x720; inspected repair_work_board.png, gate_rebuild_work.png and gate_rebuilt.png. The connected cancel button is checked against its exact one-Material return.
- This is staged automated/input/visual evidence, not human feel, full-game balance or release acceptance. Facility damage/repair belongs to the upcoming facility milestones; G01 roles/resumption and queue policy remain next. No toolkit edits, installations, exports or publication.


## 28 October 2026: G01 persistent duties and approved-work scheduling

Implementation:
- Survivors retain a regular duty while taking temporary passage/road/gate work. Completion and cancellation resume their previous assignment, including through JSON reload. Tactical Follow/Hold/Engage preserve configured work; whole-team Home resumes it. Explicit Guard home still sets guard duty. Ellis keeps the no-combat/no-guard restriction.
- Builder chooses approved reachable projects, preferring critical paid repairs and player priorities, then approval sequence/ID. General worker can take critical/prioritised work, garden work below the meal buffer, or explicitly enabled ammo production. Neither policy approves hidden facilities or spends new construction inputs; guards/followers are excluded from queue selection. Multiple automatic workers avoid choosing the same assigned site.
- The paused Work row has one Priority toggle per target. Team shows a temporary worker's return duty; successful assignment footers and duplicate idle/tactical labels were removed. No live HUD additions. Ordinary roles continue at their selected sites; new temporary gate-repair assignments use the same physical movement/paid capacity.
- Reassignment releases its old executor lease immediately. Work waits five clear active seconds after danger; closed-path retries are bounded at one second. Those clocks pause and persist. Schema 19 migrates previous assignments into explicit duty records without changing work/supplies or the earned watch.

Evidence:
- All 127 simulation scenarios pass. Five new cases cover one-off completion/cancel/reload to a grower, tactical following/return and guard exclusion, priority builder sequencing without charges, immediate lease release/five-second clear timer reload, and schema-18 duty migration/invalid fields.
- All 86 scripts load; Godot 4.7.2 headless editor/import passes. Ran the connected team-selector/priority tour and original team tour at 1280x720. Inspected temporary_duty.png, builder_next_project.png and work_priority.png; the builder physically completes the priority workshop then takes the garden without another approval/debit. Original threat/resume scenario now allows five clear seconds plus the actual return journey from shelter.
- This remains staged automated/input/visual evidence. G01 still needs its final board/field-approval audit; safe automatic maintenance/food-target refinement can expand with the facility/economy owners. Full-town content, human balance and release gates remain incomplete. No toolkit edits, installations, exports or publication.


## 28 October 2026: Ellis's default home return

- New rescues and migrated older default duties send Ellis to the home shelter when the team returns, instead of his rescue porch. Follow remains tactical, an explicitly configured Ammo duty resumes normally, and he never receives guard duty.
- All 128 simulation scenarios pass, including the older-save default-home return and configured-work preservation regression. No visual rules changed; the preceding duty tour remains the staged UI evidence. Human input/feel remains unverified.


## 28 October 2026: explicit field supplies and reserve warnings

- Nearby construction approval now distinguishes protected stock access from an explicit field-supply commitment and warns when the shown cost uses the material reserve. Passage approval rejects downed or remote callers; paused cancellation remains available separately.
- All 129 scenarios pass, all 86 scripts load, and the headless editor/import passes. The work-order capture tour stages and verifies field_supplies.png at 1280x720; inspected the contextual cost/field/reserve line. No persistent HUD counter or confirmation dialogue was added.
- The shared-order foundation now supports the map/content expansion. Work-board location/assignment access will use the known-town overview in G02; routine maintenance and food-target refinements remain with their facility/economy owners. Full-game scope is not complete.


## 28 October 2026: G02 full-town geometry and safe expansion

Implementation:
- The street spans all 24 sites in four districts, with 22 side passages, 12 crossings and 24 independent road-barrier sockets. All 18 core sites connect without requiring the six optional sites. Original six property IDs, rewards, residents and existing structures retain their identities.
- The 18 new sites are explicit development shells: no claim, reward, encounter or hidden facility effects. Walking near a site records discovery for the upcoming known-town overview. Pressure can originate at all district edges while retaining the existing living-zombie cap.
- Schema 20 expands historical saves with untouched new sites while preserving old property state, supplies, actors, RNG, prepaid work and the earned neighbourhood watch. Historical raid route IDs remain valid.
- The renderer culls offscreen drawing; path-grid construction rasterises collision rectangles and clears stale cells when rebuilding. These changes support the larger layout without changing authoritative offscreen simulation.

Evidence:
- All 135 simulation scenarios pass, including full topology/core-only connectivity, actual movement from the west edge to the east works, six-site save expansion, persistent discovery, and every path-grid cell against collision plus removed-barrier recovery. Existing fixture checks retain their original six-site scope.
- All 91 scripts load; Godot 4.7.2 headless editor/import passes. The windowed town tour stages three 1280x720 captures and asserts shell interaction cannot claim or pay rewards. Inspected market_row_shells.png and east_works_shells.png; the live HUD remains health, pause and one nearby prompt.
- Captures and automated traversal are not human playtesting or a full-town performance benchmark. The paused map/board access, new district content, full campaign balance and release acceptance remain unfinished. No toolkit edits, installations, exports or publication.


## 28 October 2026: paused known-town map

- M opens the Town page with only discovered parcels, held-ground shape marks, the player position and actual usable/blocked links. Selecting or keyboard-focusing a seen parcel shows its name, ownership and adjacent known route conditions; unknown sites have no buttons, names or contents. No live HUD fields were added.
- The connected windowed map tour verifies M opens pause, all saved state stays identical across 20 presentation frames, unseen Clinic remains hidden, and map selection never moves the player or changes simulation. Inspected known_town.png and scouted_town.png at 1280x720. All 135 simulation scenarios pass; all 93 scripts load and headless editor/import passes.
- This first overview provides selection and route status. A local preview and board location/assignment are still follow-up work. Human map usability remains unverified; the full game is still in development.


## 28 October 2026: work-board location and temporary assignment

- Each approved non-production work row has Show and a survivor picker. Show opens the paused map at the nearest known parcel and marks the actual work point; it changes no simulation state. Map names omit the old numbered prefixes.
- Board assignment goes through authoritative validation, rejecting downed workers, lost/unsafe sites and completed/unapproved work. It preserves the worker's regular duty and any existing temporary return, never approves or rebills a project, and shares the same resumption helper with automatic scheduling. Pickers refresh only when eligibility changes, so ordinary paused frames do not reset an open choice.
- All 137 scenarios pass, including two new assignment/reload/completion and rejection cases. All 95 scripts load; headless editor/import passes. The connected windowed work-board tour selects Mara through the actual picker, asserts her garden return, opens Show and checks the world snapshot remains identical. Inspected work_assignment.png and work_location.png at 1280x720; no live HUD addition.
- Local map preview, later district content and human usability/balance remain unfinished. No toolkit changes, installations or publication.


## 28 October 2026: local map preview

- Selected known sites now have a compact physical-layout preview beside their route details. It reads current collision walls, passage openings, gates, barrier footprints and gate damage. It reveals no unknown parcels, enemies or rewards, and uses no additional labels.
- The map and work-board windowed tours pass their pause/world-snapshot/selection assertions; inspected the updated work_location.png at 1280x720. All 96 scripts load and headless editor/import passes. The prior 137-scenario simulation result remains applicable: this slice changes presentation only.
- G02's geometry, discovery, overview and board access are implemented. Human navigation usability remains unverified; new district content and the rest of the full game remain incomplete.


## 28 October 2026: shared named-survivor rescue records

- Mara's start and Paige/Ellis recruitment now use validated authored survivor records and one creation path. Searches can create each person once; repeating Ellis's rescue cannot replace spent ammunition or grant another pistol gift. Existing orders, default duties, positions and rescue lines remain intact.
- Save roster validation derives expected people from implemented rescue sites; unique equipment owners derive from the validated recruited roster. This removes the fixed three-person assumptions before Market Row rescues, without adding future people or rewards.
- All existing 137 scenarios pass after the change; two additional roster cases pass for discovery/gift idempotency, JSON reload, unknown/duplicate people and Ellis's starting duty. All 99 scripts load; headless editor/import passes. No visual change; preceding captures remain applicable. New rescues, paused introductions and Market Row content remain next.


## 28 October 2026: hardware search, finite claim ledger and long spear

Implementation:
- The hardware shop is playable with three explicit Shambler stand-ins until the Runner mechanic arrives in G04. Local standing search requires clearance, pays exactly 32 Materials and two Food once, and recovers the long spear/construction tools. Search is allowed before a home connection; claiming still needs an adjacent home-connected property and pays six Materials once. Loss/reclaim/reload never repeats either reward. Original six-site combined claim/search transactions remain intact.
- The unique spear has 38 damage, 120 reach, 0.80-second cadence, a narrow forward cone and one target. It reaches over low road lines, respects tall walls, and requires both hands. The simulation, loadout controls and save validation reject a simultaneous shield or duplicate weapon owner. Its long shaft and tip are visible in greybox art.
- Schema 21 adds independent first-claim history, an empty spear owner and only the newly implemented hardware residents to old saves. It retains existing actors/corpses, resources, RNG, equipment and paid work. Tools discovery currently supplies spear availability; later reinforcement recipes remain unimplemented.
- The live UI gains only E Search at the clear site. Loadout help is reduced to one line at 18 pixels, survivor labels use 18 pixels and the redundant successful-equipment footer is removed. Two-hand conflict explanation lives on the disabled choice/command.

Evidence:
- All 143 simulation scenarios pass. Four new cases cover remote/downed/occupied search rejection, exact separate search/first-claim payouts through loss/reload, real schema-20 expansion without old-actor changes, and spear reach/one-target/low-barrier/tall-wall/two-hand/unique ownership. Focused cases pass again after sharing the hand-conflict explanation with the picker.
- All 103 scripts load; headless editor/import passes. Windowed hardware tour asserts separate search and uses the connected loadout picker. Inspected hardware_search.png, spear_loadout.png and spear_street.png at 1280x720. No file/function size violations.
- These are staged/automated checks, not human combat feel or economy acceptance. Seventeen later sites remain shells. June/clinic, casualty recovery, Oliver/greenhouse and sustainable full-roster food remain G03 work; the full game is not complete. No toolkit changes, installations, exports or publication.


## 28 October 2026: June's clinic search and paused introduction

- Clinic search is local, clear and once-only: 12 Materials, four Food, 12 Medicine and June. It can precede claim, reveals no recruit identity beforehand, and creates a standing Hold actor at the rescue point. Three explicit Shambler stand-ins precede G04's Screecher introduction. June uses shared unique gear, jobs and meal count without a name-specific skill bonus.
- June's introduction has two short lines and three ordinary choices. All clocks stop before its first presentation frame; menu/resume shortcuts cannot bypass it. Return home requires a protected route. Choice after live discovery resumes play; a loaded introduction keeps the existing pause. Original Paige/Ellis introductions retain their legacy notification behaviour pending their presentation pass.
- Schema 22 adds zero Medicine and no pending introduction to old saves, plus only newly implemented clinic residents. Existing hardware search/first-claim history, actors, stocks and RNG remain intact. Medicine appears only in paused stock after the clinic search; there is no new live counter.
- All 146 scenarios pass, including three new rescue/reload/gift/meal/gear and schema-21 migration cases. All 106 scripts load and headless editor/import passes. The connected windowed clinic tour verifies pause, blocked Return home, resume rejection and Hold choice; inspected june_introduction.png at 1280x720. The map tour also passes after moving its unfinished-site assertion to the current content state.
- Clinic restoration, treatment/medicine recipes, field bag, casualty recovery and greenhouse food remain next. This is staged/automated evidence, not human rescue/navigation acceptance. No toolkit changes, installation or publication.


## 28 October 2026: clinic restoration and physically present treatment

Implementation:
- E approves a held, searched and clear clinic for 12 Materials and 20 work seconds. Player and survivors share one prepaid construction rate, interruption, exact cancellation return and board priority/location/assignment. Permanent Clinic duty can wait for a replacement approval; temporary construction resumes the prior duty. Restore status and a simple patient-bed fixture are visible without a new HUD panel.
- At the restored, held, clear and safely connected clinic, E commits one Medicine for the nearby named injured patient. Ten work seconds from a present player holding R or a present Clinic worker restores that patient to full, including a downed survivor. No remote patient, absent worker, healthy-person charge or second payment for interrupted treatment. One site treats one patient at a time; completed treatment removes its paid record atomically with healing.
- Paid patient progress survives danger, lost ownership, disconnection, worker changes and JSON reload. Patients healed elsewhere discard unused paid capacity rather than storing it for another injury. Schema 23 starts old saves with an unrestored clinic and empty patient list, preserving Medicine, June and the pending introduction.

Evidence:
- All 150 scenarios pass, including four new restoration/shared-rate/loss/refund, local casualty/reload/revive, real worker travel/danger/disconnection and schema-22 migration cases. All 109 scripts load; headless editor/import passes. No size-limit violations.
- The connected windowed service tour assigns June through the work-row picker, checks cancellation returns her to Hold with the exact 11-Material return, verifies paused frames preserve the paid patient snapshot, and completes a present casualty once. Inspected clinic_restoration.png and clinic_treatment.png at 1280x720.
- Clinic medicine production, field bag, fixture damage/repair, casualty carrying and ordinary home-recovery replacement remain unfinished, as do greenhouse food and later campaign content. Existing home rest still has the slice's remote convenience until that recovery migration. These checks are staged/automated, not human treatment or combat acceptance. No toolkit changes, installations or publication.


## 28 October 2026: player casualty carrying and local timed home rest

Implementation:
- Holding E for two locally clear seconds lifts one nearby downed survivor. Release/danger interrupts pickup. The casualty follows the player's physical movement; movement is multiplied by 0.7 alongside armour, and both melee and firearm entry points reject attacks. Work stops while carrying. E drops at a clear held porch onto walkable yard ground; no gate/project command shares that press.
- A short E release beside home/clinic care requests the shown service; holding E lifts instead. An unreachable casualty does not bypass collision. The one contextual line names the action/target; the misleading porch E marker is suppressed around casualty handling. No persistent panel or resource counter was added.
- Home rest replaces remote instant team healing. Two Food commits fifteen safe active seconds for the injured people physically at home, first to 50 health; an explicitly requested second interval pays another two Food to heal fully. Each paid patient pauses independently when absent/carried, home is lost or danger returns, and resumes without repayment. Healthy people spend nothing. Clinic records also pause while their patient is carried.
- Schema 24 preserves old people/health/positions, supplies, equipment and clinic treatment while adding empty carry/rest state. Carried identity/position and paid patient clocks validate on reload. The existing provisional protagonist defeat drops its carried casualty before the old teleport, avoiding a silent free casualty transport.

Evidence:
- All 157 simulation scenarios pass. Seven new cases cover hold/release/danger and gate priority, direct/wrapped attack rejection and compounded movement speed, an actual on-foot carry home, paid local rest/absence/reload/full-heal phases, loss/danger interruption, carried-clinic treatment and schema-23 validation. Updated the old recovery check to assert the new timed two-stage contract.
- All 114 scripts load; headless editor/import passes; no size-limit violations. The windowed recovery tour uses real E events through press/hold/release/drop, walks the carrier home, starts local rest and asserts pause freezes its saved snapshot. Inspected casualty_carried.png and home_rest.png at 1280x720. Clinic-service and provisions tours also pass with the new tap/timed-care rules.
- Companion carry orders, the explicit defeat/foothold panel, renewable medicine, field bag and greenhouse economy remain unfinished. The full game is still in development. Staged/automated evidence does not establish human input feel or recovery balance. No toolkit changes, installations or publication.


## 28 October 2026: explicit defeat and emergency foothold recovery

Implementation:
- A lethal tick stops before recovery, production, meals, territory updates and due migration. The saved pending-defeat state freezes further simulation and exposes only Recover or Load save; resume/menu shortcuts cannot bypass it. Existing neighbourhood-watch progress resets on the fall. Recovery mutation waits for the explicit choice.
- Recover selects the nearest clear held porch with a walkable standing point, otherwise the authored west-road shelter. It returns the player at 50 health and downed people at 25, preserving standing survivors, gear, supplies, damage, discovery, paid work and active time. No repairs, ownership or search payout. Carried casualties participate in this disclosed rescue exception, then detach normally.
- Emergency recovery relocates only living hostiles inside 120 pixels to valid uncontrolled road at least 240 pixels away, preserving IDs, health and population. Distant actors and corpses stay exact. Future migration is delayed for at least 90 active seconds without changing the wave counter. Placement supports the full future nine-person roster; a small original greybox shelter makes the fallback visible.
- Schema 25 adds pending-defeat persistence without triggering recovery on old saves. A raid due on the lethal fixed tick remains a valid pending save; the recovery preparation interval is included in deadline validation. The camera recentres immediately after the explicit rescue.

Evidence:
- All 161 scenarios pass. Four new cases cover lethal-tick freeze/paid-work/due-raid reload, nearest-shelter reduced health with conservation, zero-stock/all-down/home-loss emergency relocation and capacity, and schema-24 migration. Updated two old raid fixtures to put the living player outside the encounter rather than depending on the removed automatic respawn.
- All 118 scripts load; headless editor/import passes; no size-limit violations. The windowed defeat tour checks snapshot freeze, resume rejection, unavailable-load conservation and the connected Recover button. Inspected defeat_choice.png and west_foothold.png at 1280x720. The live HUD gains no panel; the blocked road-construction hint is suppressed at the emergency foothold.
- The existing single current save/backup can be loaded from this panel. Choosing among multiple save slots remains with the planned slot UI; no pretend chooser was added. Companion carry orders, emergency material salvage, renewable medicine/field bag and greenhouse economy remain unfinished. Staged evidence is not human recovery/balance acceptance. No toolkit changes, installations or publication.


## 28 October 2026: bounded emergency material salvage

- Visible home and west-shelter scrap piles support player-held R work: two Materials per twenty work seconds, with a combined 24-Material cap across available stock and exact refundable unfinished commitments. The final batch clamps to remaining space; above-cap finite caches are never removed. Repeated approval/cancellation cannot conceal refundable stock to farm above the cap.
- Each pile preserves its own partial work through danger, absence, cap waits and JSON reload. No inputs, unique reward or automatic survivor role. Shortage applies the ordinary labour multiplier. A selected pile consumes the player's R work exclusively, so it cannot also spend the output repairing the nearby west barricade. Other workers continue their own jobs.
- Schema 26 adds zero progress at both piles without changing stocks, paid work or a pending defeat. The single nearby prompt shows the available batch and active progress; it disappears at the cap. There is no new live resource counter or panel.
- All 166 scenarios pass, including five new player-only/danger/site/reload, refundable commitment/cancellation, clamped output/cache conservation, overlapping road-repair/shortage rate and schema-25 migration cases. All 122 scripts load; headless editor/import passes; no size-limit violations.
- The windowed R-input tour checks partial work, pause snapshot, exact batch and cap disappearance. Inspected recovery_salvage.png at 1280x720. This is staged evidence, not human recovery pacing acceptance. When G06 implements the renewable salvage yard, its operational state must disable this emergency source as designed; no unimplemented yard flag is in runtime data today. Companion rescue, medicine/field bag, greenhouse economy and later campaign work remain unfinished. No toolkit changes, installations or publication.


## 28 October 2026: bounded renewable medicine

- The restored clinic can prepare two Medicine from one Material and two Food per thirty work seconds. The shared prepaid ledger now validates exact multi-resource input/output bundles; existing construction and bullet recipes retain their unchanged bundles. Inputs commit together, outputs grant once, and cancellation returns the exact remaining fraction of each input.
- One batch, repeat-to-target and stopped policies are explicit in paused Work, defaulting to stopped with target eight. Production respects the shared chosen material reserve and the next roster meal. Lowering/stopping a policy finishes its already paid batch; discovery/loading never enables production. A local player holding R or an actual Clinic worker supplies one site rate.
- Present paid clinic patients take priority and suspend the same partial medicine batch. Lost ownership, danger, absent worker and disconnected home route block work without repayment. General workers can physically travel to explicitly enabled medicine after higher-priority work; Ellis keeps civilian restrictions and returns to his General duty.
- Schema 27 adds a stopped policy to old saves without changing medicine, food, materials, patients or work. The existing production controls are reused; cancellation omits zero returns and repeated target labels. Live presentation adds only the nearby work prompt and small bottle/progress drawing at the clinic.
- All 173 scenarios pass. Seven new cases cover atomic inputs/shared rate/one batch, target lowering/both reserves, loss/JSON reload/civilian handoff, patient priority, cancellation/bundle drift, actual General-worker travel and schema-26/no-auto-discovery policy. All 126 scripts load; headless editor/import passes; no size-limit violations.
- The windowed medicine tour exercises connected mode/target/cancel controls, freezes the paid snapshot through pause, and verifies exact returns and two bounded repeat batches. Inspected medicine_work.png and medicine_crafting.png at 1280x720. Human supply balance remains unverified; companion carrying, field bag, greenhouse economy and later campaign content remain unfinished. No toolkit changes, installations or publication.


## 28 October 2026: physical companion rescue orders

- Paused Team offers Rescue for recruited downed people, naming the home/clinic destination. A standing companion follows a protected approach, spends two clear seconds lifting, then carries at the same 0.7 movement factor and drops at shelter. A nearer restored clinic with Medicine is preferred over a farther home. No follower membership, healing, medicine payment or teleport is created by rescue.
- The temporary rescue retains prior duty. Completion resumes it; individual reassignment drops the casualty in place, while whole-team shortcuts preserve the active transport. Closed initial routes reject without changing assignments. Route loss/danger pauses transport, with bounded retries and the existing clear period. Downing the carrier releases the casualty in place and retains the return duty for later recovery. Ellis can rescue without fighting or guarding.
- Player, clinic and home-rest handling recognise every attached casualty. One casualty has one carrier, attack entry points reject a loaded companion, and explicit defeat recovery clears transports before restoring downed people. Schema 28 adds an empty transport registry without changing old people, work or supplies; phase, attachment, ownership and return-duty state validate on reload.
- All 181 scenarios pass, including eight new physical route/lift/drop/JSON/duty, closed/lost route, individual/group reassignment, downed carrier/attack restriction, civilian/duplicate ownership, defeat cleanup, schema-27 and nearer-clinic cases. All 130 scripts load; headless editor/import passes.
- The windowed Team-picker tour verifies connected assignment and paused snapshot conservation, then runs the authoritative journey and previous garden-duty resumption. Inspected companion_rescue_order.png and companion_carried.png. The carrier image deliberately stages the camera away from the player and hides that offscreen player's unrelated context; it is a visual fixture, not human play evidence. Team body text is 18 pixels and redundant assignment footers are omitted. No live rescue panel was added.
- Field treatment, greenhouse food/Oliver, fixture damage/repair and later campaign content remain unfinished. Human rescue reliability and path feel remain unverified. No toolkit changes, installations or publication.


## 28 October 2026: field bag review and current-state assessment

Implementation:
- Reviewed and completed the pending field-medicine slice. Clinic search unlocks one unique field bag at the existing workshop loadout bench. Its off-hand slot excludes shield and two-handed spear combinations. A standing local patient receives up to 40 health for one Medicine and three clear work seconds; interrupted progress remains paid on that patient through range loss, danger, tool handoff and JSON reload. Fully healed patients discard unused paid capacity. Downed people still require physical shelter care.
- Held R selects nearby injured companions before self-care and yields to gates, projects, salvage and casualty handling. An explicitly ordered bag-equipped companion, including Ellis, can treat a nearby standing patient, then resume their prior duty. No autonomous medicine spending is introduced. Schema 29 adds an empty dose ledger and bag owner without changing existing stock or duties.
- Review corrected corrupted punctuation in field prompts, rescue destinations and the spear tooltip. The failing migration assertion assumed tactical Hold replaces a regular duty; it now checks every survivor's actual prior duty and order are preserved.

Current boundary and next step:
- G01/common orders and G02/full-map skeleton are implemented; G03/Market Row remains partial. Eight sites are searchable, with the original six-site loop plus hardware and clinic, four companions plus the protagonist, two enemy kinds and sixteen development shells. Original neighbourhood watch remains the slice finish. This is a playable greybox foundation, not a complete campaign.
- Next deliver Oliver's once-only greenhouse rescue and introduction as a separate slice, then greenhouse restoration/physical food production and the planned meal/garden retune. G03 acceptance needs a sustainable six-person loop, including medical costs and interruptions. Current runtime still uses 60-second meals; the full-design 120-second interval is not yet implemented.
- Later work includes new enemy behaviours/noise/pressure, remaining facilities and recruits, relief-signal ending, optional van, save slots, production art/audio/accessibility and full campaign balance/performance checks. Historical sections above describe their state at the time and do not override this boundary.

Evidence:
- The windowed field tour uses R press/release through the real game input, verifies a single paid dose and pause conservation, and completes healing. Inspected field_treatment.png and field_bag_loadout.png at 1280x720: bag selection, sparse contextual prompt and patient progress ring are readable. The standard ten-state capture tour also completes; inspected its home.png for the current general street view.
- All 187 simulation scenarios pass, including six field-medicine cases. All 134 scripts load; headless editor/import passes. Whitespace and file/function size checks pass.
- Automated and staged evidence is separate from human acceptance. No new human combat, rescue reliability, food-pressure or pacing session occurred. No export, installation, toolkit change, push or publication.


## 28 October 2026: Oliver's greenhouse rescue

- Greenhouse is searchable after clearing three explicit Shambler stand-ins (Runner behaviour remains G04). Local search grants 16 Materials, eight Food and Oliver once, independently of the connected first claim. Growing-kit discovery persists as the greenhouse search flag. No reward/name is revealed before search.
- Oliver joins ordinary equipment, orders and shared meals. His two-line introduction pauses immediately and offers Hold, Follow or a protected Return home. Schema 30 adds only greenhouse residents to old saves, preserving prior actors, RNG, supplies and discoveries.
- Headless rescue/reload/migration checks and script loading pass. The connected windowed rescue tour checks immediate pause, blocked return, resume rejection and Hold; inspected oliver_introduction.png at 1280x720. This is staged evidence, not human combat/navigation acceptance. Restoration and food production follow in the next slice.
