# Dead End Town

Reclaim a zombie-infested street, one property at a time, with a small group of survivors who work and fight together.

**Status: full-town greybox expansion (28 October 2026).** The continuous street now has all 24 property sites across four districts. The original six sites have combat, territory, building, equipment, food and a slice finish; the hardware shop now adds a separate search, material cache and long spear. The clinic adds June’s rescue, restoration and treatment for people physically present. The greenhouse adds Oliver’s rescue, restoration and physical food production. The other 15 sites are development shells without rewards or encounters. The full campaign is still being built, and human playtesting remains partial. See [progress and verification](docs/PROGRESS.md) for exactly what has and has not been checked.

## The game

You start at a fenced home with one survivor, Mara. Open the gate, clear the zombies from the next yard and secure it. Each property you hold unlocks something: food, materials, a rescued survivor, a workshop. Then go home, or send someone else.

Everything happens in one continuous top-down world, and everyone stays active off camera. Your survivors are a cooperative team, not a colony to micromanage. Growth comes from discoveries, buildings and equipment rather than XP.

- **Fight.** Melee is single-target: each swing hits the nearest zombie in reach. Aim with the mouse or swing the way you are moving. Recovered weapons change reach, damage, speed and how many zombies a swing can hit.
- **Claim.** Clearing a yard and securing it are separate steps. A property has to connect to home, and you can only claim ground next to what you already hold. Searching rewards you once; reclaiming a lost property never pays twice.
- **Defend.** Zombies wander until someone comes within about 240 pixels, then head for the nearest person. They bite on contact and break gates and barricades they bump into. Raids arrive from the map edges and grow with your territory, and a warning tells you which side. If zombies hold a yard with nobody standing in it for eight seconds, you lose it, home included. Clear them and reclaim.
- **Build.** Barricade the road, fence passages between yards, repair gates, tend a garden, restore a workshop. You approve each project at its site with **E** and spend materials once. After that you can hold **R** to work, or give the job to a survivor. Temporary construction returns them to their regular duty; Builder selects approved work, with priorities set in J. Work rows can locate a project on the paused map or assign a survivor temporarily. Progress is shared, so two workers do not double the speed. Repairs commit three materials for up to 120 health; unused capacity is discarded at full health. Broken gates instead take seven work seconds to rebuild and reopen safely.
- **Equip.** The garage hides a crowbar, sword, iron armour and shield. Restore the workshop, then choose loadouts for anyone. Every recovered item is unique, so return it before someone else takes it. Farther east, search the hardware shop for its material cache and long spear. The spear reaches farther and uses both hands, so it cannot share a loadout with the shield. Search and connected claim pay separately, once each.
- **Shoot and supply.** The east house shelters Ellis, who gives you a pistol and six bullets. Ellis works and follows but never fights or guards. Aim with the mouse and right click to shoot; melee stays on left click/Space. Claim the ammunition workshop across the road, assign a worker with F and choose one batch or a stock target in J. Each batch makes six bullets per 15 work seconds for two materials. Production needs a protected home route and respects a six-material reserve; J can change the reserve, stop future batches or cancel the current one for its shown return.
- **Treat.** Clear and search the clinic for June and 12 Medicine. Connect and secure the site, then approve its 12-Material restoration. After 20 work seconds, E commits one Medicine for the nearby named patient; hold R or assign a clinic worker for ten work seconds to heal or revive them. Both patient and worker must be present. Danger, ownership or route loss pauses paid treatment. J selects one medicine batch or repeat-to-target production: one Material plus two Food makes two Medicine in 30 work seconds, using a present clinic worker or held R. It protects the next meal and the chosen material reserve; present paid patients take priority.
- **Treat in the field.** Clinic search also recovers a unique field bag. Fit it at the workshop in place of a shield; it cannot accompany the two-handed spear. Away from work sites, hold R beside a standing injured person, or alone for self-care: one Medicine pays for three clear work seconds and up to 40 health. Interrupted progress stays with that patient. A companion with the bag, including Ellis, can receive an explicit nearby Treat order in F and then resume their previous duty. The bag cannot revive downed people.
- **Recover.** Hold E for two clear seconds beside a downed survivor to carry them. Carrying slows movement and prevents attacks; E puts them down at a clear held porch. At home, E commits two Food for fifteen safe active seconds of rest for the injured people physically there, recovering them to 50 health. Another two Food and fifteen seconds heals them to full. Leaving home, danger or ownership loss pauses already paid progress. Where a casualty is beside care, tap E for care or hold E to lift. F can assign a standing companion to rescue a named casualty along protected routes to home or a nearer operational clinic. The rescuer resumes their previous duty after drop-off. Individual reassignment puts the casualty down in place; whole-team shortcuts leave active rescue transports intact.
- **Regroup after defeat.** The world pauses when you fall. Recover returns you to the nearest clear held shelter at 50 health and downed survivors at 25, or uses the west shelter if no property is safe. Supplies, equipment and town damage remain. New raids wait 90 active seconds; nearby zombies at the emergency shelter move to uncontrolled road. Load save is available instead.
- **Rebuild depleted supplies.** Hold R at the scrap pile inside home or beside the west shelter. Twenty work seconds recovers two Materials, stopping when available stock plus current project cancellation returns reaches 24. Only the player works these piles; danger pauses them. Food shortage still slows work.
- **Grow.** Clear and search the greenhouse for Oliver, the growing kit, 16 Materials and eight Food. Secure it from the clinic, then E approves its 16-Material restoration. Hold R or assign a grower with F for 24 work seconds. A restored greenhouse yields four Food per 60 tended work seconds with a safe home route; the garden yields two per 45. Growers pause at two meals plus four recovery Food, keeping their partial harvest, and resume below that target minus one meal. Paused supplies show progress and the local reason for a pause.
- **Eat.** The group shares a meal every 120 seconds, costing one food each. Missing a meal slows work to 60%, with no hunger damage. Food also pays for healing at home. A tended garden brings in more.

