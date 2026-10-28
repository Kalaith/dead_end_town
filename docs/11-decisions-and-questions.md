# Decisions and open questions

## Confirmed direction

| ID | Decision | Basis |
| --- | --- | --- |
| D01 | Everything happens in one continuous world | User selected NEARBY |
| D02 | Player and AI survivors can both build and repair | User selected hybrid construction |
| D03 | Few named survivors with meaningful identities | User described them as few and symbolic |
| D04 | Survivors cooperate; avoid interpersonal drama and colony-sim scope | Latest survivor-management direction |
| D05 | High-level growth mainly through key items and equipment | Latest progression direction |
| D06 | Rescue a D&D-fan librarian who may eventually wear full iron armour against a wave | User's Page/Paige example |
| D07 | Document connected property reclamation, home defence, jobs, production, rewards, pressure, and Godot implementation | Current project request |
| D08 | Keep gameplay information sparse; remove the persistent bottom panel and place details in pause | User feedback after basic combat/territory playtest, 28 October 2026 |
| D09 | After taking both properties, barricade the street from both directions; dismantle temporary defences to reclaim materials as the front moves | User request after a further game playtest, 28 October 2026 |
| D10 | Direct survivors individually, such as Mara gardening and Paige working at the workshop while the player guards | User request after recruiting Paige, 28 October 2026 |
| D11 | Increase resident numbers, recurring raids and attack directions so each territory gain feels fought for | User feedback that zombies are not a threat, 28 October 2026 |
| D15 | Implement physical neighbourhood integration, equipment choices, useful food and a clear slice objective, then return for user testing | User implementation request, 28 October 2026 |
| D14 | All zombies wander when idle; nearby living people override wandering; basic player melee hits one zombie per swing | User feedback about stationary occupiers and overly strong attacks, 28 October 2026 |
| D13 | Undefended buildings fall quickly to zombie occupation; physical security buys time | User feedback that zombies cannot retake territory, 28 October 2026 |
| D12 | Remove map status/count/reward text and reveal Paige only when rescued | User requests less screen text and discovery without spoilers, 28 October 2026 |

The initial request produced this design package. The subsequent request explicitly authorises starting the game using another neighboring project as a template and adopting `../godot_toolkit`. The initial runtime and evidence are recorded in [PROGRESS.md](PROGRESS.md); the design is still broader than the implementation.

## Initial engineering defaults, 28 October 2026

- Q01: installed Godot 4.7.2 standard editor, Compatibility, desktop first. Web and Windows exports remain to configure and verify.
- Q02: original procedural top-down greybox at 1280x720, small authored four-property map. Final art and animation budget remain open.
- Q03: keyboard/mouse first, WASD/arrows, mouse aim and bat attack. Remapping, controller and touch remain future work.
- Q04: Esc/Tab pauses all authoritative simulation. No offline progression.
- Q14: prototype defeat returns the protagonist home at full health and preserves the street, jobs and discoveries. Downed companions recover by resting at the safe home porch. This forgiving prototype rule still needs a playtest.

These are implementation defaults chosen to begin the requested work, not additional confirmed creative commitments. The open-question table remains the broader review agenda.

## Road defence engineering defaults, 28 October 2026

The current map treats home/library and garden/garage as facing pairs. Each pair unlocks two authored road sockets. Build cost 8, work 8 seconds; removal 4 seconds; undamaged salvage 6, reduced proportionally by damage. These quantities and the facing-pair interpretation are implementation defaults, not separately user-selected balance. G assigns one survivor to a physical inside post. Structures remain vulnerable, and no safe-corridor claim is implied.

## Pressure engineering defaults, 28 October 2026

The first street now has 7 garden residents, 7 library residents and 10 garage residents. The first migration enters at 45 active seconds. A 12-second radio warning names its origins. The repeating sequence is east; west; north + east; south + west; all four edges. Initial waves have 4 zombies, adding 2 per claimed property beyond home, up to 10. Intervals start at 65 seconds and fall by 8 seconds per additional property (41 at full ownership, configured floor 40). These are tuning defaults in `data/street.json`, awaiting human balance review.

Migrations enter at authored map edges and now wander randomly like residents. The earlier nearest-property destination and mandatory alley-to-road travel have been superseded by D14; local pursuit overrides idle wandering. The total living population is capped at 36; excess arrivals are skipped, rather than queued into a sudden backlog. Residents stay defeated. Save schema 5 preserves the wave clock, warning and travel phase; older saves keep claimed yards cleared and get 65 active seconds of preparation. Noise and a final reclamation objective remain future work. Territory loss is implemented below.

## Territory loss default, 28 October 2026

Eight active seconds of unopposed living zombie occupation inside a claimed yard causes loss, including home. A living player or survivor inside contests it; downed actors do not. Existing walls, gates and road defences protect by blocking entry, without granting an abstract immunity bonus. Warning messages and a draining porch bar precede loss. Previously looted sites can be cleared and reclaimed without repeated rewards, rescues or construction charges. Facilities require restored home connectivity. Save schema 6 preserves occupation and discovery separately from ownership, migrating schemas 1ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ5. The eight-second value is initial tuning awaiting human review.

## Wandering and melee defaults, 28 October 2026

