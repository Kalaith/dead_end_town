# Zombie catalogue

Eight full game kinds. Only Shambler and Brute exist in the current slice. Values below are starting balance, with pixels/active seconds matching the simulation scale. [07](07-zombies-and-pressure.md) owns shared sensing and migration. “Threat cost” is a composition budget, never XP or a player-visible monster level.

## Roster and baseline values

| ID | Health | Move speed | Contact damage / recovery | Structure multiplier | Threat cost | First teaching site |
| --- | --- | --- | --- | --- | --- | --- |
| shambler | 60 | 47 | 9 / 1.2 s | 1.0 | 1 | garden |
| brute | 180 | 38 | 18 / 1.6 s | 2.5 | 3 | garage frontage |
| runner | 45 | 105 | 8 / 1.4 s | 0.5 | 2 | hardware |
| screecher | 75 | 42 | 6 / 1.5 s | 0.5 | 3 | clinic exterior |
| armoured | 130 | 40 | 12 / 1.4 s | 1.5 | 3 | station |
| crawler | 40 | 64 | 6 / 0.9 s | 0.5 | 2 | grocer or school; required introduction at radio |
| spitter | 85 | 35 | 6 / 1.5 s | 0.5 | 3 | hall |
| breaker | 420 | 30 | 24 / 2.0 s | 4.0 | 8 | pump approach |

Ordinary structure hits use base 7 damage × multiplier and the kind's contact recovery. Breaker charge damage is separate, never applied together with its ordinary hit. Kinds share physical collision, damage accounting, cooldown persistence, visible pursuit, saved intent and corpse depletion. No kind teleports, creates another zombie, attacks through a solid wall or becomes immune to basic melee.

## Shambler: crowd pressure

Purpose: teach spacing, contact danger and how a few bodies can occupy undefended property. Recognisable slow gait, hanging arms, worn civilian clothes. A short shoulder lean precedes a bite; warm-up 0.35 seconds. Bite range 29 pixels and clear line. On interruption, reset the warm-up; recovery prevents another immediate attempt.

One unarmoured bat user should handle one Shambler reliably, but several directions demand movement. Retreating in a straight line should work on open ground. The threat comes from being pinned by fences, protecting a worker or meeting another group, rather than movement speed cheats.

Initial residents dominate early properties. Later waves retain at least 50% Shambler threat cost, except explicitly authored teaching encounters. Existing health/speed/damage stay unchanged for the first expanded-combat pass.

## Brute: fortification pressure

Purpose: make a gate's remaining time and a defender's weapon matter. Broad frame, heavy staggered steps, large bare arms. Contact warm-up 0.65 seconds; normal reach 34 pixels. No charge. It batters the obstruction actually blocking its route, with the 2.5 multiplier.

Counters: focus fire, crowbar, sustained attacks from a safe inside post, moving around its slow approach. Ordinary hit stagger lasts 0.2 seconds instead of 0.45; no permanent stunlock by one fast bat. A heavy crowbar hit applies the full 0.45 seconds. Never ignore knockback entirely.

First show one outside the garage while the player has a clear retreat, not inside an unavoidable starting gate attack. Campaign introductory pacing deliberately replaces the slice's one-Brute-from-first-raid setting. Brutes become routine only after the garage discovery. Do not multiply their health as the campaign advances.

## Runner: formation pressure

Purpose: expose an unsupported rear and reward a mobile escort. Slim silhouette, forward lean, sharp footfalls. It runs at 105 and, within 110 pixels with clear line, plants for a 0.7-second lunge tell. Dash up to 85 pixels at 260 pixels/second, in the committed direction. Cooldown 4 seconds after a dash; no mid-dash homing.

Collision stops the dash. A missed lunge has 0.8-second recovery, with no contact damage during that recovery. It cannot leap a barricade, open a gate or travel through an ally. One damage event per lunge, followed by normal contact recovery. Save the committed direction, remaining distance and phase.

Counters: sidestep the visible line, a shield facing it, an intercepting companion, one pistol hit. On first introduction there are no more than two Shamblers beside it. It must not spawn behind a player who cannot see the tell.

## Screecher: attention pressure

