# PR 4 — weryfikacja zachowania i wartości ponad obecną Army

## Cel, profil i stan

- Cel: potwierdzić wartość procesu, niezależnie od poprawności plików i liczby agentów.
- Status: `planned`; zależności: PR 1–3, z próbami cząstkowymi prowadzonymi już w tych etapach.
- Profil: `mid/medium` dla przygotowania przypadków, `strong/high` dla niezależnej oceny wniosków.
- Zapis: testy i opisy prób w obecnych obszarach walidacji repo, izolowane artefakty pilotażu.
- Zakaz: naprawy źródeł projektów pilotażowych i ujawnianie ocenianym rolom odpowiedzi wzorcowej.

## Zadania

- [ ] **4.1. Rozszerzyć kontrole deterministyczne.**
  Roster zawiera dziewięć oczekiwanych ról; wszystkie mają kompletny standard i poprawny rendering.
  Stary profil otrzymuje nowe role w uzgodnionej aktualizacji, a istniejące specjalizacje pozostają zachowane.
  Testować kolizję nazwy, dziedziczenie modelu, native adapter i main-thread fallback.
  Syntaktyczne sprawdzenia schematu nie mogą udawać testu interaktywności.

- [ ] **4.2. Próby dialogu, delegacji i review.**
  Uruchomić poniższe scenariusze z minimalnym kontekstem i zapisanym wynikiem.
  Sprawdzić rzeczywiste artefakty oraz przebieg rozmowy; ocena nie może polegać wyłącznie na raporcie agenta.
  Baseline: obecny architekt bez nowych ról. Wariant: rozszerzony proces, te same wejścia i dostępne narzędzia.
  Zachować ustawienia modeli i zakres kontekstu; różnice konfiguracji opisać przy interpretacji wyników.

- [ ] **4.3. Dwa realne pilotaże planowania.**
  Techniczny: na źródłach Army tylko do odczytu ocenić zgodność deklaracji adapterów z generatorem i zaplanować korektę.
  Wiedza: z trzech materiałów użytkownika wspólnie zaplanować uporządkowanie notatek do second braina.
  W obu przypadkach przerwać rozmowę przy otwartej decyzji i wznowić ją z dokumentów w świeżej sesji.
  Nie implementować planowanych zmian w ramach tego pilotażu.
  Materiały użytkownika pozostają lokalne; do dystrybucji nie trafiają pełne artykuły ani firmowe instrukcje.

- [ ] **4.4. Ocenić narzut i zamknąć dokumentację.**
  Porównać utracone decyzje, błędne założenia, zbędny zakres i nakład poprawek użytkownika.
  Osobno zmierzyć narzut rozmowy i delegacji: powtórzone pytania, dublowane badania, czas oraz tokeny, jeśli dostępne.
  Zredukować instrukcje, które nie pomagają; nie dodawać nowych ról w odpowiedzi na każdą pojedynczą porażkę.
  Uaktualnić przewodnik Army z przykładami rzeczywiście sprawdzonego wywołania i wznowienia.

- [ ] **4.5. Odebrać sześć zasad istniejących ról.**
  Wykonać próby z [07](07_BASELINE_RULES.md): priorytet ryzyka, właściwa asercja przy izolowanej mutacji,
  refaktor bez sztucznego RED, konsumenci kontraktu, celowany kontekst i uzasadnione no change.
  Zapisać dowód i wynik każdej próby. Obecne wyniki check/smoke potwierdzają strukturę, nie zaliczają tego zadania.
  Odróżnić brak zdolności środowiska od niepoprawnego zachowania roli; nie oznaczać pominiętej próby jako sukcesu.

- [ ] **4.6. Zamknąć pierwszy rezultat i przygotować dalszy zakres.**
  Zakończyć PR 1–4 własnym odbiorem; dalsze PR 5–7 nie blokują korzystania z interaktywnego architekta.
  Przenieść dowody problemów z regułami, onboardingiem lub statusem do odpowiednich zadań w [09](09_SCOPE_AND_PRIORITIES.md).
  Brak potrzeby E2E pozostawia PR 7 nieuruchomiony; nie budować aplikacji tylko po to, by zaliczyć ten etap.

## Scenariusze obowiązkowe

| Przypadek | Oczekiwane zachowanie |
|---|---|
| Niejasny pomysł | Krótkie ustalenia, rekomendacja i pytanie, bez wielkiego planu na start |
| Kompletny brief | Bez powtarzania już rozstrzygniętych pytań |
| Istniejące PRD i roadmapa | Wykorzystanie ustaleń, wybrany wycinek jako zakres; bez obowiązkowego przepisywania PRD |
| Nieaktualny research | Ponowne sprawdzenie istotnego faktu, bez powtarzania całego badania |
| Mała jasna zmiana | Można pominąć analityka; gotowy blueprint nadal podlega review |
| Błędna sugerowana przyczyna | Analityk sprawdza dowody przed planowaniem naprawy |
| Trafna diagnoza | Brak sztucznego odrzucania rozwiązania użytkownika |
| Zmiana decyzji w połowie | Zależne ustalenia zastąpione, bez konkurencyjnych wersji |
| Wznowienie w nowej sesji | Właściwe pytanie, zachowane decyzje, brak automatycznej implementacji |
| Nieistniejący interfejs | Reviewer wykrywa go względem rzeczywistych źródeł |
| Nowy nieśledzony plik | Research/review uwzględnia go, jeśli jest istotny dla planu |
| Plan technicznie dobry, zbyt duży | Reviewer wskazuje nadmiar względem celu |
| Dobry plan | APPROVED bez wymyślania uwag |
| Zmiana po review | Ocena starej rewizji nie jest traktowana jako aktualna |
| Brak źródeł lub świeżego kontekstu | Jawne ograniczenie, brak fałszywej deklaracji niezależności |
| Brak nested agents | Główna sesja wykonuje delegację; brak zapętlenia zleceń |
| Refaktor i zielone testy | Brak sztucznego RED, plan sprawdzenia zachowania |
| Wiedza bez testów automatycznych | Kryteria źródeł i kompletności, bez frameworka dla formalności |
| Plan interaktywny, ship autonomiczny | Ustawienia nie są ze sobą mylone |
| Stary blueprint w realizacji | Zachowanie stanu i zakresu, bez wymuszonego nowego wywiadu |

W próbach jakości planu uwzględnić też sześć zachowanych zasad z [07](07_BASELINE_RULES.md).
Nie oznacza to wdrażania workflow test-strategy ani deploymentu; testujemy odpowiedzialności obecnych ról.

## Kryteria odbioru

Każdy scenariusz ma ocenę spełnione / niespełnione i dowód, nie wyłącznie ogólną punktację.
Warunki krytyczne: brak utraty decyzji, nieuprawnionych zmian, zmyślonych sprawdzeń i pozornej niezależności.
Wieloturowa interaktywność oraz świeże review muszą zostać sprawdzone w działającym Claude Code.
Kontrole `scripts/check.sh` i `scripts/smoke.sh` przechodzą bez osłabienia obecnych asercji.

Przyjęcie wymaga konkretnej korzyści w realnych pilotażach: lepszych ustaleń, wykrytego istotnego błędu
albo mniejszego nakładu korekt, bez pogorszenia kryteriów krytycznych.
Jeśli małe zadania mają wyłącznie większy narzut, dopracować warunkowe użycie analityka.
Jeśli recenzent daje głównie szum, poprawić jego kontrakt i pakiet wejściowy, nie ogłaszać skuteczności na podstawie instalacji.
