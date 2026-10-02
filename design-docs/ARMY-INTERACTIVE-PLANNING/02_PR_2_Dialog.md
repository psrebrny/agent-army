# PR 2 — interaktywny architekt i trwały zapis rozmowy

## Cel, profil i stan

- Cel: cały plan uzgadniany małymi częściami przed implementacją.
- Status: `planned`; zależność: PR 1 i [protokół](00_PROTOCOL.md).
- Profil: `strong/high`, bo zadanie dotyczy granic ról, interakcji i spójności kontraktów.
- Odczyt: architect, `/ship`, istniejące blueprinty oraz wzorce z firmowej Army do porównania.
- Zapis docelowy: architect i minimalne wspólne instrukcje baseline, przypadki dialogu.
- Zakaz: zmiana semantyki dawnych zgód, postępu ukończonych prac i źródeł projektów użytkownika.

## Zadania

- [ ] **2.1. Rozmowa zamiast ankiety i końcowego dużego bloku.**
  Włączyć sekwencję rozpoznanie → opcjonalny analityk → mapa tematów → decyzje → złożenie → review.
  Jedno główne pytanie naraz, z rekomendacją i konsekwencjami alternatyw; czekać na potrzebną odpowiedź.
  Zadawać pytania dotyczące intencji, nie odsyłać do użytkownika faktów możliwych do odczytania.
  Po każdej decyzji pokazać krótki przyrost, nie cały plan. Akceptować odpowiedzi swobodne i cofnięcie decyzji.
  Kompletny brief skraca dialog; drobne wybory można rozstrzygać samodzielnie w ramach celu.
  Przyjmować istniejący brief, PRD, roadmapę i research bez powtórnego wywiadu o potwierdzone decyzje.
  Weryfikować istotne nieaktualne źródła. Nie tworzyć tych artefaktów obowiązkowo dla drobnego zadania;
  do planu trafia wybrany wycinek roadmapy, nie automatycznie cały produkt.

- [ ] **2.2. Rozszerzyć kanoniczny wzorzec manifestu.**
  Dodać Planning Session zgodnie z protokołem: temat, pytanie, decyzje, dowody, rewizja i review.
  Aktualizować wzorzec w źródle architekta, a nie wprowadzać różne schematy w pojedynczych projektach.
  Zachować istniejące pliki PR, kontrakty zadań i Execution State.
  Na początku rozmowy wystarczy manifest roboczy; szczegółowe PR-y powstają wraz z uzgodnieniami.
  Brak osobnego task.md, nowego Checkpoint i zapisywania planu w `.agent-army/state.json`.

- [ ] **2.3. Wznowienie, korekty i review.**
  Wrócić do zapisanej decyzji bez rekonstrukcji transkryptu i powtarzania pytań.
  Po korekcie zrobić przegląd wpływu na zależne niewykonane zadania, aktualizować je w miejscu.
  Zwiększać rewizję przy merytorycznej zmianie; nie oznaczać starego review jako aktualnego.
  Wyniki review przekładać na konkretne poprawki; pytania do użytkownika tylko przy decyzjach zmieniających ustalenia.
  Ponowne review obejmuje istotnie zmieniony zakres i jego zależności, bez rytualnego audytu wszystkiego.

- [ ] **2.4. Usunąć sprzeczność zasad w samym planowaniu.**
  Plan ma definiować kryteria na podstawie celu i aktualnej polityki jakości projektu.
  Nie generować obowiązkowego RED dla researchu, dokumentacji ani refaktoru tylko dlatego, że szablon go zawiera.
  Przy bugfixie wymagać interpretacji odtworzenia błędu; przy refaktorze sprawdzenia zachowania przed i po.
  Nie usuwać wymaganych kontroli ani przebudowywać ogólnego executora TDD w tym etapie.
  Zachować przykłady formatów i trudnych przypadków, bez instrukcji ujawniania wewnętrznego rozumowania.

- [ ] **2.5. Wpleść sześć zasad w decyzje i wynik planowania.**
  Wykorzystać już zmienione instrukcje z [07](07_BASELINE_RULES.md), bez ponownego wdrażania tych samych reguł.
  Przed planem technicznym rozstrzygnąć reuse/build/no change; przy braku potrzeby implementacji zakończyć wynikiem.
  W zadaniach wskazać ryzyko i najtańszy wiarygodny check. Tester pozostaje właścicielem asercji i fault checks.
  Dla refaktoru zapisać punkty weryfikacji i recovery; dla zmienianych granic źródła kontraktu i konsumentów.
  Istniejący indeks utrzymuje docs-writer; nowy powstaje wyłącznie w uzasadnionym zakresie dokumentacji.
  Pokazać użytkownikowi istotne wybory, bez sześciopunktowej ankiety dla każdego małego zadania.

## Weryfikacja i odbiór

- `scripts/check.sh architect` oraz `scripts/check.sh --skills` dla dotkniętych instrukcji.
- Wieloturowa próba: pierwsza odpowiedź jest krótka, użytkownik rozstrzyga kolejne tematy i koryguje wcześniejszą decyzję.
- Przerwanie przed odpowiedzią i wznowienie z samym blueprintem w świeżej sesji.
- Gotowy dokument zawiera wszystkie potrzebne decyzje; rozmowa kończy się skrótem i odnośnikami.
- Plan pozostaje czytelny dla `/ship`, ale nie zostaje wykonany na skutek samego zakończenia dialogu.
- Nieaktualne review i ograniczenia dowodów są widoczne.

Jeśli lokalne reguły wykonania wymagają kontroli sprzecznej z charakterem zadania, nazwać konflikt i potrzebną
decyzję; nie deklarować, że ten blueprint sam zmienił politykę istniejącego repo.
