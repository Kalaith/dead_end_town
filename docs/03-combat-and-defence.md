# Squad action combat and automatic home defence

## Player actions

Proposed action set: move, aim, attack, dodge, interact, and issue squad orders. Shields add a block action when equipped. One held interaction performs repairs or construction at a safe reachable work site. Combat cancels work cleanly and preserves progress.

Start with a readable melee weapon and a slow basic zombie. Wind-up, reach, impact, stagger, recovery, and crowd spacing matter before weapon variety. Heavy armour improves protection and stagger resistance but should have a visible mobility tradeoff. Exact stamina, dodge invulnerability, friendly fire, and weapon durability rules are open.

## Implemented basic melee, 28 October 2026

Each basic bat swing hits one living zombie: the nearest valid target within reach, forward cone and clear attack line. Damage, stagger and knockback apply only to that target. Survivors use the same basic single-target melee. No current weapon grants cleaving; broader attacks remain a possible future equipment distinction.

## Squad

The conversation proposed one controlled character with up to three companions. Prove one companion first; the MVP target is up to two. Companion count is a tuning choice, not a requirement to recruit a large population.

| Order | Expected behaviour | Safety constraint |
| --- | --- | --- |
| Follow | Stay near the player and assist against immediate threats | Limited pursuit; avoid walking through hazards to keep formation |
| Hold | Defend a chosen reachable position | Stay within a visible leash; use nearby cover or shield position |
| Engage | Focus a target or a small local area | Never interpret as permission to clear the whole town |
| Return home | Travel to a selected safe home post | Validate route and report blockage; no teleportation |

Show each order and destination beside the survivor portrait. A blocked order produces a reason and safe fallback. Companions should not independently loot an infected house or break formation to chase a distant zombie.

## Combat roles through equipment

A shield user holds a doorway; a firearm user supports from behind; a quick melee survivor protects a flank. Equipment changes behaviour and silhouette. Background can add flavour or a small automatic advantage, but should not lock a named survivor out of useful equipment.

Reserve firing lanes, space melee allies around targets, and avoid continuous repathing for every squad member. If ranged line of sight is blocked, reposition within the order boundary or hold fire. Ammunition should not drain against a wall.

## Home defence

Guards are physical survivors with an assigned post, weapon, detection area, pursuit leash, and retreat destination. They attack reachable threats, defend entrances, conserve ammunition against invalid targets, and return to their post after danger passes. A guard never abandons the gate for a routine harvest order.

Workers have an emergency response: shelter, support a nearby defence, or treat casualties. Default builders help only when the fight reaches their local area; gardeners shelter rather than charge a horde. Small rosters need useful fallback work, not a dedicated person for every facility.

## Alerts and readiness

| Alert | World condition | Response |
| --- | --- | --- |
| Safe | No immediate local approach or breach | Normal work and maintenance |
| Threatened | Hostiles approach or attack a boundary | Exposed workers withdraw; guards engage |
| Breached | Hostiles cross a defended boundary | Shelter, local defence, casualty support |

Use local zones so one zombie at the north gate does not repeatedly stop every indoor job. Brief hysteresis prevents rapid switching between safe and threatened states.

Readiness displays guard coverage, weak boundary segments, ammunition, current threats, and the squad's expected return route. It is an estimate, not a score that decides combat. Explain uncertainty when a street has not been scouted.

Alerts identify location, structural condition, defenders, and whether the line is holding. Escalate on meaningful changes: approach, sustained damage, breach, incapacitation, resolution. Provide map pings and text as well as sound. Do not repeat a radio line every second.

## An expedition decision

The player and Paige are at the garage. A group reaches the home gate. Mara holds inside while a builder retreats. The player can finish a short search, return immediately, or send Paige home if the route is safe. That choice is meaningful because the gate has a known condition and the defender is behaving predictably.

The game must not manufacture this choice by spawning enemies inside home or disabling guard AI off-screen.

## Setbacks and recovery

Proposed MVP: survivors become incapacitated and can be recovered; facilities pause when unsafe; fortifications can break. Carried supplies can be left at a marked recovery point. The protagonist's incapacitation returns play to a recoverable checkpoint or rescue state; choose the exact rule before implementing combat persistence.

Preserve key discoveries against accidental permanent loss. A severe defeat may cost materials, time, and territory access, but should leave a viable recovery route. If every survivor is down, offer reload from a clearly identified earlier save. Permadeath is a later difficulty discussion.
