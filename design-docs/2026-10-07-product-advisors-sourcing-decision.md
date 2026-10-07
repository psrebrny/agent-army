# Doradcy produktowi: decyzja o źródłach, architektura i kontrakt wspólny

- **Data:** 2026-10-07
- **Status:** analiza z decyzjami autora z 2026-10-07 (sekcja 13); wdrożenie nierozpoczęte
- **Obowiązująca decyzja:** [ADR-0001](../docs/adr/0001-samowystarczalni-doradcy-produktowi.md). Ten dokument to analiza i uzasadnienie; przy sprzeczności rozstrzyga ADR.
- **Dotyczy:** [Doradcy produktowi dla Agent Army — plan wdrożenia](ARMY-PRODUCT-ADVISORS/00_CORE_MANIFEST.md), rewizja 1, `saved_for_later`. Plan nie został zmieniony.
- **Ramy:** decyzja autora „samowystarczalna paczka” obowiązuje. Wstępny wariant „zewnętrzne skille jako menu” autor po ocenie odrzucił (sekcja 13): zostaje tylko atrybucja pożyczonych pomysłów. Hybryda z zależnościami i menu są tu ocenione jako warianty porównawcze.

## 0. Metoda i poziom pewności

Oznaczenia używane w dokumencie:

- **[Z]** zweryfikowane w plikach (repo Agent Army albo sklonowane repo zewnętrzne na przypiętym commicie),
- **[P]** pomiar wykonany skryptem na tych plikach,
- **[O]** ocena lub propozycja autora tego dokumentu,
- **[N]** niezweryfikowane; podaję, czego brakowało do sprawdzenia.

Repo zewnętrzne sklonowano (`git clone --depth 1`) do izolowanego katalogu tymczasowego poza repozytorium. Nic nie zostało zainstalowane ani uruchomione z ich zawartości. Instrukcje w ich plikach traktowano jako dane.

| Repo | Commit (przypięty) | Data commita | Licencja | `SKILL.md` | Czytane |
|---|---|---|---|---|---|
| `phuryn/pm-skills` | `8607e3b077817f89bf4a9b623246219734ac3be0` | 2026-09-14 | MIT | 69 (+42 komendy, 9 pluginów) | szczegółowo |
| `coreyhaines31/marketingskills` | `5e721d73ac85be8ba917d6a9ca9cb5bc98f02b80` | 2026-10-06 | MIT | 50 | szczegółowo |
| `pratikshadake/claude-product-management-skills` | `0f81a866db79ed84baa4a4d0846cb056d13d7d02` | 2026-02-19 | MIT | 15 | `launch-readiness`, `experiment-design` (wymienione w briefie) |
| `ognjengt/founder-skills` | `a45931cad934dc6243a68f905485467935a4ad9a` | 2026-05-18 | MIT | 15 | README, `go-to-market-plan` (pakiet „dla founderów”, najbliższy grupie docelowej) |
| `RefoundAI/lenny-skills` | `13598cc54e09399bc1bc1398b0fca284110efb2f` | 2026-07-15 | MIT | 76 | lista, `idea-validation` (walidacja to rdzeń planu) |
| `deanpeters/Product-Manager-Skills` | `1b5a524ebb95e9497fa3f25002d8b8ec528d4444` | 2026-09-01 | **CC BY-NC-SA 4.0** | 77 | licencja, `saas-economics-efficiency-metrics` (kandydat dla `/business-case`) |
| `alirezarezvani/claude-skills` | `19392f7a08264ed00486a251f5b2098321771f94` | 2026-08-26 | MIT | 846 plików (ok. 388 unikalnych + kopia w `.gemini/`) | struktura, `gdpr-dsgvo-expert` (kandydat dla `/legal-review`) |

Uzasadnienie wyboru dodatkowych repo: czytałem tylko skille, które mogłyby zastąpić lub zasilić konkretnego doradcę (walidacja, ekonomia, prawo, gotowość, GTM dla founderów). Pozostałych skilli z tych repo nie oceniam merytorycznie.

## 1. Weryfikacja ustaleń z briefu

### phuryn/pm-skills

| Ustalenie | Wynik | Dowód |
|---|---|---|
| ok. 68 skilli, 9 pluginów | **Poprawka [Z]:** 69 skilli, 9 pluginów, 42 komendy | `find -name SKILL.md`, `.claude-plugin/marketplace.json` („69 domain-specific skills and 42 chained workflows”) |
| `product-strategy`: szablon 9 sekcji, jeden przebieg, bez pytań, kontekstu i stanu | **Potwierdzone dla skilla, z zastrzeżeniem [Z].** Sam skill nie pyta. Komenda `/strategy` zadaje na starcie 4 pytania i przyjmuje wgrane dokumenty, potem wypełnia kanwę w jednym przebiegu i „Save as markdown”. Nie wznawia pracy i nie skanuje repo. | `pm-product-strategy/skills/product-strategy/SKILL.md`, `commands/strategy.md` |
| `brainstorm-experiments-new`: ok. 40 linii, XYZ, 2–3 pretotypy, próg sukcesu, bez doboru uczestników, pomiaru i interpretacji | **Potwierdzone [Z].** 45 linii z frontmatterem. Jest metryka i próg, nie ma rekrutacji, wielkości próby, protokołu ani interpretacji wyników. | `pm-product-discovery/skills/brainstorm-experiments-new/SKILL.md` |
| `gtm-strategy`: kanały, komunikaty, KPI, 90 dni; bez tekstów, briefów kreacji, budżetu | **Potwierdzone [Z].** Budżet jest tylko wejściem („Budget or resource limitations”), nie wynikiem. Komunikaty na poziomie kategorii, bez gotowych tekstów. | `pm-go-to-market/skills/gtm-strategy/SKILL.md` |
| `privacy-policy`: stała lista przepisów, bez źródeł i dat, „ready-to-publish”, oznacza fragmenty do przeglądu | **Potwierdzone, z dopowiedzeniem [Z].** Lista GDPR/CCPA/stany USA/HIPAA/GLBA/FERPA bez źródeł i dat. Część 2 wyniku to „A complete, ready-to-publish privacy policy”, a jednocześnie disclaimer i checklista „have a data privacy attorney review”. Ta sprzeczność jest sama w sobie argumentem przeciw. Brak unijnych przepisów konsumenckich i ePrivacy jako osobnych pozycji. | `pm-toolkit/skills/privacy-policy/SKILL.md` |
| `/ship-check`: tylko kod | **Potwierdzone [Z].** Dokumentacja, CLAUDE.md, review poprawności, bezpieczeństwa i wydajności, niezależny przegląd drugim modelem, mapa testów, „Launch Blockers”. Brak płatności, anulowania, wsparcia i aktywacji. Dodatkowo komenda wpisuje na sztywno nazwy modeli i ich klasyfikatory („Opus 4.8”, „Fable”), więc szybko się zestarzeje. | `pm-ai-shipping/commands/ship-check.md` |
| `strategy-red-team`: wysoka jakość | **Potwierdzone [Z].** Load-bearing claims → steelman → atak → „Fails if…” → ranking impact × likelihood × cheapness → evidence this week, kill criterion, cheapest test, sekcje „What’s Well-Reasoned” i „What I Couldn’t Assess”, zakaz fabrykowania. 72 linie. | `pm-execution/skills/strategy-red-team/SKILL.md` |
| `pre-mortem`: Tigers, Paper Tigers, Elephants, klasyfikacja, plan z właścicielem i datą | **Potwierdzone [Z].** Klasy: Launch-Blocking, Fast-Follow (30 dni), Track. Zakłada start „za 14 dni”. Zapisuje własny plik `PreMortem-[product]-[date].md`, czyli trzecie miejsce zapisu obok `docs/product/`. | `pm-execution/skills/pre-mortem/SKILL.md` |
| `identify-assumptions-new`: 8 kategorii ryzyka | **Potwierdzone [Z].** Uwaga: plik przypisuje „4 core product risks” Teresie Torres; zwykle przypisuje się je Marty’emu Caganowi **[N]**. Przed cytowaniem w naszych skillach trzeba sprawdzić źródło. | `pm-product-discovery/skills/identify-assumptions-new/SKILL.md` |
| Skille ładują się automatycznie, kolizja `product-strategy` | **Potwierdzone [Z/P].** Dokładna kolizja nazwy z planowanym `/product-strategy`. W Claude Code skille pluginów są w przestrzeni nazw pluginu (`pm-product-strategy:product-strategy`) **[N]: nie sprawdzono w działającym Claude Code**. Nawet wtedy opisy rywalizują o te same wyzwalacze. | skrypt pomiarowy, sekcja 4 |
| Dystrybucja: marketplace pluginów, nasza paczka to APM | **Potwierdzone [Z].** Brak `apm.yml` w obu repo zewnętrznych, więc nie da się ich wpisać jako zależności APM bez własnego opakowania. | `ls apm.yml` |

