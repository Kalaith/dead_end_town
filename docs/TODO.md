# Dead End Town follow-ups

From the 28 October 2026 project review in [PROGRESS.md](PROGRESS.md). Ordered by value.

1. Move remaining hard-coded gameplay numbers into `data/street.json` and validate them in `scripts/core/catalog.gd`: garage bonus materials, starting home-gate health factor, home alert radius, start positions. Build prompt costs from balance values.
2. Split `scripts/sim/world.gd` (365 lines, owns gate repair, garden work and prompts) before it passes ~600 lines: move gate repair and garden work into their own sim modules, and prompt text into a context module.
3. In `scripts/core/save_state.gd`, replace the duplicated deep-copy key list and double schema number with constants; consider one migration step per schema file.
4. Adopt toolkit modules when the matching feature arrives: `KeyBindings`/`SettingsStore` for remapping, `TextCatalog` for UI text, `Shapes` for drawing.
5. Add `publish.json` and `export_presets.cfg` when a destination is chosen; until then publishing is unavailable.
6. Trim the README to overview, controls and commands; move rule detail into the numbered design docs.
7. Human playtest of the pursuit, provisions and neighbourhood-watch additions (not yet done).