### Your first run

1. Hold **R** at the home gate to repair it, then open it with **E**.
2. Clear the garden yard, press **E** at its porch to secure it, and collect the timber with **Q**.
3. Take the library across the road. Paige is inside. Take the garage next for tools and the equipment cache.
4. Press **F** to send Mara to the garden and Paige to the workshop while you guard the road.
5. Build barricades and passages so every yard has a protected route home.

### Finishing: a street worth keeping

Hold the original four yards (home, garden, library and garage), give each a protected route home, harvest four garden food, restore the equipment cache, deploy a recovered weapon plus iron and shield, keep everyone standing, and keep a shared meal in reserve. Then choose **Begin neighbourhood watch** in the pause menu at home and keep those conditions for 60 seconds. Any setback resets the watch. Completing it pauses with **Continue the street**, and the finish is kept.

## Controls

| Control | Action |
| --- | --- |
| WASD / arrows | Move and face |
| Mouse / left click | Aim and swing toward the cursor |
| Right click | Shoot the recovered pistol toward the cursor (one bullet per shot) |
| Space | Swing in your movement direction (or last facing); hold to repeat |
| E | Interact; tap for care beside a casualty; drop a carried person at a clear held porch |
| Hold E | Lift a locally clear downed survivor after two seconds |
| Hold R | Repair or build at the nearest gate, passage, barricade or porch project |
| Q | Collect a secured building's spare timber |
| 1 / 2 / 3 / 4 | Whole team: Follow / Hold / Engage / Resume home duty (Ellis never fights or guards) |
| F | Pause for individual orders; loadouts have their own page |
| J | Pause for approved work and bullet production (after discovery) |
| M | Pause for the known-town map; select a seen site for route conditions |
| G | Post a survivor at a nearby barricade |
| Esc / Tab | Pause and open the menu |

