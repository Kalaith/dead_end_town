# Godot implementation contracts

Full game architecture built from the existing slice, not a replacement-engine proposal. Godot 4.7.2 standard, Compatibility, 1280×720. This design-only pass does not change scripts, JSON, saves, toolkit or project settings. API documentation is not re-researched; these contracts describe project-owned responsibilities.

## Retain the authoritative layers

| Layer | Owns | Must not do |
| --- | --- | --- |
| scripts/sim | Pure fixed-step state, commands, combat, movement, routes, jobs, pressure | Scene tree, Time, OS, global random calls |
| scripts/core | JSON validation, typed definitions/mapping, save schemas/migrations | Decide combat from UI or silently default malformed data |
| scripts/presentation | Input commands, camera, drawing/animation, audio, menus | Directly mutate health, stock, jobs, collision truth or discovery |
| data | Implemented balance, content IDs, shapes, costs, catalogues | Contain unsupported “future” effects |
| tools | Headless scenarios, parse/capture entry points | Export test code or introduce test frameworks |

Keep `scenes/town.tscn` as the composition root. Presentation may grow into separate visual actor/property scenes, but `CharacterBody2D`/animation callbacks never become authoritative movement or damage owners. Simulation resolves collision and exposes positions; visual nodes interpolate. Do not migrate rules into engine physics as a side effect of adding art.

The shared ignored `addons/hatchery` junction supplies JSON IO/validation/save, UI and verification helpers. Recreate through the existing linker. Do not edit toolkit code to add game rules. Adopt existing toolkit bindings/settings/text helpers when G09 needs them; no new plugin/install dependency.

## Model and command boundaries

Use the existing 0.05-second fixed step. Every command validates current state and returns success/reason plus committed events. UI previews may be stale; command validation is authoritative. Stable IDs resolve persons, property, links, structures, item instances, orders, waves, attempts and discoveries.

Suggested command families: move/aim/attack/fire, interact/search/claim, approve/cancel/remove/repair, assign role/order/post, set stock target/reserve, equip/return item, carry/place/treat, start/abort signal, request snapshot. Keep one atomic owner per transaction; do not let a screen spend supplies then call a second method that might reject the work.

Fixed-step order: consume commands → resolve movement/attacks → damage/incapacitation → occupation/ownership → invalidate routes/operability → advance eligible work/meals → admit scheduled migrants → evaluate objectives/attempt outcome → emit presentation events. Newly admitted enemies cannot hit in the admission tick. Simultaneous lethal damage resolves before objective success, so a defeated protagonist cannot also win on the same tick. Define and scenario-check this ordering before changing the current loop.

Randomness belongs to owned saved RandomNumberGenerator streams. Prefer separate roaming and pressure streams so adding a cosmetic/UI event cannot alter migrations. Save integer RNG state without precision loss. Presentation random variation never changes authoritative results.

## State ownership and data shape

| Owner | Authoritative state | Derived/rebuilt |
| --- | --- | --- |
| Territory | Held/search flags, occupation, gate/structure health | Safe component, exposed edges, operational reasons |
| People | Position, health, capability, role/order, carry state, attack phase | Available menu choices, formation waypoints |
| Equipment | Instance definition, single owner, restored flags | Effective stats/silhouette |
| Inventory/jobs | Available stocks, committed bundles, work/output finalization | Board filters, can-afford previews |
| Pressure/noise | Scheduled events, actor origins/intent, active sound events | Spatial index and warning text |
| Campaign | Discovered keys, act records, attempt state, completion | Current next-step list/readiness explanation |

Introduce cohesive state modules before hubs grow past about 600 lines; hard limits remain 800/file and 400/function. Typed records/classes can replace fragile dictionaries incrementally. Preserve public entry points while moving a responsibility. Do not use giant actor inheritance or a kind switch spread across presentation.

Current content stays under `data/street/*.json` and `data/zombies.json`. Future campaign content can use `data/campaign/` with separate map, district properties, facilities, recipes, equipment, survivors, pressure templates and objectives. The catalog composes these into one validated definition graph. Preserve existing IDs and load compatibility rather than treating a directory move as a new game.

Validation checks type/range, unknown IDs/effects, duplicate identities, every referenced socket, link endpoints, reward ownership, item source, prerequisite cycles, core reachability without optional sites, population/composition totals and exact fixed wave budgets. Missing required data fails with file/ID/field; migration is the only place old fields receive explicit historical defaults.

## Navigation and collision

