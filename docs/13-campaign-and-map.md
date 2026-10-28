# Campaign, topology and ending

Full game target; not current runtime. Owns adjacency, core completion, act transitions and the relief-watch state machine. [15](15-property-catalogue.md) owns site rewards; [17](17-acceptance-and-balance.md) owns acceptance scenarios.

## Town shape

Four blocks extend the existing east-west road. Each block has three facing pairs, north and south. The existing six sites and IDs remain the western block. No travel loading screen or time jump separates districts.

```text
                         NORTH YARDS
HEARTH STREET          MARKET ROW              CIVIC BLOCK          EAST WORKS
home garden residence hardware clinic greenhouse station radio hall depot pump relay
----------------------------- MAIN ROAD ------------------------------------------
library garage munitions grocer allotment diner firehall museum school salvage substation assembly
                         SOUTH YARDS
```

The diagram defines column order, not literal spacing. Every token is a stable property ID. `station` is police, `hall` town hall, `pump` waterworks, and `assembly` the relief yard.

| Column | North | South | District |
| --- | --- | --- | --- |
| 0 | home | library | Hearth Street |
| 1 | garden | garage | Hearth Street |
| 2 | residence | munitions | Hearth Street |
| 3 | hardware | grocer | Market Row |
| 4 | clinic | allotment | Market Row |
| 5 | greenhouse | diner | Market Row |
| 6 | station | firehall | Civic Block |
| 7 | radio | museum | Civic Block |
| 8 | hall | school | Civic Block |
| 9 | depot | salvage | East Works |
| 10 | pump | substation | East Works |
| 11 | relay | assembly | East Works |

Same-row adjacent columns have fenced-passage sockets. Each facing pair has a protected-crossing link with west/east road barriers. These are the only settlement adjacency edges: 22 same-row edges and 12 crossings, 34 total. No diagonal claims. Street movement outside held land does not add productive connectivity.

There are 22 passage projects and 24 independent road-barrier sockets, two per crossing. A parcel is 560 pixels wide on a 720-pixel pitch, leaving a 160-pixel alley gap; adjacent crossings therefore do not share the same physical boundary. Keep that gap exposed instead of incorrectly merging its two barriers. Removing one barrier invalidates only its crossing. Retain home_west/home_east and garden_west/garden_east exactly. New pairs use <north-property-id>_west/east; the eastern pair is residence_west/east.

This parallel ladder offers recovery alternatives. A lost northern property can be bypassed through the southern row if crossings and passages remain usable. The paired property can shorten a dangerous detour. Isolated facilities pause; discoveries and ownership do not vanish merely because a bridge link fails.

## Physical metrics and routes

Retain approximately 720-pixel column pitch and a 200-pixel road. Full width is about 8,640 pixels plus edge margin; height about 1,160. A 190-pixel/second player takes roughly 45–55 seconds end to end without obstacles. Armour adds time. Measure this with final geometry; do not promise it from the diagram.

District boundaries at columns 2/3, 5/6 and 8/9 have north and south alley mouths linked to map edges. Together with west/east road entries, these make eight regular migration origins. Finale uses the east map edge and north/south Works-boundary edge entries. Its east post is relay_east; its north/south posts are alley lines at the 8/9 boundary. All three routes reach their posts directly without first crossing the home barricades. Anchors are never spawn points inside property yards.

Buildings sit within yards, leaving alternative approaches. Clinic, school and waterworks have a second entrance. No mandatory fight uses a dead-end room with one actor-width door. Ordinary door clear width is at least two actor diameters plus eight pixels. Work positions sit inside the defended side with an alternate retreat position.

Each finale alley socket includes a reachable inside access gate from depot (north) or salvage (south), a safe-side work point and a retreat into that held yard. Put the north line near y=240 and its inside post near y=280; south line near y=920 and post near y=880. These sit outside the existing passage rails at y=352–448 and y=712–808. Opening the access gate does not remove the alley barrier; the guarded pocket is a defence-post extension, not a new claim/production link. Check actual actor widths before locking these coordinates.

