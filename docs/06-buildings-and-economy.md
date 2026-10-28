# Building rewards, unlocks, and production

## Three reward types

| Type | Example | Persistence rule |
| --- | --- | --- |
| Discovery | Survivor, tool kit, seeds, unique armour | Retained once recovered; never awarded twice |
| Facility | Garden, workshop, medical station | Requires connected, controlled, usable property and relevant resources |
| Strategic position | Shortcut, sightline, compact boundary | Benefit follows actual geometry and current control |

A property can offer one or several types. Show the known reward before expansion when scouted, while leaving some discoveries for exploration. Ordinary houses can be useful through safe space and materials without each hiding a unique technology.

## Illustrative building catalogue

| Property | Discovery | Ongoing use | Strategic consequence |
| --- | --- | --- | --- |
| Starting home | Basic supplies and bat | Stockpile, shelter, simple workbench | Root of the connected settlement |
| Garden house | Seed collection | Basic renewable food | A useful protected yard |
| Library | Paige and practical manuals | Optional organisation or planning station | Rescue milestone and neighbourhood anchor |
| Garage | Welding and repair tools | Equipment restoration, reinforced barriers | Valuable site that may extend the perimeter |
| Pharmacy | Medicine and medical kit | Basic treatment when fitted out | Safer recovery after expeditions |
| Greenhouse | Growing equipment | More reliable food supply | Compact alternative to several gardens |
| Hardware store | Material cache and construction tools | Advanced construction supply later | Noisy, exposed scavenging target |
| Museum | Armour set and historical weapons | Restore discoveries elsewhere | Optional major equipment milestone |
| Police station | Shields, weapons, ammunition | Ranged equipment support | High pressure and noisy combat risk |
| Radio site | Communications equipment | Threat visibility or alerts | Late-game information rather than free safety |

These are design examples, not a promised content list. The MVP uses the home, garden house, library, and garage; the armour example can initially use a deliberately placed cache instead of a complete museum.

## Unlock chains

- Garden house → recover seeds → approve garden bed → assign safe tending → renewable food.
- Garage → deposit tools → restore workshop → reinforce gates and repair equipment.
- Armour cache or museum → recover damaged armour → working workshop plus materials → equip heavy protection.
- Pharmacy → medical kit and stock → operational treatment site → shorter or more reliable injury recovery.

Recovering tools and restoring a site are separate milestones. The UI must distinguish known recipe, available materials, operational facility, and assigned labour. Avoid a generic research timer that disconnects the unlock from the recovered object.

## Compact economy

MVP resources: Materials, Food, Ammunition. Add Metal and Medicine only when a recipe or recovery decision benefits from the distinction. Unique equipment and key items use individual records rather than fungible resource counters.

Materials come from one-time salvage and reclaimed sites. Food comes from caches and gardens. Ammunition comes from finite caches at first. Do not let unlimited automatic weapon production remove the noise-versus-ammunition choice before combat is balanced.

During expeditions, supplies remain carried until deposited at an accessible stockpile. Workers may gather remaining marked salvage inside connected safe territory. Already searched containers stay searched; ownership changes and reloads do not replenish them.

## Production rules

A facility needs an operational property, an eligible survivor, inputs, and safe access. Production advances through visible work sessions. A garden has clear growing and ready-to-harvest states; do not require watering every few seconds. A workshop uses a specific work order and committed input bundle.

Pause unsafe production without losing completed labour or duplicating outputs. Produce each output once at completion, then store it at home or as an explicit pending delivery if the route is blocked. For the MVP, require the safe home route for completion and make the reason visible.

Food upkeep is a forgiving community-scale drain, not individual meal scheduling. The first slice should provide warning and reduced work effectiveness during shortage before severe consequences. Exact rates and starvation rules remain open; do not implement permanent hunger deaths by default.

## Balance starting points

Tune in units of decisions rather than nominal realism: initial stock should support one repair and one small improvement; one garden should noticeably extend expedition freedom; restoring the garage should compete with reinforcing a vulnerable edge. All rates, costs, and work times need measurement in the prototype.

Keep a protected minimum material reserve for automatic maintenance. Explain what is available, reserved for orders, committed at sites, and carried outside the settlement. A single unexplained total makes shortages feel like lost resources.

## Preventing dead ends

Place enough accessible salvage for essential recovery. Keep a basic repair option independent of the advanced workshop. Recoverable key discoveries must survive loss of their original building. A lost food facility should create a recovery problem with alternatives, not an immediate unwinnable state.


## Implemented food loop, 28 October 2026

One shared meal every 60 active seconds costs one food per current person. Garden/library/garage searches contain 4/3/2 food once. Garden tending yields two food per 20 work seconds only with a protected home connection. A shortage reduces work to 60% without health loss; delivering enough food pays one meal and restores normal work. There is no accumulated hunger debt or individual ration interface.

Recovery at the safe home porch costs two food for the injured team. Healthy rest and failed attempts consume nothing. Food state is saved and never advances offline. Values are initial playtest tuning.


## Implemented eastern expansion

Two properties extend the authored street: the east house north of the road and the ammunition workshop opposite it. Existing clearance, connected claims, physical gates, occupation and one-time search rewards apply. The house rescues Ellis and grants the player a pistol plus exactly six bullets once. The workshop requires no separate restoration charge: claiming it unlocks Craft bullets in F. Any living survivor can take the job. An on-site worker reserves two materials and completes six bullets after 15 work seconds. No worker, local danger, lost home ownership connection or an unclaimed workshop pauses production; material shortages prevent starting another batch. Several workers share one batch rate. Bullets, reserved materials and partial work persist through save/load. Initial tuning lives in data/street/firearm.json. The original four-yard finish is unchanged.
