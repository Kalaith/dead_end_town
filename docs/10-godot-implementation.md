# Proposed Godot implementation

## Status and baseline

This is an implementation plan, not existing code. Use a supported Godot 4 release with GDScript and top-down 2D as the working direction. Pin the exact version, renderer, desktop target, and export requirements at M0. No installed engine version or device performance has been inspected for this documentation task.

The official references linked below were checked on 28 October 2026. Stable documentation may move; use the version-specific equivalent once the engine is pinned.

## Proposed project layout

```text
project.godot                 # created when implementation begins
scenes/
  world/town.tscn
  actors/player.tscn
  actors/survivor.tscn
  actors/zombie.tscn
  properties/property.tscn
  structures/barrier.tscn
  ui/hud.tscn
scripts/
  world/                     # territory, routes, noise, threat
  actors/                    # movement, combat, orders, work executor
  systems/                   # jobs, inventory, facilities, persistence
data/
  properties/ equipment/ recipes/ survivors/
assets/
tests/
```

This tree is proposed; these runtime files are not part of the current documentation package.

## Scene responsibilities

`Town` contains terrain layers, property instances, actors, and local managers. Terrain uses `TileMapLayer` with reusable tile resources; dynamic gates and barricades are separate scenes. Godot supports separate tile layers for organisation and collision/navigation data; see [Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html).

Use `CharacterBody2D` as the initial actor body choice, with explicit movement and combat components. Interaction and hit detection use separate areas. Keep damage, collision, and target selection independent of animation callbacks where possible. Each survivor uses the same actor capabilities with a different decision source: player input, squad order, guard assignment, or work execution.

Avoid many global singletons. Keep world-specific systems under the town scene and inject their references. A small application/session service can manage loading, menus, and save slots.

## State ownership

| System | Owns | Emits or exposes |
| --- | --- | --- |
| Territory | Claimed property IDs, connection graph, exposed edges | Connection and control changes |
| Inventory | Stock, reservations, unique item location/owner | Committed transfers and availability |
| Jobs | Work order lifecycle and worker leases | Progress, completion, block reasons |
| Facilities | Operational state and production sessions | Eligible work and outputs |
| Threat | Local alerts and migration groups | Approaches, breaches, resolutions |
| Noise | Short-lived spatial sound events | Investigation candidates |
| Actor state | Health, position, loadout references, current action | Incapacitation, order result |
| Persistence | Versioned snapshots of authoritative state | Validated load or recoverable failure |

A UI button requests a command; it does not edit several managers' data directly. Validate and commit a claim, item transfer, or job completion once. Signals update presentation after the commit. Derived overlays are rebuilt from authoritative data.

## Data definitions and instances

Use custom Resource definitions for equipment, recipes, property types, and survivor identity. Mutable instances are separate records; modifying one survivor's equipment must not mutate a shared definition.

Suggested stable fields:

- Property: ID, polygon, neighbour edge IDs, claim point, sockets, facility definitions.
- Edge: ID, adjoining parcels, openings, route link IDs, structure instance IDs.
- Survivor: ID, identity definition ID, position, health, assignment, order, equipment instance IDs.
- Equipment instance: ID, definition ID, owner or container ID, restoration state.
- Job: ID, recipe ID, target ID, state, labour progress, worker lease, material reservation/bundle IDs, blocked reason.
- Zombie/group: ID, position or route progress, health/population, behaviour target, simulation owner.

Do not save runtime node instance IDs as persistent identity. Validate content IDs and retain tombstones or completion flags for unique loot and rescues.

## Navigation and construction

For the snapped MVP, favour an authored walkability grid plus a property/entrance graph. A gate changes explicit passability; a destroyed barricade opens its cells. Queue route recalculation after collision and route data update, then revalidate orders. Use one collision mask convention for walls, gates, actors, interactions, and attacks.

If using navigation meshes later, distinguish pathfinding from local avoidance. Godot navigation obstacles affect avoidance or baking; adding an obstacle is not a complete runtime wall-routing solution. Explicitly update walkability or appropriate mesh/link state. See [Using NavigationObstacles](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationobstacles.html).

Construction validation uses the same route model as workers. Check stand positions, storage access, occupied exits, and final collision. Debounce graph updates when several nearby structures change. A route failure must block the job with a reason rather than make the actor walk forever into a fence.

## AI arbitration

Use a small hierarchical state machine or equivalent decision layer: incapacitated → immediate safety response → explicit squad order or guard duty → eligible job → safe idle. The ordering is conceptual: explicit orders still obey physical safety and capability checks. Guard duty cannot be superseded by routine work.

Jobs reserve a worker with an expiring lease. Resource reservations are independent and persist across worker changes. Completion is idempotent: a completed job ID cannot apply its output twice. Retrying an order after a signal or load must preserve that invariant.

## Continuous simulation

First keep the entire small street active at a fixed simulation step. Spread expensive sensing and route requests over frames and spatially index nearby targets. Profile actor counts, route cost, and collision before choosing a larger architecture.

Later tiers may be: full nearby actors; coarse actors and route segments in distant secured areas; group populations in distant infected space. The coarse model must preserve entry routes, barriers, weapon limits, damage, retreats, and elapsed time. A single readiness score must never award victory or defeat.

Handoff protocol: freeze the outgoing representation at a tick boundary; transfer stable IDs, positions/route progress, health, ammo, targets, and remaining work; create the incoming representation; then release the old owner. Each entity has one simulation owner. Groups split without duplicating population. Apply hysteresis at tier boundaries to prevent repeated conversion as the player moves.

If believable off-screen combat cannot yet be preserved, keep threatened home zones fully simulated and reduce scope. Do not ship invisible losses from an unvalidated abstraction.

## Save/load

Store versioned state under `user://` with explicit IDs and plain serialisable values. Godot's [Saving games guide](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) demonstrates `FileAccess` and JSON; the production schema here also needs graph, reservation, and identity validation.

Snapshot world time, player and survivors, property/control state, structures, inventories, jobs and material bundles, discovered content, loot depletion, production progress, zombie/group state, and random generator state where used. Save once at a coherent simulation boundary. Write a temporary save, validate it, then replace the active slot using a platform-tested strategy and retain a prior good backup.

Load in phases: definitions → persistent entities → inventory ownership → structures and route graph → jobs and leases → threats → presentation. Revalidate interrupted work and paths. Reject unknown schema versions with a clear message or run an explicit migration. Do not silently discard a corrupt stockpile and continue.

Pause all relevant clocks consistently. Proposed default: no offline progression while the game is closed, avoiding unseen attacks between sessions.

## Engineering verification

Automate graph connectivity/perimeter cases, job transitions, resource conservation, unique item ownership, claim idempotency, and save round trips. Add debug overlays for routes, edge exposure, job reservations, noise, guard leashes, and zombie origins.

Measure actual frame time and AI workload on an agreed reference device before setting supported town size. No frame-rate target or export compatibility is verified by this package.
