# Decisions and tuning register

Baseline: 28 October 2026. The user reports that the slice is working well and authorises one hour of documentation-only expansion, including making design decisions. The full game choices here are **design decisions made under that authority**, not additional user playtest results. Changes to these decisions must update their owning documents.

## User foundations retained

| ID | Decision | Origin |
| --- | --- | --- |
| D01 | One continuous world | User selected NEARBY |
| D02 | Player and survivors both build and repair | Hybrid construction request |
| D03 | Few named, meaningful survivors | Small symbolic cooperative community |
| D04 | Cooperative tone, no relationship drama or colony micromanagement | Survivor-management direction |
| D05 | Equipment and key discoveries drive growth | Simplification of earlier skill ideas |
| D06 | Paige is a D&D enthusiast rescued from the library and can become an iron-armoured defender | User's librarian example |
| D07 | Reclamation, defence, jobs, production, rewards and pressure belong in the game | Original design coverage |
| D08 | Sparse live HUD; details in pause | Human slice feedback |
| D09 | Build temporary road defences from both directions and reclaim materials as the front advances | Human slice feedback |
| D10 | Individual assignments support different jobs simultaneously | Mara gardening/Paige workshop example |
| D11 | Residents and recurring multidirectional attacks make territory worth fighting for | Human slice feedback |
| D12 | Do not reveal unsearched rewards or Paige before rescue | Discovery/presentation feedback |
| D13 | Unopposed zombies can physically take yards, including home | Territory-loss feedback |
| D14 | Nearby people override zombie wandering; basic melee hits one target | Movement/combat clarification |
| D15 | Physical integration, equipment, useful food and a slice objective | Completed implementation request |
| D16 | An eastern house gives a gun with exactly six bullets through a survivor who never fights or guards | Ellis expansion request |
| D17 | Another building unlocks survivor bullet crafting | Ammunition workshop request |
| D18 | Expand documentation into a design usable for the remaining game and make choices along the way | Full-design request |
| D19 | Add one more character and a vehicle if absent | Follow-up design request; Rowan and a usable utility van |

## Full game decisions

| ID | Settled choice | Rationale | Owner |
| --- | --- | --- | --- |
| F01 | One authored 24-property town; four districts of six | Enough distinct rewards without procedural content debt | 13, 15 |
| F02 | 18 core sites and six optional sites; 2–3 hour core first-run target | Clear finish without compulsory map exhaustion | 13 |
| F03 | Protagonist plus Mara, Paige, Ellis, June, Oliver, Theo, Nia, Rowan | Eight identities with room for home defence and production | 05 |
| F04 | Fixed protagonist; maximum two followers | Readable action and people left at home | 03, 05 |
| F05 | Ellis never fights or guards; all others use compatible equipment | Preserve requested identity without class locks | 05, 16 |
| F06 | Shambler, Brute, Runner, Screecher, Armoured, Crawler, Spitter, Breaker | Each changes a concrete combat/defence decision | 14 |
| F07 | No stamina, invulnerable dodge, active block, friendly fire, durability or magazine reload | Keep direct accessible action | 03 |
| F08 | Melee, firearm, body, off-hand/tool loadout slots | Unique ownership and legible equipment | 16 |
| F09 | Materials, Food, Bullets, Shells, Medicine | Decisions without a minor-component chain | 06 |
| F10 | Meal every 120 active seconds, one Food/person; shortage slows work to 60% | Less food supervision; no hunger damage | 06 |
| F11 | No general carrying inventory or distributed warehouse simulation | Physical routes without hauling chores | 06 |
| F12 | Shared stock usable by safely connected facilities; field projects explicitly prepaid | Define remote construction | 04, 06 |
| F13 | Eight-second unopposed occupation loss; contested yards immediately pause work | Retain physical territory loss | 02 |
| F14 | Ownership adjacency permits claim; safe connection permits production | Avoid requiring paid passages before claim | 02 |
| F15 | Noise attracts existing actors/migrants; never creates an instant population | Quiet play alters routes without punishment spawning | 07 |
| F16 | Bounded pressure scheduler, no endless per-claim interval reduction | Competent defence makes expansion manageable | 07 |
| F17 | Shallow open-front ground-floor rooms, shared simulation | Interiors without instances or floor complexity | 02 |
| F18 | No permadeath/infection; casualty pickup and emergency recovery | Preserve small cast and recoverability | 03 |
| F19 | Equipment/key items cannot be permanently lost; rewards never repeat | Growth survives territory setbacks | 05, 16 |
| F20 | Player-approved six-minute relief watch with three physical fronts | Ending demonstrates a functioning community | 13 |
| F21 | Failed finale retains world progress and allows deliberate retry | Repair and prepare without campaign restart | 13 |
| F22 | All planning/settings pause; no offline progression | Consistent clock boundary | 08, 10 |
| F23 | Three manual slots, rotating autosave and chapter recovery saves | Protect longer campaigns | 10 |
| F24 | Stylised original 2D, 32-pixel base tile, layered equipment | Bounded art pipeline and recognisable cast | 08 |
| F25 | Desktop keyboard/mouse with remapping/accessibility | Finish a defined input/platform target | 08, 09 |
| F26 | No installs, toolkit edits, deployment or publication in design work | Project boundary | 09, 10 |
| F27 | One optional utility van at depot; restore for 12 Materials/30 work seconds; player drives, two passengers | Useful travel without fleets, fuel stock, hauling or mandatory vehicle gates | 18 |

