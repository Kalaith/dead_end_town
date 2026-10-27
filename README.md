# Dead End Town

Reclaim a zombie-infested town, one property at a time, with a small group of survivors who work and fight together.

**Status: design and planning only.** This directory contains a Markdown game-design package, not a playable Godot project. There is no `project.godot`, executable, commissioned art, or implemented simulation yet.

Prepared 28 October 2026 from the [Game concept development conversation](chatgpt-conversation://6ae0fba7-c8a4-83ec-9e38-b9d8b951a9ac) and the accompanying project request.

## The game

Open the gate, take a small squad down the street, and clear the next house. Back home, the survivors you left behind repair fences, grow food, and defend the perimeter. Bring back tools, equipment, and people that change what your community can do. Connect the new property and watch a dangerous street become a lived-in neighbourhood.

Everything happens in one continuous world. The survivors are a cooperative team. Growth comes mainly from key discoveries, useful buildings, and visible equipment rather than experience grinding or complex character management.

## Documentation

| Document | Purpose |
| --- | --- |
| [Game design](docs/01-game-design.md) | Vision, pillars, core loop, player experience, scope |
| [World and territory](docs/02-world-and-territory.md) | Property claims, connections, perimeter, loss and recovery |
| [Combat and home defence](docs/03-combat-and-defence.md) | Player actions, squad orders, autonomous defence, alerts |
| [Construction and jobs](docs/04-construction-and-jobs.md) | Shared work progress, jobs, interruptions, safe autonomy |
| [Survivors and growth](docs/05-survivors-and-growth.md) | Named cast, equipment, Paige's transformation |
| [Buildings and economy](docs/06-buildings-and-economy.md) | Rewards, unlock chains, stockpile, production |
| [Zombies and pressure](docs/07-zombies-and-pressure.md) | Noise, migration, hordes, readable escalation |
| [Experience and presentation](docs/08-experience-and-presentation.md) | Opening, interfaces, visual changes, accessibility |
| [MVP roadmap](docs/09-mvp-roadmap.md) | Milestones, acceptance gates, playtest plan, deferred scope |
| [Godot implementation](docs/10-godot-implementation.md) | Proposed scenes, data, navigation, simulation, persistence |
| [Decisions and questions](docs/11-decisions-and-questions.md) | Confirmed direction, defaults, unresolved choices |
| [Sources and terminology](docs/12-sources-and-terminology.md) | Source limits, precedence, technical references, glossary |

Read the game design first, then the decisions register. For implementation, follow the MVP roadmap and treat the technical document as a proposal until tested.

## How to use this package

- **Confirmed direction** means explicitly selected by the user in the conversation or current request.
- **Proposed default** means a concrete working rule supplied to make the design buildable. It remains open to revision.
- **Illustrative** means example content or tuning, not a production commitment.
- **Open** means a decision still needs evidence or a user choice.

Unless specifically identified as confirmed, mechanics, counts, numerical values, cast details beyond Paige, and implementation choices below are proposed defaults. The latest user direction takes precedence over earlier brainstorming. In particular, earlier activity-based skill suggestions do not override the later request for high-level, item-led growth.

## First development objective

Prove that leaving home is interesting because trusted survivors continue defending a real place. Build one small street before expanding into a full town. See [the milestone gates](docs/09-mvp-roadmap.md).
