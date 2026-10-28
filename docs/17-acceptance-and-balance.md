# Acceptance scenarios and worked balance

This is a future implementation/QA specification, not a report that these scenarios ran. The documentation pass checks its own arithmetic, IDs and links only. [PROGRESS.md](PROGRESS.md) records actual game evidence. Catalogue values remain starting balance until human testing.

## Core-path reachability proof

Hold/search the complete northern chain: home → garden → residence → hardware → clinic → greenhouse → station → radio → hall → depot → pump → relay. Build eleven passages, 44 Materials total. From held north sites, clear/claim the six core south sites: library, garage, munitions, salvage, substation and assembly. Optional grocer/allotment/diner/firehall/museum/school are absent from this route and every mandatory prerequisite.

Protect crossings at columns 0,1,2,9,10,11 with two separate west/east road lines each: twelve lines cost 96 Materials. Each crossing also needs its actual yard gates open and corridor clear. The 160-pixel alley gap between adjacent crossings is excluded from their protected areas. Northern passages keep east-west travel available when road lines block through-traffic.

Finale east approach uses relay_east, already in the above budget. Add north/south Works alley lines, 16 Materials, then reinforce all three final lines for 30 Materials as a recommended preparation plan. Reinforcement is helpful but not a hidden readiness requirement. The player can reach every inside work position through the held yards. Do not place the alley line collider over the northern through-passage.

## Material ledger

Core searches total 272 Materials. Seventeen non-home core first claims add 102, the three timber piles add 30, starting stock adds 18: **422 Materials** available without optional caches or renewable salvage. Optional searches add 112 and their first claims add 36, excluded below.

| Expenditure plan | Calculation | Materials |
| --- | --- | --- |
| Required facility restoration | garden 8 + workshop 10 + clinic 12 + greenhouse 16 + radio 10 + salvage 16 + pump 18 + power 24 + relay 24 + assembly 16 | 154 |
| Original garage sword/iron/shield | Optional but included as a useful defence loadout | 12 |
| Northern passages | 11 × 4 | 44 |
| Core protected crossings | 12 independent road lines × 8 | 96 |
| Two Works alley lines | 2 × 8 | 16 |
| Three reinforced final lines | 3 × 10 | 30 |
| Six line/gate repair batches | 6 × 3 | 18 |
| Sixty crafted Bullets | 10 × 2 | 20 |
| Six crafted Medicine | 3 × 1; also six Food | 3 |
| Total spent | — | **393** |
| Remaining | 422 − 393 | **29** |
| Finale available-Materials requirement | Retain, do not spend at launch | 12 |
| Additional margin | 29 − 12 | **17** |

This is a planned baseline, not unlimited repairs. Two destroyed 300-health facilities need up to four facility repair batches (16 Materials) and still leave one above the launch reserve. Optional equipment/upgrades require an explicit budget choice or renewable salvage. A failed finale can demand salvage/repair time; it does not refund shots or create free supplies.

### Funding before the late salvage source

The first six sites supply 18 starting + 30 first-claim + 30 timber + 12 garage search = 90 Materials. Garden/workshop/original set cost 30, first two northern passages 8, and all three core crossing pairs cost 48: 86 spent, four remain before repairs. The third pair is needed for safe bullet-workshop production through residence/munitions. There are 17 Food in those searches plus the starting eight. Garden work can already sustain ordinary early consumption.

Market core searches add 60 Materials (hardware 32, clinic 12, greenhouse 16), three claims add 18. Three new northern passages cost 12, clinic/greenhouse 28; after six repair batches and 60 Bullets across the early/midgame, stock is four. That is before any Civic material rewards, optional loot or salvage production. It is not necessary to clear optional houses to afford clinic/greenhouse.

At Civic, core searches add 52 (station 20, radio 12, hall 20), claims 18; three passages cost 12 and radio costs 10. Enough remains to enter Works with a 12-Material reserve. This is a conservative ordering example, not a forced story sequence. New resources arrive through actual clear/search/claim commands, not fixture stock injections.

## Ammunition and medicine

Core finite supplies: 48 Bullets, 8 Shells and 22 Medicine. Ellis's six are included once in the 48. The ledger crafts 60 additional Bullets and 6 Medicine, giving 108 Bullets/8 Shells/28 Medicine before use.

