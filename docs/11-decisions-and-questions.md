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

The initial request produced this design package. The subsequent request explicitly authorises starting the game using another neighboring project as a template and adopting `../godot_toolkit`. The initial runtime and evidence are recorded in [PROGRESS.md](PROGRESS.md); the design is still broader than the implementation.

## Initial engineering defaults, 28 October 2026

- Q01: installed Godot 4.7.2 standard editor, Compatibility, desktop first. Web and Windows exports remain to configure and verify.
- Q02: original procedural top-down greybox at 1280x720, small authored four-property map. Final art and animation budget remain open.
- Q03: keyboard/mouse first, WASD/arrows, mouse aim and bat attack. Remapping, controller and touch remain future work.
- Q04: Esc/Tab pauses all authoritative simulation. No offline progression.
- Q14: prototype defeat returns the protagonist home at full health and preserves the street, jobs and discoveries. Downed companions recover by resting at the safe home porch. This forgiving prototype rule still needs a playtest.

These are implementation defaults chosen to begin the requested work, not additional confirmed creative commitments. The open-question table remains the broader review agenda.

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
| Q04 | Can construction/orders pause action? | M1–M2 | Test full pause for planning against live action clarity |
| Q05 | Stamina, dodge rules, friendly fire, weapon durability? | M1 | Add only what improves small melee encounters |
| Q06 | Can control switch between survivors? | M2 | Fixed protagonist first; do not assume possession or multiplayer |
| Q07 | Companion cap and guard coverage for a tiny roster? | M2–M3 | One companion first, then test two; routine home attacks must be manageable |
| Q08 | What precisely turns a contested property into lost territory? | M4 | Visible occupation and warning; never an arbitrary hidden expiry |
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
