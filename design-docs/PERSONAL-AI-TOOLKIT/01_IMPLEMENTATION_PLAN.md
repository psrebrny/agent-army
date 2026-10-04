# Personal AI Toolkit — plan implementacji i checkpoint

- Status: **do testów**; osiem skilli V1 jest zainstalowanych w Codexie i przechodzi walidację formatu.
- Prywatne miejsce docelowe: `~/.codex/skills/` (Codex). Skille są globalne dla Codexa i nie należą do APM Army.
- Implementacja poniżej nie zawiera niezależnego testu zachowania ani pilotażu użytkowego.

## Etapy

| Etap | Status | Rezultat / kryterium |
|---|---|---|
| 1. Ustalić granice MVP | **wykonane** | Cztery skille planistyczne; cztery odrębne skille opcjonalne. Nie portujemy wszystkich 33 skilli ani nie duplikujemy executora Army. |
| 2. Napisać cztery skille MVP | **do testów** | `product-discovery`, `project-research`, `project-plan`, `plan-review` — niezależne wejścia/wyjścia, dialog po jednym pytaniu, źródła i checkpoint. |
| 3. Napisać opcjonalne workflow | **do testów** | `test-strategy`, `infra-research`, `deployment-readiness`, `project-starter`; każdy może działać samodzielnie bez Army. |
| 4. Zainstalować lokalnie | **wykonane** | Osiem nieistniejących katalogów skopiowano do `~/.codex/skills/`; nie nadpisano istniejących. Każdy katalog przeszedł walidator przed i po instalacji. |
| 5. Sprawdzić zachowanie | **do zrobienia** | Przeprowadzić małe próby discovery, wznowienia planu, odmowy nieuzasadnionego review, aktualnego źródła infra i konfliktu project-starter. Zapisać rzeczywisty wynik i poprawić tylko wykazane problemy. |
| 6. Odbiór prywatnego MVP | **do zrobienia** | Użytkownik zna sposób użycia; brak fałszywych twierdzeń o niezależności, badaniu rynku, testach lub gotowości deployu. |

## Dostarczone skille

| Skill | Odpowiedzialność | Status źródła |
|---|---|---|
| `product-discovery` | Shape/Frame: dowody problemu, opcje, najmniejszy eksperyment | walidacja formatu zaliczona; zachowanie do testów |
| `project-research` | Celowane repozytorium i źródła z jawną niepewnością | walidacja formatu zaliczona; zachowanie do testów |
| `project-plan` | Samodzielny plan z pytaniami po jednym, statusem zadań i wznowieniem | walidacja formatu zaliczona; zachowanie do testów |
| `plan-review` | Read-only review rewizji, ograniczenie świeżego kontekstu | walidacja formatu zaliczona; zachowanie do testów |
| `test-strategy` | Ryzyka produktu → aktualna ochrona → etapowa mapa luk | walidacja formatu zaliczona; zachowanie do testów |
| `infra-research` | Ograniczone porównanie infrastruktury na źródłach bieżących | walidacja formatu zaliczona; zachowanie do testów |
| `deployment-readiness` | Rzeczywiste sprawdzenia lokalne i targetowe oraz blokery | walidacja formatu zaliczona; zachowanie do testów |
| `project-starter` | Bezpieczny scaffold i weryfikacja oficjalnego startera | walidacja formatu zaliczona; zachowanie do testów |

## Zapisany punkt wznowienia

Osiem skilli znajduje się w `~/.codex/skills/`: `product-discovery`, `project-research`, `project-plan`, `plan-review`, `test-strategy`, `infra-research`, `deployment-readiness`, `project-starter`. Wszystkie przechodzą `quick_validate.py`; przed usunięciem stagingu sprawdzono zgodność kopii. **Następny krok:** w świeżej sesji sprawdzić wywołanie i uruchomić pilotaże zachowania. Nie oznaczać samego renderingu jako sukcesu.
