# Continuous world and territory

Full game contract. [13](13-campaign-and-map.md) owns the 24-site topology; [15](15-property-catalogue.md) owns contents. The six-site runtime already separates ownership from protected connectivity, but does not yet implement the whole map or interiors.

## Property record and independent states

A property has a stable ID, yard polygon, building footprint, room floor, entrances, porch claim point, improvement sockets, neighbour edges and authored initial occupants. Clearance, discovery, ownership, connection and operation are separate facts.

| Fact | Definition | Changes when |
| --- | --- | --- |
| Cleared | No living hostile in its yard/rooms and no pending initial occupant | Occupants enter, leave or die |
| Searched | One-time search transaction committed | First successful search; never resets |
| Held | Claimed and not lost to unopposed occupation | Claim or occupation completes |
| Ownership-connected | Held chain through authored adjacent parcels to held home | Any ownership change |
| Safely connected | Actual usable protected route through clear held parcels to home | Gates, structures, hostiles or geometry change |
| Operational | Held, safely connected, locally safe, fixture intact/restored and recipe prerequisites available | Relevant condition changes |

The word “secured” means held and safely connected at the time being described. It is not another persistent tier. A single hostile can make production unsafe without immediately changing ownership. A destroyed gate is a breach, not automatically a lost parcel.

## Search and claim commands

For the first six sites, retain the existing combined porch discovery/claim interaction for compatibility. For new sites, a clear local search may precede a claim: stand at the search point, require site clear and protagonist standing, commit finite supplies/key discoveries/rescue exactly once. No home connection is required to search. Searching does not award the claim stipend.

Claim at a clear porch requires: standing player in interaction range, all initial occupants resolved, site clear, and one held adjacent site in the ownership-connected home component. The target's gate must be physically reachable, not necessarily repaired/closed. Home is the root and may be reclaimed without a neighbouring claim. Claims have no material fee and create no free structure. First claim grants the site's six-Material stipend once; recapture never repeats it.

Show unmet conditions without revealing unknown rewards. A blueprint boundary is not safe protection. Never require a completed paid passage as a prerequisite for claiming its unheld endpoint: this would create a construction dependency cycle. Paid connection work follows a successful claim.

## Safe route algorithm

Build a home-rooted graph over clear held parcels and authored link corridors. A link is eligible only if its endpoints are held, its route footprint is free of hostiles, required protection exists/intact, and its traversable entrances are open and wide enough for the actor. Also require a collision-valid path through each intervening yard/room. Ownership adjacency alone is insufficient.

For a same-row link: completed fenced passage, enclosing rails intact, passage gate open/intact. For a crossing: both boundary road barriers intact, both facing yard gates open/intact, no hostile in the protected road corridor. Use the shared boundary lines in 13; an inner barrier's collision can block a longer road route even though it helps a short crossing.

Choose safe paths by length with stable edge-ID ties; a longer safe route beats a shorter exposed street. Recompute eligibility on relevant changes and revalidate before a worker starts a segment. Existing travellers stop at a safe side and report the block. Never walk into a known infected yard to satisfy a work order.

Temporary closing of a gate can suspend production. All gates remain manual for this release; workers report the obstruction rather than opening the player's defence to finish a harvest. Opening an internal passage gate can restore a safe route without opening the street-facing gate.

## Exposed perimeter

Authored edges identify adjacent parcels, street corridors, rear paths, existing fixed walls and breakable openings. Compute the boundary of the safely connected component, including infected holes, concave corners and narrow corridors. Shared edges become strategically internal, but their collision remains until an approved passage or demolition changes it.

Do not draw a rectangle around held land and call everything inside safe. Exposed rear routes remain exposed even if an adjacent road is blocked. Fortification sockets on alleys physically close the relevant mouth; there is no abstract “defence coverage” immunity.

The overview can show exposed openings, weak lines and routes. These are advisory. Actual actors, barriers and travel determine whether a defence holds.

## Occupation and loss

Any living zombie inside a held parcel begins occupation if no standing player or recruited survivor is inside. Downed actors cannot contest. Eight continuous active seconds loses the parcel, home included. A standing person entering or the last zombie leaving/dying resets occupation to zero. Save the partial timer; pauses and loading consume no time.

At first occupation, one local alert and draining claim-marker bar show the danger. Escalate once near loss, then once on loss. Immediate local work suspension is independent of this timer. Zombies cannot occupy from outside an intact fence merely by being nearby.

Loss clears ownership, not search/discovery flags, surviving buildings, equipment ownership, committed work or killed resident records. Production pauses. Reclaim through the ordinary clear/adjacent rule, with home exempt from adjacency. Restored improvements become usable when access/safety return. All disconnected parcels can remain held; they do not automatically chain-fall without physical occupation.

If home falls, all productive operations pause. People use explicit safe hold/retreat points. Emergency recovery can rebuild a recoverable foothold; see 03. There is no requirement to teleport workers into an occupied home.

## Shallow interiors

Ground-floor rooms are open-front spaces in the same simulation: roof fades when the player is near/inside, upper walls remain collision, no loading, no separate loot clock. One or two rooms per landmark; ordinary houses may retain a porch-only interaction. No stairs, basements, door keys, room-by-room procedural clearing or separate indoor camera.

Occupants in rooms count toward parcel clearance and occupation. Windows are solid except authored broken-window entrances shown before traversal. All attacks use the same world line checks. High walls block projectiles; low barriers permit fire. An opaque roof cannot conceal an active Spitter attack warning.

Navigation must provide two useful fighting approaches for clinic, school and pump, but not necessarily two complete claim routes. New interior content cannot move the existing six porch search rewards or delete old save positions. Invalid historical positions relocate to the nearest collision-valid point in the same parcel and are reported during migration.

## Continuity and persistence

Everything active shares the fixed simulation clock. Camera distance cannot heal a structure, cancel a raid, refresh loot or replace a fight with a score roll. Pending unactivated district residents are saved authored identities, not simulated off-camera attackers. Once activated, they stay physical until death/exit.

Persist ownership, search flags, occupation timer, structure/fixture health, approved orders and unique rewards. Rebuild derived connections and route caches after load; never trust a serialized “safe” Boolean while ignoring a broken gate. Verify alternative routes, home loss/reclaim and construction collision before expanding map content.
