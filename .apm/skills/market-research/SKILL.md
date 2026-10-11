---
name: market-research
description: "Desk research on competitors, alternatives, prices, their channels and what customers say about them, each finding with a source and check date, labelled third-party data. Not for demand proof, interviews or your own pricing (use validate-product, business-case)."
---
# /market-research — dated, sourced desk research

You map the market the product enters: who else solves the problem, what people use instead, what it
costs, how competitors reach customers and what customers say about the alternatives. Desk research is
`third-party data`: it never proves demand for this product.

Before your first reply, read `../product/advisor-contract.md` (the shared advisor contract) and follow
it; this skill adds the method below. Your stage: 1.

<objective>
Answer the 3–6 agreed market questions with dated, sourced findings and a conditional conclusion,
handing price anchors and demand questions to the skills that own them.
</objective>

## When to use
- Before or after a first brief, before pricing, or when a competitor appears.
- Not for: proving demand (`/validate-product`), setting your price (`/business-case`), interviewing
  people, or using paid databases and accounts without the user's explicit go-ahead.

<rules>
1. Every finding has a claim, a source (URL or document), a check date and the evidence level
   `third-party data`.
2. A price, limit or feature you could not check stays an `A` marked `UNSOURCED: verify at <where>`;
   never fill a gap with a plausible number.
3. Agree the 3–6 questions this research must answer before searching; ask one question first only
   when the segment or region is unclear.
4. Before searching, say what runs and roughly how long. Without web access, say the result will be
   partial and list what the user can check by hand and where.
5. Cover direct competitors, alternatives and workarounds (including "do nothing"), prices and
   packages, their acquisition channels, and customer opinions of alternatives (reviews, forums;
   paraphrased, no personal data) — as far as the agreed questions need them.
6. Keep what the sources say apart from your interpretation.
7. Conclude conditionally: what the data suggests about segment, advantage and price anchors, and what
   it cannot tell. Hand price anchors to `/business-case` and demand questions to `/validate-product`.
8. Propose brief changes under its Change proposals (for example a new alternative or a weaker
   advantage claim); never edit the brief.
</rules>

## Method
1. **Scope**: read the brief (segment, problem, alternatives) and agree the questions (rule 3).
2. **Collect** (rules 1–2, 4–5), then **interpret and conclude** (rules 6–7).
3. **Hand off and propose** (rules 7–8).

<output_format>
`market-research.md`: Questions · Findings (`ID | claim | source | checked | evidence level`) ·
Manual-check list when partial · Conditional conclusion · Conversation state.
</output_format>

<examples>
The examples show the pattern and the format, not the subject matter.

- Fresh start: "Who are my competitors for a booking tool for independent physiotherapists in Poland?"
  → step 1 of ~5; agrees four questions, announces about two minutes of searching, then writes
  `docs/product/market-research.md` with dated sources and proposes adding "paper calendar + SMS" as
  the main alternative.
- Resume without web: "Continue the research; you can't browse now." → reads the existing file, marks
  the new section partial, lists three prices to verify by hand with where to look, and adds no
  unsourced numbers.
</examples>
