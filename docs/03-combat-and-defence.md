# Action combat, squad and home defence

Full game contract. Preserve the slice's direct movement, directional melee and separate firearm input. [14](14-zombie-catalogue.md) defines enemy attacks; [16](16-equipment-and-recipes.md) defines equipment statistics.

## Player combat

WASD/arrows move; cursor aims; left click swings toward it; Space swings along movement/last facing; right click fires equipped firearm. Holding attack repeats only after cooldown. No stamina, invulnerable dodge, active block, friendly fire, durability, headshots or magazine reload. Empty ranged input spends nothing and never disables melee.

Every melee attack chooses living targets in reach/cone with a clear line, orders them by distance then stable actor ID, and applies at most the weapon's target count. Bat/crowbar hit one. Sword can hit two. One actor cannot receive two hits from one swing. Recovery begins on the attempted swing, including a miss. Movement remains available, with a 20% movement reduction during the visible 0.18-second swing; no root animation lock.

Firearms trace along the aimed shot to the first solid obstruction/valid target. Low road barriers allow fire; buildings, solid fences, high shields used as scenery and closed gates block it. Actors cannot shoot through several enemies with one pistol bullet. Shotgun behaviour is in 16. AI fires only after a valid line/range check and a lane clear of allies; the projectile does not damage allies, but neither should AI dump ammunition through them.

Passive shield protection applies to incoming actor attacks in a 120-degree frontal arc. Body and shield multipliers multiply once; iron plus a frontal shield gives 25% incoming damage at 80% movement speed. Ground hazards use body protection only. A shield never grants rear immunity. Downed actors neither attack nor consume ammo.

## Squad orders

The protagonist is fixed. At most two recruited survivors have Follow/Engage expedition membership. Assigning a third prompts a paused choice of whom to return or hold; it never silently cancels somebody's work. Ellis can occupy a follower slot for transport, but provides no combat. Emergency casualty carrying does not create another active follower.

| Order | Action | Boundary/fallback |
| --- | --- | --- |
| Follow | Stay near player and defend immediate threats | 150-pixel formation radius; pursue at most 180 from formation anchor |
| Hold | Stay at selected reachable point, defend locally | 120-pixel leash; never chase through a gate into uncontrolled land |
| Engage | Focus selected target or local point | 220-pixel target area; no town-wide hunt; return to anchor after target falls |
| Return home | Use safe route, then hold selected home defence post | If no safe route, shelter at nearest reachable clear held yard and report |
| Guard post | Hold a physical inside position and alternate dodge point | 100-pixel leash; no chase beyond the defended line |
| Work | Execute eligible job at approved site | Preserve assignment through shelter; never self-authorise expansion |

Whole-team shortcuts affect recruited, standing non-carried survivors. Ellis maps Engage to Hold and Return home/Guard to shelter; no indirect command may bypass the prohibition. A downed person keeps assignment but cannot execute it. Explicit individual orders do not change anyone else. Whole-team tactical shortcuts leave an active rescue transport intact; individual reassignment cancels it and puts the casualty down at the carrier’s current position.

On target death or invalidity, reevaluate within the existing order boundary. Companions do not loot, claim, chase across town, spend medicine or approve new buildings. A blocked order shows one reason and keeps a safe anchor. Formation uses distinct offsets so people do not overlap at a narrow gate.

## Guards and trusted defence

A guard has a post, protected side, detection area, leash, primary weapon, ranged-ammo policy and retreat point. Guards prefer the nearest immediate threat attacking their line; a winding-up Screecher/Spitter in reachable range is next priority. Otherwise use nearest valid hostile. Reevaluate at bounded intervals, not every animation frame.

Guards can strike over low barricades within weapon reach and can fire over them. They cannot attack through solid tall gates unless a specific low attack opening is authored. Give every standard defensive line at least one legitimate inside attack position. Equipment range matters; do not grant a bat an invisible long-range hit because it is guarding.

At less than 30% health, a guard retreats to its safe fallback unless explicitly assigned Hold at all costs in the paused post policy. That optional policy is off by default and still cannot cause permanent death. Spitter pools trigger movement to the alternate inside position. When danger clears and health is adequate, resume the same post. Guards never abandon a line for routine harvesting.

