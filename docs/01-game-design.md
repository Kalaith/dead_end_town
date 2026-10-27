# Game design

## Vision

Dead End Town is a small-scale action and territory-reclamation game. The player personally fights for buildings, then turns them into a connected community with the help of a few named survivors. The town's changing appearance records that work: boarded windows become defended entrances, abandoned yards become gardens, and separate houses become a shared neighbourhood.

The emotional arc is from being trapped in one home to confidently opening its gate. Paige, rescued while overwhelmed by zombies in a library, can eventually stand in iron armour at that same gate and hold a wave. Her transformation comes from the equipment and opportunities the group recovers.

## Confirmed foundations

1. One continuous world, selected as the NEARBY approach. Expeditions happen down the street rather than in separate mission instances.
2. Hybrid construction. The player and AI survivors can both build and repair.
3. A small, meaningful cast. Survivors represent a cooperating community rather than a large simulated population.
4. High-level growth through buildings, discoveries, key items, and equipment.
5. Humans work together. Relationship drama, betrayals, and colony-management overhead are outside the intended focus.

## Design pillars

**Fight for a place you can recognise.** A claimed property should change routes, safety, available work, or equipment. Avoid interchangeable buildings that only add tiny percentage bonuses.

**Trust the people at home.** Guards hold useful positions, workers respond sensibly to danger, and routine tasks resume without fresh orders. Automation should be understandable enough that leaving feels like a decision rather than a gamble against AI mistakes.

**Make progress visible.** Weapons, protection, repairs, crops, and opened internal walkways appear in the world. Menus explain changes; they should not be the only place changes exist.

**Keep strategy close to action.** Choosing a target property changes what the squad does next. Placing a gate changes how combat unfolds. Finding welding tools creates a reason to restore the garage.

## Core loop

1. Review nearby threats, defence readiness, squad equipment, and one or two important work orders.
2. Choose a reachable target with a reward the community needs.
3. Leave through the gate with companions; fight, retreat, or approach quietly.
4. Clear the site and recover supplies, a survivor, or a key discovery.
5. Decide whether to withdraw with loot or connect and secure the property.
6. Build the useful improvement, assign work, and adjust the perimeter.
7. Use the new capability to reach a more ambitious target.

The loop is continuous and interruptible. An incoming attack can turn exploration into a retreat, while a quiet interval can let the player finish a barricade personally.

## Main decisions

- Which adjacent property is worth the risk and additional perimeter?
- Who comes on the expedition, and who protects home?
- Is quiet melee worth the danger, or should we use a noisy gun?
- Should we spend materials on repairs, expansion, or a facility?
- Can the latest discovery change a survivor's role or open a new route?

## Proposed format

Single-player, top-down 2D action with one directly controlled protagonist and AI companions. A compact authored town is the starting map direction. Target desktop first; final engine version, controls, visual resolution, and export platforms remain open. Cooperative survivors describe AI teamwork and tone, not confirmed online multiplayer.

Use a forgiving recovery model for the first prototype: incapacitation and temporary loss of facilities create setbacks. Permanent survivor death, infection timers, and irreversible equipment destruction are not MVP defaults.

## Campaign shape

Illustrative progression: home survival → connected houses → library and garden → functioning workshop → stronger equipment and perimeter → district landmark → final reclamation objective. This is a dependency web, not a mandatory building order. Any location physically reached can be looted; operational benefits still require control and prerequisites.

Town hall, a radio tower, or a final infestation could anchor the ending. The final victory condition is open. A successful ending should demonstrate a viable community rather than require exterminating an endlessly replenished zombie population.

## Scope boundaries

The design does not require detailed sleep schedules, individual ration allocation, relationship meters, betrayal events, skill trees, procedural family histories, or a manufacturing chain for minor components. Food, injuries, ammunition, and materials support expedition choices with a small number of clear decisions.

Optional systems must earn their cost by improving action, reclamation, trusted autonomy, or visible growth. If a feature mainly creates management screens, defer it.
