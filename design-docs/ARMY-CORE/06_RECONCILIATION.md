# ARMY-CORE — rozliczenie implementacji

- Data przeglądu: 2026-10-04.
- Status całego planu: **wykonane przez nowszą architekturę profilu v2**.
- Ten dokument rozlicza pierwotne PR-y. Nie dodaje równoległego generatora ani nie zmienia aktywnej granicy źródeł opisanej w głównym `AGENTS.md`.

## Wynik PR po PR

| Etap | Status | Współczesny odpowiednik / dowód | Różnica wobec starego szkicu |
|---|---|---|---|
| PR 1 — deskryptory | **Wykonane z adaptacją** | `baseline/tools/*.yml` mają schemat i są sprawdzane przez `scripts/check.sh`; targety są też walidowane w macierzy `scripts/smoke.sh`. | Deskryptory nie sterują profilem v2. Target truth żyje w deterministycznym generatorze, a pliki YAML pozostają referencją migracyjną; nie są deklarowane jako aktywne źródło prawdy. |
| PR 2 — assembler | **Zastąpione i rozliczone** | `.apm/skills/bootstrap/bootstrap.py` materializuje kanoniczne kontrakty, stan profilu i kontrolowane adaptery. `scripts/smoke.sh` sprawdza profile, aktualizacje, ochronę specjalizacji i kolizje. | Repo ma jeden aktywny generator. `assemble.sh` nie jest drugim assemblerem; to wrapper zgodnościowy. Nie odtwarzamy starego bashowego pipeline’u, `.base` ani osobnych hooków. |
| PR 3 — wspólny core | **Wykonane** | `.apm/skills/bootstrap/baseline/core/agents/` jest źródłem wspólnych kontraktów ról; checker wymaga kompletnego standardu i przykładów. | Lokalny agent pozostaje kanonicznym `.agent-army/agents/*.agent`; adapter renderuje tylko tam, gdzie profil obsługuje native agents. OpenCode używa fallbacku głównej sesji. |
| PR 4 — uproszczenie bootstrapu | **Wykonane z adaptacją** | `.apm/skills/bootstrap/SKILL.md`, `bootstrap.py` i kanoniczne `baseline/AGENTS.md` rozdzielają mechaniczne generowanie od specjalizacji przez LLM. | LLM nie wywołuje osobnego assemblera: deterministyczny Python generator wykonuje bootstrap, a skill opisuje rekonesans, wybór ownership, specjalizację i weryfikację. |
| PR 5 — walidacja | **Wykonane** | `scripts/check.sh` (151 zaliczeń) i `scripts/smoke.sh` (175 zaliczeń) sprawdzają role, wszystkie targety, APM rendering, kolizje i incremental upgrade. | Testy są dostosowane do profilu v2. Nie twierdzą, że istnieje `assemble.sh` ani że wszystkie toolchainy materializują natywnych agentów. |

## Kryteria, które uznajemy za spełnione

- Istnieje jedno wspólne źródło kontraktów ról; pakiet nie kopiuje osobnych promptów dla każdego narzędzia.
- Bootstrap tworzy profile deterministycznie i nie zastępuje lokalnej specjalizacji ani zewnętrznie zarządzanych kontroli.
- Adaptery nie udają wspólnych możliwości: macierz smoke potwierdza natywne renderowanie albo jawny fallback.
- Kontrola strukturalna i smoke profili przechodzą bez rozluźniania asercji.

## Kryteria pierwotne, których nie przenosimy dosłownie

- „Każda wiedza o targetach wyłącznie w YAML” — zastąpione przez testowalny profil v2; aktywne YAML nie są deklarowane jako źródło generatora.
- „Assembler składa kompletne pliki w natywnych katalogach agentów każdego narzędzia” — zastąpione kontraktem kanonicznego źródła, stagingiem APM i jawnym fallbackiem dla OpenCode.
- „Bash assembler jako jedyna mechaniczna warstwa” — zastąpione istniejącym generatorem Python, który zarządza także migracją, ownership i wersjonowanym stanem.

Różnice są świadomą adaptacją do aktualnego repo, nie pozostawionymi zadaniami implementacyjnymi. Ewentualny powrót do active descriptors lub nowego adaptera wymaga osobnego konkretnego problemu i testu; nie wynika automatycznie z tego historycznego planu.