Numbers are chosen starting values and may change through recorded tuning without reopening the creative foundations. An unmade asset or unperformed export test is implementation work, not an unresolved design decision.

## Earlier Q01–Q17 resolved

| Earlier question | Resolution |
| --- | --- |
| Q01 engine/platform | Godot 4.7.2 Compatibility, desktop; already used by slice |
| Q02 art/scale | F24; procedural greybox until visual-pipeline milestone |
| Q03 input | Keyboard/mouse, remapping required; controller/touch deferred |
| Q04 pause | F22; all planning paused |
| Q05 combat extras | F07 |
| Q06 switching | F04; fixed protagonist |
| Q07 companion/home coverage | Two followers; up to six others for work and defence |
| Q08 property loss | F13 |
| Q09 safe corridor | Held endpoints, actual route, required protection, no local hostile |
| Q10 cancellation/reserves | Formula/defaults in 04 |
| Q11 food/injuries | F10/F18 |
| Q12 names/roster | Paige final spelling; F03; no duplicate grower or Evelyn/Lena |
| Q13 armour | Existing garage cache stays; museum gives another specialised set |
| Q14 defeat/load | F18/F23 |
| Q15 influx/victory | F15/F16/F20 |
| Q16 size | F01/F02/F03 |
| Q17 large systems | Exclusions in 01; no hidden dependency |

## Slice compatibility and supersession

The runtime currently has six properties, four people including the protagonist, two enemy kinds, 60-second meals, one pistol, one home save, schema 12 and the original four-yard watch. Baseline checked against current JSON and simulation sources for this documentation pass. Historical evidence stays in [PROGRESS.md](PROGRESS.md).

This design does not change the game today. Future milestones deliberately change meals, pressure, recovery, safe production requirements, capabilities and saves. Existing IDs `home`, `garden`, `library`, `garage`, `residence`, `munitions`, `shambler`, `brute` stay stable. Old saves retain discoveries, unique items and earned slice completion; new campaign objectives start unearned.

The garage iron, shield and sword stay there. Moving them exclusively to the museum would erase the slice's defining progression. The future museum supplies distinct additional items.

This revision replaces conflicting generations of prototype proposals with one full game contract. Runtime source, rather than historical copied numbers, owns what the slice does today.

## Tuning and change control

Implementers may adjust numerical balance within a milestone gate, recording values, reason and evidence. Automated fixtures do not establish human balance acceptance. Content cuts, new resource systems or a different ending require a deliberate design revision.

| Area | Initial target | Evidence before locking |
| --- | --- | --- |
| Food/work | Two growers sustain nine people; verify narrow pre-pump margin | 15-minute full-roster run including interruptions |
| Defence | Two equipped defenders hold routine approaches | Three observed off-camera trials, inspect routes and health |
| Freedom | 3–5 minutes away during stable midgame | Human session; count forced returns |
| Enemy readability | Tell recognised by second encounter | Human explanation; no unavoidable first hit |
| Economy | Core path plus repairs affordable without optional loot | Ledger and command-driven scenario in 17 |
| Duration | 2–3 core hours without arbitrary waiting | Complete first-time human run; cut padding if too long |
| Performance | 60 fps target with 96 living enemies/full town | Measure on recorded reference machine |

No foundational creative question blocks the next milestone. Balance, assets, reference hardware and release validation remain work to perform.