Rear footpaths outside both rows are exposed scouting/flanking routes, never safe home links. They do not allow disconnected claims. Collision and art must leave them continuous and readable.

## Core and optional sites

Core set (18): `home`, `garden`, `library`, `garage`, `residence`, `munitions`, `hardware`, `clinic`, `greenhouse`, `station`, `radio`, `hall`, `depot`, `salvage`, `pump`, `substation`, `relay`, `assembly`.

Optional set (6): `grocer`, `allotment`, `diner`, `firehall`, `museum`, `school`.

All 12 northern sites are core, giving a continuous northern connection. The six core southern sites connect through their facing northern property; garage and munitions additionally share the existing southern chain. No optional site is a hidden bridge prerequisite. Optional southern holdings provide cross-links, supplies and alternate equipment.

All seven survivors are at core sites. Optional sites cannot hold a required person, final component or exclusive mandatory recipe. Professions never act as keys; rescues are a campaign community objective.

## Act objectives

Objectives show discovered information. Before rescue use “Search the library”, never Paige's name. Unexplored sites show visible silhouettes and street names rather than exact population or guaranteed loot.

| Act | Completion record | Capability demonstrated |
| --- | --- | --- |
| I | Search six Hearth sites; restore garden/bench; rescue Paige and Ellis | First sustainable expedition and bullet production |
| II | Recover hardware tools; rescue June/Oliver; restore clinic/greenhouse | Recovery, food margin, reinforced construction |
| III | Search station; rescue Theo; restore radio; recover hall plan | Forecast approaches and learn signal requirements |
| IV | Rescue Nia; restore salvage, pump, power and relay; secure assembly | Prepare three fronts and choose final defence |

Act records are achievements, not geographic gates. Earlier discoveries count immediately when an objective is revealed. The original four-yard watch is optional Act I teaching content; it never blocks Market Row. A migrated slice-complete save retains that record without earning later acts.

## Narrative spine

The starting radio receives fragments. People along the street reveal a practical plan: food, treatment and a guarded assembly point could make the town a relief stop. Town hall holds the emergency plan; the radio site identifies the relay; Nia explains the power installation without being its mandatory operator.

No villain or conspiracy branch. The challenge is making a place dependable. Short arrival lines and work observations acknowledge rescues and visible improvement. Do not force equipment onto Paige. Dialogue uses dismissible paused cards rather than freezing only some actors.

## Finale readiness

Begin **Open the relief signal** explicitly at the relay console with the player present. The paused panel lists every failed condition. Background migration scheduling stops during the attempt; living enemies remain. The three defence zones must be clear to start.

1. All 18 core sites held, searched and safely connected to home; all seven survivors recruited and standing.
2. Working garden, workshop, bullet bench, clinic, greenhouse, radio, salvage yard, waterworks, substation, relay and assembly shelter; none awaiting required restoration.
3. Hardware tools, medical kit, growing kit, radio receiver, relief plan, generator coupler and relay coil deposited as permanent discoveries.
4. Three named approach lines at full health: east road approach, north works alley, south works alley. Each has an inside post and retreat route to assembly.
5. A standing recruited combatant at each approach post. Ellis never qualifies. All three placements are physically checked at start; the protagonist must be at the console and therefore cannot also satisfy a distant post. After launch the player is free to reinforce or replace anyone.
6. Two meals available (2 × roster size Food), 24 Bullets or 8 Shells or an equivalent mix (1 Shell counts as 3 Bullets), 6 Medicine and 12 uncommitted Materials.

The supply check neither spends nor permanently reserves stock. Meals, healing, firing and repair spend normally. With eight people, two meals means 16 Food. No named sword, armour or follower pairing is mandatory. Reinforcement and ranged equipment help; geometry and a capable melee team remain viable.

## Six-minute watch

Duration: 360 active seconds. Save/load preserve elapsed time, wave IDs and pending members. This is not the slice's continuously checked readiness watch. Show the three-wave timetable and directions before launch; its fixed warnings below replace the ordinary migration radio timing for this deliberate event.

