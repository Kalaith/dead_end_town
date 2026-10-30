# Dead End Town: what is left

Updated 30 October 2026. The strip, relief watch and G01-G08 milestone list that used to be here are superseded by the area model ([19](19-areas-and-suburb.md)); delivery steps 1-10 there are done. History is in [PROGRESS](PROGRESS.md).

## Needs a person
1. **Play all three areas and the ending** with [the checklist](playtest-checklist.md). Nothing since the area transition has been played: the bridge and road-room boss fights, the van (riders, repair, ambulance), Spitter pools and survivors dodging, Theo/Nia/Rowan, tips, save slots and the ending screen after a real run are headless-checked only.
2. **Tune from that run:** pressure bands (`data/areas/<area>/pressure.json`, measured by `tools/sim_pressure.gd`), boss health and tells (`tools/sim_boss.gd`), the away-garden rate and van numbers.
3. **Decide the plaza and car parks.** The suburb plaza is drawn and does nothing; the office car parks are plain lots. Needs a purpose before any layout work.

## Known gaps (buildable)
- Away production beyond gardens (clinic, workshop, ammunition bench) and pressure on an area left behind: both stay frozen.
- Survivors cannot repair the van; the van does not cross areas.
- Tips missing for the work board (J), noise and areas 2-3.
- Save slots cannot be deleted or named; the overwrite prompt is unseen.
- Debt: `migrate` upgrades build a `World` from current content; raider path targets in `raiding.gd`; a Theo/Nia/Rowan lot searched before they existed never yields them.
- Pilot art, audio and accessibility (G09) have not started.

## Rules that still hold
Verification is headless scripts and `Capture.ps1` captures; look at the image before saying a visual change works. Commit each slice. See `AGENTS.md`.
