# Claude Agent Army 🛡️

Uniwersalny, wrzucany do **dowolnego repo** zestaw, który zamienia Claude Code w samokontrolującą się drużynę agentów: planista, tester, recenzent, audytor bezpieczeństwa i redaktor dokumentacji — pilnujący się nawzajem, plus deterministyczne **bariery (hooki)**, których żaden agent nie obejdzie.

## Instalacja (do dowolnego repo)
```bash
# z katalogu repo, do którego chcesz wstrzyknąć drużynę:
/ścieżka/do/claude-agent-army/install.sh .
# albo wskaż repo wprost:
/ścieżka/do/claude-agent-army/install.sh ~/projekty/moje-repo
```
Następnie:
```bash
cd moje-repo
claude
/agents            # zobacz drużynę
/ship "dodaj endpoint /health z testem"
```
Wymagania: Claude Code v2.x, `bash`, `python3` (bariery bezpieczeństwa). Na Windows: WSL lub Git Bash.

## Co dostajesz
```
.claude/
  settings.json          # rejestracja hooków (bariery)
  agents/                # drużyna subagentów
    planner.md           #  → plan + kryteria akceptacji (nie koduje)
    tester.md            #  → pisze i uruchamia testy
    code-reviewer.md     #  → recenzja diffa, blokuje na BLOKERACH (read-only)
    security-auditor.md  #  → audyt bezpieczeństwa (read-only)
    docs-writer.md       #  → aktualizuje dokumentację
    perf-auditor.md      #  → audyt wydajności (read-only)
  hooks/                 # deterministyczne bariery
    guard.sh             #  PreToolUse  → blokuje sekrety + groźne komendy
    format.sh            #  PostToolUse → auto-format po każdej zmianie
    verify.sh            #  lint + testy (wykrywa stack automatycznie)
    gate.sh              #  Stop        → nie kończy, póki testy/lint nie są zielone
    detect.sh            #  wykrywanie stacku (npm/pnpm/yarn, pytest/ruff, go, cargo)
    git-pre-commit.sh    #  bariera gita: skan sekretów + lint/testy (instalowana do .git/hooks)
  skills/ship/SKILL.md   # komenda /ship: cały pipeline end-to-end
  rules/                 # reguły zależne od ścieżki (opcjonalne)
CLAUDE.md                # pamięć projektu (uniwersalny szablon)
.github/workflows/quality.yml  # CI: ta sama bramka (verify.sh) na push/PR
```

## Jak agenci „pilnują się nawzajem"
1. **planner** rozpisuje plan i kryteria akceptacji — zanim padnie linia kodu.
2. Sesja główna implementuje najmniejszą zmianę.
3. **tester** dopisuje i uruchamia testy (nie wolno mu osłabiać asercji).
4. **code-reviewer** recenzuje diff — przy BLOKERACH zwraca `REVIEW: ODRZUCONE` i pętla wraca do napraw.
5. **security-auditor** szuka sekretów i podatności (tylko odczyt).
6. **docs-writer** aktualizuje dokumentację.

Nad tym wszystkim czuwają **hooki** — warstwa, której model nie może „przegadać":
- **PreToolUse (guard.sh)** — twardo blokuje edycję `.env`/kluczy i komendy typu `rm -rf /`.
- **PostToolUse (format.sh)** — formatuje kod po każdej zmianie.
- **SubagentStop (verify.sh)** — po pracy testera/recenzenta odpala lint+testy.
- **Stop (gate.sh)** — nie pozwala zakończyć tury, dopóki lint/testy nie są zielone.

To podział pracy: **agenci = osąd** (LLM, mogą się mylić), **hooki = prawo** (skrypty, deterministyczne).

## Uniwersalność
`detect.sh` sam rozpoznaje stack po plikach (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`…) i podstawia właściwe komendy formatowania/lintu/testów. Nie musisz nic konfigurować, by działało w nowym repo. Możesz nadpisać komendy w `CLAUDE.md`.

## Dostosowanie
- Dodaj agenta: nowy plik `.claude/agents/<nazwa>.md` (frontmatter `name/description/tools/model` + prompt).
- Zaostrz/poluzuj barierę: edytuj wzorce w `hooks/guard.sh`.
- Dodaj własny gate: dopisz hook w `settings.json` (zdarzenia: PreToolUse, PostToolUse, SubagentStop, Stop, UserPromptSubmit, SessionStart…).
- Pełna równoległa „drużyna" w osobnych sesjach: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (Agent Teams, v2.1.32+).

## Dwie warstwy: kopiowanie vs inteligencja
`install.sh` jest **deterministyczny** — kopiuje gotowe pliki 1:1, nic nie generuje (zero LLM, zero tokenów). To daje powtarzalność.

Dopasowanie do repo robi **`/bootstrap`** — skill uruchamiany w sesji Claude Code, który:
1. **czyta repo** (stack, standardy, konwencje, realne komendy test/lint),
2. **zadaje parę mądrych pytań** (tylko luki, których recon nie pokrył),
3. **generuje agentów dopasowanych do tego repo** (dokładne komendy, framework testowy, konwencje) + `CLAUDE.md`/`AGENTS.md` + szkielet `design-docs/`, i weryfikuje, że komendy działają.

Czyli: **install = mechaniczny baseline**, **/bootstrap = inteligentne dopasowanie w runtime**. Uruchom `/bootstrap` raz, zaraz po instalacji.

## Hardening (v2)
- **Stop bez nieskończonej pętli** — `gate.sh` respektuje `stop_hook_active`: po wymuszonej naprawie pozwala modelowi zakończyć, zamiast blokować w kółko.
- **Fail-closed bez python3** — gdy brak `python3`, `guard.sh` i tak blokuje najgroźniejsze wzorce (`rm -rf /`, `curl | sh`, edycję sekretów) zgrubnym fallbackiem w bashu.
- **Bariera gita (pre-commit)** — instalator dokłada `.git/hooks/pre-commit`: blokuje commit sekretów i nie wpuści czerwonych testów (działa też, gdy ktoś omija Claude Code).
- **CI** — `.github/workflows/quality.yml` uruchamia tę samą `verify.sh` na push/PR (dodaj setup-node/setup-python pod swój stack).
- **perf-auditor** — szósty agent: audyt wydajności (najpierw pomiar, potem hotspoty).

## Bezpieczeństwo
Bariery są dodatkową warstwą, nie gwarancją. Trzymaj `.claude/settings.local.json` poza gitem (instalator dodaje wpis do `.gitignore`). Przeglądaj diffy przed commitem — zgoda człowieka jest wpisana w zasady CLAUDE.md.
# agent-army