Ranged policy defaults to melee first, shoot specials within clear range or any enemy attacking a line below 40% health. Alternatives: conserve (no automatic shots) or fire at will. Shared stock reserve of six Bullets/two Shells limits routine guard fire; an active breach can spend into that reserve and raises one alert. Player fire always uses available ammunition. No invisible guard-only ammo.

## Workers and local alerts

Workers stop for hostiles within 170 pixels of themselves or their work point, a projectile telegraph covering them, or an invalid safe route. Combat-capable workers defend contact threats only while retreating; they do not charge the street. Ellis shelters without attacking. A guard's active zone does not freeze every facility in town.

| Alert | Trigger | Presentation |
| --- | --- | --- |
| Approach | Warned migration or visible group nearing a line | Direction, rough size, expected route |
| Threatened | Hostile damaging an occupied line or near work | Named place, local defenders, weak condition |
| Breached | Enemy crosses a defended boundary | Urgent ping and concise destination |
| Occupied | Yard starts unopposed loss clock | Local draining marker and warning |
| Down | Person reaches zero health | Name/location and recovery action |
| Resolved | No hostile in the alert area for 5 seconds | One clear message; resume valid work |

Alerts use visual/text plus audio, deduplicate by incident and escalate only on a meaningful change. Pause overview supplies detail. Readiness is an explanation of health, ammunition, route and coverage; it does not decide a fight mathematically.

## Injury and ordinary recovery

Health reaches zero → downed, never dead/infected. Zombies ignore downed people as attack/occupation-contest targets. Recruited people remain in the roster and meal count. Equipment stays attached and cannot be stolen or duplicated.

At a locally clear casualty, hold E for 2 seconds to lift one person. The player cannot shoot/swing while carrying; movement ×0.7, armour/slow still apply. E at a clear held shelter places the casualty there. A standing companion may be ordered to carry if both are reachable and clear; it then uses a safe route and occupies no other work slot. If no route exists, report Blocked and keep the person in place. Carrying is limited to one casualty per carrier. Companion rescue chooses the nearer available treatment shelter: clear home, or a clear restored clinic with Medicine. Approach and transport both need a protected route; already sheltered people need care rather than a redundant rescue. A blocked route retains the transport and previous duty, with bounded retries.

Safe home rest: spend 2 Food once and 15 active seconds to recover all people physically at home to at least 50 health. Optional additional 2 Food/15 seconds heals those present to full. Clinic treatment spends 1 Medicine per person, 10 work seconds, restores full health and revives; patient and worker must be present and facility operational. The player can provide clinic work using R. No treatment can complete while its danger condition is active.

Costs commit only when someone benefits and service can start; interruptions preserve paid progress. Healing a healthy team spends nothing. No automatic remote healing at the home porch. This intentionally replaces the slice's remote team-rest convenience during the recovery milestone.

## Protagonist defeat and emergency foothold

On protagonist zero health, pause before any recovery mutation. Offer Recover at foothold, Load latest valid save or Choose save. Recovery is always available, even with empty stock/all survivors down/home lost. Explain the exact consequences on the paused panel.

Ordinary recovery uses the nearest clear held shelter with a safe standing location; otherwise the authored west-road emergency shelter outside home. Move protagonist there at 50 health, equipment unchanged. Recover all downed people to the same shelter at 25 health. This is an explicit rescue/time-skip exception, not normal worker travel. Preserve enemies, territory damage, discoveries and material commitments; do not advance combat or production during the transition.

Grant no supplies, free repairs, search rewards or full healing. Remove hostile actors within 120 pixels of the emergency shelter by relocating them to the nearest valid **uncontrolled road** point at least 240 pixels away; preserve health, IDs and population. This relocation is disclosed as the emergency-recovery exception and never used during ordinary simulation. Suppress new migration for 90 active seconds; existing distant actors remain. If the attempt was running, it fails first.

The west shelter cannot be claimed, farmed, stocked or used to satisfy finale readiness. It exists solely to prevent a home-loss softlock. A basic bat remains available to every combat-capable person. Reclaiming home, finite salvage and the renewable salvage safeguard in 06 provide a route forward without duplicating unique items.

## Verification boundary

Automated checks prove damage/line/cooldown rules, target counts, order capability, carrying conservation and reload behaviour. Windowed checks inspect tell readability, formation through gates, retreat, pools and alert frequency. Human play must establish combat feel and whether ordinary home defence can be trusted for 3–5 minutes. Headless success alone never establishes those qualities.
