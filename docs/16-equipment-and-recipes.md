# Equipment, discoveries and recipes

Full game starting values. Runtime JSON contains only implemented effects. This catalogue is the source for adding those definitions milestone by milestone; it is not permission to add unsupported effect strings. Time means active work seconds at normal nutrition. Multiple workers never multiply one site's rate.

## Loadout and ownership

Four slots: melee, firearm, body, off-hand/tool. Combatants always retain a fallback bat; recovered items are unique instances. A two-handed melee weapon disables off-hand protection while selected, but does not delete/unequip its stored off-hand item. A shotgun similarly uses both hands only during the shot and its recovery, then returns to the melee/shield stance. No inventory weight or ammunition magazine.

Each item has exactly one owner: a recruited person or home storage. Unsearched discoveries are not item instances until their once-only grant. Assigned gear stays with a downed person and through defeat recovery. Return to storage before transferring to another person. No simultaneous duplicate owners and no consumption/destruction of unique weapons.

Loadout change requires standing wearer and player at the same clear, safely connected workshop bench. Starting padded clothing can also be fitted at home; weapons/iron/shields use the garage. Fitting never heals, grants ammunition or resets an attack cooldown. Ellis can fit body/tool protection but never a weapon or shield used as a guard qualification; a passive protective shield is allowed and cannot enable attacks.

UI lists known items, current owner and compatibility. Never show undiscovered museum rewards as grey locked recipes. Physical weapon/body/shield silhouettes follow actual equipped state. Save item instance IDs, not a copied equipment definition per person.

## Melee equipment

Damage is per valid target. Reach is pixels; recovery seconds. All use clear-line/cone selection and nearest-target ordering.

| Definition / instance | Source | Damage | Reach | Recovery | Targets | Knockback | Hands and distinction |
| --- | --- | --- | --- | --- | --- | --- | --- |
| bat / fallback per combatant | Start/recruit | 30 | 76 | 0.48 | 1 | 18 | One; quick reliable baseline |
| crowbar / garage_crowbar | Garage search | 50 | 82 | 0.85 | 1 | 24 | One; bypasses Armoured frontal plate |
| sword / garage_sword | Garage set restoration | 35 | 88 | 0.65 | 2 | 12 | One; crowd option with shield |
| spear / hardware_spear | Hardware tool rack | 38 | 120 | 0.80 | 1 | 20 | Two; reach behind a low line |
| fire_axe / firehall_axe | Firehall restoration | 75 | 80 | 1.10 | 1 | 34 | Two; plate bypass and strong stagger |
| polearm / museum_polearm | Museum restoration | 45 | 125 | 0.95 | 2 | 20 | Two; wide defence without shield |

Bat/crowbar forward cone dot threshold 0.2/0.5, sword 0.15, spear 0.75, fire axe 0.5, polearm 0.35. Keep long-reach weapons from hitting through tall fences. A slow weapon can miss a sidestepping Runner; no target-following hit after swing starts. No weapon automatically damages a building because the player attacks near it.

## Firearms

| Weapon/instances | Source | Damage and pattern | Range | Recovery | Ammo per discharge |
| --- | --- | --- | --- | --- | --- |
| pistol / ellis_pistol | Ellis once | 90, first target on ray | 620 | 0.65 s | 1 Bullet |
| pistol / station_pistol | Station once | Same definition | 620 | 0.65 s | 1 Bullet |
| shotgun / station_shotgun | Station search | Five fixed rays at -12,-6,0,6,12 degrees; 24 per ray | 360 | 1.25 s | 1 Shell |
| shotgun / firehall_shotgun | Firehall search | Same definition | 360 | 1.25 s | 1 Shell |

Shotgun rays resolve independently against first obstruction/target. A target may receive multiple pellets, maximum 120 unmodified damage per shot. No random spread, penetration or friendly damage. Partial edge hits are weaker; shields/plate resolve per ray. Consume one Shell once, even if every ray misses. The finite pattern helps reproducibility. Pistol remains the long-range choice, shotgun spends its distinct resource for close crowd/burst control.

AI can use either, subject to 03 policies and shared stock. Ordinary guard fire should conserve ammo with useful melee, rather than empty every stockpile into the first Shambler. Noise radii are owned by 07; muzzle/tracer/audio timing follows the successful simulation discharge.

