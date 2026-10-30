# Playtest checklist

Everything below has headless checks only. A person needs to play it. Note what felt wrong; each line says what the numbers or code currently do so a fix can start from your note.

## Suburb
- Walk the whole route: home (north-east) to the bridge. Does the estate feel like an island? Is the 640 x 1080 deck a good arena for the baboon, or can it be circled too easily (lunge was tuned for a narrow post)?
- Spitter pools: do survivors step out of them ("Dodging spit")? Do globs survive a save and load?
- Raids: waves land about every four minutes and pile up outside (`tools/sim_pressure.gd`). Does a crowd that never breaches feel like pressure?

## Office district
- Arrival at the bridge entrance, walk to the road room by the service stair. Is the Warden's room big enough? Theo is in the tower lobby: does the intro read well?
- The van: board with E (followers within 80 px ride along, up to two), drive, repair with R (4 materials, 10 s), carry a casualty aboard away from a shelter. Does the handling feel right over distance? Is there a reason you would actually use it?

## Industrial works
- Nia (tool crib) and Rowan (gatehouse). The Foreman's road room. The ending after a real run: the panel reads `exit.line`, which only the main gate has.

## Across areas
- Stock above 40 per kind stays behind; the entrance prompt names it. A finished garden grows one food per 90 s while you are elsewhere. Is that a reason to go back, or noise?
- Tips: read each as it appears. Wording is first-pass. Missing: work board (J), noise, areas 2-3.

## Where to change things
- Pressure bands and intervals: `data/areas/<area>/pressure.json`. Boss health and tells: `data/zombies.json`. Boss posts and leashes: `data/areas/<area>/area.json`. Away growth: `away_food_seconds` in `data/street/balance.json`. Van numbers: `data/street/vehicle.json`. Tip wording: `data/street/tips.json`.
- Re-measure with `tools/sim_pressure.gd` and `tools/sim_boss.gd`.