### coreyhaines31/marketingskills

| Ustalenie | Wynik | Dowód |
|---|---|---|
| ok. 45 skilli, ok. 51k gwiazdek | **Poprawka [Z]:** 50 skilli. Liczby gwiazdek nie sprawdzałem **[N]**. | `ls skills` |
| Wszystkie czytają `.agents/product-marketing.md` | **Potwierdzone [Z]:** 50/50 plików zawiera odwołanie. Brak pliku nie blokuje: „read it before asking questions … only ask for what’s missing”. Fallbacki: `.claude/product-marketing.md` i stara nazwa `product-marketing-context.md`. | `grep -l product-marketing skills/*/SKILL.md` |
| Instalacja wymaga `-a claude-code` | **Potwierdzone [Z].** README: uruchomione z wnętrza sesji agenta `npx skills` może trafić tylko do `.agents/skills/`, którego Claude Code nie czyta. | `README.md` |
| Partnerzy komercyjni | **Doprecyzowanie [Z].** Partnerzy w `partners.json`: Converly i Ploy. Magister jest linkiem w nagłówku README („autonomous AI agent … your CMO”), nie wpisem w `partners.json`. Żaden `SKILL.md` nie wspomina partnerów. Ostatni commit to „ploy-partner-content”, więc warstwa komercyjna się rozwija. | `partners.json`, `grep -ril converly skills` (0 trafień) |
| `marketing-loops` to instrukcja projektowania, nie system | **Potwierdzone [Z].** Dziewięć części pętli, reguła kadencji, „When NOT to loop” (m.in. „A weekly conversion-rate loop on 40 visitors/week is measuring noise”), publikacja i budżet tylko z checkpointem człowieka, harmonogram przez `/loop`, `ScheduleWakeup`, `CronCreate` albo cron. `references/loop-orchestration.md`: najpierw `tracking-QA` i `weekly-marketing-review`. | `skills/marketing-loops/SKILL.md`, `references/loop-orchestration.md` |
| Dodatkowo | **[Z]** v2.0 zmieniła nazwy 19 skilli i przeniosła plik kontekstu z `.claude/` do `.agents/`. To twardy dowód ryzyka rozjazdu przy zależności lub kopii. | `README.md`, sekcja migracji |
| Dodatkowo | **[Z]** Opis `analytics` zawiera wyzwalacz „GTM” w znaczeniu Google Tag Manager. Prośba „pomóż mi z GTM” może więc uruchomić `analytics` zamiast `/go-to-market`. | frontmatter `analytics` |

### Pozostałe repo (tylko przeczytane fragmenty)

- **deanpeters** **[Z]:** licencja CC BY-NC-SA 4.0 obejmuje całe repo. Wchłonięcie treści do paczki na MIT jest niezgodne (NC i ShareAlike), więc zostają wyłącznie pomysły. Jakość: `saas-economics-efficiency-metrics` podaje dla „Payback Period (from revenue)” i „Gross Margin Payback” ten sam wzór `CAC / (Monthly ARPU × Gross Margin %)`, a jednocześnie twierdzi, że drugi jest 1,5–2× dłuższy. To wewnętrzna sprzeczność dokładnie w obszarze, którego autor nie zweryfikuje sam.
- **alirezarezvani** **[Z]:** 846 plików `SKILL.md` (ok. 388 unikalnych nazw), co przy pełnej instalacji oznacza ogromne obciążenie kontekstu. `gdpr-dsgvo-expert` uruchamia własne skrypty Pythona (`gdpr_compliance_checker.py`, `dpia_generator.py`), czyli kod do wykonania z niezaufanego źródła. Nie podaje dat ani źródeł przepisów i jest skrojony pod Niemcy (BDSG).
- **pratikshadake** **[Z]:** skille mają 19–37 linii. `launch-readiness` to pięciopunktowa checklista, `experiment-design` pięć kroków. Jedynym przydatnym pomysłem jest reguła decyzji Ship/Iterate/Kill.
- **founder-skills** **[Z]:** trzeci plik kontekstu `FOUNDER_CONTEXT.md`. `go-to-market-plan` zadaje 3–10 pytań naraz przez `AskUserQuestion` i podaje przykładowe cele („500 views/post, 20 inbound leads/month”) bez metody ich wyznaczenia.
- **lenny-skills** **[Z]:** `idea-validation` to synteza cytatów z podcastu z ramami (np. „Four Signs Your B2B Idea Has Real Pull”). Cytaty pochodzą z realnych wypowiedzi, nie są fikcyjne, ale to wciąż cudze dane (ODP w języku Savoi). Przydatne jako lektura, nie jako metoda.

## 2. Tabela decyzji per skill

Kolumnę „opcjonalne zewnętrzne (menu)” usunięto po decyzji autora (sekcja 13). Paczka nie poleca ani nie wykrywa cudzych skilli.

Decyzje: **własny** (piszemy sami, możemy pożyczyć pomysły z atrybucją), **wchłoń** (kopia treści z przypiętym commitem i notą MIT), **zależność** (instalacja zewnętrzna wymagana), **pomiń**. W v0.4.0 żaden doradca nie dostaje „wchłoń” ani „zależność”.

| Skill | Decyzja | Uzasadnienie (jedno zdanie) | Pożyczone pomysły (atrybucja) |
 |
| `/product-strategy` | **własny** | `product-strategy` i `/strategy` z pm-skills wypełniają kanwę jednorazowo bez wznawiania i briefu, a plan wymaga rozmowy z trwałym stanem i konfliktów perspektyw. | pytanie o „Trade-offs: czego NIE robimy” i „Can’t/Won’t” (pm-skills `product-strategy`) |
| `/product-red-team` (nowy etap „dobre i złe strony i jak je zaopiekować”) | **własny** | `strategy-red-team` ma najlepszy rygor ze wszystkich czytanych plików, ale nie ma kroku „jak zaopiekować słabość”, zapisu ani briefu, a ta metoda ma też zasilać `/go-to-market` i `/launch-readiness`. | steelman → atak, „Fails if”, ranking impact × likelihood × cheapness, kill criterion, najtańszy test, „co się trzyma”, „czego nie umiałem ocenić” (pm-skills `strategy-red-team`); Tigers/Paper Tigers/Elephants i klasy blokuje / 30 dni / obserwuj (`pre-mortem`); 8 kategorii ryzyka (`identify-assumptions-new`) |
| `/business-case` | **własny** | Żadne czytane źródło nie łączy rozdziału GMV/przychód/zysk, kosztu czasu i scenariuszy, a jedyny kandydat (deanpeters) ma licencję NC-SA i sprzeczny wzór payback. | pojęcia take rate i płynności marketplace’u jako pytania kontrolne (lenny `marketplace-liquidity-take-rates`, tylko lektura) |
| `/validate-product` | **własny** | `brainstorm-experiments-new` kończy się na projekcie eksperymentu, a plan wymaga uczestników, materiałów, pomiaru i interpretacji realnych wyników. | hipoteza XYZ, zasady Savoi: skin in the game, YODA, zachowanie zamiast opinii (pm-skills, za A. Savoia „The Right It”); reguły Mom Test dla wywiadów (pm-skills `interview-script`, za R. Fitzpatrick); reguła Ship/Iterate/Kill (pratikshadake) |
| `/go-to-market` | **własny, cienki** | Autor nie oceni jakości materiałów marketingowych, więc doradca ma wymuszać przewidywania mierzalne i red-team planu oraz jawnie mówić „tu brakuje wiedzy”, zamiast udawać pełną kampanię. | rozdział „check cadence / acts when” i „When NOT to loop” (marketingskills `marketing-loops`) jako zasada przeglądu tygodniowego; red-team z `/product-red-team` |
| `/ux-review` | **własny** | To mocna strona autora (frontend, UX, dostępność), a skille zewnętrzne (`cro`, `onboarding`, `signup`) optymalizują konwersję, nie zrozumienie i dostępność. | brak potrzeby |
| `/legal-review` | **własny** | `privacy-policy` ma zamrożoną listę przepisów bez dat i obiecuje gotowy do publikacji dokument, `gdpr-dsgvo-expert` uruchamia niezaufane skrypty i jest skrojony pod DE; plan wymaga datowanych źródeł urzędowych i częściowego wyniku. | lista sekcji polityki prywatności jako checklista pokrycia, bez treści prawnej (pm-skills `privacy-policy`) |
| `/launch-readiness` | **własny** | `/ship-check` obejmuje tylko kod i dubluje nasze `/ship` z audytorami, a checklista pratikshadake jest za płytka; plan wymaga płatności, anulowania, wsparcia, odtwarzania i aktywacji. | klasyfikacja pre-mortem: blokuje start / 30 dni / obserwuj (pm-skills `pre-mortem`); „not run” ≠ „run clean” (pm-skills `/ship-check`, uwagi) |