| Time | Event | Composition and threat cost |
| --- | --- | --- |
| 0 | Signal starts; first warning | No new actor until t=40 |
| 40 | East road approach | 8 Shamblers, 2 Runners, 1 Brute: cost 15 |
| 130 | North alley | 6 Shamblers, 1 Screecher, 1 Armoured, 1 Spitter: cost 15 |
| 230 | South alley plus east stragglers | South: 4 Shamblers, 1 Brute, 1 Breaker, 1 Crawler; east: 4 Shamblers; total cost 21 |
| 300 | Report actual unresolved approaches | No extra surprise spawn |
| 360+ | Signal continues until attempt migrants are gone | No further scheduled wave |

Costs use [14](14-zombie-catalogue.md). Warnings occur at t=0,95,195: at least 35 seconds before map entry, followed by actual travel. Wave two uses only north, wave three warns both south and east. Release at 0.5-second spacing. Pending members wait if the population cap is full; they count as unresolved and cannot be silently skipped for an easy win. Across the attempt there are exactly 31 scheduled actors and threat cost 51.

Attempt migrants have a saved explicit approach route and relief objective. East entries target the relay fixture, north entries target substation power, south entries target the assembly shelter. They follow their assigned entry to its defence line and then toward that fixture, attacking actual blocking breakable structures. Nearby people still take priority; a strong noise can divert them, after which the approach intent resumes. They never use the ordinary under-quota settlement/exiting policy while an attempt runs. Otherwise a fully held town could make every finale enemy decide to leave without testing a defence. No actor is moved onto the route by teleport.

The first two fronts are routine-defence scale; the Breaker front is the personal response focus. Move, order, repair and recover normally. Shortage or spending below starting reserves does not fail the watch. Guards may leave launch posts; physical consequences decide risk.

## Failure and retry

Immediate failure: protagonist defeat; loss of home, relay or assembly; all standing combatants down; relay, substation or assembly facility health reaches zero. A breach, other property loss, individual casualty or shortage is recoverable within the attempt.

Relay connection/power interruption suspends the watch and starts a 30-active-second grace budget. Actors/work continue. Restore service to resume the watch and freeze the remaining budget; expiry while service is interrupted fails. Reset the budget to 30 only after five continuous active seconds of restored service. Another interruption before that uses the remaining budget, preventing rapid toggles from extending grace forever. Save both the remaining budget and stable-service timer.

Warning/arrival times use watch elapsed time; grace uses world active time. An outage therefore delays unissued waves, never despawns an issued wave or repeats a warning. Clamp watch elapsed at 360 while resolving remaining enemies. States are preparing → running ↔ suspended → failed or complete. Retry returns failed to preparing; completed never returns to running. The pause action Abort signal uses the same world-preserving failure path as a loss.

Failure pauses with its cause and offers Continue preparing or Load recovery save. Preserve the world, spent ammunition and killed residents. Living attempt migrants remain; pending arrivals cancel. Background migration restarts after 180 seconds of recovery. Retry requires fresh readiness and runs a new finite sequence with new attempt IDs. No abstract fee or resource refund.

Emergency recovery from [03](03-combat-and-defence.md) still applies. No attempt may make the campaign permanently unwinnable.

## Success and continuation

Success: clock at 360, working connected relay/power and operational assembly shelter, held home/relay/assembly, standing protagonist, all 31 scheduled attempt migrants defeated and none pending. Background zombies need not all be dead. Attempt actors cannot silently take the ordinary migration exit while running. Commit completion once, then attempt a completion autosave before ending. Failed writing retains the earned flag in memory and offers Retry save.

The illustrated ending answers the signal and recognises the rescued cast. No new simulated population appears. Show completion time, held properties and rescues without grading casualties or demanding perfection. Full reclamation earns an extra line.

Continue resumes the same town with 240–360-second low-budget migrations and no scheduled Breakers. Optional properties/projects remain. The finale cannot repeat for rewards. A new campaign never overwrites a manual slot without an explicit slot confirmation.