## Body and off-hand

| Definition / count | Source | Incoming damage | Move speed | Distinction |
| --- | --- | --- | --- | --- |
| ordinary / unlimited | Start | ×1 | ×1 | No protection, highest mobility |
| padded / craft unique instances | Home bench | ×0.8 | ×1 | Cheap light protection |
| iron / garage_iron | Garage restored set | ×0.5 | ×0.8 | Heavy protection; iconic Paige option |
| riot / station_riot | Station restored kit | ×0.65 | ×0.9 | Mobile compromise |
| iron / museum_iron | Museum restored set | ×0.5 | ×0.8 | A second heavy wearer without item duplication |
| shield / garage_shield | Garage restored set | ×0.5 in frontal 120° arc | No added reduction | One-handed stance only |
| shield / station_shield | Station restored kit | Same shield definition | Same | Second front-line option |
| field_bag / clinic_bag | Clinic search | No passive reduction | No penalty | Spend 1 Medicine to heal a standing nearby person by 40 |

Field bag uses off-hand/tool slot, preventing simultaneous shield benefit. Local treatment: user and target clear within 70 pixels, hold R for three seconds, consume Medicine once at start, preserve interrupted progress on that patient, never revive remotely. Cap at max health. Healthy/invalid targets spend nothing. Anyone including Ellis can use it. The bag is not the permanent medical-kit discovery, though both are found together.

No numeric improvement for using a weapon repeatedly. No rarity, repair durability or item-merging screen. Protection multiplies body and frontal shield once; minimum damage remains positive and fractional health is allowed.

## Permanent discoveries

| ID | Source | Enables | Consumed? |
| --- | --- | --- | --- |
| garden_seeds | garden | Basic garden | No |
| garage_tools | garage | Workshop and original armour restoration | No |
| hardware_tools | hardware | Reinforced lines, alley fences, spear availability | No |
| medical_kit | clinic | Clinic and medicine recipe | No |
| growing_kit | greenhouse | Greenhouse and optional allotment | No |
| ammunition_kit | station | Shell production | No |
| radio_receiver | radio | Forecast upgrade and relay prerequisite | No |
| relief_plan | hall | Final readiness panel and assembly recipe | No |
| generator_coupler | depot | Substation restoration | No |
| relay_coil | substation | Relay restoration | No |

The final seven-key check in 13 is a subset; seeds, garage and ammunition kit are already implied by required facilities/searches. Permanent keys are awarded even if their source is later lost, never spawned on an enemy and never used as a repeatable material input.

## Construction and restoration recipes

M = Materials. All recipes require target held and locally safe; productive use later needs safe home connection. “Core” means necessary for finale, except equipment alternatives explicitly marked optional. Every fixed facility starts at 300 max health after restoration; destroyed facilities retain unlock/restoration flags and repair from zero rather than replaying discovery.

| Recipe ID | Site/socket | Inputs | Work | Output/requirements | Core? |
| --- | --- | --- | --- | --- | --- |
| restore_garden | garden bed | 8 M | 12 s | Garden; garden_seeds | Yes |
| restore_workshop | garage bench | 10 M | 16 s | Bench; garage_tools | Yes |
| restore_garage_set | garage display | 12 M | 18 s | One sword, iron, shield; working bench | Optional for finale |
| restore_clinic | clinic room | 12 M | 20 s | Treatment/medicine; medical_kit | Yes |
| restore_greenhouse | greenhouse beds | 16 M | 24 s | Four-Food cycle; growing_kit | Yes |
| restore_allotment | allotment beds | 8 M | 16 s | Two-Food cycle; growing_kit | Optional |
| restore_radio | radio desk | 10 M | 18 s | 60-second forecast; radio_receiver | Yes |
| restore_salvage | salvage sorting bench | 16 M | 24 s | Four-Material cycle; hardware_tools | Yes |
| restore_pump | pump motor | 18 M | 24 s | Greenhouse +1 Food; hardware_tools | Yes |
| restore_power | substation fixture | 24 M | 30 s | Power service; generator_coupler | Yes |
| upgrade_salvage | salvage bench | 10 M | 18 s | Six-Material cycle while power operational | Optional |
| restore_relay | relay console | 24 M | 30 s | Signal console; receiver + coil + power | Yes |
| restore_assembly | assembly shelter | 16 M | 24 s | Clear relief staging area; relief_plan | Yes |
| restore_station_kit | garage bench | 8 M | 14 s | One riot body + station shield; station searched | Optional |
| restore_firehall_axe | garage bench | 6 M | 12 s | Fire axe; firehall searched | Optional |
| restore_museum_set | garage bench | 12 M | 20 s | Museum iron + polearm; museum searched | Optional |
| make_padding | home/garage bench | 4 M | 8 s | One padded body instance | Optional |

