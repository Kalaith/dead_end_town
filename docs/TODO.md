# Dead End Town: next implementation work

The full game is specified in [01](01-game-design.md) with system owners and catalogues 02–18. [09](09-mvp-roadmap.md) sequences the release. The design is complete enough to start implementation; this list does not claim those features exist.

1. Audit/finalise G01: shared prepaid work/repair records, bounded production, regular duties, temporary-role resumption and approved-project scheduling are implemented (schema 19). Finish explicit field-approval/board action coverage before G02; retain original save/Ellis regression coverage. Extend routine maintenance and food-target policy with the owning economy/facility milestones.
2. Continue G02: 24-site greybox, independent crossing barriers, 34 links and core-only reachability. Keep existing six IDs/rewards and test old-save expansion.
3. Build G03 Market Row/food/recovery, then introduce one enemy mechanic at a time through G04–G06. Follow catalogue prerequisites rather than adding all future effects to JSON now.
4. Finish and test the core relief ending at G07 before filling optional content and the utility van at G08. Use the funding ledger/scenarios in [17](17-acceptance-and-balance.md).
5. Pilot art/audio/accessibility and long-campaign save slots before full human runs. Record real observations separately from staged captures and automated checks.

Carry forward engineering follow-ups: grow save migrations in small modules; use toolkit bindings/settings/text helpers when those features arrive. No toolkit side effects, installations or publication. Publishing wrappers still lack a destination; configure exports only when requested for the intended release.
