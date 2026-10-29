# One recoverable utility van

## Current state (30 October 2026): driving slice

The design below was written for the old strip (depot service bay, Nia, Rowan, 18 core sites) and is partly stale. Under the area model the van is data: an area declares `vehicle_bay` (position, heading) and gets one van, parked and working from the start; only the office has one. Shared numbers are in `data/street/vehicle.json`.

Implemented (schema 41): boarding with E when stopped and near; W/S throttle and reverse, A/D steer; the specified speeds, acceleration, braking and turn rate; a swept 54 x 28 footprint blocked by walls, gates, barricades, people and zombies; an `engine` noise (radius 450, 2 s); zombies and Spitter globs damaging the 300-point hull instead of the driver; ejection when it is wrecked.

Not implemented: discovery and restoration, passengers, hull repair, recovery to a depot, downed occupants (a wrecked van just ejects an unharmed driver). The sections below remain the intent, to be re-fitted to areas. The van does not cross areas.

Original text follows.

Future design, added at the user's request on 28 October 2026. The current slice has no usable vehicle. The firehall's parked appliance remains scenery. This document owns the single usable vehicle's behaviour and numerical starting values; it does not claim implementation or playtested driving.

## Discovery and purpose

Find `utility_van` in the depot service bay on search, separate from Nia's rescue and generator coupler. It is a faded blue maintenance van with a cream roof, roof rack and visibly patched panels. Searching reveals the restoration action, not an immediately usable vehicle or extra supplies. Loss/reclaim never creates another van.

Restore at its fixed bay for 12 Materials and 30 shared work seconds, requiring depot held, clear and safely connected, and the garage workshop operational. Use the existing approved-work transaction, interruption and cancellation rules in 04; anyone can do the work. Neither Rowan, Theo nor Mara is a profession key. Record the recipe in 16.

The reward is quicker travel along a cleared street with the player's two selected followers. It carries no general inventory, generates no deliveries and grants no new follower slots. All 18 core sites and the ending remain reachable on foot. No finale condition, component or rescue requires the van; parked vehicles never count as guards or safe connections.

## Movement and controls

| Setting | Starting rule |
| --- | --- |
| Driver | Protagonist only; no AI driving or remote dispatch |
| Seats | Driver plus two passengers drawn from existing follower membership |
| Collision footprint | 54 × 28 pixels, oriented with the van; validate swept footprint on turns |
| Speed | Forward 300 px/s, reverse 140 px/s |
| Acceleration / braking | 500 / 800 px/s²; releasing throttle brakes to a stop |
| Turning | Up to 150 degrees/s while moving; no rotation through colliders |
| Input | W/S throttle/reverse, A/D steer; remappable; E enter/leave while stopped |
| Combat | No attacks, shooting, ramming, crushing or turret role from seats |
| Engine noise | Radius 450 px, lifetime 2 s; one source refreshed once/second while moving |

Drive in continuous simulation, with the same pause boundary as walking. Camera follows the driver and shows sufficient stopping distance at 1280×720. Approaching an obstacle stops movement at contact without bounce, pushing, damage or clipping. Living/downed people, zombies, fences, buildings, gates and barricades all block the swept footprint; no high-speed tunnelling. Opening a gate does not guarantee it is wide enough for the van.

Every map column needs a usable road parking bay with separate pedestrian access. The depot bay connects to the road without driving through a porch or narrow yard passage. Preserve existing barrier geometry and foot routes: road lines can block the van, requiring a stop and walk or deliberate dismantling. Yard passages are pedestrian routes. Never widen or remove an existing defence automatically for driving.

The engine adds a source to the noise rules in 07, attracting existing actors without spawning enemies. Occupied seats expose each standing person's sensed position at the van centre, preserving nearby-person priority; the van hull becomes the physical blocking target. Unoccupied vans emit no noise or person signal. Parked vans cannot satisfy a yard's standing-person contest condition, even when occupied.

## Boarding, danger and recovery