The world pauses on the opening screen and in any menu. The pause menu separates supplies/objectives, team, production, equipment, known routes and help into small pages. The street uses a small health bar, an ammo count when armed, urgent threat alerts and short nearby action/cost prompts. Flags, windows, crops and bars show state; detailed supplies and orders stay in pause.

Saving is explicit from the pause menu and stored at `user://street.json`. Reopening starts a fresh street until you choose Load. Damaged saves fall back to a backup, and older save versions migrate automatically.

## Not in the slice

Explorable interiors, audio, production art, noise-driven zombies, general build queues and freeform construction, remapping and gamepad, and a full campaign ending. The neighbourhood-watch finish ends this slice, not the game.

## Run from source

Godot **4.7.2**, Compatibility renderer, desktop keyboard and mouse, 1280x720. No export is needed.

```powershell
# First checkout: recreate the ignored shared-toolkit junction (../godot_toolkit).
& ../godot_toolkit/tools/Link-Toolkit.ps1 -ProjectDir .
./Run.ps1
```

You can also open `project.godot` in the editor. Headless checks and the staged screenshot tour (written to `docs/verification/`) are listed in [AGENTS.md](AGENTS.md). Rules live in `scripts/sim/`, presentation in `scripts/presentation/`, content validation and saves in `scripts/core/`, and all balance and map data in `data/street/*.json` (zombie kinds in `data/zombies.json`). Project layout came from The Last Hearth, and shared tooling from `../godot_toolkit`; no gameplay was borrowed.

## Documentation

| Document | Purpose |
| --- | --- |
| [Game design](docs/01-game-design.md) | Full game specification and reading map; start here |
| [World and territory](docs/02-world-and-territory.md) | Claims, connections, loss and recovery |
| [Combat and home defence](docs/03-combat-and-defence.md) | Player actions, squad orders, defence |
| [Construction and jobs](docs/04-construction-and-jobs.md) | Shared work, jobs, interruptions |
| [Survivors and growth](docs/05-survivors-and-growth.md) | Eight named survivors, rescue contracts and roles |
| [Buildings and economy](docs/06-buildings-and-economy.md) | Rewards, unlock chains, production |
| [Zombies and pressure](docs/07-zombies-and-pressure.md) | Wandering, pursuit, raids |
| [Experience and presentation](docs/08-experience-and-presentation.md) | Opening, interface, accessibility |
| [Release roadmap](docs/09-mvp-roadmap.md) | Ordered slices from the working street to the full game |
| [Godot implementation](docs/10-godot-implementation.md) | Architecture, data, persistence |
| [Decisions](docs/11-decisions-and-questions.md) | User foundations, resolved full game choices and tuning gates |
| [Sources and terminology](docs/12-sources-and-terminology.md) | Sources, precedence, glossary |
| [Campaign and map](docs/13-campaign-and-map.md) | 24-property topology, core path, finite relief-signal ending |
| [Zombie catalogue](docs/14-zombie-catalogue.md) | Eight kinds, tells, attacks, counters and composition limits |
| [Property catalogue](docs/15-property-catalogue.md) | Every building, reward, encounter and improvement |
| [Equipment and recipes](docs/16-equipment-and-recipes.md) | Unique items, costs, work and prerequisites |
| [Acceptance and balance](docs/17-acceptance-and-balance.md) | Funding/food examples, scenarios and human playtest gates |
| [Vehicle design](docs/18-vehicle.md) | Recoverable utility van, travel, recovery and save rules |
| [Progress](docs/PROGRESS.md) · [TODO](docs/TODO.md) | What is built and verified, and what is next |

The full game design targets 24 properties, eight zombie kinds and eight survivors plus the player, with a core campaign and a finite relief-signal ending. It is documentation for future implementation; the runtime currently has nine searchable properties within the full 24-site layout, including field treatment and Oliver’s greenhouse food loop. Later facilities and enemy behaviours remain in development. Design numbers are chosen starting values with validation gates, while `PROGRESS.md` records what exists and was actually checked.
