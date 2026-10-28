# Zombies, sensing and pressure

Full game design. [14](14-zombie-catalogue.md) owns the eight kinds and exact attack contracts. The slice currently uses proximity pursuit, resident quotas, wandering/settling raiders, two kinds and short recurring waves. Noise, memory and the campaign scheduler below are future work.

## Shared behaviour priority

At each simulation decision, choose: incapacitated/dead → committed attack phase → nearest standing person in notice range → recent person position → strongest relevant noise → explicit finale approach or ordinary migrant route/settlement destination → local wandering. Committed wind-ups still cancel if their attack contract requires valid range/line and it is lost. A new nearby person overrides migration and noise immediately after a non-interruptible attack phase ends. Finale actors do not choose ordinary settlement/exits while their attempt runs; 13 owns that exception.

Notice range is 240 pixels for all kinds initially. Preserve the user's nearby-person priority: walls block movement/attacks but do not prevent close proximity detection. No distant acquisition through buildings. Select the nearest standing person each simulation decision, with stable actor-ID tie break. Presentation can smooth turning but cannot retain a farther target against this rule. Explicit committed attack phases keep their telegraphed direction as specified in 14.

After losing a person, investigate the last sensed position for up to 4 seconds, then resume migration/wandering. No omniscient chasing of current unseen coordinates outside notice range. Pathfinding uses actual openings. Attack a breakable obstacle only if it blocks the selected route; do not pound an irrelevant internal fence when an open gate is reachable nearby.

Residents wander in their home yard until attracted out by a person or noise. They never respawn. Migrants travel from authored world edges, seek eligible under-quota uncontrolled yards, settle at their rear, or leave via a physical edge if no destination is eligible. Claimed yards have target quota zero, preventing intentional settlement homing on every claimed porch. Nearby people/noise may still draw migrants into them; ordinary occupation then applies.

Each non-home uncontrolled property's target quota equals its initial resident count in 15; home quota is always zero, even after loss. A raider settles with 60% deterministic actor/property-ID eligibility, selecting the nearest eligible under-quota yard by reachable route length. Quota gates entry only: an already settled actor is not expelled when another actor arrives. Claimed properties always have quota zero. Settling probabilities derive from stable IDs, while saved RNG supplies genuine wandering choices. A loss changes eligibility, never conjures replacement residents. All migrants retain origin, creation wave and destination for debugging and persistence.

## Noise contract

Noise is a spatial event that influences existing living actors. It never adds population, escalates a hidden global danger meter or schedules an instant extra wave. An event records stable ID, emitter, position, radius, expiry, category and merge key. Investigation movement obeys collision and the same physical routes.

| Event | Radius | Lifetime | Merge rule |
| --- | --- | --- | --- |
| Walking | No acoustic event | — | Nearby-person sensing handles it |
| Melee impact | 120 px | 1.5 s | Per attacker, refresh at most twice/second |
| Building/repair | 200 px | 2 s | One source per site; refresh once/second |
| Pistol | 550 px | 4 s | One source per shooter over 0.5 s |
| Shotgun | 750 px | 5 s | One source per shooter over 0.5 s |
| Screecher | 600 px | 4 s | One per successful call; cannot initiate another call |
| Relay launch | 900 px | 8 s | One event at start; finale population remains fixed |

Choose the largest `radius - distance` among in-range events, then newest event and stable ID. A newer weak noise does not repeatedly flip an actor away from a nearby person. An actor investigates one event at a time. Expired events cannot attract newly spawned migrants. One ordinary building footprint between source and listener halves effective radius; do not raycast arbitrary material acoustics in the first implementation. Open-front rooms use the building's same modifier.

A gunshot may draw a known yard's residents into the road. Quiet melee leaves most distant residents undisturbed. That difference is the reward for quieter play. The game does not punish every shot with a compulsory return-home raid.

## Campaign scheduling

First migration no earlier than 180 active seconds or the first non-home claim plus 60 seconds, whichever is later. Prior to it, authored residents provide combat. Existing actors continue through the tutorial; no invisible invulnerability zone is required.

Threat band is the furthest district with a searched core site; it never decreases or scales with equipped weapons. Its template pool and budget change once per district. Do not shorten intervals with every property. Clearings and good equipment should make familiar streets safer.

| Band | Ordinary migration budget | Interval after last entry | Max simultaneous origins | Specials eligible |
| --- | --- | --- | --- | --- |
| Hearth | 5–8 | 180–240 s | 1 | Brute after garage discovery |
| Market | 9–12 | 180–240 s | 1 | Runner, Screecher after teaching encounter |
| Civic | 12–16 | 210–270 s | 2 | Armoured, Crawler, Spitter after teaching |
| Works | 16–20 | 210–300 s | 2 | One rare authored Breaker template |
| Continued town | 6–10 | 240–360 s | 1 | No Breaker |

