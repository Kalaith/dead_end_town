# Hybrid construction and work orders

Full game contract. Player and AI contribute to the same paid site. [16](16-equipment-and-recipes.md) is the numerical recipe owner; [06](06-buildings-and-economy.md) owns stocks and reserves. Current slice orders are narrower than the general board designed here.

## Placement and approval

Every project occupies an authored compatible socket: parcel passage, road boundary, alley mouth, gate upgrade, garden bed or existing facility fixture. No arbitrary walls/houses or terrain editing. Preview footprint, protected side, stand point, completed collision, cost, work duration, unlock and cancellation return.

Approval requires a standing player in interaction range, target held and locally clear, socket compatible, known recipe, sufficient available inputs and no conflicting order. Confirm E once; hold R works. F opens the paused board and can approve an already discovered socket only when the player is at it. New expansion, demolition, facility restoration and upgrades always require explicit player approval.

Inputs come from shared home stock. A disconnected but held site permits a **field project** only while the player is present: show “Commit field supplies” and move the full bundle from stock to that site atomically. This is an explicit logistics abstraction consistent with direct search deposits; no backpack or repeated trip home. Survivors cannot remotely approve field projects. They may finish already-paid work if the player leads them there and the local work position is safe.

Routine productive recipes never use field approval and require safe home connection. This permits first passages/defences without a claim/connection cycle, while preventing new remote spending by an isolated worker. Existing prepaid projects migrate without another charge.

## State and accounting

States: `approved`, `working`, `blocked`, `completed`, `cancelled`, `destroyed`. Approved inputs leave available stock immediately and enter the unique order's committed bundle. There is no second debit when a worker arrives. Reservation means this committed bundle; do not maintain a second spendable reservation ledger.

Order fields: stable ID, recipe/socket/target IDs, phase, input bundle, work required/completed, assigned role/person, executor lease, stand position, priority, blocked reason, completion/output flags and salvage paid. Blueprint collision is absent. Partial work never adds partial health protection.

One effective work rate per site, regardless of workers. Player takeover temporarily releases the AI executor, preserving the actor's primary role; leaving releases it back. Multiple sites progress concurrently. A downed/sheltering/reassigned executor loses its lease but does not lose the bundle. Stable priority ties use approval sequence then order ID.

Before completion revalidate ownership, local safety, socket, route/field eligibility and occupied footprint. If collision would trap a living/downed/carried actor, wait with “Clear the work area”. Do not push actors through walls. Apply structure/output exactly once, mark order complete and only then expose it to UI. Save/load at the completion tick cannot repeat the grant.

## Cancellation, removal and repair

Before any work, cancelling an unbuilt blueprint returns its entire bundle. After work, construction/restoration returns `floor(input_count × (1 - 0.25 × work_fraction))` for each fungible input; unique prerequisite items were never consumed and remain discovered. The completed object cannot also pay this refund. For production batches, cancellation returns `floor(input_count × (1 - work_fraction))`; partial medical treatment never refunds consumed inputs. Show exact return before confirmation.

Demolition/removal is a separate explicit order. Collision remains until its final tick. Undamaged removable structures return 75% of build Materials rounded down; multiply by current health/max health before rounding if damaged. Reinforcement cost is included only if its recipe is explicitly salvageable. Facilities cannot be dismantled after restoration; they can be repaired or paused, avoiding accidental destruction of mandatory discoveries.

Breached structures retain socket identity and become rebuildable; their destruction pays no salvage. Destroyed blueprints pay no automatic refund. Cancelled/removal/destroyed paths share one finalization guard, so no double return. Removing a structure cancels any attached repair order without a second refund.

Repair is a bounded committed batch: 3 Materials restores up to 120 health at 24 health/second. A damaged facility uses 4 Materials for up to 200 health at 20/second. Stop at max; unused healing capacity is lost, not held for future damage. Pay once, retain remaining capacity/progress through interruption, and never bill the same repair again after load. A breached gate needs the gate-rebuild recipe rather than a repair to an absent collider.