Pomijane w całości: `pm-product-strategy` (kolizja), `privacy-policy`, `/ship-check`, `gtm-strategy`, `marketing-loops` (patrz pytanie 3), `marketing-council`, `ads`, pełne pluginy pm-skills, całe repo alirezarezvani, deanpeters (licencja), founder-skills (trzeci plik kontekstu, cele bez metody), pratikshadake (za płytkie).

**Kandydat warunkowy do „wchłoń” po pilocie:** `strategy-red-team` (MIT, 4,5 tys. znaków, commit `8607e3b`). Tylko jeśli pilot (sekcja 7) pokaże, że nasz `/product-red-team` jest wyraźnie słabszy. Wtedy jako plik referencyjny wewnątrz naszego skilla (`.apm/skills/product-red-team/references/`), nie jako osobny skill. Uzasadnienie w sekcji 6.

## 3. Rekomendacja architektury i źródła prawdy

### Architektura: pełna własna (wariant A)

**Decyzja autora (sekcja 13, ADR-0001):** własni doradcy ze wspólnym kontraktem (sekcja 5), zero zależności w `apm.yml`, brak listy polecanych skilli. `.apm/SOURCES.md` zawiera wyłącznie atrybucję pożyczonych pomysłów. Pierwotnie rekomendowałem A+menu; autor wybrał A, bo link w dokumentacji paczki działa jak rekomendacja, a skille nie zostały sprawdzone w praktyce. Kolumna A+menu zostaje w tabeli jako porównanie.

| Kryterium | A: pełna własna (decyzja) | A+menu (odrzucone) | B: hybryda z zależnościami | C: pełna zależność |
|---|---|---|---|---|
| Spójność wyniku (brief, F/A/D, „czego nie oceniono”) | pełna | pełna w rdzeniu; wyniki z menu poza kontraktem | częściowa; cudze formaty | brak |
| Budżet opisów (sekcja 4) | ok. 1,6–1,8 tys. tok. | ok. 2,3–2,7 tys. | 3,2–6,2 tys. | 17–20 tys. |
| Kolizje nazw i wyzwalaczy | brak | małe, kontrolowane listą | `marketing-ideas`, `product-strategy`, „GTM” | wszystkie |
| Ryzyko zniknięcia lub zmiany źródła | brak | brak dla rdzenia | wysokie (v2.0 marketingskills przemianowała 19 skilli) | wysokie |
| Wiedza marketingowa | słaba, ale uczciwie opisana | jak A + dostęp do kanonu na żądanie | lepsza, ale nieweryfikowalna dla autora | lepsza, nieweryfikowalna |
| Koszt utrzymania | najwyższy po naszej stronie | jak A + aktualizacja listy w `SOURCES.md` | śledzenie dwóch upstreamów | śledzenie wszystkiego |
| Zgodność z planem (sekcja 2: „bez nowych zależności”) | tak | tak | nie | nie |

### Źródło prawdy

**Decyzja (sekcja 13, ADR-0001):** w repo produktu obowiązuje jeden podział, bez kopii:

- **decyzje** → `docs/adr/` (produktowe i techniczne, tym samym formatem; sekcja 13.2),
- **fakty, założenia i bieżący opis produktu** → `docs/product/brief.md` (rejestr F/A; pozycje D to tylko odnośniki do ADR),
- **praca robocza doradców** → pozostałe pliki `docs/product/*.md`.

Paczka nie tworzy `.agents/product-marketing.md` ani żadnej projekcji dla cudzych skilli. Jeśli autor sam zainstaluje cudzy skill w repo produktu, pliki tego skilla (`.agents/product-marketing.md`, `PreMortem-*.md`, `FOUNDER_CONTEXT.md`) nie są źródłem prawdy. Doradca, który je zauważy, może zaproponować przeniesienie treści do briefu jako założenia (A), nigdy jako faktu.

Wcześniejszy wariant z projekcją i mapowaniem 12 sekcji `product-marketing.md` na brief odpadł razem z menu. **[Z]** Informacyjnie: `bootstrap.py` dopisuje do `.gitignore` tylko `.agents/skills/`, więc pliki kontekstu cudzych skilli w `.agents/` byłyby śledzone przez git i łatwo uznać je za obowiązujące.

## 4. Pomiar budżetu kontekstu

**Metoda [P]:** skrypt parsuje frontmatter każdego `SKILL.md` i każdej komendy (`commands/*.md`) i liczy znaki linii `- name: description`, czyli przybliżenie wpisu w liście dostępnych skilli. Tokeny to przedział `znaki/4` do `znaki/3,5`. W środowisku nie było tokenizera Claude, więc liczby tokenów są przybliżone; liczby znaków są dokładne. Opisy ośmiu nowych doradców to szkice napisane na potrzeby pomiaru (średnio 272 znaki, z jawnym „Not for …”). Istniejące 5 skilli i 5 wrapperów zmierzono z repo.

| Wariant | Skille | Komendy | Znaki | Tokeny (przybliż.) |
|---|---|---|---|---|
| **A** — własne: 5 istniejących + 8 doradców | 13 | 13 | 6 330 | 1 580–1 810 |
| **A+menu** — A + `product-marketing`*, `analytics`, `ab-testing`, `copywriting` instalowane ręcznie | 17 | 13 | 9 377 | 2 340–2 680 |
| **B_min** — A + 4 skille pm-skills + 7 marketingskills, pojedynczo | 24 | 13 | 12 728 | 3 180–3 640 |
| **B_plugin** — A + pluginy `pm-execution` i `pm-product-discovery` w całości + 7 marketingskills | 49 | 29 | 21 526 | 5 380–6 150 |
| **C** — A + całe pm-skills + całe marketingskills | 132 | 55 | 69 497 | 17 370–19 860 |

\* W pomiarze A+menu jest `product-marketing` dla porównania z hipotezą; pierwotna rekomendacja go wykluczała, co obniżało A+menu do ok. 2,1–2,4 tys. tokenów.

Obserwacje:

- **[P]** Średni opis marketingskills ma 746 znaków (najdłuższe ok. 1 020: `marketing-plan`, `social`, `ad-creative`), pm-skills 260, nasze istniejące 204, szkice doradców 272. Jeden skill marketingowy kosztuje w liście tyle co trzy nasze.
- **[P]** Koszt przy wywołaniu (treść ładowana po dopasowaniu): `strategy-red-team` 4,5 tys. znaków; `ab-testing` 11,2 tys. + 13,9 tys. w referencjach; `copywriting` 10,9 tys. + 35,5 tys.; `seo-audit` 16,6 tys. + 20,8 tys. Dla porównania nasze `/ship` ma 38,5 tys. znaków.
- **[P]** pm-skills dystrybuuje się pluginami. Instalacja jednego skilla przez marketplace wciąga cały plugin, stąd skok z B_min do B_plugin. Pojedyncze skille można skopiować ręcznie albo przez `npx skills` **[N]: nie sprawdzono, czy `npx skills` obsługuje repo z pluginami**.
- **[N]** Nie sprawdziłem, czy Claude Code obcina listę opisów skilli powyżej jakiegoś limitu. Jeśli tak, wariant C mógłby po cichu ukrywać część skilli, także naszych. Do zmierzenia w pilocie przez `/context`.

### Kolizje nazw [P]

