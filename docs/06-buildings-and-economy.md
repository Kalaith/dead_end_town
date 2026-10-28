# Buildings, supplies and community economy

Full game values. [15](15-property-catalogue.md) owns finite property rewards; [16](16-equipment-and-recipes.md) owns costs/work outputs. Current slice meals are 60 seconds and garden cycles 20 seconds; the campaign deliberately retunes both as below. These are design choices, not changes already made.

## Resource ledger

| Stock | Sources | Uses | Renewable rule |
| --- | --- | --- | --- |
| Materials | Claim stipends, finite searches/timber, salvage yard | Construction, repairs, equipment, ammo, medicine | Salvage role produces 4/45 work seconds |
| Food | Finite caches, garden, greenhouse, optional allotment | Shared meals, home recovery, medicine batches | Garden 2/45 s; greenhouse 4/60 s; allotment 2/40 s |
| Bullets | Ellis's six, finite station/depot supplies, bullet bench | Pistol shots | 2 Materials → 6 in 15 work seconds |
| Shells | Station/firehall caches, bullet bench after station kit | Shotgun shots | 3 Materials → 4 in 20 work seconds |
| Medicine | Clinic/cache supplies, restored clinic | Treatment and final readiness | 1 Material + 2 Food → 2 in 30 work seconds |

No Metal, fuel, water, seed, component, calibre or spare-part counters. All materials represent a mixed usable bundle. Key tools/coil/coupler are permanent discoveries, not stacks consumed each production cycle. Unique equipment has individual ownership, never a fungible count.

Start at home with 18 Materials, 8 Food, no ammo/medicine and basic bats. Existing save stocks migrate unchanged. Mara is already part of the initial two-person meal. New campaign recipe costs do not retroactively bill migrated completed facilities.

## Search, stock access and physical work

Search rewards deposit directly into shared stock at the successful search transaction, even during a distant expedition. This intentionally avoids a general carried-inventory/hauling system. People still need to reach the discovery; there is no map-click collection. Explain “Recovered to community supplies” once, then use a brief quantity notification. There is no drop bag on defeat or separate looted-but-not-deposited state.

Productive facilities can spend the shared stock only when held, safely home-connected, locally clear and intact. Equipment changes additionally require wearer and player at the appropriate bench. Field construction uses the explicit player-present prepaid-bundle exception in 04. No disconnected remote worker spends new stock.

One-time first-claim stipend is six Materials per non-home site. First three timber piles (garden/library/garage) supply ten each through Q; other sites put materials in their search ledger and do not automatically add another timber pile. Searching/claiming/collecting are independent persistent once-only flags. Recapture cannot repay any of them.

## Food and staffing

Every 120 active seconds, consume one Food per recruited person including the protagonist and downed people. Pause/loading/closed game consume nothing. A new recruit joins the next meal, not a separate timer. All people share the same meal; no ration choices.

If insufficient, spend nothing, mark shortage and work at 60%. No movement/attack penalty, health loss, death or accumulating debt. On delivery of enough Food for one meal, consume that meal once, clear shortage and restart the 120-second timer. Default production/crafting Food reserves protect the next meal; direct recovery asks explicitly before spending into it.

With eight people, consumption is four Food/minute. Garden 2/45 seconds = 2.67/minute; greenhouse 4/60 = 4/minute. Together yield 6.67/minute at full uptime, 4.67 at 70% uptime: enough with a modest margin. Two growers leave five survivors for two follower slots, two defence posts and rotating production/repair. After waterworks, greenhouse produces five per cycle (5/minute), never an unexplained global percentage bonus.

One early garden sustains two people at ordinary uptime; a four-person Hearth group needs food caches and sensible tending until the greenhouse. This encourages expansion without a starvation fail state. The 60% shortage rate still permits a garden to produce and recover. Show next meal cost/time, available meals and the local source of a production pause in the paused supply screen.

Food target: two meals plus four recovery Food. Routine grower can pause at target but keeps its assignment and resumes below target minus one meal, avoiding a start/stop every item. Lowering the target cannot discard harvested Food. No spoilage or storage upgrade tax.

