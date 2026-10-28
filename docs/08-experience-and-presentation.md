# Experience, interface, art and audio

Full game design, retaining the user's sparse street presentation. The procedural slice is the functional/art-reference baseline, not finished production art. No assets are commissioned or created by this documentation pass.

## Opening and learning sequence

Start paused at a concise title/help panel, then at home with Mara, a damaged gate, bat and eight Food. The next action is concrete: repair the gate, open it, clear the neighbouring yard. Do not front-load every button or show the full cast. Early timers below are observation targets, never forced wait gates.

| Approximate play | Experience | Teaching/feedback |
| --- | --- | --- |
| 0–3 minutes | Move, swing, repair, open home gate | One contextual prompt at a time; bat reach/contact danger |
| 3–8 | Clear/claim garden, collect timber, approve work | Claim does not build protection; E approves, R works |
| 8–15 | Build passage, start tending, leave Mara on useful duty | Worker travels and resumes; connection has physical meaning |
| 10–25 | Library or garage first | Rescue versus equipment; no unsearched reward spoiler |
| 20–35 | Ellis and bullet workshop, optional original watch | Ranged resource/noise choice and noncombatant contribution |
| Later acts | New zombie tell and one new facility at a time | Discoveries solve an understandable current problem |

The first migration rule in 07 provides a protected learning interval, not invulnerability. If the player chooses a different order, prompts follow state rather than a brittle tutorial stage. A remembered tip can be reopened in pause. No tutorial-only resources, actor teleports or secret enemy damage reduction.

## Screen and input map

| Input | World action / paused destination |
| --- | --- |
| WASD/arrows | Movement and last facing |
| Mouse + left click | Aim and melee |
| Space | Melee along movement/last facing |
| Right click | Fire equipped pistol/shotgun |
| E | Nearest valid gate/search/claim/project interaction; hold at casualty to carry |
| R held | Contextual work/repair, or selected field treatment |
| Q | Existing finite timber collection when near its pile |
| 1/2/3/4 | Whole team Follow/Hold/Engage/Return home, respecting Ellis/downed capability |
| F | Paused team/orders/loadouts |
| G | Assign eligible person to nearby known inside defence post |
| M | Paused known-town overview |
| J | Paused approved work board |
| Esc/Tab | Pause, objectives, saves, settings and help |

All gameplay bindings are remappable, including mouse actions and number shortcuts. Duplicate binding warning offers replace or cancel; no silently unbound essential action. UI navigation supports keyboard focus, confirm/back and visible selection. Rebinding never treats the confirmation key as a subsequent gameplay attack.

Context prioritises the explicitly highlighted nearest usable target. Ties: casualty, gate, active work, search/claim, new project; distance then stable ID. Show its action/cost before execution. E at a casualty says Hold to carry and never toggles a nearby gate while held. R only treats with the bag when a patient is explicitly selected/highlighted; otherwise it works the highlighted structure. If context is ambiguous, show a small paused chooser instead of spending on the wrong site.

## Pause policy and screens

Opening, pause, map, orders, construction approval, work board, loadout, dialogue, save/load and settings stop every authoritative clock. Closing one overlay returns to the previous paused screen until the last overlay closes. Local prompts/brief discovery alerts do not pause except the first rescue introduction. Losing window focus pauses by default, configurable only for an explicit accessible preference; no surprise background raid.

The pause root shows current objective, next known actionable step, available supplies, next meal and critical alerts. No more than three highlighted next steps. Selecting an unmet requirement locates a known site or explains the undiscovered capability generically.

Team page: only recruited people, scrollable rows with assignment/activity, health, location and gear. Work page: approved jobs and exact block/cost/commitment. Map: known street outline, held parcels, actual route condition and weak physical edges; selecting a location recentres a preview, not teleporting the player. Unknown parcels show what has been seen, not contents.

Loadout page names unique item owner and safe-bench requirement. Supply page shows available, committed and pending output separately. Finale page uses individual readiness rows with actionable failure reasons and clear “Begin signal” action. None exposes schema IDs, AI leases, debug seeds or implementation terminology to ordinary players.

## Sparse live world

