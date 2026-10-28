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

M0 is implemented technically; traversal scale and readability still need human review. M1Ã¢â‚¬â€œM7 have initial examples, not completed acceptance gates. M8 is not complete. This prototype is shorter and much narrower than the proposed 20Ã¢â‚¬â€œ30 minute slice.

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
- Balance, population, edge routes, formations and cadence are validated JSON content. The simulation owns all timing; pause stops the clock. Save schema 5 records the wave clock, warning, destination and alley travel phase. Schemas 1Ã¢â‚¬â€œ4 migrate while preserving claims, resources, people, work and legacy attackers. Claimed yards stay clear; unclaimed yards gain the new residents. Older runs get 65 active seconds of preparation before recurring pressure.

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

- Residents, migrants and occupiers now use the same independent random wandering. Each selects a heading for 0.8–2.8 active seconds and picks again when obstructed. Zombies no longer pursue people, path to entrances, travel toward an alley junction or rally at porches. They can wander through open gates and away from lost yards. Contact bites and bump damage against gates/road barricades remain; physical walls, territory occupation and survivor defence still apply.
- Each basic melee swing selects the nearest living target passing reach, forward-cone and clear-line checks. Damage, stagger and knockback affect that zombie alone, including basic survivor melee. A swing never spills into another target after a kill. Damage and cadence are unchanged; no future weapon upgrade is implemented.
- The simulation owns a seeded RandomNumberGenerator. Schema 7 stores its full integer state as text to avoid JSON precision loss, plus heading/turn clocks. Schemas 1–6 migrate while preserving actors, occupation, equipment, resources and work. Existing migrant destination/lane metadata may remain in older actors but does not direct movement. Unused pursuit/alley travel tuning was removed from the active catalog.
- All 54 scenarios pass. Six new scenarios cover nearest single-target hits/cooldown/knockback, fence obstruction, continued movement and multiple headings after territory loss, identical motion despite nearby people, mid-wander JSON reload with preserved RNG sequence (small floating clock rounding tolerance), schema-6 migration and malformed wandering data. Earlier directed-raid checks now exercise local guards, staged collision headings/breach, and actual random alley arrivals; they no longer assert purposeful attacks. The command-driven garden check now seeks scattered occupants and returns to the porch rather than waiting for zombies to pursue. Existing armour, task, save-backup and territory checks pass.
- Godot 4.7.2 parse and headless editor/import checks pass. Ran Run.ps1 with the toolkit capture runner at 1280x720. Inspected wander_occupation.png and wander_dispersed.png across six seconds of real windowed simulation after staged loss, plus single_target_swing.png with an assertion that one shambler was damaged. Refreshed the standard capture tour. These are scripted visual/motion checks, not human playtesting or acceptance of the new difficulty. No audio/device/export checks, toolkit edits, installations, deployment or publication.


## 28 October 2026: physical neighbourhood passages

Implementation:
- Both northern yards and both southern yards can be joined by approved fenced passages (4 materials, 6 seconds). Player and named-worker labour shares progress. Completion explicitly opens the existing side fences and adds physical rails and a closable gate. Blueprints leave fences intact; cancellation refunds unused materials. Gate occupancy, breach and committed repair survive save/load.
- Safe home connectivity is now distinct from ownership adjacency. Protected street crossings need both end barricades, usable yard gates and a clear corridor. Passage links need held endpoints and an open intact gate. Alternate routes work around a lost corner; losing home or every valid route pauses garden delivery without erasing harvest progress. Local construction can still proceed before a protected connection exists.
- Pause lists known route conditions without revealing unsearched rewards. Passage work appears in individual orders. Movement now checks actor width before using a straight route, avoiding a fence-rail corner trap.
- Schema 8 migrates schemas 1�7 with empty passage construction; existing progress and resources remain. The shared toolkit is unchanged.

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
