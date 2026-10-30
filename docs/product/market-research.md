# Market research: Agent Army

All findings are desk research (`third-party data`): they describe the market, never demand for Agent Army.
Stars and last push come from the GitHub API on the check date.

## Questions

1. Who else ships agent or skill packages for AI coding tools: what, for whom, which tools, how alive?
2. Does any of them lead from an idea to money (validation, business model, first customers), or do they stop
   at code?
3. How do they enforce quality: TDD, hooks, evidence vs assumptions?
4. What do users say is missing or annoying?
5. How do they reach users?

## Findings

### Engineering and spec-driven development (questions 1, 3)

| ID | Claim | Source | Checked | Evidence level |
|---|---|---|---|---|
| MR-1 | `obra/superpowers`: skills framework and development method with TDD, brainstorm → spec → plan → subagent execution; 309,194 stars, pushed 2026-10-29, MIT; install guides for 15+ harnesses incl. Claude Code, Codex, Cursor, Gemini CLI, Copilot CLI, OpenCode | github.com/obra/superpowers (README, API) | 2026-10-30 | third-party data |
| MR-19 | superpowers ships the same 15 generic skills to every repo; its only hook is `SessionStart`, which injects the `using-superpowers` instructions. It has no repo scan that generates agents, no stored repo profile and no hook that blocks a commit; TDD is enforced by instructions ("Deletes code written before tests") | github.com/obra/superpowers `hooks/hooks.json`, `hooks/session-start`, `skills/` | 2026-10-30 | third-party data |
| MR-2 | `github/spec-kit`: spec-driven development toolkit with processes for SDD, bug fixing and idea assessment, plus extensions, hooks and presets; 144,065 stars, pushed 2026-10-30, MIT | github.com/github/spec-kit | 2026-10-30 | third-party data |
| MR-3 | `garrytan/gstack`: "23 opinionated tools that serve as CEO, Designer, Eng Manager, Release Manager, Doc Engineer, and QA"; 138,248 stars, pushed 2026-10-30, MIT | github.com/garrytan/gstack (API description) | 2026-10-30 | third-party data |
| MR-4 | `Fission-AI/OpenSpec`: lightweight spec-driven development for brownfield code (proposal, specs, design, tasks per change); 73,439 stars, pushed 2026-10-30, MIT | github.com/Fission-AI/OpenSpec | 2026-10-30 | third-party data |
| MR-5 | `bmad-code-org/BMAD-METHOD`: agile AI-driven development covering "the whole effort, not only the code" (briefs, specs, architecture); 54,777 stars, pushed 2026-10-27; installs via `npx`, Claude Code and Codex marketplaces | github.com/bmad-code-org/BMAD-METHOD | 2026-10-30 | third-party data |
| MR-6 | `SuperClaude_Framework`: 30 commands, 20 agents, 7 modes, 8 MCP servers for Claude Code; 23,914 stars, pushed 2026-09-27, MIT | github.com/SuperClaude-Org/SuperClaude_Framework | 2026-10-30 | third-party data |
| MR-7 | `claude-task-master`: task management for AI-driven development, aimed at Cursor; 28,279 stars, last push 2026-04-28 | github.com/eyaltoledano/claude-task-master | 2026-10-30 | third-party data |
| MR-8 | `buildermethods/agent-os`: extracts codebase standards and injects them into specs; 5,562 stars, pushed 2026-10-07, MIT | github.com/buildermethods/agent-os | 2026-10-30 | third-party data |

| MR-20 | Claude Code's own `/init` writes a `CLAUDE.md` from a repo scan, and `/agents` → "Generate with Claude" drafts a subagent from a description the user writes; neither generates a set of agents or blocking hooks from the repo | docs.anthropic.com/en/docs/claude-code/sub-agents; blog.vincentqiao.com Claude Code /agents | 2026-10-30 | third-party data |
| MR-21 | Closest to per-repo gates: SonarQube's Cursor plugin installs per-project hooks (secrets checks) and quality-gate checks, but generates no agents; Agent OS (MR-8) extracts codebase standards into docs. Two searches found no tool that scans a repo and generates tailored agents with enforced gates | docs.sonarsource.com Cursor agent plugin; web searches 2026-10-30 | 2026-10-30 | third-party data |

### Product, idea to money (question 2)

| ID | Claim | Source | Checked | Evidence level |
|---|---|---|---|---|
| MR-9 | `phuryn/pm-skills`: 69 PM skills and 42 workflows in 9 plugins: discovery, assumptions, experiments, business model, pricing, monetisation, GTM, PRDs, roadmaps; native install in Claude Code and Codex; 27,546 stars, pushed 2026-10-29, MIT | github.com/phuryn/pm-skills | 2026-10-30 | third-party data |
| MR-10 | `phuryn/pm-brain`: plain Markdown files that Claude "reads before answering, writes to after", composed with pm-skills: a persistence layer like our records | github.com/phuryn/pm-skills (README section "Compose with PM Brain") | 2026-10-30 | third-party data |
| MR-11 | `slavingia/skills` (The Minimalist Entrepreneur): 10 Claude Code skills in a journey: find community, validate idea, MVP, processize, first customers, pricing, marketing, grow; 11,018 stars, last push 2026-04-14, no license on GitHub | github.com/slavingia/skills | 2026-10-30 | third-party data |
| MR-12 | spec-kit "Idea assessment" extension: five steps ending in `go`, `needs-clarification` or `kill`; the page does not mention pricing, business model or customers | github.com/github/spec-kit (README) | 2026-10-30 | third-party data |
| MR-13 | Anthropic `knowledge-work-plugins`: `engineering` and `product-management` templates for teams with connectors (brief F-1); 33,971 stars, Apache-2.0 | github.com/anthropics/knowledge-work-plugins | 2026-10-30 | third-party data |
| MR-18 | Anthropic `marketing` plugin (8 skills): campaign plan, content and email sequences, SEO audit, brand review, competitive brief, performance report; built for a marketing team with connectors and budget. No rule against invented proof: `content-creation` suggests testimonials and a statistic hook ("73% of marketers say…") with no source | github.com/anthropics/knowledge-work-plugins `marketing/` @ `2574e29` | 2026-10-30 | third-party data |

