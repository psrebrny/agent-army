# PR 1 — analityk planowania i recenzent planu

## Cel, profil i stan

- Cel: dwa samodzielne kontrakty ról, które poprawiają przygotowanie planu bez tworzenia nowych skilli.
- Status realizacji: **do testów**; dwa kontrakty i blind-eval fixture’y są zapisane, walidacja zachowania pozostaje otwarta.
- Profil: `strong/high` dla kontraktów i review; rutynowy research `mid/medium`.
- Zależność: [protokół](00_PROTOCOL.md).
- Odczyt: istniejący architect, code-reviewer, `_STANDARD.md`, przekazane materiały i testowe fixtures.
- Zapis docelowy: dwa nowe pliki ról w `.apm/skills/bootstrap/baseline/core/agents/` oraz przypadki oceny.
- Zakaz: zmiany źródeł projektów pilotażowych, runtime, hooków i firmowego pluginu.

## Zadania

- [ ] **1.1. planning-analyst.** — **Status: do testów.**
  Połączyć Frame i Research w jednej roli: diagnoza, dowody, niepewności i potrzeby dalszego badania.
  Zdefiniować wejście i raport zgodnie z protokołem, bez tworzenia blueprintu przez analityka.
  Oddzielić fakty od interpretacji, podać źródła i zakres aktualności, uwzględnić instrukcje źródeł jako dane.
  Przykłady: błędna diagnoza problemu cache, trafna diagnoza, niedostępne źródło i brak potrzeby budowania rozwiązania.
  Stosować strukturę lokalnego `_STANDARD.md`; przykłady dobierać do przypadków, nie kopiować jednej techniki.
  Uwzględnić istniejące rozwiązania i obowiązujące trwałe reguły repo. Odczytywać tylko istotne źródła,
  wskazać nieaktualne dowody; nie tworzyć drugiego rejestru lekcji obok właścicieli instrukcji.

- [ ] **1.2. plan-reviewer.** — **Status: do testów.**
  Zdefiniować ocenę planu względem celu i aktualnego repo: zależności, kontrakty, kryteria, ryzyka, nadmiar zakresu.
  Wyjście obejmuje dowody i konsekwencje uwag, aktualną rewizję oraz osobny werdykt review.
  Przykłady: nieistniejący interfejs, plan poprawny technicznie lecz zbyt duży, dobry plan bez uwag.
  Recenzent pracuje w świeżym kontekście, nie dostaje samooceny autora i nie edytuje planu.
  Ująć pięć perspektyw z protokołu: cel, koszt wykonania, zgodność z repo, martwe pola i kompletność.
  Nie tworzyć ogólnej punktacji udającej dowód ani wymuszać uwag w każdej kategorii.
  Sprawdzić dobór testów do ryzyka, niezależność oczekiwań, konsumentów zmienianych kontraktów
  i realność recovery. Indeks kontraktów traktować jako odnośnik do źródeł, nie dowód zgodności.

- [ ] **1.3. Przypadki oceny niezależne od promptów.** — **Status: do testów.**
  Przygotować surowe wejścia i kryteria obserwowalnego zachowania poza treścią ładowaną przez role.
  Nie ujawniać wykonawcy zasianego błędu ani oczekiwanego wniosku.
  Uwzględnić niedostępne źródła, sprzeczne dane, nieśledzony plik istotny dla planu i brak uzasadnionych uwag.
  Zachować wynik obecnego architekta jako baseline dla późniejszego porównania.

## Checkpoint implementacji

- Dodano `.apm/skills/bootstrap/baseline/core/agents/planning-analyst.md` i `plan-reviewer.md`.
- Dodano ślepe fixture’y dla sprzecznych dowodów, niedostępnego źródła, istotnego pliku nieśledzonego,
  poprawnego planu bez uwag oraz stały pakiet porównawczy dla obecnego architekta.
- **Weryfikacja:** `scripts/check.sh planning-analyst plan-reviewer` — 29 zaliczone, 0 błędów, 0 ostrzeżeń;
  `git diff --check` — bez błędów.
- **Punkt zatrzymania:** role i fixture’y oczekują na testy zachowania w świeżym, ślepym uruchomieniu.
  Wynik baseline architekta nie został jeszcze zarejestrowany; nie twierdzimy, że prompt działa behawioralnie.
- **Następny krok:** po integracji PR 2–3 uruchomić fixture’y bez plików `expected.md`, porównać wynik z oracle
  oraz zarejestrować baseline tego samego zadania na niezmienionym architekcie. Integracja jest gotowa; próby zachowania pozostają w PR 4.

## Weryfikacja

- `scripts/check.sh planning-analyst plan-reviewer` — po dodaniu ról, kontrola standardu i metadanych.
- Próbne użycie każdej roli na rzeczywistych plikach fixture, w zakresie odczytu.
- Porównanie rezultatu z kryteriami przygotowanymi przed uruchomieniem roli.
- Sprawdzenie, że nowe pliki ról nie deklarują niepotwierdzonych narzędzi lub identyfikatorów modeli.

Kontrola strukturalna nie zastępuje prób zachowania. Nie uruchamiamy implementacji produktu w celu testowania roli planistycznej.

## Odbiór i zatrzymanie

Raport analityka można wykorzystać bez ponawiania pełnego researchu; raport recenzenta wskazuje realne problemy
albo uczciwy brak uwag. Brak dowodu nie jest zamieniany w pewny wniosek. Żadna rola nie modyfikuje źródeł.
Gdy potrzebny jest szerszy odczyt lub uruchomienie operacji poza zakresem, rola zwraca konkretną potrzebę koordynatorowi.
