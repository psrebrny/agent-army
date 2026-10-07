# Doradcy produktowi dla Agent Army — plan wdrożenia

- **Data zapisu:** 2026-10-07
- **Status:** do zrobienia — zapisane na później, implementacja nierozpoczęta
- **Rewizja:** 1
- **Cel:** siedem niezależnych skilli pomagających solo twórcy lub małemu zespołowi przejść od pomysłu do działającego, sprzedawanego produktu.
- **Zakres bieżącego polecenia:** zachować uzgodniony plan; nie rozpoczynać wdrożenia.

## Planning Session

- **Stage:** saved_for_later
- **Plan revision:** 1
- **Current topic:** zapis planu po rozmowie o zakresie i sposobie pracy doradców
- **Confirmed decisions:** solo i mały zespół; zapis po istotnych ustaleniach; pełna integracja pakietu wraz z koniecznymi zmianami poza `.apm/`
- **Pending decision:** brak decyzji potrzebnej do samego zapisu; wykonanie wymaga późniejszego polecenia użytkownika
- **Remaining topics:** nowe pomysły zapowiedziane przez użytkownika nie zostały jeszcze przedstawione i nie należą do tej rewizji
- **Review state:** nie przeprowadzono niezależnego przeglądu planu
- **Last confirmed action:** użytkownik poprosił o zapis planu w `design-docs` na później
- **Next action:** po powrocie odczytać ten plan, sprawdzić zmiany repo i ewentualne nowe ustalenia; przed wdrożeniem przeprowadzić przegląd i ustalić zakres wykonania

## 1. Cel i przyjęte decyzje

- Skille należą do tego samego pakietu, ale nie są obowiązkowymi etapami `/ship`.
- Działają po instalacji pakietu, również bez `/bootstrap` i historycznych `design-docs`.
- Domyślnie prowadzą rozmowę: krótka rekomendacja, uzasadnienie i jedno istotne pytanie naraz.
- Automatycznie zapisują istotne ustalenia, bez transkrypcji rozmów i tworzenia pustej dokumentacji.
- Instrukcje źródłowe pozostają po angielsku; rozmowa i tworzone dokumenty używają języka użytkownika lub istniejącej dokumentacji projektu.
- Zakres obejmuje uzgodniony wyjątek od ograniczenia do `.apm/`: manifest, główną dokumentację oraz potrzebne zmiany w istniejących testach. Użytkownik wybrał „Pełna integracja”.
- Istniejące usunięcia starych planów pozostają nietknięte. Wdrożenie nie obejmuje commita, publikacji pakietu ani automatycznego usuwania kolejnych planów.

## 2. Skille i ich rezultaty

Każdy skill otrzyma własny `SKILL.md`, cienki wrapper komendy, opis zastosowania, granice odpowiedzialności, zwięzły format wyniku oraz minimum dwa różne przykłady użycia. Pierwsza wersja będzie samowystarczalna, bez nowych zależności, osobnego systemu agentów i obowiązkowych integracji.

Domyślne dokumenty powstają w `docs/product/` w docelowym repozytorium. Istniejący dokument pełniący tę samą funkcję ma pierwszeństwo.

| Skill | Zachowanie | Domyślny artefakt |
|---|---|---|
| `/product-strategy` | Krytyczna rozmowa o odbiorcy, problemie, przewadze, funkcjach i monetyzacji. Porównuje perspektywę klienta, produktu, dystrybucji i finansów; wskazuje konflikty i proponuje najmniejszy następny krok. | `brief.md`: bieżący opis produktu, priorytety, decyzje i niewiadome |
| `/business-case` | Prowadzi osobę bez wiedzy finansowej przez ocenę opłacalności. Dobiera model do produktu i tłumaczy pojęcia w momencie ich użycia. | `business-case.md`: założenia, obliczenia, scenariusze i warunkowa rekomendacja |
| `/validate-product` | Prowadzi od hipotezy przez dobór uczestników i eksperymentu do materiałów, pomiaru i interpretacji rzeczywistych wyników. | `validation.md`: eksperymenty, progi sukcesu/przerwania, wyniki i decyzje |
| `/go-to-market` | Dobiera odbiorców, ofertę i płatne lub bezpłatne kanały. Przygotowuje konkretną kampanię: komunikaty, teksty, briefy kreacji, harmonogram, budżet i pomiar. | `go-to-market.md` oraz potrzebne materiały kampanii |
| `/ux-review` | Analizuje zrozumienie oferty, onboarding, pierwszy użyteczny rezultat, zakup, błędy i dostępność kluczowych ścieżek. | `ux-review.md`: problemy powiązane z dowodami, priorytety i poprawki |
| `/legal-review` | Ustala właściwe jurysdykcje, B2B/B2C i charakter produktu; ocenia mające zastosowanie obszary prawne na podstawie aktualnych źródeł. | `legal-review.md`: zastosowanie przepisów, ustalenia, źródła, działania i pytania |
| `/launch-readiness` | Sprawdza gotowość produktu, zakupu, wsparcia i eksploatacji; korzysta z istniejących audytów i wyników testów. | `launch-readiness.md`: potwierdzone elementy, blokady, niewiadome i następne działania |