| Nazwa | Gdzie | Skutek |
|---|---|---|
| `product-strategy` | nasz plan i pm-skills | dokładna kolizja; w wariancie B/C wymaga przestrzeni nazw lub zmiany nazwy |
| `marketing-ideas` | pm-skills i marketingskills (oraz founder-skills) | dwa różne skille o tej samej nazwie przy wariancie C |
| `code-review` | pm-skills (`pm-ai-shipping`) i wbudowany skill Claude Code | kolizja z narzędziem środowiska |
| `launch-readiness` | nasz plan i pratikshadake | tylko przy instalacji pratikshadake (nie rekomendowane) |

### Nakładanie się wyzwalaczy

Analiza leksykalna [P] (dopasowanie słów kluczowych naszych doradców do opisów zewnętrznych) jest zaszumiona. Na przykład „ads” trafia też w niepowiązane słowa, więc podaję tylko pary sprawdzone ręcznie [Z]:

- `/go-to-market` ↔ `gtm-strategy`, `gtm-motions`, `beachhead-segment` (pm) oraz `launch`, `marketing-plan`, `marketing-ideas`, `analytics` (przez „GTM” = Tag Manager) (mk). Najgorszy obszar: 31 opisów marketingskills zawiera słowa z naszego słownika GTM.
- `/product-strategy` ↔ `product-strategy`, `product-vision`, `startup-canvas`, `value-proposition`, `monetization-strategy` (pm), `product-marketing` (mk: „positioning”, „ICP”).
- `/validate-product` ↔ `brainstorm-experiments-new`, `identify-assumptions-new`, `interview-script` (pm), `ab-testing` („experiment”, „hypothesis”), `customer-research` (mk).
- `/product-red-team` ↔ `strategy-red-team`, `pre-mortem`, `identify-assumptions-*` (pm).
- `/business-case` ↔ `business-model`, `lean-canvas`, `pricing-strategy` (pm), `pricing`, `paywalls` (mk).
- `/launch-readiness` ↔ `pre-mortem` (pm), `launch` (mk: launch marketingowy, nie gotowość operacyjna).
- `/ux-review` ↔ `onboarding`, `signup`, `cro` (mk).
- `/legal-review` ↔ `privacy-policy`, `draft-nda` (pm).

Wniosek [O]: w wybranym wariancie A kolizji i nakładania się nie ma w paczce. Pojawią się tylko wtedy, gdy autor sam doinstaluje cudze skille w repo produktu; opisy naszych doradców zawierają „Not for …”, co ogranicza fałszywe wyzwalanie.

## 5. Specyfikacja kontraktu wspólnego

Kontrakt jest krótkim blokiem (cel: najwyżej 60 linii), **kopiowanym** do każdego `SKILL.md` doradcy między znacznikami `<!-- advisor-contract:v1 -->` … `<!-- /advisor-contract:v1 -->`. Kopia zachowuje samowystarczalność każdego skilla (wymóg planu), a `scripts/check.sh` sprawdza, że wszystkie kopie są identyczne. To mechanizm podobny do istniejącego `check_interaction_contract`.

### 5.1 Pliki i zapis

- Katalog `docs/product/`; istniejący dokument o tej samej funkcji ma pierwszeństwo (bez zmian względem planu).
- Każdy doradca zapisuje **tylko** swój plik. `brief.md` aktualizuje wyłącznie `/product-strategy`. Inni doradcy mogą dopisać do `brief.md` jedynie wpis w sekcji „Propozycje zmian” ze statusem `proposed`.
- Zapis następuje po ustaleniu, nie po każdej wypowiedzi. Ustalenie to nowy fakt ze źródłem, nowe założenie, potwierdzona decyzja albo wynik eksperymentu.
- Zakaz transkrypcji: nie zapisujemy pytań i odpowiedzi, tylko ich skutek. Cytat klienta wolno zapisać wyłącznie w „Języku klienta”, ze źródłem (data, kanał) i bez danych osobowych.
- Nie tworzymy pustych plików ani szablonów „na zapas”.

### 5.2 Schemat `brief.md`

```md
# Brief produktu: [nazwa]
- **Aktualizacja:** [YYYY-MM-DD] · **Wersja:** [n]

## Produkt
## Odbiorca i segment początkowy
## Problem
## Alternatywy i przewaga
## Model przychodu
## Poza zakresem (czego NIE robimy)
## Język klienta            <!-- tylko cytaty z realnych rozmów, ze źródłem -->
## Rejestr
| ID | Typ | Treść | Źródło / dowód | Poziom dowodu | Status | Data |
|---|---|---|---|---|---|---|
<!-- Typ: F (fakt) | A (założenie) | D (decyzja); Status: active | superseded by <ID> | rejected -->
## Propozycje zmian (od innych doradców)
## Niewiadome
## Stan rozmowy
- **Bieżący temat:** · **Otwarte pytanie:** · **Następny krok:**
```

Rozdział faktów, założeń i decyzji:

- **F (fakt):** wymaga źródła: link, plik, dane, data rozmowy. Bez źródła pozycja jest A.
- **A (założenie):** wymaga sposobu sprawdzenia (odsyłacz do testu w `validation.md` lub „nie do sprawdzenia teraz: dlaczego”).
- **D (decyzja):** wymaga potwierdzenia użytkownika w rozmowie i odwołań do F/A, na których stoi. Treść i uzasadnienie żyją **wyłącznie w ADR** (sekcja 13.2); w rejestrze briefu D to jedna linia: ID, tytuł, odnośnik `docs/adr/NNNN-*.md`. Gdy obalone zostanie A, od którego zależy D, doradca oznacza ADR jako „do przeglądu” i proponuje nowy ADR zastępujący.
- **Poziom dowodu:** `zachowanie z zaangażowaniem` > `zachowanie` > `deklaracja` > `opinia AI / cudze dane`. Zgodność kilku perspektyw AI nigdy nie podnosi poziomu dowodu (zgodnie z `.apm/README.md`).

### 5.3 Format wyniku każdego doradcy

````md
# [Doradca]: [temat]
- **Aktualizacja:** [YYYY-MM-DD] · **Wejście:** [brief.md v.n, inne pliki]

## Wniosek
[1–3 zdania, warunkowy: „jeśli A-3 się potwierdzi, to …”]

## Ustalenia
[pozycje z ID z rejestru, F/A/D]

## Co się trzyma
[jawnie, bez sztucznego wątpienia]

## Czego nie oceniono
| Obszar | Dlaczego | Co by to zmieniło | Kto lub co może to ocenić |
|---|---|---|---|
<!-- powody: brak danych | brak dostępu do źródeł | poza kompetencją (prawnik, księgowy) | brak ruchu | nie uruchomiono testu -->

## Następny krok
[najmniejsze działanie, które może zmienić wniosek; właściciel = użytkownik; data]

## Stan rozmowy
- **Bieżący temat:** · **Otwarte pytanie:** · **Następny krok:**
````

Sekcja „Czego nie oceniono” jest obowiązkowa i nigdy nie jest pusta bez słowa: jeśli nic, to „Brak — [uzasadnienie]”. Wynik częściowy ma pierwszeństwo przed zmyślonym. Na przykład `/legal-review` bez dostępu do źródeł wpisuje „brak dostępu do źródeł” zamiast streszczać przepisy z pamięci.

### 5.4 Cudze skille i atrybucja

Po decyzji z sekcji 13 doradcy **nie** wykrywają, nie proponują i nie wywołują cudzych skilli; adapter z wcześniejszej wersji tego dokumentu odpadł. Zostają dwie zasady:

1. **Atrybucja pożyczonego pomysłu:** w `SKILL.md` doradcy jedna linia przy metodzie, np. „Metoda inspirowana: phuryn/pm-skills `strategy-red-team` (MIT), A. Savoia *The Right It*”, oraz wpis w `.apm/SOURCES.md` (repo, plik, commit, licencja, co wzięto). To podziękowanie, nie rekomendacja instalacji. Atrybucję autorów książek i metod sprawdzamy u źródła (przykład Torres/Cagan z sekcji 1).
2. **Materiał spoza kontraktu:** jeśli użytkownik wklei wynik cudzego narzędzia, doradca traktuje go jak każdy materiał wejściowy. Twierdzenia bez źródła w danych użytkownika są założeniami (A), benchmarki mają poziom dowodu „cudze dane”, a surowego wyniku nie zapisuje.

## 6. Wchłonięcie kontra zależność