## Reserves and maintenance

Default Materials reserve: six early, twelve after hardware discovery. Routine repeating ammo/medicine/equipment and automatic repair cannot start if the full new commitment would take available Materials below reserve. Explicit player-approved construction can spend into reserve after a clear warning; no second confirmation dialogue beyond the shown cost and warning. Player manual repair can also override it. An active breach allows permitted critical repair into reserve and reports once.

Food reserve is the next meal cost. Medicine crafting respects it. Treatment/home recovery can spend below it with the cost visible in the explicit action. AI queued treatment respects the Food reserve for home rest, but clinic treatment costs Medicine only. Ammo reserves and guard policies are in 03.

Count committed stock separately from available; show pending outputs separately. Prepaid work is not counted as spendable twice. There is no upkeep drain on walls, idle facilities or equipment. Damage comes from actual attacks. Destroyed facilities retain their restoration/unlock state and use repair work, rather than demanding a second discovery.

## Facilities and output

Each facility has one effective worker rate and one active batch, not one output per worker. A present player can substitute R work at all facilities except bullet/shell production, which remains a survivor-operated role as requested. Food grows through tended work, not offline time. No dedicated worker needed while a facility is idle or a stock target met.

Inputs commit once at batch start; outputs enter shared stock once at completion, only while safe connection holds. Disconnect/danger suspends labour and final output without deleting progress. A facility does not create a hidden warehouse of uncollected outputs. [04](04-construction-and-jobs.md) defines cancellation.

Restore waterworks to add one Food to each greenhouse completion. Restore power to enable relay operations and the salvage-yard upgrade (4 → 6 Materials per 45 work seconds). There is no fuel/wiring upkeep or network puzzle. These bonuses are attached to explicit facilities and depend on their current operation. A power outage suspends the upgrade benefit, not already delivered output.

## Recoverability and material exhaustion

Finite core-site rewards cover the main route plus a repair/ammunition allowance; 17 carries the ledger. Renewable salvage is a convenience and long-term repair source, not a required 30-minute grinding phase. It unlocks at the salvage yard in East Works, with sufficient finite earlier supplies to reach it.

Whenever no salvage yard is operational, emergency salvage is available at home and the west recovery shelter. The player may work its visible scrap pile while available Materials plus refundable unfinished-project commitments are below 24: 2 Materials per 20 active work seconds, clamped to that combined cap. No input, unique reward, worker automation or farming discovery flag. Each output rechecks the cap atomically. It stops when danger is within 170 pixels. It cannot pay for multiple prepaid projects above the cap by cycling approval/cancellation. The 24 cap covers the most expensive essential single restoration; a lower twelve-Material cap would softlock a town with every cache spent and its sixteen-Material salvage bench unrestored.

This is deliberately slow and explicitly labelled recovery salvage. It gives a way to rebuild a gate/basic garden or resume a needed chain after waste. It is not a timed rescue gift or enemy loot farming. Basic bats, nonlethal shortage and recovery at 50/25 health provide a viable next action even with no Food/Medicine. The player can return to finite optional caches or reclaim the salvage route rather than restart.

Medicine is renewable but not required for ordinary survival: food-based home recovery works before clinic. Firearms are helpful but basic melee can clear every mandatory encounter. No key discovery can be consumed accidentally or lost with a building. No recipe output is required to make its own prerequisite.

## Economy validation

Check the core route independently of optional loot, perfect no-hit play and renewable salvage. Include all required passage/road/approach construction, mandatory facility restorations, one usable defensive loadout, six repair batches, 60 crafted Bullets, Medicine and finale reserve. Record timing and stocks at each district, including meals and treatment.

Then deliberately waste resources: dismantle a damaged line, lose a food site, abandon a committed project and recover after defeat. Prove a practical next action without duplication or a restart. Human sessions must determine whether this remains satisfying; a ledger alone cannot establish pacing or food pressure.