### Business case

Uwzględnia inwestycję początkową, koszty stałe i zmienne, pozyskanie klienta oraz czas założyciela. Rozdziela GMV, przychód, marżę i zysk; wydatki gotówkowe od kosztu czasu. Pokazuje trzy scenariusze, próg rentowności, potrzeby gotówkowe i wrażliwość na kluczowe założenia. ROI wymaga jawnego horyzontu i definicji kosztu inwestycji. Brak danych o retencji nie może prowadzić do pozornie wiarygodnego LTV. Obliczenia mają jawne wzory, jednostki i okresy.

### Legal review

Obejmuje prywatność, przepływy danych, tracking i marketing, warunki świadczenia usług, subskrypcje, prawa konsumenta oraz licencje. Dostępność, regulacje sektorowe i obowiązki dotyczące AI sprawdza wtedy, gdy dotyczą produktu. Każde istotne ustalenie wskazuje źródło, datę sprawdzenia i podstawę zastosowania; bez dostępu do aktualnych źródeł wynik pozostaje częściowy. Skill wskazuje konkretne sprawy wymagające prawnika lub księgowego, zamiast deklarować pełną zgodność.

### Launch readiness

Obejmuje także nieudaną płatność, anulowanie usługi, kontakt, monitoring, dowody odtwarzania po awarii oraz podstawowy pomiar aktywacji, powrotów i konwersji. Nie powiela audytora bezpieczeństwa ani nie przedstawia nieprzetestowanego backupu jako sprawnego odzyskiwania.

## 3. Rozmowa, pamięć i połączenie z kodowaniem

- Każdy doradca zaczyna od aktualnego opisu produktu, odpowiedniego artefaktu, istotnych ADR-ów i potrzebnych fragmentów repo. Nie skanuje całego projektu bez powodu.
- Dokument odróżnia fakty i źródła od założeń, propozycji i potwierdzonych decyzji. Kończy się bieżącym tematem, otwartym pytaniem i następnym krokiem.
- Po wznowieniu skill kontynuuje zapisany temat; nie powtarza rozstrzygniętych pytań. Sprzeczność z aktualnymi dowodami zgłasza i wyjaśnia.
- Strategia aktualizuje opis produktu, pozostali doradcy własne dokumenty. Mogą proponować zmianę ustalonej strategii, ale nie zapisują jej jako zaakceptowanej bez podstawy.
- Inspiracje znanymi przedsiębiorcami przekładamy na konkretne perspektywy analizy. Nie tworzymy fikcyjnych cytatów ani „panelu ekspertów” udającego dowód popytu.
- Walidacja odróżnia przygotowany eksperyment od przeprowadzonego. UX odróżnia ocenę ekspercką od badania użytkowników.
- Research korzysta z dostępnych narzędzi i materiałów; brak integracji nie zatrzymuje rozmowy, ale ograniczenia wyniku są jawne. Żaden skill nie zakłada obecności konkretnego płatnego narzędzia.
- Przygotowanie materiałów nie uruchamia reklam, publikacji, kontaktowania respondentów, zakupów ani wdrożenia. Takie działania wymagają odpowiedniego polecenia użytkownika.

### Lekkie ADR-y

