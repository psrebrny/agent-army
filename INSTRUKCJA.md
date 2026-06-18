# Claude Agent Army — instrukcja (gotowy produkt)

Samokontrolująca się drużyna agentów Claude Code dla **dowolnego repo**: architekt (SDD + Testing Trophy + strict TDD), niezależny tester, audytor architektoniczny, security, performance i docs — pilnujący się nawzajem, plus deterministyczne **hooki** (bariery, których model nie obejdzie).

## Wymagania
Claude Code v2.x · `bash` · `python3` (bariery; bez niego działa fallback). Windows: WSL lub Git Bash.

## Instalacja (raz na repo)
```bash
# rozpakuj paczkę, potem z katalogu repo:
/ścieżka/do/claude-agent-army/install.sh .
# albo wskaż repo:
/ścieżka/do/claude-agent-army/install.sh ~/projekty/moje-repo
```
Instalator kopiuje `.claude/`, `CLAUDE.md`, CI, instaluje git pre-commit i dopisuje `.gitignore`. To kopia 1:1 — żadnego LLM.

## KROK 1 — punkt wejścia: `/bootstrap`  (uruchom najpierw)
```bash
cd moje-repo
claude
/bootstrap
```
`/bootstrap`:
1. **czyta repo** (stack, standardy, konwencje, realne komendy test/lint),
2. **zadaje parę mądrych pytań** (tylko luki; biznes, architektura, testy, NFR, proces),
3. **tworzy/specjalizuje całą drużynę pod to repo** (dokładne komendy, framework testów, konwencje) + dopasowane `CLAUDE.md`/`AGENTS.md` + szkielet `design-docs/` + specjalizuje szablony,
4. **weryfikuje** (odpala lint+testy raz) i raportuje.
Greenfield (puste repo) → pełny wywiad + bootstrap fundamentów. Jakość pilnuje `.claude/agents/_STANDARD.md`.

## KROK 2 — praca w repo: `/ship`  (orchestrator)
```bash
/ship "dodaj endpoint /health z testem"
```
Pipeline: **Discovery/wywiad → wybór trybu → Blueprint (architect, design-docs/) → implementacja w strict TDD (tester: RED → kod → GREEN) → review (code-reviewer) → security → docs → podsumowanie + propozycja commita** (commit dopiero za Twoją zgodą).

Na starcie `/ship` pyta o **tryb wykonania**:
- **A) Autonomiczny** — drużyna robi wszystko sama; zatrzymuje się tylko na bramkach hooków i po zgodę na commit.
- **B) Nadzorowany** — orchestrator przerywa w checkpointach (po blueprintcie, po testach RED, po GREEN, przed eskalacją) i czeka na „ok/popraw". Możesz przejąć ster i sprostować agenta.
Przełączasz w locie: „przełącz na autonomiczny/nadzorowany".

## Ściąga komend
- `/bootstrap` — RAZ: analiza repo + wywiad + budowa drużyny.
- `/ship "<zadanie>"` — przeprowadź feature end-to-end z kontrolą jakości.
- `/new-agent` — dodaj nowego agenta (zawsze do `_STANDARD.md`).
- `/agents` — lista drużyny.

## Co jest w repo po instalacji
```
.claude/
  settings.json                 # rejestracja hooków (bariery)
  agents/                       # drużyna (architect, tester, code-reviewer, security-auditor, perf-auditor, docs-writer)
    _STANDARD.md                # poprzeczka jakości dla KAŻDEGO agenta
  hooks/                        # guard / format / verify / gate / detect / git-pre-commit
  skills/                       # bootstrap (wejście) · ship (orchestrator) · new-agent
  templates/
    blueprint/                  # 00_CORE_MANIFEST + 0X_PR (architekt wypełnia)
    reports/                    # code-review / security / perf / docs / adr / test-report
CLAUDE.md                       # pamięć projektu (po /bootstrap dopasowana do repo)
.github/workflows/quality.yml   # CI: ta sama verify.sh
```

## Bariery (działają automatycznie, niezależnie od osądu agentów)
- **PreToolUse** → blokuje edycję sekretów i groźne komendy.
- **PostToolUse** → auto-format po zmianie pliku.
- **SubagentStop** → lint+testy po testerze.
- **Stop** → nie kończy tury, póki lint/testy nie są zielone (z ochroną przed pętlą).
- **git pre-commit** → skan sekretów + lint/testy, nawet gdy ktoś omija Claude Code.

## Rozbudowa
Nowy agent: `/new-agent` (trzyma `_STANDARD.md`). Override per-repo: wrzuć własny `.claude/agents/<nazwa>.md` — przykryje generała.

## Troubleshooting
- `claude doctor` — diagnostyka (hooki, MCP, powłoka).
- Hooki nie działają na Windows → użyj WSL/Git Bash.
- Brak `python3` → bariery działają w trybie fallback (blokują najgroźniejsze wzorce).
