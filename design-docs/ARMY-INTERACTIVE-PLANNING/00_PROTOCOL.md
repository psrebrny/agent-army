# Kontrakt interaktywnego procesu architekta

## 1. Wejście i wynik

Wejście: potrzeba lub istniejący plan, wskazane materiały, instrukcje repo i znane ograniczenia.
Wynik: kompletny blueprint Army, dowody istotnych założeń, wynik review oraz decyzja potrzebna przed wykonaniem.
Użytkownik rozmawia z architektem; nie wybiera narzędzi delegacji ani nie koordynuje agentów.

Brief, PRD, roadmapa, raport researchu lub decyzja infrastrukturalna mogą być wejściem, lecz żaden z tych
formatów nie jest wymagany. Zachowaj potwierdzone decyzje i linki do źródeł; sprawdź aktualność istotnych faktów.
Z roadmapy wybieramy zakres jednej zmiany. Nie zamieniamy całej roadmapy automatycznie w zgodę na realizację.

Nie dodajemy komendy `/plan` lub `/kit-plan`. Architekta uruchamia się dotychczasowym mechanizmem roli,
bezpośrednio albo przez `/ship`, gdy potrzebny jest blueprint. Nazwa wywołania zależy od adaptera.

## 2. Kolejność i interakcja

1. **Rozpoznanie:** przeczytaj instrukcje i dostępne wejście, określ cel oraz luki.
2. **Analiza warunkowa:** deleguj konkretne pytania przy niepotwierdzonej przyczynie, nieznanym przepływie,
   sprzecznych źródłach lub istotnym wyborze zależnym od researchu. Jasny mały zakres zbadaj sam.
3. **Krótka mapa rozmowy:** pokaż ustalenia i tematy decyzji, bez gotowego wielkiego blueprintu.
4. **Dialog:** jeden istotny temat, rekomendacja, uzasadnienie i znaczące alternatywy; pytanie i oczekiwanie na odpowiedź.
5. **Aktualizacja:** zapisz decyzję, pokaż zmieniony fragment i konsekwencje; przejdź do następnego tematu.
6. **Złożenie:** gdy istotne decyzje są zamknięte, złóż pełny plan z etapami, kontraktami i kryteriami.
7. **Review:** przekaż plan do świeżego recenzenta. Techniczne braki popraw w uzgodnionym zakresie;
   decyzje zmieniające cel, zakres lub istotne ograniczenia wracają do użytkownika.
8. **Odbiór:** pokaż skrót planu, wynik review i linki; wykonanie wymaga dotychczasowej bramki `/ship`.

Rozpoznanie można pogłębić po nowej decyzji. Nie powtarzamy pełnego researchu, jeśli dowody nadal są aktualne.
Nie pytamy o każdą rutynową czynność, wywołanie agenta ani wybór możliwy do ustalenia z repo.
Kompletny brief skraca rozmowę. Użytkownik może skorygować temat, poprosić o szczegóły lub przyjąć rekomendację.
„Zaproponuj sam” upoważnia do jawnych założeń w tym obszarze, nie do rozszerzenia wykonania.
Nie odkładamy istotnych pytań aż pod gotowy dokument. Pełny plan w czacie tylko na życzenie.

## 3. Pakiety dla ról pomocniczych

### planning-analyst

- Wejście: pytanie badawcze, cel, ograniczenia, dopuszczone źródła i znane decyzje.
- Obserwację, sugerowaną przyczynę i proponowaną poprawkę oznacz osobno.
- Wyjście: ustalenia, dowody ze wskazaniem plików/sekcji, hipotezy, obalone założenia,
  niepewności, pytania wymagające użytkownika i możliwe najmniejsze sprawdzenia.
- Może potwierdzić pierwotną diagnozę albo wskazać, że nic nie trzeba budować.
- Bez pisania źródeł, blueprintu, instalacji zależności, zmian konfiguracji i automatycznej naprawy.
- Odczyty lub komendy tylko w udzielonym zakresie; brak dostępu ujawnia, nie zastępuje go zgadywaniem.

### plan-reviewer

- Wejście: cel, potwierdzone decyzje, aktualny blueprint, surowe źródła i zakres review.
- Nie dostaje transkryptu autora, jego samooceny ani raportu analityka jako rozstrzygającej wyroczni.
  Może czytać odnośniki do źródeł i sprawdzać fakty obecne w planie.
- Sprawdza trafność problemu, pokrycie celu, dowody założeń, interfejsy i zależności,
  obserwowalność kryteriów, ryzyka oraz zbędną pracę.
- Ocena obejmuje pięć perspektyw: zgodność z celem, oszczędność wykonania, dopasowanie do repo,
  martwe pola i kompletność. To kryteria jednego review, nie pięć nowych ról ani obowiązek znalezienia pięciu wad.