The ammunition workshop becomes usable on claim/search with no restoration bill, preserving the slice. Search grants damaged/recoverable set flags for the station/museum/fire axe; restoration grants usable instances once. It must not grant both an immediately usable set and another set at restoration.

The substation's **search** grants the relay coil; restoration enables power. No recipe grants the discovery a second time. Every prerequisite is in an earlier or the same reachable site's search; no random dependency.

## Fortification recipes

| Recipe | Cost | Work | Health/collision | Removal/notes |
| --- | --- | --- | --- | --- |
| passage | 4 M | 6 s | Fixed rails, breakable gate 160; opens authored shared fence | 75% Materials × health fraction; 4 s |
| road_line | 8 M | 8 s | 180, low barrier blocks travel, allows fire/melee reach | 75% × health fraction; 4 s |
| alley_line | 8 M | 8 s | 180, same attack rules at alley socket | Same |
| reinforce_line | 10 M | 12 s | Increase road/alley max to 360; needs hardware_tools | Upgrade cost salvageable; removal 6 s |
| reinforce_gate | 6 M | 10 s | Increase parcel gate max 160 → 280; needs hardware_tools | Fixed gate cannot be removed for supplies |
| rebuild_gate | 3 M | 7 s | Restore broken gate to 160/current max, initially open | Clear footprint before closing |
| repair_line_or_gate | 3 M | Up to 5 s | Restore up to 120 health at 24/s | Partial batch persists |
| repair_facility | 4 M | Up to 10 s | Restore up to 200 health at 20/s | Two batches can recover zero-health 300 fixture |

Reinforcement changes max health and adds the max-health difference to current health, rather than instantly healing old damage. Upgrading a line at 80/180 gives 260/360. Require it above zero, and ordinary repairs for remaining damage. Finale starts require full health. Fixed fences/building walls are indestructible; only authored breakable structures/fixtures accept damage.

## Productive recipes and recovery

| Recipe | Inputs | Work | Output/constraints |
| --- | --- | --- | --- |
| grow_garden | None | 45 s | 2 Food; tending and safe route |
| grow_greenhouse | None | 60 s | 4 Food, 5 while pump operational |
| grow_allotment | None | 40 s | 2 Food |
| sort_salvage | None | 45 s | 4 M, or 6 after powered upgrade |
| craft_bullets | 2 M | 15 s | 6 Bullets; present survivor at munitions |
| craft_shells | 3 M | 20 s | 4 Shells; ammunition_kit, present survivor at munitions |
| prepare_medicine | 1 M + 2 Food | 30 s | 2 Medicine; clinic, medical_kit |
| home_recover | 2 Food | 15 s | Present patients to at least 50 health |
| home_heal | 2 Food | 15 s | Present patients to full |
| clinic_treat | 1 Medicine/patient | 10 s/patient | Present patient to full, revives |
| field_treat | 1 Medicine | 3 s | +40 health to standing patient; field bag |
| emergency_salvage | None | 20 s | 2 M, eligibility/cap in 06; player only |

Production timers advance with actual tending, not passive calendar growth. Full stock target pauses work, retaining partial cycle. Each facility/recipe output has an idempotent completion record and committed-input state. No recipe creates fractional Bullets/Shells/Medicine.

## Catalogue invariants

Every item has an obtainable source; every mandatory recipe has a reachable permanent prerequisite; no first discovery requires its own future output; damaged sets create usable gear once; unique source flags survive loss; Ellis remains incompatible with weapon fitting; two-handed stance disables rather than duplicates off-hand effects; shotgun uses one Shell per five-ray event; missing definitions fail startup with the offending ID.
