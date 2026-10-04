# Kontrakty skilli Personal AI Toolkit

## Wspólne zachowanie

- Zaczynaj od celu i ograniczeń. Nie wymuszaj wewnętrznego toku rozumowania; zapisuj wnioski, dowody i krótkie uzasadnienie.
- Czytaj dostarczone źródła i istniejące artefakty przed pytaniem. Gdy decyzja zmienia zakres albo wynik, pokaż krótką rekomendację i zadaj jedno pytanie, po czym poczekaj na odpowiedź.
- Ustalaj proporcjonalną liczbę dokumentów, pytań i sprawdzeń. Nie twórz PRD, roadmapy, test runnera, katalogu `context/` ani trackerów tylko po to, by spełnić szablon.
- Rozdzielaj fakty, cytowane twierdzenia, inferencje i niewiadome. Każdy istotny wynik ma wskazywać źródło albo jawny brak źródła.
- Niewykonane sprawdzenie nie jest zaliczone. Składnia, obecność pliku i deklaracja agenta nie dowodzą zachowania.
- Każdy skill opisuje granice działania. Żadna analiza nie upoważnia sama z siebie do kontaktowania ludzi, zakupu, provisioningu, migracji, deployu ani zmiany danych.
- Nie prowadź drugiego postępu po przekazaniu wybranej pracy do istniejącego planu Army lub innego wskazanego systemu.

## Artefakty

Skill zapisuje wynik tylko wtedy, gdy użytkownik chce plik lub wskazał jego miejsce. Domyślnie aktualizuje istniejący artefakt zamiast tworzyć kopię. Jeśli docelowe miejsce nie jest znane i zapis ma znaczenie, najpierw o nie pyta.

Krótki brief decyzji lub research powinien wskazać: pytanie/cel, zakres, dowody i źródła, inferencje/niepewności, wynik, otwarte pytanie oraz następny krok.

Plan projektu ma manifest i pliki etapów tylko wtedy, gdy rozmiar pracy tego wymaga. Każde zadanie ma rezultat, kryterium akceptacji, proporcjonalną metodę weryfikacji i jawny status. Dozwolone statusy: `do zrobienia`, `w trakcie`, `do testów`, `do review`, `wykonane`, `czeka na decyzję`, `zablokowane`, `warunkowe`. Manifest zapisuje temat dialogu, decyzje, dowody, rewizję, wynik review, ostatnie potwierdzone działanie i dokładny następny krok. Po wznowieniu nie powtarza rozstrzygniętych pytań.

Wiedza bez sensownego automatycznego testu dostaje kryterium źródeł i kompletności. `none` oznacza brak obowiązku testów automatycznych, nie brak kontroli wyniku. Przy zatwierdzonym refaktorze passing baseline jest prawdziwym baseline; przy bugfixie nie zastępuje odtworzenia błędu.

## Kompetencje i przekazanie

| Skill | Wytwarza | Nie robi |
|---|---|---|
| `product-discovery` | Brief problemu, dowody, rekomendację i mały eksperyment | Nie wymyśla popytu, nie kontaktuje respondentów ani nie implementuje |
| `project-research` | Celowany raport źródeł, faktów, inferencji i braków | Nie pisze planu ani kodu |
| `project-plan` | Interaktywny, wersjonowalny plan z checkpointem i statusami | Nie implementuje ani nie traktuje review jako zgody na start |
| `plan-review` | Werdykt dla konkretnej rewizji, z cytowanymi blockerami lub bez uwag | Nie edytuje planu, nie uruchamia testów, nie udaje świeżego kontekstu |
| `test-strategy` | Priorytety ryzyk produktu i etapową strategię ochrony | Nie jest drugim executorem testerów |
| `infra-research` | Porównanie opcji oparte na aktualnych źródłach i założeniach kosztu | Nie tworzy kont ani zasobów |
| `deployment-readiness` | Raport lokalnych/targetowych sprawdzeń, blockerów i recovery | Nie deployuje ani nie migruje produkcji bez osobnego zlecenia |
| `project-starter` | Bezpieczny scaffold z raportem sprawdzeń | Nie czyści katalogu, nie wybiera produktu ani nie instaluje Army automatycznie |

Jeśli Army jest dostępna, przekazanie zawiera zatwierdzony brief/rewizję, wybrany zakres, źródła i decyzje. Użytkownik wybiera, czy uruchomić taki handoff. Przy wymaganiu niezależnego review bez świeżego kontekstu wynik jest ograniczony lub `INSUFFICIENT_EVIDENCE`, nigdy pozornie niezależny.
