# Named survivors and equipment-led growth

Final full game roster: the protagonist and seven named survivors. Four people exist in the present slice: player, Mara, Paige, Ellis. June, Oliver, Theo and Nia are future content. No random recruits, relationship system, classes, XP, activity skills or survivor level-ups.

## Roster

| ID/name | Starting situation | Identity and voice | Default useful role | Visual anchor |
| --- | --- | --- | --- | --- |
| player / You | Starts at home | Quiet practical organiser; no authored name/gender requirement | Direct action, orders, field work | Player-selected accent on jacket |
| mara / Mara | Already at home, guarding | Mechanic; short concrete observations, dry humour | Build/repair or equipped gate defence | Rust-red overalls, tied hair, tool belt |
| paige / Paige | Library | Librarian and D&D enthusiast; imaginative but competent | Workshop work or shield defence | Teal scarf, glasses, book patch |
| ellis / Ellis | East house (`residence`) | Quiet former print worker; clear about never fighting | Bullets, growing, general safe work | Mustard cardigan, ink-stained hands |
| june / June | Clinic | Nurse; calm action-focused reassurance | Treatment or general worker | Pale blue coat, red-cross-free medical bag |
| oliver / Oliver | Greenhouse | Retired gardener; patient, observant, interested in what grows | Food production or general work | Green hat, rolled sleeves |
| theo / Theo | Police-station side office | Delivery driver who sheltered there; brisk route observations | Mobile escort or relief guard | Orange courier jacket, shoulder strap |
| nia / Nia | Depot service cabin | Electrical technician; likes explaining a repair once, then doing it | Salvage/power restoration or ranged post | Violet work shirt, safety goggles |

The player and every survivor have 100 base health. Initial movement: player 190 pixels/second, survivors 145. No hidden background bonus to attack/work speed. Jobs require tools/facilities, never the “right” named person. June's medical knowledge gives context, not exclusive access; anyone can operate a restored clinic. Theo does not unlock vehicle simulation, Nia does not unlock wiring.

All except Ellis can use every compatible melee/firearm/body/off-hand item. Ellis can carry protection and work tools but cannot equip weapons, attack, guard, draw aggro deliberately or receive an Engage order. Whole-team orders, emergency fallbacks, load, automation and job completion must preserve that restriction.

## Rescue contract

Each rescue is an authored once-only discovery at a core site. Locally clear the yard and room, search the point and dismiss a brief paused introduction. For the original six sites, search stays part of the existing claim transaction. New sites permit search before claim as defined in 02. Before rescue the sheltered figure is presentation/narrative, not a targetable standing combat actor; recruitment creates the authoritative actor once. No survivor is shown dead if the player takes a long time to arrive; there is no hidden rescue timer.

Recruitment adds exactly one actor with stable ID, starter bat for combatants, health 100, no free duplicated armour and no personal stock inventory. Rescue supplies belong to the property's reward ledger. A recruit initially Holds at the clear rescue point. If a safe route home exists, offer Return home; otherwise offer Follow or keep Hold. With two followers already selected, swap one through the paused panel. Never silently create a third attacking follower or teleport the person home.

The rescued person becomes visible in roster/meal count immediately. Prior to rescue, prompts and objectives do not reveal the name, role or guaranteed equipment. Short world silhouettes may show a living person where actually visible; no portrait appears in a locked roster slot. Recruiting in a different order is valid and survives save/load.

## Authored rescue scenes

| Person | Discoverable situation | Clear action | First useful choice |
| --- | --- | --- | --- |
| Paige | Sheltered behind library shelving, a few zombies in the yard | Clear/search library; no escort combat cutscene | Follow with a bat or help finish an approved workshop |
| Ellis | Calls from east-house porch when its yard clears | Search/claim; gives protagonist pistol + exactly six Bullets once | Safe worker; panel explicitly says “Does not fight or guard” |
| June | Barricaded treatment room with medicine already sorted | Clear clinic's two approaches and search | Restore clinic or bring an additional mobile ally |
| Oliver | Greenhouse tool shed; tended plants visible through broken panes | Clear the yard, search shed | Start greenhouse work, freeing Mara/Paige for defence |
| Theo | Side office marked by a courier bag, not a uniform | Defeat first Armoured group and search station | Ranged support or escort on the civic road |
| Nia | Depot cabin beside a dismantled generator | Clear depot loading yard, search cabin | Explain coupler; restore salvage route or help defend |

