# PR 2 — interaktywny architekt i trwały zapis rozmowy

## Cel, profil i stan

- Cel: cały plan uzgadniany małymi częściami przed implementacją.
- Status realizacji: **do testów**; implementacja w `architect.md` i fixture’y dialogu/wznowienia są zapisane; zależność: kontrakty PR 1 i [protokół](00_PROTOCOL.md).
- Profil: `strong/high`, bo zadanie dotyczy granic ról, interakcji i spójności kontraktów.
- Odczyt: architect, `/ship`, istniejące blueprinty oraz wzorce z firmowej Army do porównania.
- Zapis docelowy: architect i minimalne wspólne instrukcje baseline, przypadki dialogu.
- Zakaz: zmiana semantyki dawnych zgód, postępu ukończonych prac i źródeł projektów użytkownika.

## Zadania

- [ ] **2.1. Rozmowa zamiast ankiety i końcowego dużego bloku.** — **Status: do testów.**
  Włączyć sekwencję rozpoznanie → opcjonalny analityk → mapa tematów → decyzje → złożenie → review.
  Jedno główne pytanie naraz, z rekomendacją i konsekwencjami alternatyw; czekać na potrzebną odpowiedź.
  Zadawać pytania dotyczące intencji, nie odsyłać do użytkownika faktów możliwych do odczytania.
  Po każdej decyzji pokazać krótki przyrost, nie cały plan. Akceptować odpowiedzi swobodne i cofnięcie decyzji.
  Kompletny brief skraca dialog; drobne wybory można rozstrzygać samodzielnie w ramach celu.
  Przyjmować istniejący brief, PRD, roadmapę i research bez powtórnego wywiadu o potwierdzone decyzje.
  Weryfikować istotne nieaktualne źródła. Nie tworzyć tych artefaktów obowiązkowo dla drobnego zadania;
  do planu trafia wybrany wycinek roadmapy, nie automatycznie cały produkt.

- [ ] **2.2. Rozszerzyć kanoniczny wzorzec manifestu.** — **Status: do testów.**
  Dodać Planning Session zgodnie z protokołem: temat, pytanie, decyzje, dowody, rewizja i review.
  Aktualizować wzorzec w źródle architekta, a nie wprowadzać różne schematy w pojedynczych projektach.
  Zachować istniejące pliki PR, kontrakty zadań i Execution State.
  Na początku rozmowy wystarczy manifest roboczy; szczegółowe PR-y powstają wraz z uzgodnieniami.
  Brak osobnego task.md, nowego Checkpoint i zapisywania planu w `.agent-army/state.json`.

- [ ] **2.3. Wznowienie, korekty i review.** — **Status: do testów.**
  Wrócić do zapisanej decyzji bez rekonstrukcji transkryptu i powtarzania pytań.
  Po korekcie zrobić przegląd wpływu na zależne niewykonane zadania, aktualizować je w miejscu.
  Zwiększać rewizję przy merytorycznej zmianie; nie oznaczać starego review jako aktualnego.
  Wyniki review przekładać na konkretne poprawki; pytania do użytkownika tylko przy decyzjach zmieniających ustalenia.
  Ponowne review obejmuje istotnie zmieniony zakres i jego zależności, bez rytualnego audytu wszystkiego.

- [ ] **2.4. Usunąć sprzeczność zasad w samym planowaniu.** — **Status: do testów.**
  Plan ma definiować kryteria na podstawie celu i aktualnej polityki jakości projektu.
  Nie generować obowiązkowego RED dla researchu, dokumentacji ani refaktoru tylko dlatego, że szablon go zawiera.
  Przy bugfixie wymagać interpretacji odtworzenia błędu; przy refaktorze sprawdzenia zachowania przed i po.
  Nie usuwać wymaganych kontroli ani przebudowywać ogólnego executora TDD w tym etapie.
  Zachować przykłady formatów i trudnych przypadków, bez instrukcji ujawniania wewnętrznego rozumowania.

