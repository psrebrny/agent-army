# Co jeszcze warto wykorzystać z materiałów

## Zakres oceny

To ocena dostarczonych materiałów, nie benchmark 10x ani audyt wszystkich implementacji jego skilli.
Przeczytano brief prywatnego toolkitu, artykuł „Modele rozumujące w praktyce”, indeks dokumentacji 10x
oraz lokalne instrukcje źródłowej i firmowej Army. Nowa analiza obejmuje również pełny przekazany katalog 33 skilli;
porównujemy opisy, bez audytu implementacji skilli 10x ani sprawdzania aktualności strony online w tej analizie.
Wpis „Army już ma” oznacza obecność reguły lub mechanizmu w źródłach, nie dowód jego skuteczności w praktyce.

Aktualizacja 2026-10-02: sześć zasad jest już w lokalnych instrukcjach istniejących ról. Po wyjaśnieniu,
że prośba dotyczyła docsów, użytkownik zdecydował o zachowaniu tych zmian. [Zakres i właściciele](07_BASELINE_RULES.md).
Nie wdrożono jeszcze dwóch nowych agentów. Bieżąca aktualizacja zmienia tylko dokumentację.

Pełne rozróżnienie „mamy / częściowo / plan / brak” jest w [08](08_CATALOG_COMPARISON.md),
wybór kolejności w [09](09_SCOPE_AND_PRIORITIES.md), a projekty osobnych skilli w [10](10_OPTIONAL_SKILLS.md).
PR 1–4 nie stają się programem implementacji całej biblioteki.

## 1. Warto włączyć do tego rozszerzenia

| Pomysł | Wartość | Sposób użycia |
|---|---|---|
| Frame: objaw nie jest przyczyną | Ogranicza realizację błędnie postawionego zadania | Analityk rozdziela obserwację, hipotezę i rozwiązanie |
| Research z dowodami | Plan opiera się na aktualnym repo i źródłach | Celowane badanie, źródła, niepewności i sprawdzenie założeń |
| Niezależne review planu | Błąd wykryty przed kodem jest tańszy do poprawy | Osobny reviewer, świeży kontekst, bez samooceny autora |
| Cele i ograniczenia | Daje modelowi swobodę rozwiązania problemu | Kontrakty ról opisują wynik i granice, nie wewnętrzny tok rozumowania |
| Few-shoty formatów i trudnych przypadków | Ułatwiają zrozumienie odpowiedzialności | Zachować konkretne przykłady, bez uniwersalnego wzorca technicznego |
| Kontekst na żądanie | Ogranicza szum i dublowanie badań | Krótkie raporty, odnośniki do źródeł, bez czytania wszystkiego na start |
| Jedno źródło prawdy | Chroni przed sprzecznymi planami | Aktualizacja w miejscu, jeden stan, review przypisane do rewizji |
| Kryteria zachowania | Pomaga sprawdzić cel, nie tylko kompilację | Plan określa obserwowalny rezultat, reviewer sprawdza jakość wyroczni |
| Testowanie według ryzyka | Chroni najważniejsze zachowania przy rozsądnym koszcie | Wprowadzone do testera: priorytety ryzyk i najtańszy wiarygodny poziom sprawdzenia |
| Build vs buy / nie budować | Może usunąć całe zbędne przedsięwzięcie | Wprowadzone do architekta; planowany analityk może później dostarczać dodatkowych dowodów |

Interaktywny dialog o całym planie jest szczególnie ważnym wymaganiem użytkownika.
Nie przypisujemy artykułom konkretnej implementacji dialogu, której nie pokazano; to nasze doprecyzowanie produktu.

## 2. Army ma już odpowiedni punkt zaczepienia

| Pomysł | Obecny mechanizm | Decyzja |
|---|---|---|
| Wznowienie i status | Blueprint, Execution State, rozwiązywanie zakresu przez ship | Rozszerzyć o rozmowę planistyczną, bez osobnego Checkpoint |
| Utrwalanie korekt | adapt-army i rozróżnienie poprawki lokalnej od trwałej | Korzystać z istniejącego mechanizmu; nie budować Learn |
| Hooki, pre-commit i CI | Runtime oraz ownership warstw | Nie tworzyć nowych kontroli; nie obiecywać niemożliwości obejścia hooka |
| Review kodu i audyty | code-reviewer, security-auditor, perf-auditor | Zachować; plan-reviewer ma inną odpowiedzialność i ich nie zastępuje |
| Dystrybucja i aktualizacje | APM, bootstrap, inventory, upgrade review | Dodać role do istniejącej ścieżki |
| Stopniowanie kosztu modeli | Profile możliwości i routing adaptera | Korzystać z obecnego mapowania, bez nowych hardcoded model IDs |
| Korekta zależnych planów | Reguły architekta; rozwinięty Impact Sweep w firmowej Army | Doprecyzować w tym projekcie aktualizacje całego przyszłego zakresu |
| Wiarygodność testów | Tester: celowany fault/mutation check w izolacji | Reguła dodana; eksperyment tylko dla istotnego ryzyka, bez obowiązkowego frameworka |
| Odwracalny refaktor | Architekt: kroki i recovery; coder: wykonanie; reviewer: ocena | Reguły dodane, z prawidłową interpretacją zielonego baseline |
| Rejestr kontraktów | Architekt: granice i konsumenci; reviewer: kontrola; docs-writer: aktualizacja | Mały indeks do źródeł schematów, tworzony tylko przy rzeczywistej potrzebie |
| Higiena kontekstu | Wspólne AGENTS.md: odczyt według potrzeby i właściciel instrukcji | Reguły doprecyzowane; brak automatycznego przepisywania dokumentacji użytkownika |

