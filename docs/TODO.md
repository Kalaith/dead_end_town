# Dead End Town follow-ups

From the 28 October 2026 project review in [PROGRESS.md](PROGRESS.md). Ordered by value.

1. Split `scripts/sim/world.gd` (365 lines, owns gate repair, garden work and prompts) before it passes ~600 lines: move gate repair and garden work into their own sim modules, and prompt text into a context module.
2. Consider one migration step per schema file in `scripts/core/save_state.gd` as the chain grows; the remaining fixed positions in `combat.gd` (gate strike point) could move to data.
3. Adopt toolkit modules when the matching feature arrives: `KeyBindings`/`SettingsStore` for remapping, `TextCatalog` for UI text, `Shapes` for drawing.
4. Add `publish.json` and `export_presets.cfg` when a destination is chosen; until then publishing is unavailable.
5. Trim the README to overview, controls and commands; move rule detail into the numbered design docs.
6. Human playtest of the pursuit, provisions and neighbourhood-watch additions (not yet done).
