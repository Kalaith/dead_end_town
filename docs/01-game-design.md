# Dead End Town: full game design

Design baseline: 28 October 2026. This package specifies the game to build after the working street slice. **It is design, not an implementation or verification claim.** The user authorised making the remaining design decisions. Numerical values are implementation starting values with explicit playtest gates, rather than measured balance.

## The promise

Reclaim a recognisable town with a handful of people you learn to trust. Personally fight for a property, connect it to home, and turn its discoveries into better food, equipment, routes and defences. Leave useful people holding the line while you go farther. Eventually open the town's relief signal and prove that the community can keep its streets.

The emotional progression is trapped → capable → connected → dependable. Paige, rescued from the library, can become the armoured defender who keeps the next rescue route open. Ellis contributes without ever being made to fight. Buildings and equipment, rather than experience points, make these changes possible.

## Foundations

1. One continuous, authored top-down world; no expedition instances, combat turns or loading barriers between districts.
2. One fixed player protagonist and cooperative named AI survivors. Single player only.
3. Physical defence: gates, fences, barricades, sightlines and actual defenders decide outcomes on and off camera.
4. Separate clearance, claim, safe connection and facility operation. Ownership never creates free walls.
5. Hybrid construction at authored sockets. Player and survivors share paid work and progress.
6. Equipment, discoveries and facilities create growth. No XP, classes, activity grind or research tree.
7. Small community, understandable automation, sparse live HUD and fully paused planning.
8. Recoverable setbacks. No permanent survivor death, infection countdown, interpersonal conflict or hunger damage.

## Locked release scope

| Area | Full game decision |
| --- | --- |
| Format | Godot 4.7.2, Compatibility, desktop keyboard/mouse, 1280×720 reference view |
| Campaign | One authored town, 24 properties in four six-property districts |
| Duration target | 2–3 hours for a first core campaign; 2.5–4 with optional sites; 1–2 on replay |
| People | Protagonist plus seven named survivors; player plus at most two followers |
| Enemies | Eight zombie kinds; six additions beyond the current Shambler and Brute |
| Construction | Existing buildings, fixed improvement/fortification sockets, no freeform walls |
| Economy | Materials, Food, Bullets, Shells and Medicine; unique key items and equipment |
| Combat | Melee, pistol, shotgun, frontal passive shields; no stamina/dodge/reload/durability subsystem |
| Ending | Restore the relief signal and defend three approaches for a finite six-minute watch |
| After victory | Explicit ending, completion save and optional continued reclamation |
| Presentation | Grounded stylised 2D; readable silhouettes and visible work; no gore dependency |
| Shipping boundary | Local desktop release first; exports and distribution require separate user direction |

The duration is a content and pacing target, not permission to stretch work timers. Completion requires 18 named core properties; six optional properties offer alternatives, supplies and equipment. Taking every property is an optional final accomplishment, not a victory prerequisite.

## Core loop and decisions

Review readiness and one or two active jobs. Choose a nearby reward or route. Set the home defence and expedition loadouts. Fight, fall back, search and rescue in continuous space. Bring discoveries into use, secure the route and move the defensive front. A stronger community opens a harder landmark.

Useful decisions recur: rescue versus equipment first; a compact boundary versus a valuable exposed site; quiet melee versus ammunition and noise; a mobile ally versus an armoured post; materials for a new capability versus repairs. Quiet intervals let the player enjoy the change, rather than generating compulsory chores.

Every property must change at least one of equipment, production, route geometry, rescue capacity or campaign readiness. Ordinary houses may offer finite supplies and a shorter perimeter; no building exists only for a tiny passive percentage bonus.

## Campaign arc

| Act | District | Main change | Demonstration |
| --- | --- | --- | --- |
| I: Keep a street | Hearth Street, existing six sites | Food, workshop, Paige, Ellis and ammunition | Original neighbourhood watch becomes an optional teaching milestone |
| II: Make it dependable | Market Row | Clinic, renewable salvage, food surplus, June and Oliver | Two defenders keep routine attacks manageable while the player visits another block |
| III: Choose how to fight | Civic Block | Reinforced defences, specialist equipment, Theo and radio forecast | Mixed enemies reward preparation and two viable approaches |
| IV: Open the signal | East Works | Power, water, relay and relief assembly | Prepare three physical fronts and begin a deliberate final defence |

