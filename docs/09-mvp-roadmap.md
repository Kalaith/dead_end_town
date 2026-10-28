# From working slice to full game

The original M0–M8 framework is historical. A playable six-site slice now exists; the user reports it works well. The full campaign is designed here, not implemented by this pass. Each G milestone below is a future buildable slice with its own checks, visual inspection and immediate commit under AGENTS.md. Do not batch the whole campaign into one implementation change.

## Baseline to preserve

Six property IDs, protagonist/Mara/Paige/Ellis, Brute/Shambler, physical passages/road barriers, individual roles, shared project work, meals/recovery, unique equipment, pistol/bullets, production interruptions, original watch, schema-12 saves. Current sources and the latest [PROGRESS.md](PROGRESS.md) entries own exact implementation detail.

Preserve old discoveries and earned watch completion. A positive slice report does not validate future content, audio, exports or every recovery edge case. Do not revise the shared toolkit or install anything as part of game expansion.

## Ordered delivery gates

| Milestone | Buildable scope | Dependencies | Done when |
| --- | --- | --- | --- |
| G01: reliable common orders | General work records, idempotent bundles, blocked reasons, role resumption, reserves | Current slice | Handoff/cancel/loss/reload conservation scenarios pass; existing slice still plays |
| G02: campaign skeleton | Full 24-site geometry, 34 links, shared road lines, core route, known map | G01 | All sites reachable; no optional dependency; migrate original six without changed rewards |
| G03: sustainable Market Row | June/Oliver, clinic/greenhouse, full food rates, recovery salvage | G02 | Six-person loop sustains food; no material/medical softlock; people work physically |
| G04: mobile/attention threats | Runner, Screecher, noise and campaign migration scheduler | G03 | Telegraph/counter/reload checks; quiet/loud encounter visibly differs; home time remains useful |
| G05: Civic choices | Theo, station/radio/hall, shotgun, riot gear, Armoured and Crawler | G04 | Flank/plate/shotgun rules, forecasts, two-follower limit and route choices work |
| G06: late-game pressure | Nia, salvage/pump/power, Spitter, Breaker, guard alternate positions | G05 | Siege tell can be evaded; pool displaces guard; eight-person economy survives interruptions |
| G07: relief ending | Relay/assembly, three posts, readiness, finite waves, failure/retry/continue | G06 | Full core campaign completes; no skipped arrivals or duplicate completion on reload |
| G08: optional properties | Grocer, allotment, diner, firehall, museum, school and extra gear | G07 | Optional sites add routes/equipment and remain unnecessary to win |
| G09: production presentation | Modular art, interiors, layered gear, audio, remapping, accessibility | Art pilot can precede G03; final content after G08 | All states/tells/screens inspected with real input at fixed scale |
| G10: release candidate | Save slots/recovery, full balance/performance pass, desktop packaging | G09 | Acceptance in 17, real complete human run and platform checks recorded |

G02 includes greybox shells for optional sites, but their loot/equipment/facilities arrive at G08. Until then, they are explicitly unavailable content in development builds and cannot hold hidden mandatory rewards. G07 must be winnable without G08. No ship milestone can leave unimplemented optional promises in player-facing UI.

## Recommended implementation slices

G01: extract order ledger → migrate existing constructions → repeating production/targets → reserves/board → preserve legacy save coverage. Do not simultaneously replace all combat dictionaries and UI.

G02: new map/parcel definitions → shared-line ownership/migration → north-chain passages → protected crossings/alternate routes → fog/known overview. Prove two adjacent shared lines before extending all twelve columns.

G03: general rescue actor records → June/clinic → casualty carrying/recovery → Oliver/greenhouse → meal retune and safeguard. Keep Ellis capability checks as regression coverage in every order change.

G04–G06: introduce one enemy mechanic at a time with its tell/counter, then its first encounter, then routine-template eligibility. Make guard displacement before deploying Spitters to defended routes. Keep raw statistics in content and behaviour in simulation.

G07: readiness query → start transaction → fixed attempt events → pause/load → outage grace/failure → emergency recovery → success/ending/continue. Verify failure as carefully as victory.

G09: art/audio can progress as independent asset work, but system acceptance uses original procedural art until the art pilot passes. Do not delay a working gameplay commit for unfinished cosmetic assets.

## Save and migration strategy

Add only fields needed by the current slice. Do not reserve a guessed “final schema”. Every schema change migrates from supported historical saves and keeps a fixture for original schema 12 plus the immediate predecessor. Preserve existing lower-version migration coverage. Unknown future versions fail clearly.

Long-campaign manual/auto slots can arrive before G10 once the save owner is ready. Introduce recovery saves before human full-campaign testing, not after someone loses a two-hour run. Migration writes a new backup only after validation; it never replaces the user's only valid old file on a failed load.

## Review gates and scope control

At each major milestone run parse, simulation scenarios and headless editor/import using installed Godot. Use windowed captures for changed visuals/input and inspect them. Check file/function sizes and whitespace. No test frameworks/addons or `tests/` directory.

Record implementation, automated evidence, staged visual evidence, human observations and remaining uncertainty separately in PROGRESS. A scripted perfect-economy run proves accounting, not a fair campaign. Each working slice is committed immediately; finish with clean Git status. No pushing/publication unless requested.

If scope or pacing misses the target, first shorten travel/work repetition, reduce redundant waves and cut optional facility variations. Preserve all seven named identities, the core route, meaningful counters, trusted home defence and the finite ending. Do not fill time with slower crafting or larger hit-point numbers. Reassess the 2–3-hour core target after a complete first-time run.

## Release acceptance boundary

Required: no blocking progression/corrupt save issues; unique ownership conserved; valid recovery from home loss and full defeat; all eight tells legible; 18-core path funded; meals manageable; routine defence trusted; final attempt reloadable in every phase; complete ending/continuation; remapped keyboard/mouse and enlarged UI; measured full-town frame time; verified intended local desktop build.

Reference device and supported desktop OS list are recorded during packaging based on real available hardware, not inferred from the development editor. Web, gamepad, touch, storefront publishing and deployment remain outside this release target unless separately requested.