Enter only when stationary, within 48 pixels of an accessible door, with a clear standing approach. Selected standing followers within 64 pixels of an available passenger door may board through a short visible approach; do not teleport a distant follower. Wait or depart without them explicitly. Passenger status pauses their previous assignment exactly as following does. Ellis may ride and keeps every noncombatant restriction. No downed-person loading or mounted treatment system.

Leaving requires speed zero and a valid unoccupied exit position beside a door. Check each occupant independently; never overlap, push someone through a wall or silently drop a passenger. If every exit is blocked, explain the block and allow the driver to move/reverse. Passengers can disembark through the paused roster panel when an exit is valid. Stop before changing follower membership; seated actors must disembark before swapping out.

The van has 300 hull health. Zombies damage it using their authored obstacle attack and cooldown, including Breaker structure damage; bullets and melee cannot be launched from inside. A Spitter glob striking the hull damages the hull once at its direct-hit value, leaving its ordinary ground pool outside; seated occupants receive no separate direct/pool hit. Hull never has armour, invulnerability or passive regeneration. Moving cannot cancel a committed valid hit.

At zero hull, stop the van and turn off the engine. Seated people become downed in their seat slots, preserving identity, equipment and meal membership. They can be picked up from an accessible door using ordinary casualty carrying; no standing exit position is required for pickup, but the carrier needs a valid approach. If the protagonist is seated, normal paused defeat/recovery in 03 is available immediately and recovers seated casualties too. No occupant can become permanently trapped or die. The disabled hull remains, with no explosion, loot or replacement copy.

Repair a stopped, empty van with the standard facility-repair batch: four Materials for up to 200 hull health over ten work seconds. Require a locally clear work point; prepay once and preserve partial work. At zero hull, the first positive health restores mobility. No routine fuel, battery, tyre, parts or servicing counters; no passive wear.

Once empty, the player can approve **Recover van to depot** at its service bay if depot and garage workshop operate. Cost: six Materials and 30 work seconds using one survivor at the bay. Keep the existing hull at its original position until completion, locked against boarding/repair while recovery is committed; at completion relocate that same empty vehicle to the clear depot socket, preserving hull health. This is an explicit workshop recovery abstraction, not normal travel or a free repair. An occupied destination blocks completion without another charge. Loss/danger pauses work; cancellation follows 04. Emergency salvage in 06 can fund this optional recovery. Never require it to progress on foot.

## Persistence and implementation

Simulation owns movement, swept collision, seats, noise and damage. Presentation renders and issues commands. Add validated vehicle content only when its behaviour is implemented at G08. Store stable vehicle ID, discovered/restored state, position, heading, speed, hull health, seat actor IDs and pending repair/recovery commitments. Paused save/load preserves motion and paid progress; no fresh noise event or reward merely from loading. Reconstruct collision from content, not a second saved geometry.

Seated actors remain the same authoritative actors and cannot simultaneously walk, work, guard, attack, be carried or occupy two seats. Reject duplicate/missing seat owners, overcapacity, invalid hull/speed/position and occupied recovery jobs. Migrate earlier saves with an undiscovered unrestored van and Rowan unrescued; preserve already-searched depot/assembly rewards by exposing their new discoveries once without repaying search stock. Keep original actors, equipment and earned slice completion.

## Acceptance before claiming completion

Check discovery/repair once, including older searched-depot saves; nine-person meals and Rowan rescue before/after assembly restoration; exact two-passenger capacity; Ellis capability; no distant boarding; follower swaps and individual exits; narrow gates/turning/barriers/people at full speed; zero-hull casualties and all-blocked doors; prepaid repair/recovery cancel/loss/reload; and no duplicated vehicle or supply on recapture. Prove core completion without restoration and with the van disabled across a road.

Inspect real windowed input for steering, stopping distance, prompts, passengers, blocked exits and engine-noise investigation. Human testing must establish whether it saves useful travel time without trivialising encounters or creating constant barricade dismantling. If routes make it frustrating, tune parking and driving geometry while preserving the original defences and walking campaign. Automated captures cannot establish driving feel.