Restored facility fixtures have their own 300-health breakable hitbox within the building; the building shell is indestructible. A zombie reaching an active work-noise source may attack that fixture if no standing person takes priority. Ordinary zombies do not damage silent fixtures without a route/noise reason. Finale actors may target their explicit relief fixture after entering; 13 assigns those targets. A zero-health fixture keeps its unlock/restore flag but is inoperable until repaired; stock and committed bundles are never destroyed with it.

## Job policy

Each survivor has a primary role and optional selected site. Guard/follower assignments are exclusive; they do not compete with general work. The player approves at most eight pending non-production projects at a time; completed and blocked history does not count after acknowledged. No general infinite work queue.

| Priority | Eligible task | Limit |
| --- | --- | --- |
| 1 | Immediate shelter/casualty transport | Safety first; no unsafe rescue charge |
| 2 | Approved critical repair at a defended line below 40% | Work from safe side only |
| 3 | Player-prioritised approved project | One flagged priority project per site |
| 4 | Role's approved construction/restoration or batch | Match prerequisites and physical route |
| 5 | Routine role production/maintenance | Stock cap/reserve applies |
| 6 | General safe work or idle | Never scavenge infected space autonomously |

Builder: approved construction then permitted repairs. Grower: selected garden/greenhouse/allotment. Mechanic: approved equipment, then bullet/shell production if selected. Medic: queued present patients then selected medicine batches. General worker: critical safe repair, priority project, food below target, explicit production order, then idle. No need for a separate hauler.

The policy does not commandeer someone already on a different explicit role. A grower keeps tending while another person restores the clinic. Completing one project releases its lease, retains primary role and looks for the next permitted task. One-off orders can explicitly return to previous role.

## Repeating production and stock targets

Production has three modes: one batch, repeat to target, stopped. Default bullet target 24, shell target 8, medicine target 8; food target is two meals plus four recovery Food. Check available output plus committed pending output before starting another batch; otherwise multiple stations can overshoot. Finish a prepaid batch even if the target is lowered; do not erase its work. All repeat modes respect the reserves in 06.

No instant automation of a new recipe on discovery. First use requires choosing the batch/target. Afterwards the role resumes repeat-to-target automatically after safety or supply interruptions. Lowering a reserve cannot spend anything by itself; a valid recipe still must start.

## Danger, route loss and resumption

Local danger suspends labour immediately and invokes the actor's shelter policy. Pause the site, not every worker in town. Preserve completed work and input ownership. Route loss blocks a productive facility and future worker travel; a nearby player can finish a previously approved field construction project while locally safe. New batch production remains blocked until safe connectivity returns.

Retry only on relevant state changes or at a bounded one-second interval. Do not path every tick into a closed gate. A five-second clear period resumes normal work after an alert, reducing oscillation. If a target is lost, retain the order as “Reclaim site”; repairs/improvements survive unless physically destroyed. Reclaim resumes without a duplicate charge.

## Work board

Paused board shows site, project, progress, worker/role, committed inputs, available stock, priority and one actionable block reason. Selecting a row locates its known world socket. Actions: assign, prioritize, pause repeat mode, cancel with return preview, remove with salvage preview. Unknown property facilities do not appear as locked spoilers.

Commands return a structured result so the same reason appears beside the disabled button and in a brief message when state changes between preview and approval. Common reasons: need safe home route, reclaim site, clear nearby threats, need input, clear footprint, bring person to bench, incompatible item, field trip already used.

## Acceptance

Exercise player→AI→player handoff; two sites concurrently; several workers at one site; cancel before/after work; danger during final tick; ownership loss/reclaim; destruction versus cancellation; repair interruption; target lowered mid-batch; full board; field approval/presence validation; load before/after completion. In every case inputs = available + committed + consumed + returned, with outputs granted once. No job can heal/spend/create collision through a UI-only mutation.