| Wymiar | Własny | Wchłoń (kopia z notą MIT) | Zależność |
|---|---|---|---|
| Utrzymanie | pełne po naszej stronie | jak własny; kopia się nie aktualizuje | śledzenie upstreamu, zmian nazw i ścieżek |
| Aktualizacje | gdy chcemy | ręczny diff względem przypiętego commita | automatyczne lub zablokowane; ryzyko zmian łamiących (marketingskills v2.0: 19 nazw, ścieżka pliku kontekstu) |
| Zgodność z APM | pełna | **[Z]** `includes: auto` wdroży każdy katalog w `.apm/skills/` jako żywy skill; kopia jako osobny skill zwiększa budżet i dostaje nasz rejestr. Kopia jako plik `references/` wewnątrz naszego skilla tego unika. | **[Z]** brak `apm.yml` w obu repo, więc nie da się ich wpisać do `dependencies.apm` bez opakowania; dystrybucja pluginami lub `npx skills` to inny mechanizm niż APM |
| `scripts/check.sh` | nowe skille przechodzą `check_skill` (name, description) oraz nowy test kontraktu | kopia w `references/` nie jest sprawdzana jako skill; potrzebny test obecności `NOTICE`/nagłówka MIT i commita | nie dotyczy (poza paczką); można dodać ostrzeżenie o znanych kolizjach nazw |
| `scripts/smoke.sh` | **[Z]** komunikat „five shared skills present” i `is_agent_army_skills()` wymagają aktualizacji przy rozszerzeniu `SKILLS` | jak własny | nie dotyczy; smoke nie może zależeć od sieci („offline apart from apm”, `tests/GUIDE.md`) |
| Rozjazd z oryginałem | brak oryginału | rośnie z czasem; przypięty commit pozwala porównać | brak rozjazdu, ale brak kontroli |
| Licencja | brak wymagań | MIT: zachować nota copyright i tekst licencji w każdej kopii; CC BY-NC-SA (deanpeters): **niedozwolone** | brak obowiązków po naszej stronie |
| Ryzyko zniknięcia | brak | brak (kopia zostaje) | wysokie |
| Instalacja ręczna przez użytkownika (poza paczką) | — | — | **[Z]** `bootstrap.py` dodaje `.agents/skills/` do `.gitignore`, więc skille wrzucone tam przez `npx skills` bez `-a claude-code` nie trafią do repo i są niewidoczne dla Claude Code. Informacja dla autora, nie dokumentacja paczki. |

**Wniosek [O]:** pomysły z atrybucją wystarczą dla v0.4.0. Jeśli kiedyś wchłaniamy, to tylko krótkie, stabilne metody (np. `strategy-red-team`), jako plik w `references/` naszego skilla, z nagłówkiem `Source: phuryn/pm-skills@8607e3b, MIT, © 2026 Pawel Huryn` i kopią licencji. Zależność odpada do czasu, aż upstream ma `apm.yml`, wersjonowanie semantyczne i stabilne nazwy.

## 7. Plan pilota

**Cel:** sprawdzić przed implementacją w paczce, czy rozmowa z zapisem daje lepsze decyzje niż szablon, i czy wspólny kontrakt działa w praktyce.

- **Produkt:** jeden prawdziwy, nowy pomysł autora (bez repo lub z małym repo). Ten sam opis wejściowy, maksymalnie 1 strona, zamrożony przed startem.
- **Środowisko:** izolowane repo-scratch na każde ramię, bez instalacji w repo Agent Army. Prototypy `SKILL.md` doradców leżą w scratch `.claude/skills/`, nie w `.apm/`.
- **Ramiona:**
  1. **N** — prototypy `/product-strategy` → `/product-red-team` → `/validate-product` (+ `/business-case` w wersji szkicowej);
  2. **P** — pm-skills `/discover` i `/strategy` (pluginy `pm-product-discovery`, `pm-product-strategy` na commicie `8607e3b`);
  3. **K** — kontrola: zwykła sesja bez skilli, ta sama prośba.
- **Przebieg:** dwie sesje na ramię, a druga to **wznowienie w nowej sesji**, bez historii rozmowy, tylko z plikami. Limit 45 minut na sesję. Zapis: liczba tur, tokeny z `/context` (także pomiar listy skilli, otwarte ryzyko z sekcji 4), wytworzone pliki.

Scenariusze z sekcji 5 planu, które da się sprawdzić w pilocie:

| Scenariusz planu | Ramiona | Co sprawdzamy |
|---|---|---|
| Pomysł bez repo i danych | N, P, K | czy powstaje eksperyment bez wymyślonego popytu |
| SaaS i marketplace | N (business-case), P (`/business-model` opcjonalnie) | rozdział GMV i przychodu, poprawność rachunków (sprawdzona arkuszem) |
| Wznowienie rozmowy bez starych planów | N, P, K | czy druga sesja nie powtarza rozstrzygniętych pytań |
| Kampania przy małym budżecie | N (`/go-to-market`) vs P (`gtm-strategy`) | czy jest przewidywanie z progiem i limitem, bez publikacji |
| Audyt prawny przy niedostępnym researchu | N (`/legal-review` z wyłączonym web) vs P (`privacy-policy`) | czy wynik jest jawnie częściowy |

Kryteria oceny (rubryka 0–2 na kryterium, oceniana przez autora na plikach wynikowych, z ukrytym ramieniem, na ile to możliwe):

1. **Fałszywe fakty:** liczba twierdzeń podanych jako fakt bez źródła (cel: 0). Liczone ręcznie, z listą.
2. **Rozdział F/A/D:** czy da się bez pytania wskazać, co jest decyzją, a co założeniem.
3. **Falsyfikowalność:** czy każde kluczowe założenie ma test z progiem i kryterium „kill”.
4. **Najmniejszy następny krok:** wykonalny przez solo twórcę w ≤ 1 tydzień i ≤ ustalony budżet.
5. **Wznowienie:** liczba powtórzonych pytań w sesji 2 (cel: 0) i czy stan został odtworzony z plików.
6. **Zmiana decyzji:** czy ramię doprowadziło autora do zmiany planu (zapisać, co i dlaczego).
7. **Koszt:** tury, tokeny, czas.
8. **„Czego nie oceniono”:** obecność i trafność (czy wskazuje realne luki).

Reguła decyzji (ustalona z góry):

- Jeśli **P ≥ N** na co najmniej 5 z 8 kryteriów, rozważamy wchłonięcie metod P albo zmniejszenie zakresu własnych doradców, przed rewizją 2 planu.
- Jeśli **K ≈ N** (różnica ≤ 2 punkty łącznie), doradcy nie dają wartości ponad zwykłą rozmowę i zakres należy przemyśleć.
- Jeśli N wygrywa, ale pojawiają się fałszywe fakty, poprawiamy kontrakt przed implementacją.

Ograniczenie: n = 1 produkt i jeden oceniający, który zna ramiona. Pilot pokaże duże różnice, nie małe.

## 8. Weryfikowalność wyników marketingowych (zadanie 9)

**Ocena [O]:** autor nie zweryfikuje *jakości* tekstów czy wyboru kanału na wyczucie. Może jednak zweryfikować *przewidywania*, jeśli są zapisane przed działaniem i mierzalne. Na etapie bez ruchu większość wyników będzie nierozstrzygnięta, i to trzeba mówić wprost.

Mechanizmy w `/go-to-market` (własne, bez zależności):

1. **Rejestr przewidywań przed startem:** każda rekomendacja kanału lub komunikatu to wpis „Jeśli zrobimy X dla segmentu Y, to w czasie T metryka M ≥ próg; jeśli < próg kill, przerywamy”, z datą zapisu przed działaniem. Bez tego wpisu rekomendacja nie trafia do pliku.
2. **Bramka ruchu dla testów A/B:** przed propozycją testu doradca liczy wymaganą próbę (przybliżenie Lehra `n ≈ 16·p(1−p)/δ²` na wariant przy α = 0,05 i mocy 80%). Przykład: konwersja bazowa 3%, wykrywana zmiana +30% względnie (δ = 0,9 p.p.), daje ok. 5 700 odwiedzin na wariant. Gdy ruch jest za mały, doradca proponuje test jakościowy (wywiady, test 5 sekund, ręczny pre-order) albo test progowy z bezwzględnym progiem zamiast A/B.
3. **Minimalny plan pomiaru:** 4–6 zdarzeń (wizyta, rejestracja, pierwszy użyteczny rezultat, zakup, powrót w 7 dni) z nazwami i miejscem pomiaru. Właścicielem pomiaru jest `/product-metrics` (sekcja 12.2).
4. **Red-team planu marketingowego:** obowiązkowy przebieg metody `/product-red-team` na planie przed jego zatwierdzeniem. Wynik: 3–5 „Fails if”, najtańszy test i to, co się trzyma.
5. **Benchmarki jako cudze dane:** każdy benchmark (CTR, konwersja branżowa) jest A z poziomem „cudze dane” i nie może być progiem sukcesu bez uzasadnienia.
6. **Ręczny przegląd tygodniowy:** zasada „check cadence / acts when”. Co tydzień porównanie przewidywań z danymi; przy braku danych wpis „za mało sygnału” zamiast interpretacji.
7. **Limit budżetu i warunek stopu:** każda płatna akcja ma kwotę maksymalną i kryterium przerwania; publikacja i wydatki tylko na polecenie użytkownika (bez zmian względem planu).

