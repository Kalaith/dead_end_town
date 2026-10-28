# Property and encounter catalogue

Full game content manifest. Six Hearth properties exist; all later districts are future design. [13](13-campaign-and-map.md) fixes positions and core/optional flags. [16](16-equipment-and-recipes.md) owns recipe costs. No catalogue effect is implemented merely by being listed here.

## Reward ledger

M/F/B/S/Med = Materials/Food/Bullets/Shells/Medicine. Search rewards below are finite and awarded once. Every non-home first claim additionally gives 6 M. Only garden/library/garage have separate Q timber, 10 M each; do not add timber to other rows. Start stock is 18 M/8 F, recorded in 06. “0” means no reward, never infer a generic fallback cache.

| ID | Core | Search M | F | B | S | Med | One-time discovery / usable equipment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| home | Yes | 0 | 0 | 0 | 0 | 0 | Shared stock/shelter; Mara already recruited |
| garden | Yes | 0 | 4 | 0 | 0 | 0 | garden_seeds; separate 10 M timber |
| library | Yes | 0 | 3 | 0 | 0 | 0 | Paige; separate 10 M timber |
| garage | Yes | 12 | 2 | 0 | 0 | 0 | garage_tools, crowbar, recoverable original set; separate 10 M timber |
| residence | Yes | 0 | 4 | 6 | 0 | 0 | Ellis and ellis_pistol; these six are the gun gift, not six more |
| munitions | Yes | 0 | 4 | 0 | 0 | 0 | Bullet bench unlock on claim/search; no restore charge |
| hardware | Yes | 32 | 2 | 0 | 0 | 0 | hardware_tools, hardware_spear |
| grocer | No | 12 | 16 | 0 | 0 | 0 | Food buffer, safe southern route |
| clinic | Yes | 12 | 4 | 0 | 0 | 12 | June, medical_kit, clinic_bag |
| allotment | No | 16 | 6 | 0 | 0 | 0 | Extra growing socket, no exclusive key |
| greenhouse | Yes | 16 | 8 | 0 | 0 | 0 | Oliver, growing_kit |
| diner | No | 16 | 12 | 0 | 0 | 2 | Recovery supplies, sheltered southern crossing |
| station | Yes | 20 | 2 | 18 | 8 | 0 | Theo, station_pistol, station_shotgun, ammunition_kit, recoverable riot kit |
| firehall | No | 28 | 4 | 0 | 4 | 4 | firehall_shotgun, recoverable fire axe |
| radio | Yes | 12 | 2 | 6 | 0 | 0 | radio_receiver |
| museum | No | 20 | 2 | 0 | 0 | 0 | Recoverable museum iron/polearm set |
| hall | Yes | 20 | 6 | 0 | 0 | 4 | relief_plan |
| school | No | 20 | 10 | 0 | 0 | 4 | Supplies, secondary civic route |
| depot | Yes | 36 | 4 | 12 | 0 | 0 | Nia, generator_coupler |
| salvage | Yes | 24 | 2 | 0 | 0 | 0 | Sorting bench location |
| pump | Yes | 24 | 2 | 0 | 0 | 0 | Waterworks restoration site |
| substation | Yes | 24 | 2 | 0 | 0 | 0 | relay_coil on search, power site |
| relay | Yes | 16 | 2 | 6 | 0 | 2 | Signal console |
| assembly | Yes | 24 | 8 | 0 | 0 | 4 | Relief staging site |

Key discoveries commit on search; core facilities still require approval/work in 16. Material caches include the former garage bonus explicitly. All finite rewards enter shared stock directly; no carrying/drop-bag ledger. Every table row must map to one persistent search flag, not separate flags that can grant the same gift twice.

## Authored initial population

S = Shambler, B = Brute, R = Runner, C = Crawler, Q = Screecher, A = Armoured, P = Spitter, K = Breaker. Letters are authoring shorthand only, never player HUD labels. Positions are authored within the stated encounter geometry. Total initial population is 89, leaving room below the 96-living cap; all are present from campaign creation and simulate continuously.

