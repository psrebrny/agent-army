# Porównanie katalogu 10x z Army

Katalog zawiera 33 skille. Army pokrywa znaczną część wykonania zmiany, ale nie całe przygotowanie produktu,
infrastruktury i wdrożenia. Rekomendujemy ponowne użycie obecnych ról oraz kilka opcjonalnych workflow,
zamiast odtwarzać wszystkie komendy. Żaden wiersz tej analizy nie zleca implementacji.

## Podstawa i znaczenie statusów

Analiza z 2026-10-02 opiera się na pełnym tekście katalogu przekazanym przez użytkownika oraz lokalnych
źródłach Army. Opisy kart nie są kodem skilli: nie zweryfikowano ich wewnętrznych procedur ani skuteczności.
Rekomendowana lokalizacja i priorytet są naszym projektem, nie deklaracją autora 10x.

- **Jest:** istnieje odpowiadający mechanizm Army, choć format i szczegóły mogą być inne.
- **Częściowo:** istnieją elementy, lecz brakuje odrębnego rezultatu lub pełnego przebiegu z karty.
- **Plan:** brak gotowego mechanizmu; ujęty w PR 1–4 tego projektu.
- **Brak:** nie znaleziono odpowiednika w obecnych kontraktach i skillach Army.

Stan obejmuje lokalne niezacommitowane instrukcje, w tym zachowane na życzenie użytkownika sześć zasad
z [07](07_BASELINE_RULES.md). Nie oznacza wydania, aktualizacji projektów ani potwierdzonej jakości zachowania LLM.
Priorytety i kolejność opisuje [09](09_SCOPE_AND_PRIORITIES.md); projekty osobnych skilli opisuje [10](10_OPTIONAL_SKILLS.md).

## Fundament

| Skill z katalogu | Stan Army i brakująca część | Rekomendacja |
|---|---|---|
| `/10x-init` | Częściowo: bootstrap przygotowuje zespół, architect tworzy `design-docs`; nie ma drzewa `context/` i cyklu archiwum | Użyć istniejących katalogów. Nie dodawać osobnego init |
| `/10x-shape` | Częściowo: architect ma wywiad biznesowy i rozpoznaje greenfield/brownfield; lepszy dialog jest w planie | Mała zmiana: architect. Odkrywanie nowego produktu: opcjonalny `product-discovery` |
| `/10x-prd` | Częściowo: manifest opisuje cel, ograniczenia i architekturę; brak osobnego schematu PRD produktu | Opcjonalny wynik `product-discovery`; małe zadanie nie potrzebuje PRD |
| `/10x-tech-stack-selector` | Częściowo: architect wybiera stack greenfield; brak rejestru starterów i czterech bramek z katalogu | W architect kryteria wyboru i dowody, bez obowiązkowej kopii rejestru. Scaffold osobno |
| `/10x-stack-assess` | Częściowo: bootstrap analizuje stack i komendy; nie ma oceny komponentów według bramek katalogu | Rozszerzenie raportu bootstrap o ograniczenia istotne dla pracy agentów |
| `/10x-bootstrapper` | Brak: `/bootstrap` Army instaluje i specjalizuje zespół, nie uruchamia oficjalnego startera aplikacji | Opcjonalny `project-starter`; zachować wyraźnie różne znaczenie bootstrap |
| `/10x-health-check` | Częściowo: recon, komendy, ownership kontroli i security-auditor; brak zbiorczej oceny zdrowia projektu i zależności | Opcjonalne readiness w bootstrap, raport przed naprawami. Nie deklarować pełnego audytu na podstawie recon |
| `/10x-agents-md` | Jest: bootstrap tworzy i specjalizuje główne instrukcje oraz wskazówki narzędzi | Wykorzystać obecny mechanizm |
| `/10x-rule-review` | Częściowo: adapt-army reaguje na feedback; brak całościowego audytu sprzeczności i aktualności reguł | Opcjonalny przebieg audytu w adapt-army, bez nowego agenta |
| `/10x-lesson` | Jest odpowiednik trwałej korekty: adapt-army kieruje ją do właściciela i zapisuje decyzję; brak append-only `lessons.md` | Zachować routing i możliwość poprawienia starej reguły. Pamięć propozycji nie zastępuje obowiązującej instrukcji |
| `/10x-infra-research` | Brak osobnego porównania platform z aktualnymi źródłami | Samodzielny `infra-research`, uruchamiany przy realnej decyzji infrastrukturalnej |

## Cykl zmiany

| Skill z katalogu | Stan Army i brakująca część | Rekomendacja |
|---|---|---|
| `/10x-roadmap` | Częściowo: architect dzieli zmianę na PR-y i zadania; to nie roadmapa produktu | Roadmapa opcjonalnym wynikiem `product-discovery`; do Army trafia wybrany wycinek |
| `/10x-new` | Częściowo: architect tworzy folder Task-ID, manifest i pliki PR; brak oddzielnego `change.md` | Rozpoczynać zadanie obecnym wejściem, bez drugiej tożsamości i stanu |
| `/10x-plan` | Częściowo: blueprint i wywiad są; cały plan uzgadniany temat po temacie oraz trwały stan dialogu są w PR 2 | Najbliższy priorytet w architect. Krótkie podsumowanie wyprowadzać z planu |
| `/10x-plan-review` | Plan: osobny `plan-reviewer` w PR 1; code-reviewer sprawdza późniejszy kod | Zachować nową rolę i świeży kontekst; nie zaliczać samooceny autora |
| `/10x-implement` | Jest: `/ship`, tester, główna sesja lub coder, Execution State i weryfikacja | Nie dodawać executora. Army wymaga zgody człowieka na commit |
| `/10x-archive` | Brak workflow archiwizacji; statusy zakończenia istnieją | Odłożyć do potrzeby porządkowania wielu planów; zachować odnośniki i historię, bez automatycznego commita |
| `/10x-impl-review` | Jest: niezależny code-reviewer, kontrakt, werdykty i routing poprawek | Użyć obecnej roli; trwałe lekcje przez adapt-army, dokumentacja kontraktów przez docs-writer |
| `/10x-frame` | Plan: oddzielanie objawu od diagnozy przez planning-analyst w PR 1 | Warunkowy krok przed projektowaniem; prawidłowa diagnoza też jest wynikiem |
| `/10x-research` | Częściowo: recon architekta/bootstrap; dedykowany raport analityka jest w PR 1 | Jeden pakiet dowodów na potrzebę; bez ponownego pełnego researchu i obowiązkowej równoległości |