Purpose: make target priority matter without generating punishment waves. Narrow upright pose, torn bright scarf, hands near the face. On noticing a person within 240 pixels it stops, visibly inhales for 1.5 seconds, then emits an investigation noise of radius 600 for existing zombies. Its call can be heard and seen through a pulse ring; it does not damage actors or structures.

Any damaging hit interrupts the inhale and applies a 4-second call retry delay. Successful call cooldown 18 seconds. A call cannot trigger another Screecher call by itself: calls require personally sensing a person, and acoustic events do not count as that condition. Global event deduplication prevents a call chain.

Counters: interrupt with a fast weapon, shoot before the inhale completes, retreat beyond sensing range. A completed call attracts only actors in range through real routes. If no other zombies are nearby, the call has no invisible consequence. It still closes to ordinary contact combat when the call is unavailable.

## Armoured: facing pressure

Purpose: reward flanking and a tool choice. Damaged riot vest/helmet, heavy squared silhouette, clear front plate. Frontal 120-degree arc reduces incoming melee and bullets by 50%; side/rear take full damage. Determine facing when damage resolves. Shotgun pellets obey the same arc. Crowbar and fire axe bypass the plate reduction; they do not bypass unrelated body protection.

The zombie turns at at most 120 degrees/second while pursuing and 60 while winding up. Warm-up 0.8 seconds. This creates a real flanking window; instant facing correction must not cancel the intended counter. It is never bulletproof and has no separate plate-health inventory.

Counters: circle with a companion holding attention, use a crowbar/fire axe, or spend more ranged ammunition. A lone player with a bat must remain able to win by movement. Plate reduction applies once, not once per armour component. Its damage multiplier against structures stays 1.5 even when flanked.

## Crawler: close-ground pressure

Purpose: ask the player to inspect clutter and protect a breach. Low dragging body, visible moving shoulders, audible scrape. Always alive and visible when in view; do not imitate a dead corpse or revive a previously killed actor. It uses the same walls and barriers as every other zombie.

Warm-up 0.45 seconds. A successful bite slows movement to 75% for 1.5 seconds. Repeated bites refresh duration, never multiply the slow. Apply the slow after armour speed: 190 × 0.8 × 0.75 = 114 for an iron-wearing protagonist. The slow neither blocks attacks nor prevents pause/orders. On load, restore remaining time exactly; emergency recovery clears it.

Counters: deliberate spacing, a broad sword swing, shooting low before entering a cluttered gap, placing a defender behind a broken line. Never use an intact-fence crawl-through exception. First required Crawler appears at radio with an unobstructed silhouette; optional grocer/school examples may be found earlier.

## Spitter: stationary-post pressure

Purpose: discourage leaving a defender indefinitely in one exposed spot while preserving cover as a counter. Hunched silhouette, swollen throat, visible aiming head tilt. Its person notice range is 340 pixels, overriding the shared 240 default. At 140–340 pixels and clear shot, aim for 0.9 seconds, showing a target circle at the person's current position. Fire one slow glob at 240 pixels/second toward that committed point. Attack cooldown 6 seconds.

The glob hits the first solid wall/closed gate/high cover; low road barriers do not stop it. It deals 8 direct damage at most once and makes a 42-pixel-radius pool lasting 4 seconds. Pool ticks at ages 1,2,3,4 seconds, with the final tick before expiry. Each tick deals 4 damage to actors standing inside. Direct hit plus that pool is at most 24 unmodified damage for a person who stays for its full duration. Overlapping pools share a per-actor one-second pool-damage cooldown: choose the largest eligible tick, never additive or offset ticks from several pools. Pools do not damage structures or zombies, spread between tiles or block claims after expiration.

Body armour reduces damage normally. A frontal shield reduces the direct projectile; it cannot block the ground pool. Guards may step to an alternate post within their leash while retaining assignment. Workers retreat from the marked area. Telegraph rings and distinct edge pattern remain legible without colour or audio.

Counters: step after the committed tell, use high cover, engage during cooldown, send a mobile follower to flank. Place the first one at hall across a wide yard, never firing through a hidden roof. No off-screen projectile attacks without a visible/audible directional warning.

## Breaker: deliberate siege encounter