| Site | Composition | Total | Teaching / geometry |
| --- | --- | --- | --- |
| home | None | 0 | Safe starting yard, damaged gate |
| garden | 7 S | 7 | Open yard, spaced groups, no blind doorway |
| library | 7 S | 7 | Two shelving lanes, porch retreat |
| garage | 9 S + 1 B | 10 | Brute on frontage, usable side approach |
| residence | 3 S | 3 | Short humane rescue breather |
| munitions | 4 S | 4 | Benches create two attack lanes |
| hardware | 2 S + 1 R | 3 | Runner visible beyond a wide service bay |
| grocer | 1 S + 1 C | 2 | Optional early Crawler, visible aisle edge |
| clinic | 2 S + 1 Q | 3 | Screecher on exterior forecourt, two entrances |
| allotment | 2 S | 2 | Low-risk food/routing alternative |
| greenhouse | 2 S + 1 R | 3 | Clear plant rows, no invisible glass collision |
| diner | 2 S | 2 | Counter cover, food reward breather |
| station | 3 S + 1 A | 4 | Armoured front lane plus flanking side office |
| firehall | 2 S + 1 B | 3 | Wide appliance bay, slow heavy encounter |
| radio | 2 S + 1 C + 1 Q | 4 | Required Crawler introduction; Screecher separated by room wall |
| museum | 2 S + 1 A | 3 | Optional armour duel around low displays |
| hall | 3 S + 1 P | 4 | Spitter visible across broad forecourt |
| school | 2 S + 1 C | 3 | Two-door hall, clear low silhouette |
| depot | 2 S + 1 R + 1 A | 4 | Mobile/facing combination, separated loading lanes |
| salvage | 2 S + 1 B | 3 | Brute guarding scrap mouth, clear escape |
| pump | 2 S + 1 K | 3 | Breaker teaching lane with two perpendicular escape routes |
| substation | 3 S + 1 A | 4 | Tall electrical housing blocks fire, no shock hazard system |
| relay | 2 S + 1 P + 1 A | 4 | Known specials in separate approaches |
| assembly | 3 S + 1 R | 4 | Wide staging yard, final preparation space |

Population totals by district: 31, 15, 21, 22. Later districts use fewer bodies with stronger mechanics and migration pressure, rather than multiplying basic zombies until movement becomes cluttered. Special teaching encounters trigger discovered-kind eligibility only after the player sees the tell or resolves that encounter. Merely hearing distant combat does not enable an unintroduced special migration.

## Hearth Street: retain the working foundation

### home — Starting home

Shared stock, ordinary recovery, padded-clothing work and emergency salvage. Home starts held and searched, with no discovery payout. Mara starts at the inside post. Gate begins at 65% of 160 health. Keep a visible bench, porch, stock crate and safe casualty spot. A home loss pauses productive operations across town, but not claims already earned. Do not charge a restoration fee to regain basic recovery after reclaiming.

### garden — Garden house

The first food improvement. Seven residents are split so approaching the gate need not aggro all at once. Search seeds, claim and approve garden; physical safe passage home is required for delivered harvest. Show crops/worker/ready produce. Opening the passage should be visible growth rather than only a connection icon.

### library — Library

Paige's rescue and the first opposite-road claim. Shelving lanes introduce chokepoints without hiding attacks under a roof. Its ongoing value is a protected crossing and southern circulation, not an organisation buff. A quiet reading corner appears after claim; no new management station or research timer.

### garage — Garage

Workshop, crowbar and original armour progression. The heavy resident is visible from outside the frontage; a side approach permits a quiet retreat. Restoration shows the sword/iron/shield before they become usable. Preserve the exact existing reward identities on migration. Late-game repair remains possible here even after the front advances.

### residence — East house

Ellis's noncombatant rescue. Three known enemies make this an intentional breather. The paused introduction gives one pistol and exactly six Bullets. The house primarily supports the northern route and recovery sheltering; it does not conceal an extra craft upgrade. Ellis is useful immediately without violating the never-fight rule.

### munitions — Ammunition workshop

Bullet crafting unlocks on claim/search, no additional restoration cost. One physical worker station and an accessible protected route. Shell recipe appears only after the station ammunition kit is known. “Two workers” never means double output. Pause/resume should visibly preserve the partially assembled batch.

## Market Row: make the community sustainable

### hardware — Hardware shop

Core material cache, construction tools and one long spear. Runner teaching encounter has a broad door, an obvious retreat lane and a clearly committed dash. Tool discovery unlocks reinforcement/late construction but grants no free reinforced walls. The north passage into Market Row is the first longer expedition connection.

### grocer — Corner grocer

Optional large Food buffer, ordinary Materials and a lower southern route. One Crawler lies visibly moving beside the first aisle, never disguised as a defeated corpse. It is safe to skip; there is no exclusive nutrition recipe. Counter and rear door allow a local flank.

### clinic — Clinic

June, renewable medicine, treatment and field bag. Screecher is outside where a new player can see its inhale before entering. A second entrance leads around its forecourt. Once restored, a patient bed and work point must both be reachable without blocking the main route. No daily disease/infection system.

### allotment — Community allotment

Optional two-Food cycle once growing kit is recovered from greenhouse. Before that it is supplies and a southern yard connection. This deliberate prerequisite is displayed after search; optional growing cannot block Oliver's rescue or core food. No seed stock, season or watering meter.