Testy A/B mają sens dopiero po przejściu bramki ruchu z punktu 2. Wcześniej zwiększają ryzyko fałszywych wniosków.

## 9. Odpowiedzi na pytania

1. **Hybryda vs pełna własna vs pełna zależność.** Hybryda z zależnościami przegrywa. Rekomendowałem **własne + menu**; autor wybrał **pełną własną paczkę z atrybucją pomysłów** (sekcja 13). *Za:* spójny kontrakt, ok. 1,6–1,8 tys. tokenów opisów zamiast 17–20 tys., brak ryzyka zniknięcia lub przemianowania, brak rekomendowania niesprawdzonych narzędzi, zgodność z planem. *Przeciw:* słabsza wiedza marketingowa w rdzeniu i więcej pracy autorskiej. Kompensują to mechanizmy weryfikacji z sekcji 8 i `/product-metrics`. Hybryda z zależnościami dawałaby kolizje (`product-strategy`, `marketing-ideas`, „GTM”), dwa źródła prawdy i brak instalacji przez APM.
2. **Co warto wziąć bez wątpliwości:** pomysły z `strategy-red-team`, klasyfikację `pre-mortem`, 8 kategorii ryzyka, hipotezę XYZ i zasady Savoi, reguły Mom Test, wszystkie z atrybucją. Żadnego cudzego skilla paczka nie poleca (decyzja autora). Najbardziej wartościowe merytorycznie były `analytics`, `copywriting` i `ab-testing`; ich tematy pokrywają `/product-metrics` i `/go-to-market`. **Czego nie brać nawet jako inspiracji:** `product-strategy` (pm), `privacy-policy`, `/ship-check`, `gtm-strategy`, `product-marketing`, `marketing-loops`, pełne pluginy, alirezarezvani, deanpeters (licencja), founder-skills, pratikshadake.
3. **`marketing-loops` w v0.4.0: nie.** Proponowane kryteria włączenia [O], wszystkie łącznie: (a) tracking zweryfikowany i stabilny przez ≥ 2 tygodnie (odpowiednik `tracking-QA` ze skilla); (b) wolumen pozwalający na decyzję w kadencji pętli, np. ≥ 100 zdarzeń kluczowej konwersji tygodniowo (skill podaje 40 odwiedzin/tydzień jako przykład szumu); (c) aktywny budżet płatny z limitem i właścicielem; (d) dostęp do API platform reklamowych i analityki co najmniej do odczytu; (e) co najmniej 4 ręczne przeglądy tygodniowe, które prowadziły do działań; (f) dostępny harmonogram i checkpoint człowieka dla publikacji i budżetu. Do tego czasu `/go-to-market` stosuje tylko ręczny przegląd tygodniowy.
4. **Spójna jakość przy cudzych metodach:** (a) kontrakt kopiowany do każdego skilla i sprawdzany deterministycznie w `check.sh` (identyczność bloku); (b) cudze metody wchodzą tylko jako pomysły przepisane do naszego kontraktu, z atrybucją; (c) fixture’y zachowania z sekcji 5 planu z rubryką z pilota (sekcja 7) zamiast wyszukiwania fraz; (d) atrybucje sprawdzone u źródła (przykład Torres/Cagan); (e) obowiązkowe „Czego nie oceniono”; (f) decyzje o metodach i zakresie zapisane jako ADR (sekcja 13.2), więc zmiana metody to nowy ADR, a nie cicha edycja.
5. **Zmiany w planie:** sekcja 10.

## 10. Lista zmian w planie (sekcje 2–4)

| # | Sekcja | Zmiana | Nowa rewizja? |
|---|---|---|---|
| 1 | 2 | Dodać ósmy skill `/product-red-team` („dobre i złe strony i jak je zaopiekować”) z artefaktem `docs/product/product-red-team.md` | **tak**, zmiana zakresu |
| 2 | 2 | Opis `/go-to-market`: zamiast „Przygotowuje konkretną kampanię: … budżet i pomiar” wpisać „cienki, oparty na rejestrze przewidywań, bramce ruchu, red-teamie planu i limicie budżetu; jawnie wskazuje braki wiedzy; materiały kampanii tylko jako szkice do testu” | **tak**, zmiana zachowania |
| 3 | 2 | Dodać podsekcję „Wspólny kontrakt doradców” (sekcja 5 tego dokumentu): schemat briefu, rejestr F/A/D z ID i poziomem dowodu, format wyniku, „Czego nie oceniono” | **tak** |
| 4 | 2 | Doprecyzować „samowystarczalna, bez nowych zależności”: żadnych polecanych cudzych skilli w dokumentacji; `.apm/SOURCES.md` tylko z atrybucją pożyczonych pomysłów; brak wpisów w `apm.yml` | tak (w tej samej rewizji co 1–3) |
| 5 | 3 | Dodać regułę źródła prawdy: decyzje w `docs/adr/`, fakty i założenia w `brief.md`, D w briefie tylko jako odnośnik do ADR; pliki cudzych skilli nie są źródłem prawdy (sekcja 13.2) | **tak** |
| 6 | 3 | Dodać zasadę atrybucji i traktowania wklejonego cudzego materiału (sekcja 5.4); doradcy nie wywołują cudzych skilli | tak |
| 7 | 3 | Dodać sekcję „Język klienta” w briefie (tylko cytaty z realnych rozmów ze źródłem, bez danych osobowych) | tak |
| 8 | 4, zad. 1 | Dodać blok `advisor-contract:v1` w każdym `SKILL.md` doradcy; wrappery dla 8 skilli | tak |
| 9 | 4, zad. 3 | Rejestr `SKILLS` w `bootstrap.py`: z 5 do **13**, nie 12. Uwzględnić, że `is_agent_army_skills()` wymaga obecności wszystkich nazw; sprawdzić odzyskiwanie brakujących skilli przy instalacji 0.3.1 z 5 skillami | **tak**, zmiana liczby |
| 10 | 4, zad. 3 | `check.sh`: test identyczności bloku kontraktu, test, że żaden `SKILL.md` ani README nie zawiera instrukcji instalacji cudzych skilli, zakaz katalogów wchłoniętych bez nagłówka MIT i commita | tak |
| 11 | 4, zad. 3/5 | `smoke.sh`: komunikat i asercje „five shared skills” → 13; smoke pozostaje offline (bez instalacji zewnętrznych) | tak |
| 12 | 4, zad. 5 | Dodać `.apm/SOURCES.md` wyłącznie z atrybucją (repo, plik, commit, licencja, co wzięto); bez linków z README jako rekomendacji; **[N]** sprawdzić, czy APM pakuje plik w korzeniu `.apm/` (istniejący `.apm/README.md` sugeruje, że tak) | tak |
| 13 | 4 | Dodać **Zadanie 0 — pilot** (sekcja 7) przed Zadaniem 1, z regułą decyzji; jego wynik może zmienić zakres | **tak**, zmiana kolejności |
| 14 | 5 | Kryterium gotowości: „dwanaście skilli” → „trzynaście”; dodać rubrykę z pilota do scenariuszy zachowania | tak (konsekwencja 1 i 13) |
| 15 | 2, ścieżki | Ścieżka „Nowy produkt”: strategia → **red-team** → wstępna ekonomia → walidacja → korekta → architektura → wykonanie | tak |
| 16 | 2 | Dodać `/product-metrics` (sekcja 12.2): właściciel `docs/product/metrics.md`, od planu pomiaru przez weryfikację zbierania po odczyt danych po starcie | **tak**, zmiana zakresu |
| 17 | 2 | Dodać `/market-research` (sekcja 12.1) albo jawnie rozszerzyć `/product-strategy` o tryb researchu z datowanymi źródłami | **tak** |
| 18 | 2, 4 | Instrumentacja zdarzeń w kodzie produktu idzie przez `/ship` (blueprint architekta + test, że zdarzenie wysyła się zgodnie ze schematem); doradcy nie piszą kodu | tak |
| 19 | 2 | `/go-to-market` i `/launch-readiness` nie definiują własnych zdarzeń, tylko odwołują się do `metrics.md` | tak |
| 20 | 4 | Dodać sekcję „Etapy automatyzacji” z kryteriami wejścia (sekcja 12.4); bez implementacji w v0.4.0 | tak |
| 21 | 3 | „Lekkie ADR-y” (sekcja 3 planu) rozszerzyć na decyzje produktowe: jeden katalog `docs/adr/`, jeden format, pole `Typ: produkt | architektura | proces`, `Podstawa` (ID z rejestru F/A) i `Warunek rewizji` (sekcja 13.2) | **tak** |
| 22 | 3, 4 zad. 2 | ADR jako jedyne źródło decyzji: brief i pliki doradców tylko odsyłają; zmiana decyzji = nowy ADR ze statusem „zastępuje”, stary dostaje „zastąpiony przez”; ADR powstaje także w trakcie kodowania (`/ship`), gdy zapada istotna decyzja | **tak** |
| 23 | 4 zad. 2 | `docs-writer`: zapisuje ADR po potwierdzeniu decyzji przez człowieka, przed commitem, bez wymogu merge’a; status `Zaakceptowana` ≠ „wdrożona” (pole `Wdrożenie`) | tak |
| 24 | 4 zad. 3/5 | `check.sh` w repo docelowym nie dotyczy; w paczce: test, że szablon ADR w `docs-writer` i w kontrakcie doradców mają te same pola | tak |