Keep small player health/relevant ammo and pause access. No permanent property titles, zombie counts, reward lists, CONNECTED stamps, progress checklist, billboard text or large bottom panel. Detailed supplies/team live in pause. Current target gets one short prompt; nearby project health/progress appears only when relevant.

Use flags, lit windows, crop states, patched fences, workbench objects, clothing and visible equipment to show change. Damage appears until repaired. Completed passages visibly open original fences; removed inner barriers visibly free the road. Core discoveries have a brief notification, never a permanent text label.

Urgent alerts show place/direction, event and one useful response. Supply warnings happen at meaningful transitions: next meal underfunded, shortage begins, resumed, reserved ammo breached. Do not replay a warning after every menu close or every load. New-kind tells use shapes/motion even when the HUD is sparse.

## Art direction and bounded asset plan

Original stylised top-down town, slightly visible front faces, 32-pixel base tiles. Survivor bodies about 48–64 pixels tall at the reference view, zombies with distinct silhouettes. A readable large body matters more than detailed tiny faces. Keep the camera scale fixed during combat; window resizing letterboxes/scales the same reference composition. No zoom-dependent combat advantage.

Build one modular house/yard kit, one shop/interior kit and one works kit. Reuse walls, gates, roofs, doors, floors and props, while giving every landmark a distinct frontage/sign shape. Four states per important fixture: derelict, approved/work in progress, operational, damaged/broken. Do not make four entire building sprites for every state when modular props suffice.

Survivors need four/eight-direction readable movement/attack poses, hit/downed/carry/work actions, unique head/clothing accents and layered melee/body/off-hand overlays. Eight-direction movement can reuse mirrored poses where identity permits. Portraits identify people when helmets obscure faces. Preserve original artwork; replacements are new assets with explicit provenance.

Zombies need the tells in 14 and clear death silhouettes; no blood/gore is required for mechanics. Puddles use a patterned rim and animated surface. Heavy attacks use a lane/brace pose rather than relying on red alone. Keep foreground roofs from covering a threat marker.

Art pipeline gate: one survivor in bat, sword/shield and iron states; one room with roof fade; one Brute/Runner tell; one passage's four states at 1280×720. Inspect before commissioning the full catalogue. The current procedural drawing remains until this gate succeeds.

## Audio scope

Minimum distinct cues: bat/metal swing, enemy impact, bite, shield impact, pistol, shotgun, empty click, work loop, completion, gate open/close, approach, breach, downed person, discovery, meal shortage/resume and signal start/success. Eight kinds have recognisable movement or attack cues. Construction loops merge by site; crowds cap simultaneous voices to avoid a wall of noise.

Use separate master/music/effects/alert volume sliders. Optional low-key district ambience and one restrained tension layer; no adaptive music system prerequisite. Critical alerts/tells always have visual/text equivalents. No actor voice acting requirement; dialogue is text with optional nonverbal acknowledgement.

## Accessibility and settings

Required: remapping, hold/toggle continuous attack/work, text scale 100/125/150%, UI contrast option, shape-based state markers, reduced flashes, screen shake 0–100% (default low), disable corpse/gore embellishment, subtitles for semantic alerts, independent volumes and focus pause. Minimum body text 18 pixels at reference size; enlarged screens scroll instead of clipping buttons. Tooltip information must be available on keyboard focus.

Supply/attack assists can be offered as an explicit Relaxed preset: 25% less incoming actor damage and 25% longer migration interval; it never changes unique rewards or completion eligibility. Standard uses catalogue values. No hidden adaptive difficulty. Preset persists in save and settings, can change while paused, and cannot heal or retroactively move a scheduled arrival. No Hard/permadeath mode in release scope.

## Presentation acceptance

Inspect opening, pre-rescue library, post-rescue roster, full nine-person panel, enlarged work board, equipment transfer, shortage, blocked route, every new tell, three-front finale, defeat recovery and ending. Verify actual mouse/keyboard commands, no unknown reward leaks, no clipped text at 150%, readable colours/shapes and audio-muted alerts. Captures are staged evidence; human input/feel require separate playtesting. Use the project's fixed capture paths and labels.
