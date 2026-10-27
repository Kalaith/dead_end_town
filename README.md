# Dead End Town

Reclaim a zombie-infested town, one property at a time, with a small group of survivors who work and fight together.

**Status: first playable greybox prototype, 28 October 2026.** A continuous four-property street now runs in Godot 4.7.2 with melee combat, Mara's home defence, connected property claims, a shared garden construction job, Paige's rescue, manual save/load, garage restoration, Paige's first iron armour and shield, salvageable road barricades, and individual survivor assignments. This is an early foundation, not the complete MVP. See [progress and verification](docs/PROGRESS.md) for the exact boundary.

Prepared 28 October 2026 from the [Game concept development conversation](chatgpt-conversation://6ae0fba7-c8a4-83ec-9e38-b9d8b951a9ac) and the accompanying project request.

## Play from source

Use the installed standard Godot **4.7.2** editor, Compatibility renderer. Desktop keyboard and mouse are the initial target; the viewport is 1280x720. No installation or export is needed.

```powershell
# First checkout: recreate the ignored shared-toolkit junction.
& ../godot_toolkit/tools/Link-Toolkit.ps1 -ProjectDir .
./Run.ps1
```

Alternatively, import `project.godot` in Godot and run the project. The opening screen pauses the world until Begin. Saves are explicit through the pause menu and live in Godot's `user://street.json`; reopening starts a fresh preview until you choose Load saved street. New street preserves the existing on-disk save until a later Save, and archives it as `.previous` first. Incompatible or damaged saves without a usable backup block saving and show a message.

| Control | Action |
| --- | --- |
| WASD / arrows | Move and face |
| Mouse / left click | Aim explicitly; click swings toward the cursor, including while moving |
| Space | Swing in your movement direction; when stopped, keep the last facing; hold to repeat |
| E | Interact; approve road construction/dismantling; cancel unfinished road work |
| Hold R | Repair the home gate or road barricade; contribute construction/dismantling work |
| 1 / 2 / 3 / 4 | Team Follow / Hold / Engage / Return home and guard |
| F | Pause and open individual survivor orders |
| G | Post one survivor at a nearby completed road barricade |
| Esc / Tab | Pause all simulation and open the menu |

Keyboard movement takes control of facing from the mouse. Space follows movement or your last facing when stationary. Moving the mouse aims explicitly; holding left click follows the cursor while moving. A swing keeps its original direction until its animation finishes.

Start by approaching the home gate, holding R to repair it, then opening it with E. Cross east into the garden yard, clear its seven shamblers and press E at the marked porch. Press E again to reserve garden materials, then hold R or assign a survivor with F. Keep home access open for their route. A closed gate reports blocked work. The library across the road rescues Paige; the garage adds tools and materials. All actors stay active while off camera. The garden and library each hold seven zombies; the garage holds ten. Recurring map-edge raids begin after 45 active seconds, with a 12-second warning. They cycle through the east and west roads, north/south alley flanks, and attacks from all four edges. Claiming more properties grows each wave from four to ten and shortens the interval from 65 to 41 seconds. Raiders attack the closest claimed entrance and physical barricades along their route. A 36-living-zombie cap bounds arrivals; cleared residents never respawn.

After securing the garage, press E at its porch to commit 10 materials to restoring its workshop. Hold R or assign a survivor with F. Once complete, E commits 12 materials to restoring its cached iron armour and shield. Finish that work, bring rescued Paige to the bench with Follow (1), then press E to fit the single set. Iron armour halves incoming damage and reduces her movement speed by 20%; the shield halves the remaining damage from the front. No healing or remote equipment swap is granted.

The street has no floating building/status/count/reward labels or permanent facility captions. Flags, windows, crops and equipment show progress. Health and danger alerts stay visible; prompts appear nearby, and short messages report discoveries. Unsearched buildings keep their rewards hidden, including Paige until her rescue. Facility orders appear after claiming their property. Pause with Esc/Tab for the next objective, stockpile, team status, equipment and controls. Existing schema-1/2/3/4 saves migrate to schema 5 when loaded, preserving their street, supplies, work, equipment and existing orders. Claimed yards stay cleared; unclaimed yards receive the extra residents. Old saves get 65 active seconds to prepare for recurring attacks. Each survivor now stores their own work target.

Secure **home and library**, the properties facing one another across the western road block, to unlock its west/east barricade sockets. Garden and garage unlock the next block's pair. Stand at a dashed socket on the road and press E to commit 8 materials, then hold R for 8 seconds or assign a survivor with F. Barricades block all actors, and zombies attack and eventually breach them. G posts one living survivor on the inside; use it at the other end to post another. Guards strike over the low barricade. Team orders 1-4 override these posts.

E at a built barricade approves dismantling; hold R for 4 seconds or assign a survivor through F. An undamaged barricade returns 6 materials, with less salvage after damage. E again keeps it without a refund. E on an unfinished blueprint cancels it: full refund before any work, decreasing toward the built salvage value as work proceeds. Hold R to repair a damaged standing barricade for one 3-material commitment. Unsafe work pauses. Collision remains until dismantling finishes, so open an inner barricade to reach the next block as the line advances. These are temporary road defences; a full safe-corridor/perimeter model remains future work.

Press **F** (or Esc/Tab) for paused team orders. Choose **Garden: build and tend** beside Mara and **Workshop: build and restore** beside Paige, then return to the street. Each walks to their own work site while you guard. Any recruited, standing survivor can do either job. Approve each project at its porch with E first; assigning a role never spends supplies or starts a new recipe. Closed gates and danger can block work, and the row beneath each name explains their activity.

The garden role stays after construction and produces food only while someone tends the safe beds (or you hold R there). The workshop role stays at the bench after finishing, ready for the next restoration order you approve. You can also give one survivor Follow, Hold, Engage, Home guard, or work/guard orders at relevant road barricades. Those choices leave everyone else's assignment intact. Keys 1-4 still deliberately command the entire team and override individual jobs.

The prototype uses original procedural greybox drawing. Buildings have solid footprints with porch interactions; there are no explorable interiors yet. No audio, firearm, general equipment inventory or recipes, food consumption, general construction queues/priorities, physical inter-property integration, noise-driven migration or final campaign ending is implemented.

## Project template and toolkit

The Last Hearth supplied the project structure, Compatibility configuration and toolkit workflow. Its gameplay, art, BDI agents and turn-based combat were not copied. Dead End Town has its own pure fixed-step rules in `scripts/sim/` and presentation in `scripts/presentation/`.

`../godot_toolkit` is linked at the ignored `addons/hatchery` junction. Runtime code uses its `JsonIO`, `DataRules`, `JsonSave`, `Palette` and `UiKit`; developer tools use the shared parse, scenario and capture runners. The shared toolkit itself was not modified. The standard publishing wrappers are present but have no configured destination or export presets; nothing has been published.

```powershell
$godot = 'C:/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path . --script res://tools/parse_all.gd
& $godot --headless --path . --script res://tools/sim_checks.gd
& $godot --headless --editor --path . --quit
./Run.ps1 -GameArgs @('--script','res://tools/capture.gd','--','--size=1280x720','--no-save')
```

The capture tour stages example states without writing a gameplay save. Its images are in `docs/verification/`. The user has human-playtested basic zombie combat and territory capture. The user subsequently reported another game playtest and requested movable street defences. The new barricades have automated and staged visual verification; their human feel and browser/device support remain unverified.

## The game

Open the gate, take a small squad down the street, and clear the next house. Back home, the survivors you left behind repair fences, grow food, and defend the perimeter. Bring back tools, equipment, and people that change what your community can do. Connect the new property and watch a dangerous street become a lived-in neighbourhood.

Everything happens in one continuous world. The survivors are a cooperative team. Growth comes mainly from key discoveries, useful buildings, and visible equipment rather than experience grinding or complex character management.

## Documentation

| Document | Purpose |
| --- | --- |
| [Game design](docs/01-game-design.md) | Vision, pillars, core loop, player experience, scope |
| [World and territory](docs/02-world-and-territory.md) | Property claims, connections, perimeter, loss and recovery |
| [Combat and home defence](docs/03-combat-and-defence.md) | Player actions, squad orders, autonomous defence, alerts |
| [Construction and jobs](docs/04-construction-and-jobs.md) | Shared work progress, jobs, interruptions, safe autonomy |
| [Survivors and growth](docs/05-survivors-and-growth.md) | Named cast, equipment, Paige's transformation |
| [Buildings and economy](docs/06-buildings-and-economy.md) | Rewards, unlock chains, stockpile, production |
| [Zombies and pressure](docs/07-zombies-and-pressure.md) | Noise, migration, hordes, readable escalation |
| [Experience and presentation](docs/08-experience-and-presentation.md) | Opening, interfaces, visual changes, accessibility |
| [MVP roadmap](docs/09-mvp-roadmap.md) | Milestones, acceptance gates, playtest plan, deferred scope |
| [Godot implementation](docs/10-godot-implementation.md) | Proposed scenes, data, navigation, simulation, persistence |
| [Decisions and questions](docs/11-decisions-and-questions.md) | Confirmed direction, defaults, unresolved choices |
| [Sources and terminology](docs/12-sources-and-terminology.md) | Source limits, precedence, technical references, glossary |

Read the game design first, then the decisions register. For implementation, follow the MVP roadmap and treat the technical document as a proposal until tested.

## How to use this package

- **Confirmed direction** means explicitly selected by the user in the conversation or current request.
- **Proposed default** means a concrete working rule supplied to make the design buildable. It remains open to revision.
- **Illustrative** means example content or tuning, not a production commitment.
- **Open** means a decision still needs evidence or a user choice.

Unless specifically identified as confirmed, mechanics, counts, numerical values, cast details beyond Paige, and implementation choices below are proposed defaults. The latest user direction takes precedence over earlier brainstorming. In particular, earlier activity-based skill suggestions do not override the later request for high-level, item-led growth.

## First development objective

Prove that leaving home is interesting because trusted survivors continue defending a real place. Build one small street before expanding into a full town. See [the milestone gates](docs/09-mvp-roadmap.md).
