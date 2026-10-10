# Spec: ClassFill MVP

- S-1 (must) A studio owner signs up and creates a studio.
- S-2 (must) The owner imports a waitlist (name, phone, consent date) from CSV.
- S-3 (must) The owner releases a free spot in under a minute.
- S-4 (must) Opted-in waitlist members get an SMS with a claim link.
- S-5 (must) First claimer gets the spot; others see it is taken.
- S-6 (must) Unsubscribe link in every SMS; delete a number on request.
- S-7 (should) The owner sees who claimed each spot.
- S-8 (should) The owner pays the subscription by card.
- S-9 (later) Weekly email summary for the owner.
Events: spot_offered, spot_claimed.