All shamblers choose independent random headings every 0.8–2.8 active seconds and turn again if blocked. The nearest living player or survivor within 240 pixels takes priority immediately and supplies a local movement goal, even through an unfinished wander heading. Downed people are ignored. Zombies head directly toward that person, with physical collision and bump damage against blocking defences; they do not find routes around walls. When nobody is in range, idle wandering resumes. Entrances and occupation points are not fixed destinations. They bite on contact and damage gates/barricades they bump into. The seeded generator and heading clocks persist in schema 7, with migration from schemas 1–6. Basic melee hits the nearest legal zombie once per swing; surviving enemies in the same cone are untouched. These movement intervals are initial tuning; no future weapon or cleave upgrade is implemented.

## Proposed defaults used across this package

| ID | Working choice | Reason to start here |
| --- | --- | --- |
| P01 | Single-player top-down 2D, Godot 4, GDScript | Small enough to prototype continuous action and AI |
| P02 | Authored street with four functional properties | Tests route and reward variety without full-town content |
| P03 | Home-rooted connected graph plus physical edge/entrance data | Makes ownership and perimeter explainable |
| P04 | Snapped construction sockets | Limits trapped actors and invalid layouts |
| P05 | One active executor per work site initially | Simplifies correct shared progress and accounting |
| P06 | Materials, Food, Ammunition first | Keeps economy small |
| P07 | Incapacitation and recoverable territory setbacks | Supports experimentation with a small cast |
| P08 | No offline progression | Prevents unseen losses while closed |
| P09 | Fully active MVP street; tiers only after profiling | Preserves reliable defence before optimisation |
| P10 | Paige is the working spelling | Matches current request and most prior development |

These defaults allow useful prototyping without implying that the user approved every numerical or technical detail.

## Open questions, ordered by when they matter

| ID | Question | Resolve by | Recommended starting point / evidence |
| --- | --- | --- | --- |
| Q01 | Exact Godot release, renderer, and desktop target? | M0 | Inspect local tooling and export requirements; pin one version |
| Q02 | Tile scale, view angle, animation detail, asset budget? | M0 | Test a greybox street and one readable equipment silhouette |
| Q03 | Keyboard/mouse only or controller from the start? | M0 | Pick primary input; preserve remapping and command accessibility |
| Q04 | Can construction/orders pause action? | M1ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“M2 | Test full pause for planning against live action clarity |
| Q05 | Stamina, dodge rules, friendly fire, weapon durability? | M1 | Add only what improves small melee encounters |
| Q06 | Can control switch between survivors? | M2 | Fixed protagonist first; do not assume possession or multiplayer |
| Q07 | Companion cap and guard coverage for a tiny roster? | M2ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“M3 | One companion first, then test two; routine home attacks must be manageable |
| Q08 | What precisely turns a contested property into lost territory? | M4 | Implemented: eight seconds of unopposed physical occupation with a warning; tune after playtest |
| Q09 | What qualifies a road corridor as safely connected? | M4 | Authored crossings with explicit access and exposed boundaries |
| Q10 | Cancellation salvage, repair batch costs, reserve limits? | M5 | Check resource conservation and player understanding |
| Q11 | Food upkeep, injuries, shortage consequences? | M6 | Forgiving warnings before severe penalties; no detailed need simulation |
| Q12 | Final spelling Page or Paige and final roster? | Before character art | Paige working name; retain only distinct useful characters |
| Q13 | Armour source, restoration prerequisites, equipment tradeoffs? | M6 | One cache and workshop recipe; test shield/armour readability |
| Q14 | Protagonist defeat, rescue, and reload policy? | Before M7 | Choose recoverable checkpoint/rescue rules and verify persistence |
| Q15 | Map-edge influx, horde frequency, eventual victory? | M7 / campaign design | Establish calm intervals and a sustainable ending |
| Q16 | Full-game property count, playtime, final named-survivor count? | After M8 | Derive from content cost and slice playtests |
| Q17 | Multiple floors, vehicles, day/night, permadeath, multiplayer? | Post-MVP | Defer unless the core loop proves a specific need |

## Earlier ideas superseded or constrained

Earlier discussion suggested activity-trained skills, four ability tracks, experience-based confidence, and survivor-specific progression. The later user direction simplifies growth to key discoveries and equipment. Do not implement hidden grind or class prerequisites from the earlier brainstorm.

Eight to twelve survivors, one controlled character plus three companions, museum armour, final town-hall reclamation, and distant simulation tiers were suggestions. They are reference possibilities rather than locked scope.

## Maintaining the package

When a choice is resolved, record the date, rationale, and affected documents here, then update the owning system document. Avoid leaving contradictory rules in a later appendix. Record implementation and test results separately once work begins; a design statement is not evidence that a feature works.


## Expanded slice defaults, 28 October 2026

The requested four systems are implemented for the current authored street. Physical integration uses paid, fenced yard passages and explicitly protected street crossings; productive workers use safe routes. Any actor can equip the unique recovered crowbar, sword, iron and shield at the connected workshop. Shared meals cost one food per person every 60 active seconds; shortage reduces work to 60%, with no hunger injury. Recovery costs two food. Three finite timber caches provide ten materials each, including for migrated runs.

The slice objective is **A street worth keeping**: all four clear, held yards physically connected to home, four food actually harvested, restored equipment deployed, everyone standing and one meal reserved, then 60 active seconds of neighbourhood watch started at home. Setbacks restart the watch; completion remains earned during continued play. This is an implementation default for testing, not the final campaign ending. Values and encounter feel await user feedback. Schema 11 preserves the new states and migrates previous saves.