Districts are geographic progression, not level gates. Players can scout and loot far ahead at personal risk. Claims need held adjacency; productive facilities need safe home connection. No invisible wall requires an act-complete flag. Finale dependencies and the exact map are in [Campaign and map](13-campaign-and-map.md).

## What persists and what can be lost

Cleared residents remain dead. Searches, rescues and key discoveries never repeat. Equipment remains unique and cannot be permanently destroyed. Gates, barricades and facility health can be damaged. Zombies can occupy and take claimed property; operational facilities pause while unsafe or disconnected. Work, prepaid inputs, food clocks, warnings and enemy intent survive saving.

All clocks stop in menus and while closed. Recoveries preserve campaign progress; defeat is a setback in territory and preparation, never a requirement to start a new campaign. Details are authoritative in [Combat](03-combat-and-defence.md) and [Construction](04-construction-and-jobs.md).

## Scope exclusions

No multiplayer, procedural town generator, driveable vehicles, multiple storeys, day/night survival schedule, hunger deaths, permanent deaths, infection cures, relationship meters, betrayals, population recruitment, armour wear, loot rarity rolls, ammunition calibres, fuel deliveries, electrical wiring or distributed warehouse simulation. Building interiors are shallow open-front ground-floor rooms sharing the outdoor simulation, not separate maps.

No new system may enter by implication from a building name. A waterworks unlocks one visible town improvement; it does not create pipe placement. A depot supplies salvage, not a transport fleet.

## How to build from this package

Read this document and the [decision register](11-decisions-and-questions.md), then the owning system document. Use [release milestones](09-mvp-roadmap.md) in dependency order. Implement only the current milestone's effects in runtime JSON; future design entries stay in Markdown until their commands and validation exist. Acceptance scenarios specify required outcomes, not an instruction to mirror implementation in tests.

| Owner | Contents |
| --- | --- |
| [02 World and territory](02-world-and-territory.md) | Claims, safe routes, boundaries, shallow interiors, losses |
| [03 Combat and defence](03-combat-and-defence.md) | Attacks, orders, guards, casualty recovery |
| [04 Construction and jobs](04-construction-and-jobs.md) | Transactions, queue, autonomy, repair and cancellation |
| [05 Survivors and growth](05-survivors-and-growth.md) | Final cast, rescues, roles and dialogue constraints |
| [06 Buildings and economy](06-buildings-and-economy.md) | Resources, production, reserves, recovery safeguards |
| [07 Zombies and pressure](07-zombies-and-pressure.md) | Sensing, noise, migration scheduling and fairness |
| [08 Experience](08-experience-and-presentation.md) | Tutorial, screens, art, audio, accessibility |
| [09 Roadmap](09-mvp-roadmap.md) | Ordered implementation slices and release gates |
| [10 Godot implementation](10-godot-implementation.md) | Authoritative state, schemas and engineering contracts |
| [11 Decisions](11-decisions-and-questions.md) | Settled choices, rationale and tuning authority |
| [12 Terminology](12-sources-and-terminology.md) | Sources, precedence and consistent vocabulary |
| [13 Campaign and map](13-campaign-and-map.md) | Adjacency, objectives, finale and continuation |
| [14 Zombie catalogue](14-zombie-catalogue.md) | Eight kinds, tells, attacks, counters and encounter budgets |
| [15 Property catalogue](15-property-catalogue.md) | All 24 sites, unique rewards, improvements and encounters |
| [16 Equipment and recipes](16-equipment-and-recipes.md) | Items, costs, prerequisites and production ledger |
| [17 Acceptance and balance](17-acceptance-and-balance.md) | Reproducible scenarios, economy examples and playtest gates |

[PROGRESS.md](PROGRESS.md) is the record of implementation and actual evidence. [TODO.md](TODO.md) is the immediate work queue. Neither a design decision nor the user's positive slice feedback proves a full campaign feature is implemented.
