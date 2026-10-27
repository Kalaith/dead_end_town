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

M0 is implemented technically; traversal scale and readability still need human review. M1–M7 have initial examples, not completed acceptance gates. M8 is not complete. This prototype is shorter and much narrower than the proposed 20–30 minute slice.

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