### greenhouse — Greenhouse

Oliver and the primary full-roster food facility. Clear plant aisles, broken panes marked as openings, ordinary intact glass collision matching art. Work produces four Food/cycle, five with working pump. Restoring the pump changes a visible irrigation tank, not a pipe-building system. A ruined greenhouse does not erase the growing kit.

### diner — Roadside diner

Optional supply breather and southern loop. Tables/low counter offer shooting cover and a clear return path. Provides food/medicine, not a cooking station with a second meal type. Preserve the site's value through route geometry and visual community use.

## Civic Block: choose equipment and information

### station — Police station

Theo sheltered here as a courier, not an additional police character. One Armoured zombie teaches slow turning and the side-office flank. Recovered pistol/shotgun, finite ammo, ammunition kit and damaged riot equipment change loadouts. Station kit restoration happens at the garage; no forced gun use to claim the station.

### firehall — Fire station

Optional second shotgun, fire axe and repair supplies. Its Brute is a known mechanic in a wide bay. The parked appliance is static scenery, not a driveable vehicle. Low yard equipment creates useful inside defence positions. Axe restoration costs a small work order, not a new tool chain.

### radio — Radio office

Required north-chain site with Crawler and known Screecher in separate sightlines. The moving low silhouette is readable before close contact. Restore receiver desk for longer migration warning and scouted kind silhouettes. Base warnings continue if radio is lost; its upgrade never makes the player blind by withholding essential alerts.

### museum — Local museum

Optional second iron set and polearm, distinct from the garage gear. The Armoured enemy's plate is framed by two low display aisles, making a flank apparent. Search recovers a damaged display set; usable instances grant only at restoration. No mandatory museum detour, puzzle key or historical weapon repair durability.

### hall — Town hall

Core relief plan and Spitter teaching encounter. Broad paved forecourt gives room to step away from the marked impact. High entrance wall blocks a glob; low street barriers do not. Searching opens the final readiness page, revealing only unknown component categories rather than hidden survivor names. Previously collected requirements count.

### school — School hall

Optional medicine/food, a two-door southern route and a cleared community space. Reuses Crawler safely; no child rescue or extra population. Its sheltered hall is a legal casualty drop point when held/clear. No schooling/education subsystem or invisible productivity bonus.

## East Works: prepare the relief signal

### depot — Delivery depot

Nia and generator coupler. Separate loading lanes combine Runner and Armoured counters already taught. Static pallet stacks create approach choices. The coupler is permanent knowledge/equipment discovery used by substation restoration, not a supply consumed by each outage. No delivery-truck simulation.

### salvage — Salvage yard

Core renewable Materials: four per 45 work seconds, six with separately purchased powered upgrade. Sorter works at a protected bench; unlimited long-term salvage is an abstract recovery supply, not duplicated one-time loot. A Brute protects the mouth; side route remains traversable. Finite core rewards suffice to reach/restore it without grind.

### pump — Waterworks

First Breaker. Display its brace lane from a safe approach, with two sideways escapes and a repairable line behind the player. Only two Shamblers accompany it. Pump restoration adds one Food per greenhouse harvest while operational. No water stock, thirst, pumps-to-pipes logistics or electrocuted pools.

### substation — Substation

Search yields relay coil; restore with depot coupler to enable power. Solid housings block fire and form a flanking route around the Armoured enemy. Power is a Boolean service while operational, not a fuel/resource minigame. Outage pauses the relay and salvage upgrade; it does not delete progress.

### relay — Relief relay

Final console, attacked only through actual approaches. Spitter and Armoured start in separate lanes, both known kinds. Console fixture must be reachable for work, recovery and the finale interaction. During finale, power/route interruption uses the grace rule in 13; destroying the fixture fails the attempt. Searching/clearing alone cannot trigger the watch.

### assembly — Relief assembly yard

Core shelter and final south-side staging space. Wide geometry supports retreat, a casualty spot and an inside guard post. It is not a newly recruited population. Restoring tents/lighting creates the visual endpoint of communal growth. Its crossing to relay is a required final safe link; keeping optional adjacent school is helpful but unnecessary.

## Per-site authoring checklist

Provide stable ID; exact core flag/column/row; yard and building geometry; search/claim/work points; entrances and sightlines; clear attack/retreat positions; room roof fade; neighbour sockets; initial actor IDs/kinds/positions; finite reward flags; facility recipes; shelter/casualty spots; art state for held/damaged/restored; relevant discovery text.

At each site prove: all occupants reachable without clipping; quiet and loud approaches have a real difference where intended; mandatory work reachable from safe side; no unique reward leaked before search; loss/reclaim does not repeat supply; optional site not required by any core recipe/connection; original six identities/saves remain stable.
