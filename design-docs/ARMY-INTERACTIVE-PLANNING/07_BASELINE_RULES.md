# Sześć zasad włączonych do istniejących ról

- Data: 2026-10-02.
- Zakres: źródłowe instrukcje obecnych agentów i niezbędne doprecyzowania handoffu `/ship`.
- Nie obejmuje: wdrożenia nowych `planning-analyst` / `plan-reviewer`, dialogu z PR 2 ani aktualizacji zainstalowanych projektów.
- Zmiany pozostają lokalne; bez commita, wydania paczki i edycji firmowego pluginu.
- Użytkownik wyjaśnił, że pierwotnie chodziło o projekt w dokumentacji, a następnie wyraźnie zdecydował,
  żeby zachować również już wykonane zmiany instrukcji. Dalsze rozszerzenia są na etapie projektu.

## Właściciele

| Zasada | Właściciel | Konkretne zachowanie |
|---|---|---|
| Testowanie według ryzyka | tester | Opisuje awarię widoczną dla użytkownika, jej wpływ i prawdopodobieństwo; wybiera najtańszy wiarygodny test |
| Wiarygodność testów | tester | Sprawdza niezależność wyroczni; przy potrzebie wykonuje izolowany fault check z dowodem właściwej porażki |
| Odwracalny refaktor | architect, coder, code-reviewer | Plan weryfikowalnych kroków, kompatybilność i recovery; wykonanie bieżącego kroku; niezależna kontrola |
| Rejestr kontraktów | architect, code-reviewer, docs-writer | Wskazuje źródła i konsumentów; sprawdza zgodność; aktualizuje mały indeks z dostarczonych zmian |
| Higiena kontekstu | wspólne baseline AGENTS.md i architect | Ładuje źródła dla konkretnej decyzji, zachowuje reguły i sprzeczne dowody, nie kopiuje pełnych transkryptów |
| Budować / wykorzystać / nie zmieniać | architect, handoff ship | Ocena istniejących rozwiązań i kosztu utrzymania; możliwość zakończenia bez fikcyjnych zadań implementacyjnych |

## Ograniczenia celowe

- Mutation check nie jest obowiązkowy dla każdego zadania. Błąd składni lub środowiska nie dowodzi skuteczności asercji.
- Tester nie mutuje produkcyjnych plików roboczych; używa dozwolonego narzędzia w izolacji lub zgłasza potrzebny zakres.
- Po eksperymencie usuwa mutację i potwierdza wynik zwykłego sprawdzenia na niezmienionym obiekcie.
- Zatwierdzony refaktor zachowujący zachowanie może mieć zielone testy przed i po zmianie.
  Nowa funkcja i bugfix nie zyskują automatycznego wyjątku od wymaganej reprodukcji i weryfikacji.
- Rejestr kontraktów to indeks do autorytatywnych schematów, nie druga kopia pól. Preferujemy istniejący rejestr;
  brakujący `docs/reference/contract-surfaces.md` powstaje tylko w zatwierdzonym zakresie potrzeby.
- Review obejmuje staged, unstaged i istotne nowe pliki; raport zawiera wnioski i dowody, bez wymuszania toku rozumowania.
- Polecenie planowania nie jest zgodą na zakup, instalację, aktywację usługi czy wysłanie danych.

## Weryfikacja

Stosujemy istniejące `scripts/check.sh` oraz `scripts/smoke.sh`; nie dodajemy testów opartych tylko na
występowaniu nowego zdania w prompcie. Kontrole sprawdzają format, rendering i istniejące gwarancje migracji.
Przed tą zmianą checker: 123 passed, 0 failed, 0 warnings.
Po zmianie: checker 123 passed, 0 failed, 0 warnings; smoke 164 passed, 0 failed.
To potwierdza format i zgodność generatora; nie jest dowodem skuteczności LLM w zadaniu.
Realne próby zachowania i pilotaże pozostają opisane w [PR 4](04_PR_4_Validation.md).

## Co pozostaje do sprawdzenia

Poniższe kryteria są planem oceny, nie dowodami wykonanych prób ani nowymi zleceniami implementacji.

| Reguła | Próba odbioru |
|---|---|
| Ryzyko | Tester wybiera ochronę przed podwójną płatnością przed kolejnym testem banalnego pola; uzasadnia poziom i luki |
| Wiarygodność | Celowany mutant psujący zachowanie uruchamia właściwą asercję; błąd składni nie liczy się jako dowód; workspace pozostaje nienaruszony |
| Refaktor | Zielony baseline nie powoduje sztucznego RED; plan recovery ujawnia nieodwracalne skutki danych |
| Kontrakty | Zmiana pola wskazuje realnych konsumentów lub ich nieznajomość; indeks nie kopiuje schematu i jest aktualizowany |
| Kontekst | Agent odnajduje istotną sprzeczną regułę i aktualny plik bez kopiowania całego repo lub transkryptu |
| Wybór rozwiązania | Istniejąca funkcja spełniająca cel prowadzi do rekomendacji użycia jej, bez wymyślonego projektu |

Nie oznaczamy tych reguł jako kompletnych skilli test-plan, contract czy opportunity-map.
Granice pokrycia opisuje [porównanie katalogu](08_CATALOG_COMPARISON.md).

## Jak zmiany trafią do projektów

To zmiany baseline repo źródłowego. Istniejących wyspecjalizowanych agentów nie nadpisujemy ręcznie.
Po późniejszym wydaniu paczki aktualizacja i `/bootstrap` powinny pokazać różnice w istniejącym
Incremental Upgrade Review, zachowując kontrolę użytkownika nad zmianami jego lokalnych ról.
