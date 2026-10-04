# Kolejność realizacji i dalsze etapy Army

PR 1–4 dostarczają interaktywnego architekta. PR 1–3 są zaimplementowane; PR 4 jest odbiorem zachowania
i pilotażem. PR 5–6 rozwijają utrzymanie Army i widoczność pracy; PR 7 jest warunkową procedurą E2E.
To zadania obecnego planu, a nie wyłącznie katalog rekomendacji.
Status `planned` oznacza pracę zaprojektowaną, nie uruchomioną ani zatwierdzony zakres wykonania ship.
Bez próby na realnym zadaniu nie podajemy szacunków w tygodniach ani nie obiecujemy oszczędności.

## Co jest już zmienione

Sześć zasad w istniejących rolach pozostaje w lokalnych źródłach na wyraźne życzenie użytkownika.
[07](07_BASELINE_RULES.md) rozdziela instrukcje od brakującej walidacji zachowania. Nowe role, dialog,
checkpointy i integracja z `/ship` są w źródłach; ich odbiór jakościowy należy do PR 4.

## Najbliższy zakres

| Kolejność | Praca | Kryterium zakończenia |
|---|---|---|
| 1 | PR 1: analityk i recenzent; minimalny kontrakt oraz próby na źródłach | Analiza oddziela fakt od hipotezy; review wykrywa rzeczywisty brak lub uczciwie nie znajduje uwag. Kontrakty i fixture’y są dodane; test zachowania i baseline obecnego architekta są nadal otwarte. |
| 2 | PR 2: cały plan przez rozmowę i zapis decyzji | Jedno zagadnienie naraz; wznowienie nie gubi decyzji i nie uruchamia kodowania |
| 3 | PR 3: istniejący bootstrap i ship | Nowe role docierają do instalacji; zachowane specjalizacje i granica plan/wykonanie |
| 4 | PR 4: kontrola adapterów i pilotaż | Udokumentowana wartość ponad baseline oraz brak regresji krytycznych |

PR 1–3 są zintegrowane w źródłach. Fixture’y wymagają teraz świeżego uruchomienia ról i dialogu; checkpoint
jest zapisany w manifeście i [PR 1](01_PR_1_Roles.md). To punkt odbioru rozszerzenia Army, nie zmiana przyszłego procesu na planowanie
przeplatane implementacją produktu użytkownika.
Próby cząstkowe ruszają przy każdym PR; nie odkładamy wszystkich problemów do PR 4.

W PR 1–4 uwzględniamy dostarczony brief/PRD/research, proporcjonalne pytania, review kosztu i kompletności,
sześć zasad istniejących ról, ich przekazanie do wykonania oraz osobne próby odbioru.
Nie dodajemy obowiązkowego PRD, roadmapy, startera ani deploymentu do zwykłej zmiany.

## PR 5 Reguły i gotowość repo

Status realizacji: **do zrobienia**; kolejność: po odbiorze PR 4. Właściciele: adapt-army i bootstrap.
Zakres przyszłych zmian: `.apm/skills/adapt-army/`, `.apm/skills/bootstrap/` oraz właściwe istniejące próby i dokumentacja.
Bez nowego agenta, automatycznych napraw projektów i zmian ownership kontroli.

- [ ] **5.1. Audyt instrukcji.** — **Status: do zrobienia.** Dodać do adapt-army wywoływany na żądanie przegląd reguł głównych,
  zagnieżdżonych i ról. Wynik: sprzeczności, nieaktualne polecenia, duplikaty i zbędny kontekst z dowodami.
  Oddzielić fakty od preferencji; prawidłowe reguły mogą otrzymać raport bez uwag. Poprawki przez istniejący proces propozycji.
- [ ] **5.2. Raport gotowości.** — **Status: do zrobienia.** Rozszerzyć istniejący recon bootstrap, nie wykonywać drugiego pełnego skanu.
  Raport pokazuje sprawdzone komendy, testy, konfigurację, ownership i blokady konkretnego rodzaju pracy.
  Zapisać wynik, powód niewykonania i priorytet; wykrycie runnera nie znaczy, że testy działają.
- [ ] **5.3. Odbiór.** — **Status: do zrobienia.** Sprawdzić repo ze sprzecznymi regułami, nieaktualną komendą, poprawnymi instrukcjami
  i niedostępnym narzędziem. Potwierdzić brak niezamówionych napraw i zmian zewnętrznych kontroli.
  Uruchomić właściwe `scripts/check.sh --skills` i smoke dla zmienionej ścieżki bootstrap.

Etap kończy się wiarygodnym raportem i propozycjami, nie obowiązkowym usunięciem wszystkich braków repo.
Nie dodawać arbitralnej punktacji blokującej pracę ani deklarować pełnego audytu zależności bez jego wykonania.

## PR 6 Zbiorczy status prac

Status realizacji: **do zrobienia**; kolejność: po PR 5; zależność techniczna: stabilny format z PR 2–3.
Właściciel: nowy odczytowy skill `army-status` w paczce Army, bez osobnego agenta.
Zakres przyszłych zmian: `.apm/skills/army-status/`, wrapper w `.apm/commands/` i niezbędne instrukcje dystrybucji/walidacji.

