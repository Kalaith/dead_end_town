# Continuous world and territory

## Physical layout

Properties are authored parcels containing buildings, yards, entrances, claim points, loot, and construction sockets. Streets and alleys are walkable spaces with their own threat exposure. Being adjacent on a map is insufficient: a usable connection needs a real traversable entrance or corridor.

The home is the root of the settlement connection graph. Properties can be cleared far from home, but remote sites do not automatically join the productive settlement. A street crossing requires a designated corridor with visible defensive exposure; the player cannot claim arbitrary disconnected islands by clicking them.

## Implemented temporary road defences, 28 October 2026

The home/library pair unlocks barricades joining their west and east fence ends across the road. Garden/garage unlocks another pair. Claiming changes socket availability; it never creates free walls. Build each defence through its nearby E/R/F work interaction. A completed barricade blocks the player, companions and zombies, and shamblers attack a blocking road defence before continuing toward their target. G stations one survivor on the inside. Low barricades allow melee defence over them.

To advance, dismantle an inner barricade for salvage and build at the next captured pair. Removal leaves collision active until work completes, then opens the route and pays salvage exactly once. The opposite front remains intact. Defenders on a removed or breached line return home; other posts remain assigned. This proves temporary road barriers, not all exposed parcel edges, flanking routes or safe production corridors.

## Property states

| State | Meaning | Player benefit |
| --- | --- | --- |
| Infected | Occupied or exposed to established zombie presence | Exploration and recoverable loot |
| Cleared | Immediate occupants defeated; no secure connection established | Temporary access, no guaranteed safety |
| Secured | Claimed, connected to home through valid passages, and locally safe at claim time | Facility and work eligibility |

Operational status is separate: a secured property can be threatened, breached, disconnected, or damaged. A single wandering zombie does not instantly reset ownership. It makes the affected work unsafe and can lead to loss if control cannot be restored.

## Claim transaction: proposed default

The player interacts with the claim point. Validate that the property has no active hostile occupant, the connection reaches home, the entrance is usable, and a defensible boundary plan exists. Show failed conditions directly. Commit ownership, discover available facility options, recalculate exposed edges, and create only player-approved work orders.

A boundary plan may contain unfinished or damaged barricades. Claiming does not conjure walls or guarantee safety. Display exposed openings before the player confirms the claim. Blueprint completion remains physical work.

Reclaiming a lost property restores its previous improvements where they survive. Unique discoveries and rescue rewards are not granted twice.

## Connected perimeter

Every authored parcel edge has a stable identity, neighbours, openings, and any physical wall or gate. The exposed perimeter comprises edges separating the home-connected secured component from uncontrolled space. Include street corridors and alleys explicitly; a narrow connection has two vulnerable sides.

When two neighbouring properties become connected, their shared edge becomes internal for defence planning. Existing fences remain until opened or dismantled by a player order. Ownership never silently removes collision or gives free construction materials.

Concave blocks, holes of infected territory, and enemy-accessible courtyards still have exposed edges. A simple rectangle around all owned properties would incorrectly mark these safe. Use authored edge relationships and actual entrance reachability.

## Example

Home A connects east to house B. Their common fence stops counting as an outer defence, but still blocks travel until its gate opens. Claiming house C north of B creates an L-shaped settlement: its inner corner remains exposed. Capturing the corner property D can shorten the defended boundary and make circulation easier even if D has modest loot.

This makes compact expansion useful without awarding an unexplained adjacency multiplier.

## Disconnection and loss

1. A breach opens a physical route for zombies and raises local danger. It does not automatically sever every property beyond it.
2. A corridor becomes unsafe or blocked. New worker travel through it stops; remote facilities pause if no alternative safe route exists.
3. Isolated survivors shelter or retreat along a verified route. They never teleport to the stockpile.
4. A claimed property falls after eight active seconds with living zombies physically inside its yard and no standing player or survivor inside. A brief warning and draining porch bar show the occupation. Returning a living defender or clearing all occupants resets it. Closed gates and road barricades prevent occupation until attackers physically enter; downed people cannot defend. This applies to home too. Loss pauses facilities through the ownership graph; surviving improvements and discoveries remain. Clear the yard and use E at its porch to reclaim without repeated loot/rescue rewards.
5. The player clears the route or site, restores connectivity, and repairs damage. Previously recovered knowledge and rescued survivors remain.

Disconnected stock is unavailable for new orders. For the MVP, keep the single physical stockpile at home; do not implement distributed warehouses until routing and recovery are proven.

## World continuity

Expedition and home share a clock, threat events, and persistent identities. Camera distance must not cancel an attack or regenerate loot. Initially keep the whole small prototype active. Later simulation tiers must preserve the same outcomes and entry routes; see [Godot implementation](10-godot-implementation.md).
