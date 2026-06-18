---
name: ship
description: Pełny pipeline SDD z drużyną agentów — discovery/wywiad, blueprint w design-docs/, implementacja w strict TDD (Red→Green), audyt architektoniczny, bezpieczeństwo, dokumentacja. Wywołaj /ship, by przeprowadzić zadanie end-to-end z kontrolą jakości.
---
# /ship — pipeline SDD + Testing Trophy + strict TDD

## 0 · DISCOVERY & WYWIAD  → agent `architect` (Phase 0)
Najpierw zrozum projekt. `architect` klasyfikuje repo:
- **GREENFIELD** (brak AGENTS.md/CLAUDE.md, mało/brak kodu) → wywiad + **bootstrap** (AGENTS.md/CLAUDE.md, struktura katalogów, tooling testowy, szkielet `design-docs/`).
- **ISTNIEJĄCE** → recon (skan AGENTS.md/CLAUDE.md, detekcja stacku, lustrzane wzorce) + dopytanie tylko luk.
Pytania grupowane: biznes (co to za projekt, użytkownicy, MVP) · architektura (stack, styl, stan, dane) · testowanie (Testing Trophy, narzędzia, komendy) · NFR · proces (Task-ID, commity). **Nie twórz plików**, póki cel/stack/strategia testów/kryteria akceptacji nie są jasne. „Załóż i jedź" → spisuje ZAŁOŻENIA i kontynuuje.

### Wybór TRYBU WYKONANIA (zadaj zaraz po wywiadzie)
Zapytaj użytkownika, jak ma przebiegać realizacja, i zapisz wybór w `00_CORE_MANIFEST.md` (pole `Execution Mode`):
- **A) Autonomiczny** — zespół przeprowadza cały pipeline sam, bez przerywania. Zatrzymuje się TYLKO na twardych bramkach (hooki) i na końcu po zgodę na commit. Najszybszy, najmniej pytań.
- **B) Nadzorowany (checkpointy)** — orchestrator przerywa w kluczowych punktach, pokazuje stan i czeka na Twoje „ok / popraw":
  1. po **blueprintcie** (akceptacja planu),
  2. po napisaniu **testów RED** dla zadania — pokazuje testy, pytasz/poprawiasz, ZANIM powstanie implementacja,
  3. po **GREEN** każdego zadania/PR — możesz skorygować kierunek przed kolejnym,
  4. przed eskalacją/większą zmianą architektury.
  W tym trybie użytkownik może w każdej chwili przejąć ster i sprostować agenta; orchestrator wraca do planu po korekcie.
Domyślnie, jeśli nie wskazano: **B (nadzorowany)** dla zadań nietrywialnych, **A** dla drobnych. Tryb można zmienić w trakcie komendą „przełącz na autonomiczny/nadzorowany".

## 1 · BLUEPRINT  → `architect` (Phase 2)
Zapisuje `design-docs/[Task-ID]/00_CORE_MANIFEST.md` + `0X_PR_*.md` (1 PR = 1 plik). Zadania atomowe (Logic + UI/Endpoint + Test), z explicit ścieżkami testów i kontraktami API. Przy wielu opcjach — pyta o wybór.

## 2 · IMPLEMENTACJA per task — STRICT TDD `<auto_critic>` z udziałem `tester`
Dla KAŻDEGO zadania z blueprintu:
1. **`tester` pisze testy (RED)** — niezależnie, z kontraktu/kryteriów akceptacji (nie z implementacji), w wadze Testing Trophy. Uruchamia → **MUST FAIL (RED)** dla właściwego powodu.
2. **Sesja główna implementuje** najmniejszą zmianę realizującą zadanie (nie pisze testów na nowo).
3. **`tester` weryfikuje (GREEN)** — uruchamia ponownie → **MUST PASS**. Czerwone → diagnoza (bug vs test), napraw i powtórz. Nie wolno osłabiać asercji.
Bez batchowania bez weryfikacji. *Wyjątek:* dla trywialnych zadań sesja główna może zrobić cały cykl Red→Green inline, bez round-tripu do subagenta. Tak czy siak hooki `SubagentStop`/`Stop` egzekwują zieleń deterministycznie.
**W trybie Nadzorowanym:** po RED pokaż testy i czekaj na „ok/popraw" przed implementacją; po GREEN zatrzymaj się przed kolejnym zadaniem. **W Autonomicznym:** lecisz dalej bez przerw (poza bramkami hooków).

## 3 · REVIEW  → `code-reviewer` (Architectural Auditor)
Audyt gotowego diffu vs blueprint + standardy + cel biznesowy. Zapisuje raport w `design-docs/[Task-ID]/reviews/`. Werdykt:
- `CHANGES_REQUESTED` → wykonaj Micro-Blueprints i wróć do kroku 2.
- `ARCHITECTURAL_ALIGNMENT_NEEDED` → wróć do `architect` (course correction, aktualizacja blueprintów).
- `APPROVED` → dalej.

## 4 · SECURITY  → `security-auditor` (read-only)
Usuń znaleziska KRYTYCZNE/WYSOKIE. Kroki 3 i 4 to analizy read-only na gotowym diffie — można je puścić równolegle (fan-out).

## 5 · DOCS  → `docs-writer`

## 6 · PODSUMOWANIE
Diff, wynik testów, werdykt review, znaleziska bezpieczeństwa. Zaproponuj commit (Conventional Commits). NIE commituj bez mojej zgody.

Hooki (PreToolUse/PostToolUse/SubagentStop/Stop) działają niezależnie jako twarda, deterministyczna bariera — niezależnie od osądu agentów.
