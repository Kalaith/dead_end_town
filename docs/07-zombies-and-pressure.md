# Zombies, noise, and expansion pressure

## Current street implementation, 28 October 2026

Following feedback that zombies are not a threat, the greybox has 24 residents across its three reclaimable properties and recurring edge migrations. Waves start at 45 active seconds with a 12-second directional radio warning. A five-wave cycle introduces east, west, north/east, south/west and four-edge attacks. Each extra claimed property adds two migrants and removes eight seconds from the next interval: 4–10 zombies every 65–41 seconds, capped at 36 living zombies across the map.

All zombies now wander independently, including residents, edge arrivals and occupiers after a property falls. Random headings last 0.8–2.8 seconds; collision triggers another choice. The nearest living player or survivor within 240 pixels immediately overrides idle wandering. Zombies head directly toward that person, reselecting the nearest living target each step, and resume wandering when nobody is nearby. They have no fixed porch, road-junction or property destination. They bite only on physical contact and damage a closed gate or built road barricade when moving into it, including while pursuing someone. Walls still block movement. Lost yards remain places to wander through, rather than rally points. Defeated residents stay cleared; new zombies still arrive at physical map edges under the existing budget. Eight seconds of unopposed occupation inside a claimed yard causes loss.

Raiders are the exception to idle wandering. Each building has a hidden zombie quota (`hidden_zombies` in `data/street/properties.json`; home is 0). A raider heads for the nearest building whose yard holds fewer zombies than its quota (quota gates arrival only, so settled raiders are never pushed back out), provided that raider would stay there (`settle_percent`, fixed per raider and building by id so no roll is saved). Once inside a yard it would stay in, it walks to the back of the yard and then wanders near it like any resident. Raiders drift along their route with a gentle sway; only pursuit of a person is a straight line. If no building needs zombies it follows the road to a map-edge exit chosen by its id and leaves the map; defeated raiders keep their corpses. Nearby people still override all of this.

The world owns a seeded RandomNumberGenerator; save schema 7 preserves its full integer state as text plus each actor's heading and remaining turn clock. The same seed and commands reproduce the same motion; loading resumes the random sequence. Values live in `data/street/*.json` (zombie kinds in `data/zombies.json`). See [PROGRESS.md](PROGRESS.md) for verification and limits. The noise ideas below remain earlier proposals. Current pursuit uses proximity alone, without noise, remembered destinations or route finding.

## Threat inhabitants

Residents occupy buildings and yards until disturbed. Wanderers move through streets and openings. Hordes are travelling groups that can redirect toward substantial activity. These are behaviour roles, not necessarily three distinct monster species.

The current slow archetype wanders, bites on contact, bumps defences, staggers when struck and falls when defeated. Nearby-person pursuit takes priority over wandering; investigation and sound destinations remain outside the current movement rule.

## Noise events

Each event has a world position, category, intensity, time, lifetime, and emitter. Use qualitative UI language even if simulation values are numerical.

| Activity | Relative noise | Expected consequence |
| --- | --- | --- |
| Walking | Very low | Nearby awareness only |
| Melee impact | Low | May disturb adjacent rooms or yard |
| Hammering and repairs | Moderate | Draws attention from the nearby street |
| Gunfire | High | Can attract several nearby groups |
| Alarm or explosion | Very high | Can redirect a travelling horde |

Buildings and walls may attenuate noise later; the MVP can use distance plus room or property modifiers. Repeated hammering is a bounded sound source rather than an endlessly stacking global danger score. Zombies investigate the last sound, then search or return to wandering when it expires.

## Pressure with a physical explanation

Expansion exposes more boundary, lengthens routes, and brings the settlement closer to occupied areas. Machinery and combat can attract residents. These consequences provide escalation before any time-based difficulty curve.

If additional zombies migrate into the map, use authored edge routes and staged travel. Never spawn inside secured rooms or directly beside an unseen guard simply because the player is away. Record origins and destinations so attacks are explainable in debugging and visible through scouting.

Map-edge inflow must have a budget and a population cap. Defeated residents remain defeated unless replacement arrives through a valid route. Distant hordes can be represented as persistent groups, but cannot teleport through an intact perimeter.

## Pacing defaults

The opening gives a short protected learning window and a clearly telegraphed first approach. Later encounters alternate with time to repair, explore, and observe town growth. Background pressure should not force a return home after every cupboard search.

Do not scale every encounter directly to the player's latest weapon. A recovered shotgun or armour set must feel like progress. Harder landmarks and larger migrations provide new challenges while early streets become meaningfully safer.

## Example

The squad fires at residents in the garage. Nearby wanderers investigate the shots, creating a return-route threat. Home's hammering can attract a different street group. Defenders engage at the gate, generating more local noise. Each movement follows a world event; neither fight is an abstract punishment roll.

## Fairness checks

- Can the player identify where attackers approached from?
- Did the alarm allow a meaningful response given actual travel time?
- Can a competent home team hold routine attacks without personal intervention?
- Does quiet play change the encounter, rather than merely delay a fixed wave?
- Is there enough calm time to enjoy improvements and prepare again?

Day/night modifiers, special infected, siege bosses, and scheduled horde nights remain open or deferred. They should not enter the MVP until the basic pressure loop works.

Zombie kinds are data: `data/zombies.json` defines each type's health, speed, damage and cooldown, and all movement and combat read them through `scripts/sim/zombie_types.gd` using the actor's optional `kind` (default Shambler). Adding a type needs a JSON entry plus a saved `kind` field on actors; behaviour differences can then branch on the kind.

The Brute is the first non-default kind: 180 health, slower (38), bites for 18 on a 1.6 second cooldown and damages gates and barricades 2.5 times as hard. `pressure.specials` in `data/street/pressure.json` puts `count` of a kind into the first spawn slots of every raid from `from_wave` on, so the first raid already includes one. A non-default zombie stores `kind` on its actor; saves without it load as shamblers, so no schema bump was needed.
