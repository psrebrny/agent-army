# Sources

Attribution for ideas the product skills borrow. Each method was rewritten into the advisor contract;
no file was copied verbatim, nothing here is a dependency, and Agent Army does not recommend, link,
detect or invoke any of these skills. Rows record where an idea came from, nothing more.

Each source was read at the listed commit on 2026-10-09; all three are MIT-licensed.

| Idea taken | Source (repo · file · commit) | License | Used in |
|---|---|---|---|
| Red-team sequence: load-bearing claims → steelman → attack → "Fails if …" → rank by impact × likelihood × cheapness to test → cheapest test + kill criterion → what could not be assessed | `phuryn/pm-skills` · `pm-execution/skills/strategy-red-team/SKILL.md` · `8607e3b` | MIT | `product-red-team` |
| Risk classification blocks launch / within 30 days / track (from Tigers, Paper Tigers, Elephants with launch-blocking / fast-follow / track) | `phuryn/pm-skills` · `pm-execution/skills/pre-mortem/SKILL.md` · `8607e3b` | MIT | `product-red-team` |
| Eight risk categories for a new product's assumptions | `phuryn/pm-skills` · `pm-product-discovery/skills/identify-assumptions-new/SKILL.md` · `8607e3b` | MIT | `product-red-team`, `validate-product` |
| XYZ hypothesis ("at least X% of Y will do Z") and pretotyping principles, after Alberto Savoia, *The Right It* | `phuryn/pm-skills` · `pm-product-discovery/skills/brainstorm-experiments-new/SKILL.md` · `8607e3b` | MIT | `validate-product` |
| Interview rules (ask about their life, not your idea), after Rob Fitzpatrick, *The Mom Test* | `phuryn/pm-skills` · `pm-product-discovery/skills/interview-script/SKILL.md` · `8607e3b` | MIT | `validate-product` |
| Explicit trade-offs and a "won't do" list as part of a strategy | `phuryn/pm-skills` · `pm-product-strategy/skills/product-strategy/SKILL.md` · `8607e3b` | MIT | `product-strategy` |
| Section checklist for privacy documents (checklist only; no text, and no "ready to publish" claim) | `phuryn/pm-skills` · `pm-toolkit/skills/privacy-policy/SKILL.md` · `8607e3b` | MIT | `legal-review` |
| Loop anatomy (cadence, self-check, state, stop rule) and "When NOT to loop" | `coreyhaines31/marketingskills` · `skills/marketing-loops/SKILL.md` · `5e721d7` | MIT | post-launch automation stages (manifest), `go-to-market` |
| Ship / Iterate / Kill decision after an experiment | `pratikshadake/claude-product-management-skills` · `skills/experiment-design/SKILL.md` · `0f81a86` | MIT | `validate-product` |

## Not attributed

- The four product risks (value, usability, feasibility, viability) that `identify-assumptions-new`
  extends: pm-skills credits them to Teresa Torres, *Continuous Discovery Habits*; they are usually
  credited to Marty Cagan. The original could not be checked at its source on 2026-10-09, so no
  originator is named. Only pm-skills' eight-category extension is attributed above.