Rozszerzyć istniejącego `docs-writer` i etap dokumentacji `/ship`. Dla istotnej decyzji zapisać kontekst, wybór, potwierdzone uzasadnienie, rozważane alternatywy, konsekwencje, datę i status. Wskazać aktualną implementację, gdy pomaga to czytelnikowi.

Dokumentowanie odbywa się po zweryfikowaniu zmiany, jeszcze przed commitem; nie może wymagać wcześniejszego merge'a ani przedstawiać lokalnej implementacji jako opublikowanej. Zwykła poprawka nie wymaga ADR-a. Aktywne plany nadal służą do wznawiania `/ship`, ale trwałe uzasadnienie decyzji nie może zależeć wyłącznie od nich.

## 4. Integracja i kolejność prac

### Zadanie 1 — siedem skilli i wrappery

- **Status:** do zrobienia
- **Zmiana:** dodać źródła w `.apm/skills/<name>/SKILL.md` i wrappery w `.apm/commands/<name>.md`. Ujednolicić zasady rozmowy i zapisu przy zachowaniu samowystarczalności każdego skilla.
- **Kryterium odbioru:** każdy skill ma wyraźny zakres, artefakt i przykład rozpoczęcia oraz wznowienia pracy; wrapper wskazuje instalowaną ścieżkę `.agents/skills/<name>/SKILL.md`.
- **Weryfikacja:** kontrola metadanych i wrapperów oraz scenariusze zachowania z sekcji 5.

### Zadanie 2 — ADR-y i przekazanie do wykonania

- **Status:** do zrobienia
- **Zmiana:** doprecyzować `.apm/skills/bootstrap/baseline/core/agents/docs-writer.md` i etap dokumentacji `.apm/skills/ship/SKILL.md`. Brief produktowy może być wejściem dla `architect`; `/ship` zachowuje obecne zasady planowania, wyboru zakresu i weryfikacji.
- **Kryterium odbioru:** doradcy nie dodają nowych obowiązkowych bramek; istotne decyzje mają krótkie ADR-y z potwierdzonym uzasadnieniem, a drobne poprawki nie produkują zbędnych dokumentów.
- **Weryfikacja:** walidacja roli i skilla oraz próby na zmianie architektonicznej i drobnej poprawce.

### Zadanie 3 — pakowanie i aktualizacja

- **Status:** do zrobienia
- **Zmiana:** rozszerzyć rejestr `.apm/skills/bootstrap/bootstrap.py` z pięciu do dwunastu skilli. Zweryfikować materializację, wykrywanie nowych skilli i zachowanie instalacji częściowej. Nie nadpisywać istniejących lokalnych plików podczas odzyskiwania brakujących skilli.
- **Wersje:** ustawić wersję pakietu w `apm.yml` i generatora na **0.4.0**, pozostawiając schemat profilu w wersji 2.
- **Kryterium odbioru:** komplet skilli działa we wszystkich wspieranych profilach; instalacja i aktualizacja zachowują dotychczasowe kontrole oraz lokalne specjalizacje.
- **Weryfikacja:** rozszerzone kontrole deterministyczne i rzeczywista instalacja lokalnego pakietu w izolowanym repo przez APM.

### Zadanie 4 — istniejące instalacje

- **Status:** do zrobienia
- **Zmiana:** aktualizacja APM dostarcza skille; przegląd aktualizacji pokazuje nowe możliwości i rekomendowaną zmianę lokalnego `docs-writer`. Zachować jego specjalizację oraz istniejący wybór zastosowania lub pominięcia rekomendacji.
- **Kryterium odbioru:** aktualizacja z 0.3.1 nie nadpisuje lokalnych decyzji, a kolejne uruchomienie bez zmian jest idempotentne.
- **Weryfikacja:** przypadki aktualizacji, zastosowania/pominięcia rekomendacji i ponownego uruchomienia.

### Zadanie 5 — katalog i końcowa weryfikacja