## Jakość

| Skill z katalogu | Stan Army i brakująca część | Rekomendacja |
|---|---|---|
| `/10x-test-plan` | Częściowo: tester dobiera testy do ryzyka zadania; brak mapy ryzyk całego produktu i wieloetapowego rolloutu ochrony | Opcjonalny `test-strategy`: diagnoza i plan produktu, potem zwykły architect/ship |
| `/10x-tdd` | Jest: tester i `/ship`, asercje z kontraktu, RED/GREEN oraz jawne polityki; nowe instrukcje dodają kontrolę wiarygodności | Nie dodawać drugiego TDD skilla ani sztywnego limitu 15–20 testów |
| `/10x-e2e` | Częściowo: tester zna poziom E2E i komendy repo; brak dedykowanego przebiegu na działającej aplikacji z obsługą środowiska/danych | Najpierw opcjonalna procedura testera; osobny skill tylko gdy ten workflow regularnie ma własnego użytkownika |

## Praca zespołowa

| Skill z katalogu | Stan Army i brakująca część | Rekomendacja |
|---|---|---|
| `/10x-opportunity-map` | Częściowo: architect ma już zasadę reuse/build/no implementation; brak badania okazji, dowodów bólu i eksperymentu | Połączyć z walidacją pomysłu w opcjonalnym `product-discovery` |
| `/10x-mom-test` | Brak: wywiad architekta nie jest badaniem zachowań klientów | Część `product-discovery`; przygotowuje wywiad i analizuje dane, nie wymyśla respondentów |
| `/10x-impl-review-ci` | Częściowo: są lokalny reviewer i deterministyczne CI; brak ich integracji w automatyczny review PR | Osobny projekt integracji Army z CI po potrzebie zespołu i ocenie uprawnień/kosztu |
| `/pack-init` | Jest odpowiednik dystrybucji własnego toolkitu przez APM; brak generatora paczki npm/CodeArtifact | Zostawić APM. Osobny skill paczkowania tylko dla innego konkretnego produktu |
| `/tf-registry` | Brak generatora infrastruktury AWS CodeArtifact | Poza rdzeniem Army; osobny skill infrastrukturalny dopiero po wyborze tej technologii |
| `/setup-cicd` | Częściowo: Army ma CI jakości; brak pipeline publikacji npm do CodeArtifact przez OIDC | Osobny skill publikacji dopiero wraz z realnym rejestrem; CI jakości nie jest publikacją |
| `/10x-goal-implement` | Częściowo: `/ship` ma autonomiczne wykonanie zatwierdzonego zakresu; brak równoważnego trybu `/goal`/headless i automatycznych commitów | Zachować jeden executor. Headless to osobny późniejszy projekt, nie kolejna komenda teraz |

## Dodatkowe

| Skill z katalogu | Stan Army i brakująca część | Rekomendacja |
|---|---|---|
| `/10x-status` | Częściowo: stan per PR i wznowienie przez ship; brak zbiorczego widoku wszystkich zmian i dryfu | Opcjonalny `army-status` w Army, wyłącznie odczyt istniejących planów |
| `/10x-contract` | Częściowo: nowe instrukcje architect/reviewer/docs-writer określają indeks i zgodność; brak osobnej komendy/rejestracji ani gwarancji wykrycia wszystkich konsumentów | Pozostawić w rolach, z próbami zachowania. Źródła kontraktów są ważniejsze niż dopasowanie nagłówka |
| `/10x-deployment` | Brak dedykowanego preflight/config/deploy; zielone testy i CI jakości nie świadczą o gotowości operacyjnej | Osobny `deployment-readiness`, najpierw dla jednej używanej platformy |

## Źródła Army

- [Bootstrap](../../.apm/skills/bootstrap/SKILL.md): recon, komendy, instalacja i specjalizacja instrukcji.
- [Architect](../../.apm/skills/bootstrap/baseline/core/agents/architect.md): wywiad, blueprint, kontrakty i decyzje.
- [Ship](../../.apm/skills/ship/SKILL.md): wykonanie, stan, routing i bramki.
- [Tester](../../.apm/skills/bootstrap/baseline/core/agents/tester.md) i [reviewer](../../.apm/skills/bootstrap/baseline/core/agents/code-reviewer.md): jakość zmiany.
- [Adapt army](../../.apm/skills/adapt-army/SKILL.md): trwałe korekty; [manifest APM](../../apm.yml): dystrybucja.
- Źródło katalogu: załącznik użytkownika „10X WORKFLOW // BIBLIOTEKA SKILLI // KATALOG”, odczytany w całości.
  Publiczny adres referencyjny: [biblioteka skilli](https://platforma.przeprogramowani.pl/10xdevs-hub/biblioteka-skilli).
  Nie sprawdzano w tej analizie aktualności strony online; oceniane są dostarczone opisy.
