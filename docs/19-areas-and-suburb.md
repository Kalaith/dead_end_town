# Areas, the suburb and the boss

Direction change, 29 October 2026, chosen by the user. **This supersedes the single 24-lot strip, the four-district ladder, "no travel loading screen" and the six-minute relief watch in [13](13-campaign-and-map.md), [02](02-world-and-territory.md), [09](09-mvp-roadmap.md) and F01/F02/F20/F21 in [11](11-decisions-and-questions.md).** Those documents stay as history and as the source for rules that this one does not replace (claim, occupation, safe connection, work, economy, combat). Values here are starting values, not measured balance. Nothing here is implemented yet.

## Why

The strip is one road that keeps going. It has no inside, no edge to defend and no moment where a place is finished. The game should instead let you make one bounded place dependable, face a story boss there, and only then move to a new kind of place.

## Structure

The campaign is a sequence of **areas**. Each area is its own map with its own bounds, properties, roads, pressure routes, survivors and exit. Areas are not one connected world.

| Order | Area | Character | Boss / gate |
| --- | --- | --- | --- |
| 1 | Suburb | Houses on a street grid, a corner shop, clinic, greenhouse and community hall. Many small yards and fences. | Boss guards the only way out |
| 2 | Office district | Dense blocks, narrow corridors, plazas and car parks. Calls, ambush and ranged pressure (Screecher, Spitter). | Mid-boss or gate event |
| 3 | Industrial area | Open yards, vehicles, depots and power. Heavy pressure (Brute, Breaker). | Final event |

Areas 2 and 3 are outlined only. Area 1 is designed here in enough detail to build.

## Area 1: the suburb

Modelled on [Sanctuary Hills](reference/sanctuary_hills_map.webp): a **ring road** around an island of lots, a **market roundabout** at the back, **one entrance** (a bridge) guarded by the boss, and a bounded settlement. The first layout, one straight street, was rejected as "still one long street".

```text
                top street                                  east
 outer N  [hardware][residence][garden][HOME]                 ring
 ══════════════════════════════════════════════╗             road
 island N [house_a][munitions][garage][library]║   ◉ plaza    ║
          ─ rear fences, with a gate each ─    ║  (market)    ║
 island S [clinic][greenhouse][No.12][corner]  ║              ║
 ══════════════════════════════════════════════╝
 outer S  [No.14][No.10][No.16][half-built]
 west road ▼  bridge approach: BABOON, the only way out
```

- About 3,360 × 2,180. 16 lots: the nine originals with unchanged identities (home, garden, library, garage, residence, munitions, hardware, clinic, greenhouse) plus No. 8, 10, 12, 14, 16, the corner house and the half-built house (48 Materials, close to home).
- **Home is in the north-east corner**, the far side from the bridge, near the plaza. The player pushes west along the top street, down the west road, and east along the bottom street toward the bridge. Every lot is reachable two ways round the ring.
- 24 links: 12 same-row passages, 8 street crossings (top and bottom street) and 4 **rear gates** between the back-to-back island rows. Ten lots are core (the originals plus No. 8, which bridges to the clinic).
- Gates only face a horizontal street, so the ring's side roads have no lots. The plaza is drawn but has no function yet.
- **Pressure comes from one end only**: the bridge, at the south-west corner. A wide approach strip runs along the bottom edge so a formation fits. The baboon holds the bridge road, so the horde passes it on the way in. Pressure timing and band numbers are not yet tuned for this size (step 5).
- The baboon, its roadblock and the exit marker are built (step 7). Using the exit is step 8.

### Preparing for the boss

There is no readiness gate and no scripted arrival. The boss is a monster that **guards the only way out** of the suburb and waits there. The player decides when to go. The pause menu may show an advisory summary (food, medicine, ammunition, perimeter health, defenders) so the choice is informed, but nothing blocks the attempt.

Being self-sufficient and defended still matters, because the fight happens away from home and the community must hold while the player is gone. That is a consequence of the world, not a rule.

### Boss: the undead baboon

- A large baboon (or similar monkey) turned undead. One authored monster at the exit road, new zombie type. It is large, fast over short distances and strong, with readable telegraphs and counters. Specific attacks, phases and health are designed in [14](14-zombie-catalogue.md).
- It stays at its post unless drawn out, and may bring a few resident escorts from the existing kinds. It is a place to fight, not a wave to survive.
- Its death is permanent (like all residents) and opens the exit. Failure uses the existing defeat and emergency-recovery rules, with no abstract refund.
- Save support covers its position, health and phase.

## Travel between areas

- An exit gate at the end of an area. Using it is an explicit, confirmed action once the boss is defeated.
- The roster, equipment, discoveries and permanent unlocks travel with the player. Area stock (Food, Materials, Medicine, Bullets) is carried within a stated cap.
- **Decided: the player can go back to an area.** The reason is not yet designed and will come later, so build for it: every area's full state is kept in the save, and the exit gate works in both directions. What happens in an area while the player is away (nothing, frozen, or limited pressure) is an open point.
- A transition screen and fresh area load are acceptable. The old "no loading screen" rule no longer applies.

## What carries over unchanged

Claim, occupation and loss; safe connection and production; work orders; economy; noise and attention; Runner and Screecher; defeat and emergency recovery; equipment ownership; physical passages, barriers and gates. Only the **map model, pressure routing, win condition and progression** change.

## Impact on existing systems

| System | Change |
| --- | --- |
| `town.json` | `columns` (12 pairs), `core` (18), `districts` (4) replaced by a per-area lot graph, core set and entrances. Validation of 12/18/4 removed. |
| Catalog | Loads one area at a time; `bounds`, properties, roads, passages and pressure routes are per area. |
| Camera, `town_view`, `routes`, map overview | Remove hardcoded 1160 height, 720 pitch and the single-road assumption. |
| Roads and barricades | Authored per entrance and street, not only on one main road. |
| Pressure (uncommitted scheduler) | Bands follow progress, not `column / 3`. Routes are the area's entrances. Enemy statistics still never change with scheduling. |
| Slice watch and relief signal | Retired and replaced by the boss. The radio and relief-plan story fragments may become the thread that sends the player to area 2. |
| Save | New schema wraps existing state as area 1 plus a per-area state registry and the current area id. Older saves migrate to the suburb as far as their data fits; unmapped lots are reported, not silently dropped. |

## Open points

- The baboon's tells, attacks, phases and health.
- Why the player returns to earlier areas, and whether an area changes while they are away.
- Fate of the 15 shell lots (currently dropped) and the survivors not yet implemented (Theo, Nia, Rowan): assign them to areas 2 and 3.
- Carry-over cap for stock.
- Whether the relief-signal story survives as the campaign's spine across all three areas.
- Fate of the optional vehicle ([18](18-vehicle.md)): likely an area 3 feature.

## Delivery order

1. Docs updated (this file and supersession notes).
2. Generalise the map model to per-area lot graphs (no behaviour change for the current strip).
3. Area layer, per-area bounds and the schema migration.
4. Author the suburb.
5. Rework pressure onto entrances; finish and commit the scheduler. (done, see PROGRESS)
6. Optional advisory summary in the pause menu. (done, see PROGRESS)
7. Baboon boss at the exit. (done, see PROGRESS)
8. Area transition. (done, see PROGRESS)
9. Office district, then industrial area, each with its own boss or gate.
10. Retire the old slice and watch.
11. Verification by playing the real game, proportionate to each change (see `AGENTS.md`).