- [ ] **2.5. Wpleść sześć zasad w decyzje i wynik planowania.** — **Status: do testów.**
  Wykorzystać już zmienione instrukcje z [07](07_BASELINE_RULES.md), bez ponownego wdrażania tych samych reguł.
  Przed planem technicznym rozstrzygnąć reuse/build/no change; przy braku potrzeby implementacji zakończyć wynikiem.
  W zadaniach wskazać ryzyko i najtańszy wiarygodny check. Tester pozostaje właścicielem asercji i fault checks.
  Dla refaktoru zapisać punkty weryfikacji i recovery; dla zmienianych granic źródła kontraktu i konsumentów.
  Istniejący indeks utrzymuje docs-writer; nowy powstaje wyłącznie w uzasadnionym zakresie dokumentacji.
  Pokazać użytkownikowi istotne wybory, bez sześciopunktowej ankiety dla każdego małego zadania.

- [ ] **2.6. Obowiązkowy status w każdym przyszłym planie.** — **Status: do testów.**
  Zmienić Workflow i kanoniczne wzorce Output w źródłowym `architect.md`, aby już pierwszy zapis planu
  zawierał stan planowania, stan realizacji, bieżącą część, ostatni potwierdzony wynik i dokładny następny krok.
  Każda aktualizacja odświeża punkt wznowienia; sam zapis tekstu nie oznacza wykonania, testów ani review.
  Zapewnić czytelne rozróżnienie do zrobienia / w trakcie / do testów / do review / wykonane,
  z oczekiwaniem na decyzję lub blokadą i ich powodem. Uzgodnić widok bez dublowania kanonicznego Execution State.
  Wymaganie dotyczy wszystkich przyszłych blueprintów, nie tylko tego projektu i nie dopiero skilla army-status.

## Checkpoint implementacji

- Zmieniono workflow i zasady wyjścia w `.apm/skills/bootstrap/baseline/core/agents/architect.md`:
  jedno ważne pytanie na turę, krótki progress card, przyrostowe aktualizacje, odczyt checkpointu przy wznowieniu,
  wpływ korekt na zależne zadania, Planning Session od pierwszego zapisu i task status w każdym PR.
- Kanoniczny wzorzec zawiera etap rozmowy/review, decyzje, dowody, rewizję, status review, ostatnie działanie
  i dokładny następny krok. Test strategy rozróżnia feature/bugfix, zatwierdzony refaktor i pracę bez kodu.
- Dodano manualne fixture’y dialogu i wznowienia w `tests/fixtures/planning-roles/`; oczekiwane wyniki są osobnymi
  plikami oracle, których nie przekazuje się roli.
- **Weryfikacja:** `scripts/check.sh architect` — 17 zaliczone, 0 błędów, 0 ostrzeżeń; `git diff --check` — bez błędów.
- **Punkt zatrzymania:** wymagane próby wieloturowe i wznowienia nie zostały uruchomione; nie potwierdzono jeszcze
  jakości zachowania modelu ani poprawności zapisu w rzeczywistym adapterze.
- **Następny krok:** integracja bootstrap/ship jest zapisana w PR 3. W PR 4 wykonać blind runs
  dla PR 1–2 i dialogu/wznowienia oraz utrwalić raporty i baseline.

## Weryfikacja i odbiór

- `scripts/check.sh architect` oraz `scripts/check.sh --skills` dla dotkniętych instrukcji.
- Wieloturowa próba: pierwsza odpowiedź jest krótka, użytkownik rozstrzyga kolejne tematy i koryguje wcześniejszą decyzję.
- Przerwanie przed odpowiedzią i wznowienie z samym blueprintem w świeżej sesji.
- Gotowy dokument zawiera wszystkie potrzebne decyzje; rozmowa kończy się skrótem i odnośnikami.
- Plan pozostaje czytelny dla `/ship`, ale nie zostaje wykonany na skutek samego zakończenia dialogu.
- Nieaktualne review i ograniczenia dowodów są widoczne.
- Nowy plan od pierwszego zapisu pokazuje status i punkt wznowienia; aktualizacja zachowuje potwierdzony postęp.

Jeśli lokalne reguły wykonania wymagają kontroli sprzecznej z charakterem zadania, nazwać konflikt i potrzebną
decyzję; nie deklarować, że ten blueprint sam zmienił politykę istniejącego repo.
