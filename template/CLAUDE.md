# CLAUDE.md — pamięć projektu

> Wypełnij sekcje [w nawiasach]. Trzymaj plik < 200 linii (ładuje się przy KAŻDEJ wiadomości).
> Szczegóły przenoś do `.claude/skills/` (ładują się na żądanie) i `.claude/rules/`.

## Projekt
[Jednozdaniowy opis. Stack/język: … . Najważniejsze katalogi: … .]

## Uruchomienie / testy / lint
[Komendy build/test/lint. Jeśli zostawisz puste — hooki wykrywają je automatycznie:
npm/pnpm/yarn · pytest/ruff · go · cargo.]

## Konwencje
- [Styl, nazewnictwo, wzorce architektoniczne. Czego unikać.]
- Małe, atomowe zmiany. Najpierw plan, potem kod.
- Commity w formacie Conventional Commits.
- SDD: plan jako pliki w `design-docs/[Task-ID]/`, nie tylko w czacie.
- Testy: Testing Trophy (E2E/integracja > unit), zachowanie nie implementacja.
- Strict TDD: Red → Green dla każdego zadania (auto-critic lock).

## Punkt wejścia, orchestrator i drużyna
**Punkt wejścia → `/bootstrap`** (uruchom RAZ, po instalacji): czyta repo (analiza kodu), zadaje pytania, ogląda szablony i **tworzy/specjalizuje całą drużynę pod to repo** zgodnie z `.claude/agents/_STANDARD.md`. Greenfield → wywiad + bootstrap fundamentów.

**Orchestrator → sesja główna prowadzona przez `/ship`**: to ona rozmawia z Tobą, deleguje do subagentów, pilnuje trybu (Autonomiczny/Nadzorowany) i NIE obchodzi hooków. (Subagent nie może prowadzić interaktywnego wywiadu, więc punkt wejścia i orchestrator to skille sesji głównej, nie subagenci.)

**Drużyna (`.claude/agents`)** — deleguj wg pola `description`; jakość pilnuje `_STANDARD.md`:
- `architect` — wywiad (greenfield/existing) + blueprint w `design-docs/` (nie koduje)
- `tester` — niezależny executor TDD: pisze testy RED z kontraktu, weryfikuje GREEN
- `code-reviewer` — Architectural Auditor: audyt diffu vs blueprint+biznes, raport w `design-docs/reviews/`
- `security-auditor` — audyt bezpieczeństwa (tylko odczyt)
- `perf-auditor` — audyt wydajności, „measure first" (tylko odczyt)
- `docs-writer` — aktualizacja dokumentacji

**Tworzenie kolejnych agentów → `/new-agent`** (zawsze do `_STANDARD.md`).

## Bariery (hooki — działają automatycznie, deterministycznie)
- **PreToolUse** → blokuje edycję sekretów (`.env`, klucze) i niebezpieczne komendy bash.
- **PostToolUse** → auto-format po każdej zmianie pliku.
- **SubagentStop** → lint + testy po pracy `tester`/`code-reviewer`.
- **Stop** → bramka jakości: nie kończę, dopóki lint/testy nie są zielone.
Nie obchodź barier. Jeśli coś blokuje słusznie — napraw przyczynę.

## Zasady twarde
- NIE commituj bez zgody człowieka.
- NIE wyłączaj ani nie osłabiaj testów/hooków, żeby „przejść".
- NIE wklejaj sekretów do kodu ani promptów.
- Niepewność → zadaj pytanie, nie zgaduj.