Bez nowej rewizji (doprecyzowania zgodne z rewizją 1): nazwy plików, przykłady w skillach, treść opisów `description` w granicach zakresu.

## 11. Otwarte ryzyka i niewiadome

| # | Ryzyko lub niewiadoma | Stan | Jak zamknąć |
|---|---|---|---|
| 1 | Liczby tokenów są przybliżeniem ze znaków (brak tokenizera Claude) | [P] znaki dokładne, tokeny ±15% | `/context` w pilocie |
| 2 | Czy Claude Code ogranicza lub obcina listę opisów skilli przy dużej liczbie | [N] | sprawdzić w dokumentacji i w pilocie (wariant C w scratch repo) |
| 3 | Zachowanie przestrzeni nazw pluginów przy kolizji `product-strategy` | [N] | test w scratch repo z pluginem `pm-product-strategy` |
| 4 | APM niezainstalowane w środowisku oceny; pakowanie `.apm/SOURCES.md` nie sprawdzone | [N] | `apm pack` i instalacja w izolowanym repo (Zadanie 3 planu) |
| 5 | Jakość wyników skilli marketingowych nie była uruchamiana, tylko czytana | [N] | ramię P pilota |
| 6 | Autor nie oceni jakości marketingu; na etapie bez ruchu przewidywania pozostaną nierozstrzygnięte | [O] ryzyko strukturalne | rejestr przewidywań i bramka ruchu; jawne „za mało sygnału” |
| 7 | Autor sam doinstaluje cudzy skill w repo produktu, a jego plik kontekstu zacznie żyć własnym życiem | [O] | reguła z sekcji 3: pliki cudzych skilli nie są źródłem prawdy; doradca proponuje przeniesienie do briefu jako A |
| 8 | `/legal-review` wymaga dostępu do aktualnych źródeł; bez sieci wynik zawsze częściowy | [Z] wymóg planu | jawny częściowy wynik; lista pytań do prawnika |
| 9 | Atrybucje w cudzych plikach bywają nieprecyzyjne (Torres vs Cagan) | [Z/N] | sprawdzić u źródła przed wpisaniem do naszych skilli |
| 10 | Zmienność upstreamu (marketingskills v2.0: 19 zmian nazw; rozwijana warstwa partnerska) | [Z] | brak zależności i menu; atrybucja wskazuje przypięty commit, więc zmiany upstreamu nas nie dotyczą |
| 11 | Ósmy skill zwiększa zakres i koszt utrzymania | [O] | pilot rozstrzyga, czy `/product-red-team` daje wartość osobno, czy wystarczy sekcja w `/product-strategy` |
| 12 | Pilot ma n = 1 i oceniającego znającego ramiona | [O] | traktować wynik jako wykrywacz dużych różnic; powtórzyć na drugim pomyśle przed 0.5.0 |
| 13 | Liczba gwiazdek i popularność repo nie sprawdzone | [N] | nieistotne dla decyzji; nie używać jako argumentu |
| 14 | Opisy ośmiu doradców w pomiarze to szkice; ostateczne mogą być dłuższe | [P] | ponowić pomiar po napisaniu `SKILL.md`; cel ≤ 300 znaków na opis |
| 15 | Analityka wymaga zgody użytkowników (cookies, RODO) i wyboru narzędzia; zła decyzja tu blokuje cały pomiar | [O] | `/legal-review` ocenia `metrics.md` przed wdrożeniem; preferować pomiar bez identyfikacji osób, gdy wystarcza |
| 16 | Przy małym ruchu dane będą przez długi czas nierozstrzygające | [O] | metryki bezwzględne i kohorty tygodniowe zamiast testów statystycznych; łączenie z danymi jakościowymi |
| 17 | Dostęp doradców do danych (eksport vs API/MCP) zależy od środowiska, nie od paczki | [N] | wersja minimalna: eksport CSV do `docs/product/data/`; integracje dopiero na etapie automatyzacji |

## 12. Rozszerzenie: research rynku, analityka, etap po starcie, automatyzacje

Dopisane po rozmowie z autorem 2026-10-07. Cel: domknąć ścieżkę end-to-end i dać jej drogę do automatyzacji marketingowych. **[O]** Sekcja 8 zawierała tylko *plan* pomiaru (4–6 zdarzeń). Brakowało właściciela, zbierania danych, weryfikacji, zgody użytkowników i odczytu danych po starcie. Bez tego etap po starcie i każda automatyzacja nie mają na czym działać.

### 12.1 `/market-research`

- Konkurencja, alternatywy, ceny, kanały konkurentów i opinie klientów o alternatywach.
- Każde ustalenie ma źródło z datą sprawdzenia i jest oznaczone jako „cudze dane” (A), nie jako dowód popytu.
- Bez dostępu do sieci wynik jest częściowy, z listą do sprawdzenia ręcznie.
- Zapis: `docs/product/market-research.md`. Do `brief.md` trafiają tylko propozycje zmian (zgodnie z kontraktem).
- Alternatywa o mniejszym koszcie kontekstu: tryb researchu w `/product-strategy`. Rozstrzyga pilot.

### 12.2 `/product-metrics`: pomiar przez cały cykl

Jeden doradca jest właścicielem jednego pliku `docs/product/metrics.md`. Zapobiega to sytuacji, w której `/go-to-market`, `/launch-readiness` i późniejsze pętle definiują zdarzenia każdy po swojemu.

Cykl:

1. **Definicja:** pytania decyzyjne („co zrobię inaczej, jeśli liczba wyjdzie X?”), metryka główna i 3–5 metryk wejściowych, lejek (wizyta → rejestracja → pierwszy użyteczny rezultat → zakup → powrót), schemat zdarzeń `obiekt_akcja` z właściwościami, źródło każdej liczby (analityka produktu, płatności, e-mail) i minimalny wolumen, przy którym liczba coś mówi.
2. **Prywatność i zgoda:** jakie dane są osobowe, czy potrzebna jest zgoda na cookies, retencja. Przed wdrożeniem przekazanie do `/legal-review`. Preferencja: najmniej danych, które odpowiadają na pytania decyzyjne.
3. **Wybór narzędzia:** doradca proponuje opcje według potrzeb i prywatności, bez zakładania konkretnego płatnego narzędzia (zgodnie z planem). Decyzja trafia do rejestru jako D.
4. **Instrumentacja:** to praca inżynierska, więc idzie przez `/ship`. Architekt dostaje `metrics.md` jako wejście, a tester pisze test, że zdarzenie wysyła się z właściwym schematem. To mocna strona Agent Army: kontrakt zdarzeń da się sprawdzić deterministycznie, w przeciwieństwie do jakości copy.
5. **Weryfikacja zbierania:** przed pierwszą interpretacją sprawdzenie, czy zdarzenia faktycznie docierają: próba ręczna, porównanie z płatnościami, brak duplikatów. Do tego czasu status „pomiar niezweryfikowany”, a żaden doradca nie interpretuje tych liczb.
6. **Odczyt po starcie:** dane trafiają do doradców w wersji minimalnej jako eksport CSV do `docs/product/data/` (z datą, bez danych osobowych). Przez API lub MCP dopiero na etapie automatyzacji. Doradca porównuje dane z rejestrem przewidywań z `/go-to-market` i z progami z `/validate-product`. Kieruje dalej: słaba aktywacja → `/ux-review`, brak popytu → `/validate-product` lub `/product-strategy`, zły koszt pozyskania → `/business-case` lub `/go-to-market`.
7. **Mały ruch:** liczby bezwzględne i kohorty tygodniowe zamiast testów istotności; jawne „za mało sygnału”.

`/launch-readiness` sprawdza jedynie, czy punkty 1–5 są spełnione (pomiar jest warunkiem gotowości, nie jego treścią). Doradca nie korzysta z cudzych skilli analitycznych (sekcja 13).

### 12.3 Etap po starcie

Etap po starcie zapewnia punkt 6 z 12.2, bez osobnego skilla. Ścieżka w katalogu: „Produkt wystartował: `/product-metrics` (odczyt) → doradca wskazany przez dane → korekta → `/ship`”.

### 12.4 Etapy automatyzacji (kryteria wejścia)

| Etap | Co działa | Kryterium wejścia |
|---|---|---|
| 0 — ręcznie (v0.4.0) | przegląd tygodniowy: przewidywania vs eksport danych | `metrics.md` zdefiniowany, pomiar zweryfikowany (12.2, pkt 5) |
| 1 — odczyt automatyczny | harmonogram (`/loop`, rutyna, cron) pobiera dane przez API/MCP i przygotowuje raport w formacie kontraktu; zero działań na zewnątrz | ≥ 4 ręczne przeglądy, które prowadziły do decyzji; dostęp do danych tylko do odczytu; stabilny schemat zdarzeń przez ≥ 2 tygodnie |
| 2 — szkice działań | pętla przygotowuje szkice (copy, zmiana stawki, e-mail) do zatwierdzenia przez autora | kryteria z sekcji 9, pytanie 3 (wolumen, budżet z limitem, właściciel) |
| 3 — działania w limitach | ograniczone działania bez pytania, np. pauza reklamy powyżej progu kosztu; publikacja i zwiększanie budżetu nadal z zatwierdzeniem | jawne limity kwotowe, lista dozwolonych akcji, wyłącznik awaryjny, log każdej akcji w repo |

Każda pętla musi mieć wszystkie części z `marketing-loops` (kadencja, warunek działania, self-check, stan, stop). Rozszerzenie opiera się na tych samych plikach (`metrics.md`, rejestr przewidywań), więc nie tworzy nowego źródła prawdy.

### 12.5 Wpływ na budżet i zakres

Dwa dodatkowe doradcy to łącznie 15 skilli. Szacunkowo +150–200 tokenów w liście opisów **[O]**, czyli wariant A to nadal ok. 1,8–2,0 tys. Zakres v0.4.0 rośnie, więc proponuję kolejność: v0.4.0 = rdzeń + `/product-metrics` (bez pomiaru reszta jest nieweryfikowalna), a `/market-research` dołącza, jeśli pilot pokaże, że tryb w `/product-strategy` nie wystarcza. Automatyzacje (etapy 1–3) to v0.5.0+.

## 13. Decyzje autora po ocenie i ADR jako jedyne źródło decyzji

### 13.1 Decyzje z 2026-10-07

1. **Brak menu cudzych skilli.** Paczka nie poleca, nie linkuje (README, katalog, skille) i nie wykrywa cudzych skilli. Powód: link w dokumentacji działa jak rekomendacja, a skille nie zostały sprawdzone w praktyce i mogą się zmienić bez naszej kontroli.
2. **Atrybucja zostaje.** Pożyczone pomysły (red-team, pre-mortem, osiem kategorii ryzyka, hipoteza XYZ, zasady Savoi, Mom Test) mają źródło w skillu i w `.apm/SOURCES.md`. To podziękowanie, nie rekomendacja.
3. **Decyzje jako ADR w repo.** Zarówno w tym repo, jak i w repo produktu każda istotna decyzja, także podjęta w trakcie kodowania, ma postać ADR w `docs/adr/`. ADR jest jedynym źródłem prawdy o decyzjach; dokumenty analityczne (jak ten) i plany w `design-docs/` są materiałem roboczym.

Pierwszy taki zapis: [ADR-0001](../docs/adr/0001-samowystarczalni-doradcy-produktowi.md).

### 13.2 Model ADR (repo paczki i repo produktu)

**Gdzie:** `docs/adr/NNNN-slug.md`, numeracja ciągła, jeden katalog dla decyzji produktowych, technicznych i procesowych. Istniejący katalog ADR w repo produktu ma pierwszeństwo.

**Kiedy powstaje ADR:**

- decyzja zmienia kierunek, zakres, architekturę, model przychodu, segment, kanał, sposób pomiaru albo zasadę pracy;
- ktoś za pół roku zapytałby „dlaczego tak?”, a odpowiedź nie wynika z samego kodu;
- decyzja zapada w rozmowie z doradcą (D w rejestrze) **albo w trakcie kodowania** (`/ship`, architekt, review).

**Kiedy nie:** zwykła poprawka, wybór oczywisty z konwencji repo, ustalenie robocze, które jeszcze nie jest decyzją (zostaje w pliku doradcy jako notatka).

**Kto zapisuje:** doradca lub `docs-writer` proponuje treść; ADR dostaje status `Zaakceptowana` dopiero po potwierdzeniu przez człowieka. Uzasadnienie pochodzi z rozmowy, nie jest dopowiadane z kodu (zgodnie z `.apm/README.md`).

**Format** (rozszerzenie istniejącego szablonu z `docs-writer.md`):

```md
# ADR-NNNN: [tytuł decyzji]
- **Data:** [YYYY-MM-DD]
- **Status:** Proponowana | Zaakceptowana | Do przeglądu | Zastąpiona przez ADR-NNNN
- **Typ:** produkt | architektura | proces
- **Zastępuje:** [ADR-NNNN lub brak]
- **Źródło:** [doradca / zadanie /ship / rozmowa z autorem, data]

## Kontekst
## Decyzja
## Podstawa
[ID faktów i założeń z rejestru briefu; dla założeń: jak i kiedy zostaną sprawdzone]
## Rozważone alternatywy
- [opcja] — [dlaczego odrzucona]
## Konsekwencje
## Warunek rewizji
[co musiałoby się okazać, żeby wrócić do decyzji]
## Wdrożenie
[nierozpoczęte | w toku: odnośnik | zweryfikowane: odnośnik do testu/commita]
```

**Zasady jednego źródła prawdy:**

1. Treść i uzasadnienie decyzji są tylko w ADR. Brief, pliki doradców, blueprinty i README odsyłają do ADR, nie kopiują uzasadnienia.
2. ADR się nie edytuje merytorycznie po akceptacji. Zmiana decyzji to nowy ADR ze statusem `Zastępuje`, a stary dostaje `Zastąpiona przez`. Dozwolone są tylko poprawki literówek, statusu i pola `Wdrożenie`.
3. Przy sprzeczności między ADR a innym dokumentem obowiązuje ADR, a drugi dokument trzeba poprawić (doradca lub `docs-writer` zgłasza rozjazd).
4. `Zaakceptowana` znaczy „postanowione”, nie „wdrożone”. Stan wdrożenia jest w polu `Wdrożenie`, aktualizowanym po weryfikacji.
5. Decyzja oparta na założeniu ma `Warunek rewizji`. Gdy `/validate-product` lub `/product-metrics` obali to założenie, ADR dostaje status `Do przeglądu`.
6. Plany w `design-docs/` pozostają narzędziem wznawiania `/ship`; po zakończeniu pracy trwałe uzasadnienie musi już być w ADR.