Choose interval/template with the owned saved RNG; select from authored templates whose costs fit the budget. At least 50% of routine threat cost is Shamblers. At most one rare Breaker migration per 12 active minutes, never until the pump teaching encounter has resolved. Finale waves override this table only during an explicit attempt.

On a new band, retain current scheduled event; apply the new pool to the next scheduling decision. No retroactive early spawn. After any routine entry, suppress the next entry for at least 90 seconds after the last local breach resolves. This calm timer may extend, never shorten, the existing interval. The final defence has its own fixed timetable.

### Initial routine template pool

Roll an integer budget in the band's range, then choose uniformly among its eligible templates at or below budget. If none qualify, use that budget of Shamblers. Required-kind eligibility comes from a resolved/observed teaching encounter; ineligible templates are excluded rather than introducing a surprise kind. If a globally capped special is unavailable at admission, replace its threat cost with that many Shamblers, still subject to the living cap. Record the final admitted composition.

| Template ID | Band | Composition | Threat cost |
| --- | --- | --- | --- |
| hearth_drift | Hearth | 5 Shamblers | 5 |
| hearth_group | Hearth | 6 Shamblers | 6 |
| hearth_heavy | Hearth | 4 Shamblers + 1 Brute | 7 |
| hearth_crowd | Hearth | 8 Shamblers | 8 |
| market_rush | Market | 7 Shamblers + 1 Runner | 9 |
| market_call | Market | 6 Shamblers + 1 Screecher | 9 |
| market_walk | Market | 10 Shamblers | 10 |
| market_pair | Market | 8 Shamblers + 2 Runners | 12 |
| civic_plate | Civic | 9 Shamblers + 1 Armoured | 12 |
| civic_call | Civic | 9 Shamblers + 1 Screecher | 12 |
| civic_ground | Civic | 8 Shamblers + 1 Spitter + 1 Crawler | 13 |
| civic_fast | Civic | 8 Shamblers + 2 Runners + 1 Screecher | 15 |
| works_heavy | Works | 10 Shamblers + 1 Brute + 1 Spitter | 16 |
| works_mixed | Works | 10 Shamblers + 1 Armoured + 1 Screecher + 1 Runner | 18 |
| works_siege | Works | 10 Shamblers + 1 Breaker | 18 |
| works_rush | Works | 12 Shamblers + 4 Runners | 20 |
| continued_walk | Continued | 6 Shamblers | 6 |
| continued_heavy | Continued | 5 Shamblers + 1 Brute | 8 |
| continued_rush | Continued | 6 Shamblers + 2 Runners | 10 |

Split multi-origin events round-robin across selected entries, with stable actor ordering. Avoid repeating the same sole origin more than twice if another eligible route exists. Standard random variation changes routes/intervals/composition, never enemy health. The works_siege cooldown starts on actual Breaker admission, not on a skipped capped slot.

## Origins, warning and movement

Eight edge routes are mapped in [13](13-campaign-and-map.md). Choose up to two valid origins whose approach can physically reach uncontrolled road space. Never place a new entry behind a held intact perimeter. All entries remain at outer map edges and travel inward. A protected mouth can stop or deflect a group; selection does not bypass it.

Base warning is 35 active seconds before entry. The restored radio gives 60 seconds plus kind silhouettes actually scouted on that route. Without radio the starting receiver still reports direction and approximate size; no unseen death caused by missing a mandatory warning upgrade. Warnings describe approach, not a guarantee that home is the destination.

Retain a warned event's origin/composition/time on load. Entry uses 0.5-second spacing and distinct positions. If a routine event hits the 96-living cap, admit what fits, discard the rest and schedule the next normal interval. Do not create a deferred overflow wave. The finite finale instead retains pending actors and waits for capacity; see 13.

## Resident population and technical cap

The 24 authored encounters in 15 total 89 living residents at new campaign creation. All are present from the start, with stable IDs and their real positions. There is no district activation spawn, pending-resident claim blocker or invisible progression gate. The 96-living cap leaves seven initial migrant slots and more as the player clears the street. Routine overflow is skipped under the rule above, never stored as a backlog.

All actors stay authoritative off camera. Do not replace guards/zombies with a readiness percentage. Fully simulate the 96 cap first and optimise after profiling. Corpses can collapse into persistent defeated IDs for memory, but cannot become living again. Old-save expansion adds new residents only to the new district parcels while the load screen is paused; its placement/overage policy is in 10.

## Fairness and debugging

The player should be able to explain an attack's origin, tell and route. Debug overlays show perceived target, remembered position, noise, origin, route, pending entries and special phase. Player UI shows relevant alerts, never these implementation details.

Required checks: identical seed/commands repeat migration choices; reload warning/cooldown/noise without duplicates; off-camera combat obeys identical collision; quiet and loud approaches redirect different existing actors; a capped routine event has no backlog; a capped finale retains exact finite population; recapture never repopulates a defeated resident.