If 84 Bullets are spent before launch, 24 remain; Shells are still an alternative reserve. If 22 Medicine are spent on treatment, 6 remain. The final watch spends normally; falling below preparation reserves while running is allowed. Do not continuously reset/fail it because a defender fired the ammunition they were told to bring.

Basic melee remains a valid counter for every core enemy, with movement/cover. Do not set up an encounter that requires shooting a special which can only be reached after spending all obtainable ammo. Guard policies/reserves need human observation, especially ranged-versus-Shambler waste.

## Food model

At eight people: one meal costs eight every two minutes = four/minute. Two growers: 2/45 s garden + 4/60 s greenhouse = 6.67/minute; at 70% combined effective uptime = 4.67. Waterworks adds another 0.7/minute at that uptime. Optional allotment is extra resilience, not a hidden requirement.

Illustrative 120-minute campaign roster: two people for 10 minutes, four for 25, six for 30, eight for 55. Approximate consumption is 10 + 50 + 90 + 220 = 370 Food. Exact discrete meal timing depends on rescue ticks and must be checked in the implementation scenario.

Core finite Food is 61 plus eight starting = 69. Garden working from minute 8 at 70% uptime produces about 209 Food; greenhouse from minute 40 produces 224; pump from minute 90 adds 21. Total potential supply about 523 against 370 meals + 20 recovery + six medicine Food = 396. Repeating targets stop excess production; this is capacity headroom, not a claim that 127 surplus is physically stored.

The early four-person interval is the tight part. Observe whether caches and garden interruptions create pressure without repeated work babysitting. If shortage becomes routine despite two growers, tune output/meal interval rather than adding hidden food gifts or disabling danger. If food never matters, reduce finite caches before increasing management complexity.

## Scenario acceptance matrix

Automated fixtures may stage initial actors/resources for an isolated rule, but integrated campaign checks must record every staged exception. A “command-driven core run” may use authored commands and deterministic seed; clearing enemies by fixture does not prove a playable combat run.