Extend the existing authored walkability/route model. Each structure has a footprint, height/fire-block category, work stand and protected side. Gate/line health changes update collision at a tick boundary, then link eligibility and path caches. Worker paths use protected areas; expedition/zombie paths may use exposed roads. Both obey the same solid walls.

Broad-phase spatial indexing bounds target/noise/structure queries. Spread noncritical route replans over ticks and cache until geometry/target invalidates. Do not run an all-town path search per actor every tick. Occupancy checks include downed/carried footprints. Build completion cannot close a gate on an actor; wait rather than teleport.

Shallow room floors/roof fades are presentation over the same collision geometry. Separate low barrier fire allowance from travel blocking; no blanket “line clear ignores every defence” flag. Kind attacks invoke the shared collision/damage service and their own phase data, not animation signals.

## Persistence and slots

Save coherent snapshots at fixed-step boundaries under `user://`. Three named manual slots, three rotating autosaves and four protected district-entry recovery snapshots. Keep the legacy `street.json` import path. Never overwrite a manual slot through autosave. Store displayed campaign time, location/district, roster and schema as validated metadata, not an independent authority.

Autosave every five active minutes when not in immediate attack danger, after first district entry at a clear approach, and once on final completion. If danger persists, postpone the periodic save, but an explicit paused manual save remains available anywhere, including combat/finale. Do not indefinitely accumulate deferred save requests. The final attempt also creates a pre-start recovery snapshot; failed saving does not spend readiness stock or launch automatically.

Snapshot includes world clock, RNG streams, all living actors and defeated resident IDs, health/action phases/cooldowns/statuses, people/roles/loadouts, carries, properties/searches, structures, safe-link source geometry, stocks/bundles/orders/output flags, food clock/shortage, active noise, migrations/warnings/pending finale members, discoveries, dialogue flags, attempt grace/clock/completion and difficulty preset.

Do not save nodes, runtime instance IDs, UI focus, cached navigation or derived safe flags as authority. Reconstruct definitions → entities/ownership → geometry → routes → orders/leases → pressure/objective references → presentation. Remain paused until all validation finishes; loading consumes no simulation time.

Use toolkit staged write/backup recovery. A failed save retains progress, live stock and prior valid slots; show reason and retry. A corrupt latest autosave can offer earlier valid rotation/backup with timestamp/location. Never silently create a fresh campaign in place of an invalid load. Unknown newer schema is a readable incompatibility.

## Expanding old streets

Keep the first six property identities/positions, old loot/search/timber state, people, unique items and partial projects. Add 18 new unsearched/unheld sites and their 58 authored residents once. Original living enemies remain untouched; do not replace garage residents with a Brute or reroll defeated actors. Existing completion means slice watch complete, never campaign victory.

An old street may already have 48 living actors; adding 58 can make 106. Preserve them all as a grandfathered migration overage above the normal 96 cap. Admit no new routine migrant until below cap; do not delete/damage/queue existing actors. Scenario-check and profile this explicit 106-actor case. Finale cannot start while capacity would prevent its valid admission semantics.

Expand bounds/geometry while the load screen is paused and show “Your street continues east” once. No newly added actor occupies an original held parcel. Apply full game meal interval without retroactive consumption: retain the proportion of current meal elapsed, mapped to 120 seconds, preserve shortage/stock. Completed facilities/paid work are never rebilled at new costs. Existing worn items map one-to-one to stable instances.

Allocate schema numbers only when implementing changes. Keep per-step migrations small, deterministic and testable; preserve lower-version fixture coverage. A migration that fails validation leaves source/backup untouched.

## Simulation scale and presentation events

Target 60 fps on a recorded reference machine with 96 living zombies, eight people, 24 properties and the busiest legal special attacks. Measure the 106-actor migrated case too. This is a target, not verified performance. Keep the whole active world authoritative; no distant fight abstraction or tier handoff is needed for release scope unless profiling proves otherwise.

Presentation consumes typed events for discharge, hit, work, warning, discovery, loss, casualty and attempt transitions. Event IDs prevent replayed audio/rewards on load. Persistent state determines every visual; particles/sounds cannot spend stock. Fast visual interpolation can smooth 20 Hz without changing collision.

## Verification and deployment boundary

Use installed console Godot for parse, simulation scenarios and editor/import checks at milestones. Add focused meaningful scenarios in tools, no tests directory/framework/addon. Windowed captures through toolkit paths prove inspected states only. Human input, audio, combat feel, performance and exports each need their own recorded evidence.

No implementation, engine run, export configuration, install, external publication or toolkit change is performed by this design pass. Publishing wrappers remain boilerplate without a configured destination. Future deployment is a separate explicit user action.
