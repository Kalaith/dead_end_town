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

Still absent: explorable interiors, general blueprint placement/cancellation, general repair targets beyond home, job leases/hauling, general equipment inventory/recipes, firearm, noise-driven migration, recurring horde pressure, contested territory loss/recovery, ending, food upkeep, settings/remapping, gamepad/touch, audio and production art. The ownership graph does not yet prove physically safe street corridors: claiming does not magically secure the road. The alert model covers home only. The guard's barricade strike is a provisional low-fence combat rule.

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
- The new progression and revised HUD have not received a human playtest. The approach remains the original single authored group, so equipment does not yet have a dedicated defensive encounter. No exports, audio, performance benchmark, deployment or publication were added.
- Explicit safe street corridors/perimeter accounting remain the next territory step. Workshop eligibility still uses the existing claimed graph plus local threat clearance; physical actors use the existing route collision, but safe road connectivity is not yet modelled. Do not treat this as complete M4, M6 or M8 acceptance.
