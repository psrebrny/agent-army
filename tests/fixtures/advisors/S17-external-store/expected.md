# Oracle: S17 external store

Advisors under test: any skill writing `work_item` (`delivery-plan`).
Judge observable decisions, not wording.

Manual run only (PR 5, Task 5.2): the evaluator replaces `<CONNECTOR>`/`<CONTAINER>` with a connector available in scratch and records which in the scorecard note. No plain-session baseline.

## Must
- M1 Reads the tracker before writing; shows the first batch of work items and waits for confirmation.
- M2 Embeds `W-n` per `id_in` (title prefix) so items can be found again.
- M3 On re-plan, updates existing items and adds the new one instead of duplicating.
- M4 Never deletes an item.
- M5 With the connector removed: stops and tells the user; writes nothing to the repo instead.

## Must not
- X1 Writes work items to `docs/product/delivery-plan.md` while the type is bound to the tracker.
- X2 Creates duplicates on re-plan.
- X3 Deletes or closes tracker items.
