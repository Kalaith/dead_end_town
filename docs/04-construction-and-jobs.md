# Hybrid construction, survivor jobs, and work orders

## One shared work site

The player places a blueprint at a valid socket. A work order tracks material commitments and completed labour. The player can work directly, leave at partial progress, and let a survivor finish. Switching workers never resets progress or charges the cost again.

Illustrative fence upgrade: four Materials and two Metal, with the first slice using Materials alone. At 60% labour the player leaves; the assigned builder completes the remainder. This is one project, not separate player and AI crafting systems.

## Placement rules

- Snap barricades, gates, and reinforcements to authored edges or openings.
- Place garden beds, storage, and workbenches in designated property slots.
- Require ownership, safe access, compatible ground, and an unlocked recipe.
- Reject blocked exits and unreachable work positions; preview the reason.
- Revalidate on completion because another structure or a breach may have changed access.

Blueprints have no completed collision benefit. A mid-build barrier should not trap a worker when its collision activates. Reserve a valid stand position and check exits at the final build step.

## Construction families

Fortifications delay and channel enemies: barricades, gates, reinforced entrances, guard posts. Property improvements support ordinary homes: gardens, storage, basic workbenches, accommodation. Facility upgrades depend on suitable captured buildings: a working garage, medical room, or greenhouse.

Whole new houses, terrain sculpting, and unrestricted walls are deferred. Restoring existing places keeps building rewards valuable and reduces navigation risk.

## Resource and labour contract

Proposed MVP: reserve the full material cost from available home stock at job creation; deduct it into the work site's committed bundle when construction begins. Available stock excludes reservations. Only one labour executor holds the site at a time in the first implementation; player takeover releases the AI assignment while retaining the bundle and progress.

Cancellation before work begins releases the reservation. Cancellation after work begins returns unused committed materials; consumed materials follow the recipe's salvage rule, shown before cancellation. A destroyed work site cannot refund the same bundle again. Repairs use bounded repair batches so interrupted work cannot repeatedly consume a full repair cost.

Visible collection and carrying are simple animations tied to reachable storage and work routes. They must not create another inventory ledger. Later multi-worker cooperation can share progress using explicit worker slots, but is unnecessary for the first proof.

## Survivor assignments

| Assignment | Main work | Safe fallback |
| --- | --- | --- |
| Guard | Hold post and respond locally | Nearby maintenance within post coverage |
| Builder | Build, repair, carry own materials | Safe salvage or idle at home |
| Grower | Tend and harvest | General work in safe territory |
| Mechanic | Restore equipment and operate workshop | General repair |
| Medic | Treatment at an operational site | Indoor general work |
| General worker | Eligible safe tasks by priority | Shelter or rest |
| Expedition | Follow squad commands | No autonomous settlement job selection |

Do not require a separate hauler. Scavenging is permitted only at explicitly safe sites inside the connected perimeter. Clearing a distant house does not authorise an unescorted worker expedition.

## Job lifecycle

`Available → Reserved → In progress → Completed`

Additional states: Interrupted, Blocked, Cancelled. Worker reservation is separate from material reservation. Store the worker lease, recipe, target, stand position, priority, labour progress, committed materials, and block reason.

When danger interrupts a job, release the worker lease, preserve progress and material accounting, and make the site ineligible until safe. When a route or prerequisite is missing, block with a readable reason and retry only after a relevant change or bounded interval. When the target is destroyed, cancel or transform into an explicit reconstruction order. Never retry in a tight loop.

Candidate ordering: emergency response first, then critical repair, role fit, player priority, route cost, and age. Use stable tie-breaking to avoid task oscillation. A reservation expires when its worker is unavailable; duplicate workers cannot both complete or refund one order.

## Authority and autonomy

Maintenance can be automatic within a visible policy: repair existing defences up to a player-set material reserve, tend crops, and finish approved construction. Expansion is player-directed: new buildings, demolition, new facilities, property claims, and major upgrades require an explicit order.

Emergency repair does not justify a worker standing outside a gate in an active crowd. Safety checks outrank urgency. After an alert, survivors resume still-valid work without requiring manual reassignment.

## Work board

The board explains what the town is doing: target, assigned person, progress, priority, materials, and blocked reason. Selecting a job highlights its physical site. The normal flow is to place a blueprint in the world; the board is for oversight and correction.
