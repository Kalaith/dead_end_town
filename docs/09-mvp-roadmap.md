# MVP roadmap and validation

## Current state

An initial playable greybox street was implemented on 28 October 2026. M0 has a pinned engine, controls, map and camera; portions of M1–M7 demonstrate melee, squad orders, home defence, claims, shared work, rescue and persistence. The user subsequently human-playtested basic zombie combat and territory capture. Garage restoration and a first visible armour/shield set are now implemented, and the persistent bottom panel is removed. Full milestone acceptance gates and human review of the new progression remain open. See [PROGRESS.md](PROGRESS.md) for implemented behavior and evidence. The table below remains the target acceptance roadmap; estimates should follow observed play.

## MVP content budget: proposed

One continuous small street with four functional properties: home, garden house, library, garage. Include connecting streets and a test boundary approach route. Use a protagonist, one starting companion, and Paige; generic debug actors can exercise additional jobs without expanding the shipped roster. Allow up to two AI expedition companions after one is proven.

One basic zombie, melee combat, one firearm, a shield, basic and heavy protection, barricades, gate, guard post, garden, workshop, and three resources. Use one armour cache to demonstrate the long-term equipment idea without building a full museum. Target a repeatable 20–30 minute slice, with the armour setup optionally accelerated for demonstrations.

## Milestones

| Stage | Deliverable | Acceptance gate |
| --- | --- | --- |
| M0: foundation | Pin engine/platform, greybox street, controls, camera | Traversal and scale feel readable; engine project opens cleanly |
| M1: action | Player melee, basic zombie, damage, stagger | Small fights are readable and repeatable; no collision traps |
| M2: squad | One companion, Follow/Hold/Engage/Return home | Obeys leashes, handles blocked routes, holds a doorway |
| M3: home | Physical barriers, gate, guard, local alerts | Guard holds a routine approach while player is elsewhere |
| M4: reclamation | Clear/claim distinction, graph, connected perimeter | Two properties integrate correctly; internal fence remains physical |
| M5: hybrid work | Blueprint, resource reservations, interruption/resume | Player-to-AI handoff preserves progress and charges once |
| M6: progression | Garden, garage restoration, Paige rescue, equipment | Discoveries create usable capabilities and visible change |
| M7: continuity | Save/load, defeat recovery, controlled noise/migration | No lost/duplicated items, workers, jobs, or zombie groups after reload |
| M8: slice review | Opening, feedback, performance pass | New players understand the loop and choose another property voluntarily |

Dependencies matter: do not optimise a distant combat simulator before physical defence works. Save schemas should be considered from M0, with integrated round-trip checks before content expansion.

## Required scenario checks

1. **Away from home:** leave one guard with a viable barricade and observe a real approach. The guard attacks, workers shelter, an alert reports changes, and ordinary work resumes.
2. **Breach recovery:** deliberately weaken the gate. Verify physical entry, retreat, paused production, and a practical recovery route.
3. **Connection edge cases:** claim an L-shaped group, leave an infected hole, block a corridor, and restore it. Exposed edges and work eligibility must match the layout.
4. **Construction accounting:** start personally, hand off, interrupt, cancel, and reload at each phase. No duplicate costs, outputs, or reservations.
5. **Progression:** rescue Paige, recover tools and armour, restore equipment, and equip it. No XP requirement or duplicate unique reward.
6. **Noise:** compare quiet melee and gunfire from the same initial world state. Attraction follows positions and events.
7. **Persistence:** save during work, combat, and a disconnected route. Restore states and reconcile routes before resuming simulation.
8. **Blocked autonomy:** close a route, remove a target, or incapacitate a worker. The order reports a reason and does not stall all jobs.

Use automated checks for graph rules, material conservation, unique item ownership, job transitions, and save migrations. Use in-engine playtests for combat feel, path following, readable alerts, and trust in defence. An import or parse check is not a gameplay test.

## Playtest observations

Record time spent away before a forced return, alert frequency, avoidable AI casualties, blocked-job duration, resource shortages, and whether the next property choice feels different. Ask the player to explain a new unlock in their own words. These observations guide tuning; numerical success thresholds should be set after a baseline session.

## Deferred until the loop works

Full town generation, multiplayer, vehicles, multi-floor combat, freeform construction, advanced logistics, day/night threats, special zombie families, permanent death, deep survival needs, and large rosters. Distant simulation tiers are conditional on profiling, not a prerequisite for a four-property street.

## Production workstreams

Design: resolve the next milestone's open questions and maintain the building reward table. Engineering: protect state ownership, navigation, and accounting invariants. Art: establish tile scale and one survivor/equipment pipeline before producing the cast. Audio: make attacks, work, and warnings distinct. QA: maintain reproducible world seeds or authored scenarios and label what was actually tested.

After M8, decide whether to expand the map, improve combat, or cut systems based on observed play. Reaching the milestone means the promise is demonstrated, not that a commercial release is ready.