- Wyjście: zakres sprawdzenia, problemy z dowodem i skutkiem, ograniczenia oraz werdykt
  `APPROVED`, `CHANGES_REQUESTED` albo `INSUFFICIENT_EVIDENCE`.
- Nie zmienia planu ani produktu; dobry plan może otrzymać wynik bez uwag.
- Review planu nie zastępuje późniejszego `code-reviewer`, security ani perf audytu.

Wspólne Handoff pozostaje zgodne z Army. Werdykt recenzenta jest osobnym polem od statusu wykonania roli.
Koordynator zapisuje wyniki w blueprintach; role pomocnicze nie są konkurencyjnymi autorami dokumentów.

## 4. Jeden stan, w istniejących blueprintach

Do wzorca `00_CORE_MANIFEST.md` dodajemy sekcję `Planning Session`:

| Pole | Znaczenie |
|---|---|
| `Mode` | `interactive-complete` dla nowego procesu |
| `Stage` | `discovery`, `discussion`, `review`, `ready` |
| `Current topic` | Aktualny temat albo `none` |
| `Pending decision` | Dokładne pytanie, rekomendacja i alternatywy albo `none` |
| `Remaining topics` | Krótka lista niezakończonych tematów |
| `Decision log` | Potwierdzone decyzje i krótkie powody zmian, bez transkryptu |
| `Evidence` | Istotne fakty, źródła i ograniczenia; dla dużego raportu odnośnik |
| `Plan revision` | Liczba zwiększana po zmianie merytorycznej planu lub kryteriów |
| `Review` | Rewizja, zakres, werdykt, niezależność, otwarte uwagi i link do raportu |
| `Next action` | Następny krok planowania; nie dubluje wykonawczych tasków PR |

Gotowość planowania: brak blokujących decyzji i uwag, review aktualnej rewizji oraz jawna niezależność oceny.
Werdykt `APPROVED` nie jest zgodą użytkownika na implementację.
Zmiana merytoryczna oznacza wcześniejsze review jako nieaktualne; kosmetyczna korekta nie wymaga nowego review.
Zmiana źródeł mogąca podważyć plan wymaga ponownego sprawdzenia właściwych założeń i aktualizacji wyniku.

Duże raporty trafiają opcjonalnie do `planning-evidence.md` i `plan-review.md` przy manifeście.
Nie tworzymy osobnego `task.md`, nowych baz ani drzewa `context/work`.
Execution State i checkboxy wykonania pozostają tylko w plikach PR. Karta `/ship` odsyła do decyzji
planistycznej zamiast utrzymywać jej drugą niezależną wersję.

## 5. Korekty, wznowienie i zgodność

- Wznowienie zaczyna od Planning Session, następnie potrzebnych źródeł; nie powtarza znanych pytań.
- Jeśli użytkownik właśnie odpowiedział na zapisane pytanie, zastosuj odpowiedź zamiast pytać jeszcze raz.
- Zmiana decyzji: przegląd zależnych niewykonanych części, klasyfikacja keep/rewrite/remove i aktualizacja w miejscu.
- Zachowaj historyczne dowody ukończonych prac; usuń nieaktualne przyszłe instrukcje, nie dopisuj planu obok planu.
- Przed zapisem ponownie odczytaj dokument, jeśli zmieniła go inna sesja. Nie obiecujemy równoległych zapisów.
- Stary blueprint bez Planning Session jest czytelny i nie zostaje automatycznie otwarty do ponownego planowania.
  Dodaj sekcję przy świadomym rozpoczęciu nowego procesu lub istotnym przeplanowaniu.
- Firmowe `interactive rolling` nie jest aliasem `interactive-complete`; nie konwertuj tych trybów po cichu.

## 6. Delegacja i ograniczenia środowiska

Główna sesja uruchamia role kolejno i utrwala wyniki. Jeśli sama pełni rolę architekta, deleguje bezpośrednio.
Jeżeli architekt jest workerem, zwraca koordynatorowi potrzebne pytanie lub zlecenie badania/review,
bez zakładania dostępu do zagnieżdżonych subagentów. W trakcie rozmowy nie uruchamiamy wykonawców kodu.

Na adapterze bez subagentów analityk może być kontraktem roli wykonanym w głównej sesji.
Niezależny recenzent wymaga nowego kontekstu. W razie braku takiej możliwości koordynator przygotowuje
pakiet dla nowej sesji i zapisuje `INSUFFICIENT_EVIDENCE` z powodem „brak niezależnego review”.
Samoocenę można pokazać pomocniczo; nie można nią spełnić deklaracji niezależnego odbioru.
Gdy użytkownik świadomie zleci wykonanie bez tego review, istniejąca bramka zapisuje jawny wyjątek,
nie zmienia wyniku na APPROVED i nie sugeruje, że niezależna kontrola się odbyła.