- **Status:** do zrobienia
- **Zmiana:** rozwinąć obecny `.apm/README.md` w szczegółowy przewodnik. Główny `README.md` zawiera krótką tabelę i odsyłacz, a instrukcje repo i baseline poprawne informacje o dostępnych workflowach. Zaktualizować odpowiednie testy i ich przewodnik.
- **Kryterium odbioru:** katalog opisuje wejścia, wyniki, zapis dokumentów, przykład wywołania i miękkie ścieżki użycia; dokumentacja odpowiada rzeczywistemu zachowaniu.
- **Weryfikacja:** odsyłacze, kompletność katalogu, kontrole z sekcji 5 i końcowy przegląd zmian.

Sugerowane ścieżki w katalogu:

- Nowy produkt: strategia → wstępna ekonomia → walidacja → korekta → architektura → wykonanie.
- Słaba adopcja: dane klientów i UX → hipoteza → eksperyment → poprawka.
- Premiera: przygotowanie marketingu i ocena prawna odpowiednio wcześnie → poprawki → sprawdzenie gotowości.

Nie dodawać automatycznego orkiestratora uruchamiającego wszystkie skille.

## 5. Weryfikacja i kryteria odbioru

### Kontrole deterministyczne

- Uruchomić `scripts/check.sh`, `scripts/smoke.sh` i pakowanie przez dostępne APM.
- Rozszerzyć istniejące kontrole o zgodność nazw, wrapperów i rejestru dwunastu skilli oraz poprawność lokalnych odsyłaczy.
- Sprawdzić wszystkie wspierane profile: komplet skilli, zachowanie dotychczasowych agentów i brak dodatkowych agentów natywnych dla doradców.
- Sprawdzić aktualizację z 0.3.1, ponowne uruchomienie bez zmian, odzyskanie brakujących skilli oraz zachowanie lokalnych specjalizacji i zewnętrznych kontroli.
- W izolowanym repo sprawdzić rzeczywistą instalację bieżącego lokalnego pakietu przez APM, nie poprzedniej wersji z GitHuba.

### Scenariusze zachowania

Przygotować małe fixture'y z żądaniem, materiałami wejściowymi i kryteriami oceny; przeprowadzić próby użycia, zamiast uznawać wyszukiwanie fraz za test jakości doradztwa:

- Pomysł bez repo i danych: rozmowa oraz eksperyment, bez wymyślonego popytu.
- SaaS i marketplace: odrębna ekonomia, prawidłowe rozdzielenie GMV i przychodów, sprawdzone rachunki.
- Wznowienie rozmowy bez starych planów: wykorzystanie briefu i ADR-ów.
- Kampania przy małym budżecie: konkretne materiały i pomiar, bez publikowania.
- Audyt prawny przy nieznanym rynku lub niedostępnym researchu: jawne niewiadome i częściowy wynik.
- UX bez badań oraz premiera bez próby odtworzenia: brak fałszywych potwierdzeń.
- Istotna zmiana architektoniczna tworzy krótki ADR; drobna poprawka go nie tworzy.

Wdrożenie jest gotowe, gdy dwanaście skilli poprawnie się instaluje, nowe workflowy działają samodzielnie i wznawiają rozmowę z zapisanych ustaleń, istniejące kontrole przechodzą, a dokumentacja odpowiada rzeczywistemu zachowaniu.

## 6. Materiały i stan repo przy planowaniu

- [Roboczy katalog doradców](../../.apm/README.md) — wcześniejsza propozycja, jeszcze nie dokumentacja wdrożonych skilli.
- [Manifest pakietu](../../apm.yml) i [generator](../../.apm/skills/bootstrap/bootstrap.py) — wersja 0.3.1 i stały rejestr pięciu skilli w czasie przygotowania planu.
- [Docs writer](../../.apm/skills/bootstrap/baseline/core/agents/docs-writer.md) — istniejący szablon ADR; wymaga doprecyzowania momentu dokumentowania względem merge'a.
- [Ship](../../.apm/skills/ship/SKILL.md) — wykonanie i wznawianie pracy na podstawie aktywnych `design-docs`.
- [Kontrole strukturalne](../../scripts/check.sh), [smoke testy](../../scripts/smoke.sh) i [przewodnik testów](../../tests/GUIDE.md) — istniejące punkty integracji weryfikacji.

Przed implementacją sprawdzić aktualność tych ustaleń. Zapis tego planu nie oznacza przeprowadzenia testów nowych funkcji ani niezależnego zatwierdzenia planu.