Purpose: a visible late-game problem that prepared defences buy time to solve. Largest silhouette, dragging metal brace and slow weight shifts. It does not scale from the player's current gear. Only authored late-game encounters, one scheduled migration template and the finale can contain one; maximum one living Breaker globally.

Within 260 pixels of a person or breakable obstruction on its route, it braces for 2 seconds with a straight danger lane. Charge at 240 pixels/second up to 220 pixels; direction locks at the end of the tell. Stop on the first collision. One person struck takes 30 damage and knockback; one structure takes 60 damage. Solid buildings stop it without being destroyed. No separate ordinary hit in the charge tick.

After a charge, recover for 2.5 seconds; damage received is ×1.5 during recovery. Charge cooldown 10 seconds. A strong hit during brace extends the tell by 0.4 seconds once, not indefinitely. Shields reduce frontal actor damage; they do not stop the charge or prevent displacement. No knockback through a closed gate, wall or map edge.

Counters: leave the lane, hit its exposed recovery, focus from two angles, retreat behind a reinforced line with a second line behind it. It may breach one ordinary barricade that was already damaged, but cannot erase an entire corridor in one collision sweep. Defeating one grants no repeatable rare loot; access to the site is the reward.

## Undead baboon: area boss (first pass)

Purpose: the suburb's gate. One authored monster that holds the bridge road and is fought where it stands, not survived as a wave. It never appears in a migration template (threat cost is the budget maximum, 20, only to satisfy validation). Health 700, speed 70, contact damage 26 / 1.5 s, structure multiplier 3.0. Large, hunched, dark-furred, with a long muzzle toward its facing and an always-visible health bar.

It charges like a heavy Runner: within 220 pixels with a clear line it plants for a 1.1-second tell (drawn lane), dashes up to 260 pixels at 420 pixels/second, then recovers for 1.8 seconds with no contact damage, and cannot charge again for 5 seconds. Ordinary hits do not cancel the tell or dash (`uninterruptible`); a collision with a person, zombie or wall still ends it, which is the counter: sidestep the lane, or put a body or the shield in it.

It stays within a 320-pixel leash of its post and walks back when nothing in the leash is noticed. It ignores sounds. Two resident Shambler escorts stand by it. Its death is permanent, opens the exit and is saved (position, health and charge phase).

Not yet tuned against play: the numbers are a first pass, and bare-handed the fight is expected to be lost. Further phases or attacks are open.

## Behaviour combinations and limits

| Situation | Good composition | Prohibited default |
| --- | --- | --- |
| New-kind introduction | One new kind plus 0–3 known Shamblers, clear retreat | Two unfamiliar special mechanics at once |
| Routine defended approach | 5–8 Shamblers plus one Brute or two Runners | Spitter and Breaker on every calm interval |
| Flanking landmark | Armoured + Shamblers, with two entrances | Mandatory gun-only target |
| Attention encounter | One Screecher, nearby visible residents | Sound-spawned reinforcement or scream chain |
| Late siege | One Breaker plus 4–8 known common actors | Two Breakers, unsupported worker surprise |
| Finale | Fixed compositions in 13 | Scaling enemy health to prepared equipment |

Global caps: 96 living zombies, one Breaker, two Spitters, two Screechers and four Runners in any one routine migration. Landmark populations may include additional Runners but still obey the living cap. Special caps count residents and migrants together. If a routine special slot is unavailable, use Shamblers within the same threat budget; never exceed the cap or save an invisible backlog.

## Authoring requirements

Each kind needs a readable idle/move pose, wind-up, attack, hit and fall; Runner adds dash, Screecher inhale/call, Spitter aim/glob/pool, Breaker brace/charge/recovery. All attacks have a visual tell and directional audio where available. A shadow/outline option helps the Crawler; colour is supplementary.

Per-kind data must include stable ID, display name, base statistics, warm-up, special parameters, threat cost, silhouette marker and sound cue IDs. Validators require only fields implemented for that behaviour. Unknown kind or missing field fails at load; migration alone supplies `shambler` for historic actors without kind.

Acceptance: kind survives save/load in every special phase; obeys collision/clear lines; warning has time to respond; counter works with attainable equipment; no damage duplicates on load; nearest-person priority wins over travel and noise; special caps and finite actor conservation hold. See [17](17-acceptance-and-balance.md).
