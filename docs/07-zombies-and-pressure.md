# Zombies, noise, and expansion pressure

## Threat inhabitants

Residents occupy buildings and yards until disturbed. Wanderers move through streets and openings. Hordes are travelling groups that can redirect toward substantial activity. These are behaviour roles, not necessarily three distinct monster species.

Begin with one slow zombie archetype. Its readable states are idle, wander, investigate, pursue, attack, stagger, and defeated. Zombies need a reachable target or last-known sound location. They should attack an obstruction only when it plausibly separates them from a target.

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