### What users say (question 4, partial)

| ID | Claim | Source | Checked | Evidence level |
|---|---|---|---|---|
| MR-14 | Comparisons rate Spec Kit and BMAD as process-heavy (rigid phases, a large pile of Markdown) and OpenSpec as the lightest | developertoolkit.ai spec-driven frameworks comparison; braingrid.ai and dev.to comparisons | 2026-10-30 | third-party data |
| MR-15 | Superpowers spends tokens up front (brainstorm, specs, spec review, subagents); users switch it off for small fixes; claimed savings are self-reported (one 12-session A/B: 14% fewer tokens) | mejba.me review; mcp.directory; gautamkhorana.com | 2026-10-30 | third-party data |

### Distribution (question 5)

| ID | Claim | Source | Checked | Evidence level |
|---|---|---|---|---|
| MR-16 | The largest packages install from plugin marketplaces: superpowers sits in Anthropic's official marketplace and OpenAI's Codex plugin marketplace; BMAD, pm-skills and Minimalist Entrepreneur ship their own Claude Code and Codex marketplaces; BMAD also uses `npx skills add` | READMEs of MR-1, MR-5, MR-9, MR-11 | 2026-10-30 | third-party data |
| MR-17 | Several grow through the author's audience: newsletter (pm-skills, Product Compass), book (Minimalist Entrepreneur), YouTube and paid community (Agent OS) | READMEs of MR-8, MR-9, MR-11 | 2026-10-30 | third-party data |

## Manual-check list

1. User complaints straight from users: Reddit r/ClaudeAI and r/ClaudeCode, GitHub issues sorted by reactions in
   superpowers, spec-kit and pm-skills (MR-14 and MR-15 come from articles, not from users).
2. Whether superpowers enforces TDD with hooks or only with instructions: its `hooks/` folder and skills.
3. What PM Brain stores and whether it ties records across skills like our register: github.com/phuryn/pm-brain.
4. Whether Minimalist Entrepreneur keeps any records between sessions, and its license status.

## Conditional conclusion

What the data suggests, if the stars and READMEs reflect real use:

1. **Engineering is crowded and led by very large projects.** Superpowers (MR-1) already offers TDD and the same
   multi-tool reach we list as advantages. spec-kit, gstack and OpenSpec (MR-2 to MR-4) cover spec-driven work.
   "TDD" and "many tools" are not differentiators on their own. What superpowers lacks (MR-19): agents generated
   for the repo by `bootstrap`, and hooks that block instead of instructions that ask.
2. **Idea to money is less crowded but not empty.** pm-skills (MR-9) covers more frameworks than our advisors.
   Minimalist Entrepreneur (MR-11) has the same journey idea, down to a `/first-customers` skill. Anthropic's
   marketing plugin (MR-18) targets teams with budgets and sets no limit on invented proof.
3. **What nobody shows here:** one evidence register shared across stages, predictions with kill lines written
   before results, advisors that never send or spend, and actuals vs plan. PM Brain (MR-10) is the closest and
   needs a manual check.
4. **Distribution:** the winners install from Claude Code and Codex marketplaces (MR-16) and grow through an
   author's audience (MR-17). Agent Army installs through APM only.

What it cannot tell: whether anyone wants our evidence discipline (A-2), and whether our advisors give better
decisions than pm-skills or Minimalist Entrepreneur (A-3). Those need real use.

## Hand-offs

- **Brief:** Change proposals 1–3 below.
- **`/product-red-team`:** "Why Agent Army instead of superpowers plus pm-skills?", and whether ADR-001 still
  holds for `/ship` and `bootstrap` given MR-1.
- **`/validate-product`:** test A-2 and A-3 against pm-skills and Minimalist Entrepreneur, not only Anthropic.

Proposed to the brief's Change proposals:

1. Alternatives: add superpowers, spec-kit, gstack, OpenSpec, BMAD (engineering) and pm-skills with PM Brain,
   Minimalist Entrepreneur, spec-kit idea assessment (product). Basis: MR-1 to MR-12.
2. Advantage: drop "TDD" and "many tools" as differentiators. Keep two claims, each as an `A` with a test: the
   shared evidence register across stages, and repo-tailored agents with enforced gates. Basis: MR-1, MR-9,
   MR-11, MR-19.
3. New assumption: people install agent packages from Claude Code and Codex plugin marketplaces rather than APM.
   Test: offer a marketplace install and compare installs over a month. Basis: MR-16.
4. New assumption: no other package generates repo-tailored agents with enforced gates. Test: a manual search of
   the Anthropic and Codex plugin directories and GitHub topics finds no such tool. Basis: MR-19 to MR-21.

## Conversation state

- Settled: the five questions (2026-10-30).
- Open: question 4 is partial (manual-check list); the hand-offs above.
- Next step: `/product-strategy` reviews the three Change proposals with the user.