| ID | Setup/action | Required invariant/outcome | Evidence mode |
| --- | --- | --- | --- |
| A01 | Validate all catalogues, unknown IDs, wrong types, prerequisite cycle | Fail clearly; 24 sites, 18 core, seven named companions, eight kinds | Headless/data |
| A02 | Remove all optional vertices, trace home connections | Every core site/facility/finale requirement still obtainable | Headless/graph |
| A03 | Build adjacent crossing lines then remove one boundary; enter intervening alley | Only its crossing pauses; exposed alley never counts safe; no duplicate collider/refund | Headless + window |
| A04 | Occupy yard for 7.9 s, contest, then 8 s unopposed | Timer resets on standing entry; downed actor cannot contest; home can fall | Headless |
| A05 | Lose bridge parcel, use alternate lower route, then reclaim | Physical safe path chosen; rewards/work commitments unchanged | Headless + window |
| A06 | Player→AI→player work; switch roles; two sites at once | One debit/output/site; one site's completion does not reset another | Headless |
| A07 | Cancel before/after work, destroy/remove/repair at reload boundary | Exact formula, no double return or duplicate repair charge | Headless |
| A08 | Finish blueprint with person/downed actor in footprint | Completion waits; no trapped/pushed actor | Headless + window |
| A09 | Lower stock target mid-batch, spend reserve, disconnect facility | Paid batch preserved, no new invalid batch, one readable block | Headless + UI |
| A10 | Rescue in alternate order; mixed whole-team orders incl. Ellis | Unique actors/gift; Ellis never attacks/guards/equips weapon | Headless + window |
| A11 | Attempt third follower; carry injured recruit | Explicit swap choice; never third attacker or duplicate carried actor | Headless + UI |
| A12 | Transfer unique equipment around all compatible people | One owner, no heal/ammo grant; two-handed stance disables shield | Headless + window |
| A13 | Bat/sword/long weapon cone/line/target checks | One or two valid targets as authored; no wall bypass | Headless |
| A14 | Pistol/shotgun miss, partial hit, wall, allied lane, empty stock | Exact one-round consumption; deterministic rays, no friendly damage | Headless + input |
| A15 | Runner tell, locked dash, collision, miss, reload phases | Counter window; no homing or double hit | Headless + window/human |
| A16 | Interrupt Screecher, chained sound sources, quiet/loud route | No spawned population; no recursive scream; nearest person wins | Headless + window |
| A17 | Armoured front/rear/crowbar and slow turn | Plate once, reachable flank, no invulnerability | Headless + human |
| A18 | Crawler bite refresh plus iron speed | 114 player speed while combined slow; no stacking/permanent slow | Headless + window |
| A19 | Spitter direct/pool/overlap, low/high cover, guard dodge | Damage max/expiry correct, no stacked pools; assignment retained | Headless + human |
| A20 | Breaker charge on person/structure/wall and reload | One collision event, correct damage, no wall travel or phase duplication | Headless + human |
| A21 | 96 living at warning; migration due; reload next interval | Routine overflow discarded, no backlog; warning persists | Headless |
| A22 | 106-actor migrated old save | All actors retained, admission suppressed until below 96, viable performance | Headless + measured |
| A23 | Full-roster meal shortfall; food delivered; pause/load | No debt/death; one restoring meal; work rate returns correctly | Headless |
| A24 | Carry/place/treat, unsafe interruption, healthy recovery | Conservation, real location, one input commitment, no remote revive | Headless + input |
| A25 | All down, home occupied, no resources | Emergency recovery always available; IDs/gear retained; no free loot | Headless + human |
| A26 | Spend every finite cache; no refundable jobs/food; salvage bench and power unrestored | Emergency salvage reaches 24; restore 16-Material salvage bench and fund remaining progress; viable gate/garden/reclaim action | Headless + human |
| A27 | Save all supported schemas, corrupt newest slot, write failure | Valid backup offered, prior save/live progress intact, no silent reset | Headless + UI |
| A28 | Finale starts with each missing prerequisite individually | Named actionable reason; unknown rewards not exposed; no spend | Headless + UI |
| A29 | Save at warning/entry/last pending finale member | Exactly 31 scheduled migrants/cost 51, no skipped or duplicate member | Headless |
| A30 | Power/route cut, 30 s grace, five-second reset rule | Watch suspends/resumes/fails correctly; repeated toggles cannot extend grace | Headless + UI |
| A31 | Lose optional site or spend below starting reserve during watch | Attempt continues; only explicit failure rules apply | Headless |
| A32 | Finale defeat/retry/success/continue; failed completion save | World retained, pending cancelled only on failure, completion once | Headless + full run |
| A33 | Pre-rescue screens/map/objectives/equipment | No undiscovered name/reward leak | Window inspection |
| A34 | 150% text, remapped mouse/keys, muted audio/reduced flashes | Every essential action/info still accessible; no clipped confirmation | Real input/window |
| A35 | Full 18-core route funded by authored rewards and real commands | Ledger conservation, no mandatory optional loot or injected resources | Integrated simulation |
| A36 | Routine home defence while expedition is away | Two equipped defenders hold; work resumes without unsafe chase | Three human observations |
| A37 | Full game start→ending→continue | Understandable next steps, 2–3-hour core target, no mandatory grind | First-time human run |

## Human playtest scorecard

Record build/seed, difficulty, input bindings, prior familiarity, session time and route. Track compulsory returns home, avoidable AI downs, confusing blocked jobs, time spent waiting for supplies, unknown special hits, wasted guard ammo and optional-site choices. Ask the player to explain one claim, one safe route, one new enemy counter and the final objective in their own words.

Targets: stable midgame supports 3–5 minutes away; two-defender routine attacks succeed in three observed trials; new kind understood by its second encounter; no invisible entry into held space; food/reserve settings require occasional choices rather than continuous correction. A missed target changes design/tuning, not the wording of the evidence.

## Presentation and performance evidence

Use stable flat labels under docs/verification through the toolkit capture runner. Suggested genuinely new states: runner_tell, screecher_call, armoured_flank, crawler_approach, spitter_pool, breaker_charge, market_overview, full_roster, relief_readiness, relief_watch, relief_failure, relief_complete. Reuse labels when retaking, never timestamp/final/fix variants. Inspect the image before claiming readability.

Capture full-town worst legal population/specials with frame-time/route counters on the actual reference machine. Record median and slow frames, process memory and pathological blocked-route behaviour. Aim 60 fps, but report measured results and the device. An editor/import check or a static screenshot establishes neither frame rate nor audio/input feel.