## 3. Dalsze etapy i osobne możliwości

| Pomysł | Kiedy ma wartość | Najmniejszy sensowny kolejny krok |
|---|---|---|
| Całościowa mapa ryzyk produktu | Istniejący system ma luki jakości wykraczające poza aktualne zadanie | Opcjonalny test-strategy; lokalny dobór testów według ryzyka jest już w testerze |
| Debugowanie z wielu źródeł | Logi, network, trace i testy dają rozproszone sygnały | Celowany kontrakt analizy incydentu, jeśli bieżący research nie wystarcza |
| Hot spots i historia zmian | Legacy ma duży obszar i trzeba wybrać miejsce pracy | Pomiary churn i zależności przed decyzją o refaktorze |
| Słownik domeny / DDD | Te same pojęcia znaczą różne rzeczy w modułach | Wspólne nazwanie pojęć i granic z właścicielem domeny |
| Audyt całego zbioru instrukcji | AGENTS.md i reguły są długie, sprzeczne lub nieaktualne | Opcjonalny audyt w adapt-army; bieżąca higiena kontekstu nie zleca masowego porządkowania |
| Walidacja potrzeby i roadmapa produktu | Niepewne jest co budować i dla kogo | Osobny product-discovery; istniejący wywiad architekta nie jest badaniem zachowań klientów |
| Research infrastruktury | Projekt potrzebuje decyzji o miejscu uruchomienia | Osobny infra-research z aktualnymi źródłami i ograniczeniami |
| Deploy readiness | Aplikacja działa lokalnie, ale nie ma wiarygodnej ścieżki uruchomienia | Osobny workflow dla konkretnego hostingu i recovery; wybór platformy nie jest dowodem gotowości |
| Zbiorczy status i archiwizacja | Rośnie liczba planów | Najpierw opcjonalny odczyt army-status; archiwizacja dopiero przy rzeczywistym problemie |
| CI review | Zespół potrzebuje regularnego przeglądu PR-ów | Osobny projekt z pomiarem szumu, kosztu i uprawnień |
| Praca równoległa / zdalna | Istnieją niezależne zadania i zdolność odbioru ich wyników | Izolacja zakresów oraz stanu; dopiero później skalowanie liczby agentów |

Audyt reguł, readiness i status mają teraz zadania w PR 5–6, a E2E warunkowy PR 7 w [planie](09_SCOPE_AND_PRIORITIES.md).
Pozostałe tematy są opcjami poza rdzeniem. Zapis etapów nie uruchamia ich automatycznie po PR 4.

## 4. Czego świadomie nie kopiujemy

- Liczby skilli jako miernika jakości i pełnego obowiązkowego łańcucha dla każdej pracy.
- Tworzenia wielu agentów tylko dlatego, że delegacja jest dostępna.
- Bezwzględnego RED dla refaktoru, researchu i dokumentacji ani test runnera dla każdej notatki.
- Zasady, że każdy etap musi kończyć się commitem.
- Sztywnego budżetu 15–20 testów jako uniwersalnej gwarancji jakości.
- Dopisywania lekcji bez możliwości poprawienia lub usunięcia nieaktualnej reguły.
- Wielkiego PRD, roadmapy i zestawu raportów przy drobnym zadaniu.
- Uznawania zielonych testów za wystarczający dowód, gdy asercje powielają implementację.
- Zrównania poprawnego frontmatteru lub renderingu z użytecznością agenta.
- Obietnic „nieomijalnej” kontroli zapisanej wyłącznie w promptach lub runtime hookach.

## 5. Źródła

- Przekazane przez użytkownika teksty: brief, „Modele rozumujące w praktyce”, „10X WORKFLOW — dokumentacja / quick search”
  oraz „10X WORKFLOW — biblioteka skilli / katalog” (33 karty).
- [Indeks 10x](https://platforma.przeprogramowani.pl/10xdevs-hub/docs).
- [Biblioteka skilli 10x](https://platforma.przeprogramowani.pl/10xdevs-hub/biblioteka-skilli).
- [Źródłowy architekt](../../.apm/skills/bootstrap/baseline/core/agents/architect.md),
  [ship](../../.apm/skills/ship/SKILL.md), [adapt-army](../../.apm/skills/adapt-army/SKILL.md).

Materiały pokazują wiele wartościowych praktyk. Dwie nowe role są wybranym rozszerzeniem Army,
a nie twierdzeniem, że pozostałe inspiracje zostały wyczerpane lub są nieprzydatne.