- [ ] **6.1. Kontrakt odczytu.** — **Status: do zrobienia.** Odczytywać manifesty i Execution State z `design-docs`;
  pokazywać etap planowania, postęp zadań, oczekującą decyzję oraz ostatni zapisany dowód weryfikacji.
  Odróżnić historyczny wynik od świeżego sprawdzenia. Brak/stary format oznaczyć jako nieznany, nie zgadywać.
- [ ] **6.2. Widok zbiorczy i szczegółowy.** — **Status: do zrobienia.** Dodać filtrowanie po Task-ID i stanie oraz ostrzeżenia o sprzecznościach.
  Wynik zawiera linki do kanonicznych plików. Nie tworzyć bazy, nie korygować statusu i nie uruchamiać ship.
- [ ] **6.3. Dystrybucja i odbiór.** — **Status: do zrobienia.** Sprawdzić plany nowe, stare, częściowo uszkodzone i zakończone,
  w tym brak sekcji, rozbieżne statusy i nieaktualne review. Potwierdzić brak zapisów przy samym odczycie.
  Sprawdzić dostarczenie skilla i wrappera przez dotychczasową ścieżkę APM oraz właściwe kontrole skilli.

Gotowe, gdy użytkownik widzi rzeczywisty zapis stanu i jego ograniczenia bez otwierania każdego planu.
Archiwizację odłożyć: najpierw sprawdzić, czy filtrowanie zakończonych prac wystarcza.

## PR 7 Procedura E2E

Status realizacji: **warunkowe**; po PR 4, po wskazaniu rzeczywistej aplikacji i luki w ochronie przeglądarkowej.
Właściciel: tester; zakres przyszłych zmian: jego kontrakt i opcjonalne materiały referencyjne baseline,
minimalny handoff ship oraz przypadki odbioru. PR 5–6 nie są zależnością techniczną.

- [ ] **7.1. Określić warunki.** — **Status: warunkowe.** Wskazać istniejący scenariusz użytkownika, lokalną aplikację, komendy startu,
  runner, dozwolone dane i izolację. Brak aplikacji lub dostępu pozostaje ograniczeniem, nie fikcyjnym sukcesem.
- [ ] **7.2. Opisać cykl.** — **Status: warunkowe.** Przygotowanie → sprawdzenie gotowości aplikacji → test rzeczywistej ścieżki →
  review asercji → wynik i sprzątanie. Tańsze wiarygodne testy zachować; nie wprowadzać nowego stanu obok Execution State.
- [ ] **7.3. Odebrać na aplikacji.** — **Status: warunkowe.** Pokryć poprawny przebieg, istotną awarię integracji i błąd przygotowania środowiska.
  Wynik rozróżnia defekt produktu od braku środowiska, dowodzi wykonania testu i usunięcia danych tymczasowych.
  Nie instalować frameworka ani nie używać produkcyjnych danych bez odpowiedniego zakresu.

Brak przypadku użycia pozostawia etap niewykonany. Nie blokuje odbioru i dystrybucji PR 1–6.

## Osobne skille wybierane według potrzeby

1. **Product discovery** — pierwszy wybór, gdy częściej nie wiadomo co i dla kogo budować niż jak to wykonać.
   Łączy okazję, nieprowadzący wywiad i zakres produktu; PRD oraz roadmapa są opcjonalnymi wynikami.
2. **Test strategy** — pierwszy wybór dla istniejącego produktu z nieznaną ochroną najważniejszych zachowań.
   Nie zastępuje testera; przygotowuje wieloetapowy plan poprawy jakości do wykonania przez Army.
3. **Infra research i deployment readiness** — wybierane, gdy pojawia się rzeczywisty projekt do uruchomienia.
   Rozdzielamy decyzję o platformie od sprawdzenia konkretnej aplikacji i jej wdrożenia.
4. **Project starter** — dopiero przy powtarzalnym zakładaniu nowych aplikacji.

Kontrakty i granice tych skilli są w [10](10_OPTIONAL_SKILLS.md) oraz w [prywatnym toolkicie](../PERSONAL-AI-TOOLKIT/00_CORE_MANIFEST.md).
Skille są zainstalowane globalnie w Codexie; ich zachowanie pozostaje do pilota.

## Tematy odłożone

- CI z LLM review: wymaga osobnego projektu uprawnień, kosztu, szumu, nieufnego kodu PR i sposobu odbioru raportów.
- Headless i autonomiczne commity: nie wynikają z posiadania autonomicznego trybu ship i nie są potrzebne do dialogu.
- npm, CodeArtifact, Terraform i publikacja OIDC: tylko przy konkretnej potrzebie infrastrukturalnej; Army ma APM.
- Centralna pamięć, drugi executor, obowiązkowe archiwum i 33 komendy: brak uzasadnienia w obecnym celu.

## Reguła przyjmowania następnego pomysłu

Najpierw wskazać powtarzalny problem i obserwowalny rezultat. Potem sprawdzić właściciela w istniejącej Army.
Regułę dopisać do roli; osobny workflow użytkownika opisać jako skill. Osobną rolę tworzyć dopiero,
gdy potrzebna jest niezależna odpowiedzialność lub kontekst. Jeśli pilot nie daje wartości, nie rozbudowywać.
Nie każdy pomysł z katalogu musi zostać zrealizowany.
