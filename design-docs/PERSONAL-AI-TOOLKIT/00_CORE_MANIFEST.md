# Personal AI Toolkit — prywatne, niezależne skille

- Data wznowienia projektu: 2026-10-04.
- Status: **V1 zainstalowane; testy zachowania pozostają do wykonania**. Osiem skilli jest w `~/.codex/skills/` i przechodzi walidator; nie są częścią pakietu APM Agent Army.
- Docelowe miejsce: globalne skille Codexa `~/.codex/skills/<skill-name>`. Ten format to zwykłe `SKILL.md`; ewentualna adaptacja do innych narzędzi jest osobnym krokiem.
- Użytkowanie samodzielne: żaden skill nie wymaga Army. Gdy repo już używa Army, `project-plan` kieruje do jej architekta zamiast zakładać drugi rejestr postępu. Handoff pozostaje opcjonalny.
- Powiązane dokumenty: [kontrakty](00_CONTRACTS.md), [użycie](10_USAGE.md), [kolejność implementacji i status](01_IMPLEMENTATION_PLAN.md).

## Cel i granice

Toolkit obsługuje prywatne projekty: aplikacje, PoC, automatyzacje i pracę z wiedzą. Skille są rozłączne; uruchamiaj tylko ten, który odpowiada aktualnej potrzebie. Przekazują kontekst przez istniejące pliki i decyzje, nie przez ukrytą pamięć ani obowiązkową maszynę stanów.

V1 zawiera cztery skille planistyczne: `product-discovery` (Shape + Frame), `project-research`, `project-plan` i `plan-review`. Dodatkowe, niezależne workflow z materiałów 10x to `test-strategy`, `infra-research`, `deployment-readiness` i `project-starter`.

Nie portujemy wszystkich 33 pozycji katalogu. Oddzielne `project-check` oraz `status-close` nie wchodzą do V1: rozpoznanie i checkpoint mieszczą się w `project-research`/`project-plan`, a drugi system archiwizacji konkurowałby z plikami projektu i Army. Osobny `PRD`, roadmapa, skill CI, deploy executor i katalog starterów też nie powstają bez powtarzalnej potrzeby.

## Aktualny checkpoint

- Cztery skille V1 i cztery opcjonalne skille V1 są napisane i przechodzą `quick_validate.py`.
- Osiem katalogów skopiowano bez nadpisywania istniejących; zawartość docelowa odpowiada zwalidowanym źródłom, a wszystkie osiem przechodzi `quick_validate.py` także z katalogu globalnego.
- Walidacja struktury nie potwierdza zachowania. Próby na realnych zadaniach pozostają otwarte i nie są oznaczone jako zaliczone.
- Następny krok: sprawdzić skill discovery/wywołanie w świeżej sesji Codexa i wykonać krótkie pilotaże. Zmiany deploymentu, uruchomienie infrastruktury ani zapisy do second braina nie są autoryzowane samym istnieniem skilla.