Mara is not rescued from the garage. She starts with the player, preserving the implemented opening. No final survivor is optional because the finale's community requirement includes everyone; every rescue site is on the mandatory path. No repeated rescue reward on loss/recapture/load.

## Paige's visible transformation

1. Library: recognisable glasses/scarf, bat and enthusiasm about surviving a “very bad first session”.
2. Garage: crowbar/sword, restored shield and iron are available to any combatant. The player may choose Paige, another person or themselves.
3. Defended street: Paige can hold a real post wearing the chosen equipment. An optional contextual line acknowledges her first successful armoured defence; it grants no stats/reward and does not require a scripted last hit.
4. Museum: another historical set and polearm offer a later alternative without moving the garage's original items. No class prerequisite, unique Paige-only socket or armour quest timer.

Her identity remains visible through armour via scarf/glasses/portrait accent. Do not require the player to bring her to every narrative trigger. A radio line can acknowledge a discovery without removing her from her current job.

## Roles and everyday autonomy

Each person has one persistent primary assignment, one optional destination and one current activity/block reason. Role is a policy, not an occupation lock. Gardeners tend the selected facility; builders finish approved work; a medic treats present queued patients; mechanics execute approved equipment recipes; guards hold an assigned line. General worker follows the priority policy in 04.

Emergency shelter temporarily overrides work and resumes it afterward. Guard duty is never replaced by a routine job. Follower membership pauses home work without deleting its configured role; returning home can resume it. A downed/carried person consumes a roster meal portion but contributes no labour or defence.

Do not create sleep cycles, personal hunger bars, moods, homes, furniture needs or time-off requests. Short idle actions (reading, tending a tool, sitting) give life without adding player obligations. Survivors may stand together in a safe yard without relationship calculations.

## Small roster staffing examples

| Stage | Expedition | Food | Defence | Other work |
| --- | --- | --- | --- | --- |
| Opening, 2 people | Player | Player/Mara briefly tend | Mara when not working | Player shares construction |
| Hearth, 4 people | Player + Paige | Ellis | Mara | Bullet batches when food buffer permits |
| Market, 6 people | Player + Paige | Oliver + Ellis if needed | Mara + June | Shift one person to treatment/build after threat clears |
| Full, 8 people | Player + Theo + Paige | Oliver + Ellis | Mara + June | Nia salvage/repair; rotate through medicine/bullets |

These are examples, not forced roles. Two growers can sustain eight people under 06. The final watch deliberately brings expedition people back onto posts. Do not require every facility to have a dedicated permanent operator; finite stock buffers support switching a worker for a batch.

## Writing and presentation limits

Aim for 2–4 short lines per rescue, one line per first important facility/equipment discovery and infrequent conditional observations. No dialogue trees, persuasion rolls, relationship choices or quarrels. Make requests about a shared practical goal, never personal approval. Avoid implying Ellis will eventually “overcome” the noncombatant role.

Prepare a small per-person line set: arrival, first assignment, blocked route, shelter, return to work, equipment change, first successful defence (except Ellis), finale preparation and ending. Mechanics own all actual state changes; text cannot grant an item without the committed discovery command.

## Interface and save requirements

Show name/portrait, location, health, primary assignment, current activity, loadout, follower membership and one blocked reason. No XP/skill column. Unknown people are absent rather than greyed spoilers. Ellis's incompatible controls are disabled with a plain reason. An item held by someone else links to that owner rather than disappearing from the list.

Save stable identity, recruited flag, position, health, order/role, anchor, carried state, recovery work, loadout references and once-only dialogue flags. Rebuild portraits and derived available jobs. Reject duplicate person/item ownership. Migration must keep Mara and all previously rescued actors, preserve Ellis's civilian capability and add future rescues as undiscovered, never already recruited.
