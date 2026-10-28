# Dead End Town: next implementation work

The full game is specified in [01](01-game-design.md) with system owners and catalogues 02–18. [09](09-mvp-roadmap.md) sequences the release. The design is complete enough to start implementation; this list does not claim those features exist.

1. G01 shared-order foundation is implemented (schema 19): prepaid work/repairs, bounded production, regular duties, temporary-role resumption, approved-project scheduling and explicit field commitments. Retain original save/Ellis regression coverage; board location/assignment now uses G02’s known-town overview. Extend routine maintenance and food targets with their economy/facility owners.
2. Proceed to G03; G02 local preview is implemented. The known-town overview, board location/temporary assignment, 24-site geometry, independent crossing barriers, 34 links, core-only reachability and schema-20 old-save expansion are implemented; 16 sites remain explicit development shells; hardware search/materials/spear and schema-21 first-claim history are implemented. June’s search/rescue/introduction and schema-22 medicine stock are implemented.
3. Continue G03 with clinic restoration/treatment, physical casualty recovery and Oliver/greenhouse/food, then introduce one enemy mechanic at a time through G04–G06. Follow catalogue prerequisites rather than adding all future effects to JSON now.
4. Finish and test the core relief ending at G07 before filling optional content and the utility van at G08. Use the funding ledger/scenarios in [17](17-acceptance-and-balance.md).
5. Pilot art/audio/accessibility and long-campaign save slots before full human runs. Record real observations separately from staged captures and automated checks.

Carry forward engineering follow-ups: grow save migrations in small modules; use toolkit bindings/settings/text helpers when those features arrive. No toolkit side effects, installations or publication. Publishing wrappers still lack a destination; configure exports only when requested for the intended release.
