# Projekty opcjonalnych skilli poza rdzeniem Army

Te skille są niezależnymi wejściami użytkownika, a nie obowiązkowymi krokami `/ship`.
Status 2026-10-04: pięć opisanych tu workflow ma implementację jako globalne skille Codexa w `~/.codex/skills/`;
nie wchodzą do pakietu APM Army. Każdy działa także bez Army; gdy Army jest dostępna, użytkownik może przekazać
jej wybrany zakres i dowody do zaplanowania. Pliki, instalacja i checkpoint: [Personal AI Toolkit](../PERSONAL-AI-TOOLKIT/00_CORE_MANIFEST.md).

## Wspólne zasady

- Rozmowa ma krótkie kroki: znane fakty, jedna istotna decyzja, rekomendacja i zapis wyniku.
- Używać istniejących dokumentów i miejsc docelowych; nie tworzyć obok nich automatycznie `context/`.
- Przy braku miejsca użytkownik wskazuje je przed zapisem; odczyt i szkic można przygotować wcześniej.
- Wskazywać źródła, datę/zakres sprawdzenia i niepewności; nie udawać aktualnego researchu bez dostępu do źródeł.
- Własny raport zawiera ustalenia i decyzje. Postęp implementacji po przekazaniu żyje wyłącznie w planie Army
  albo w istniejącym systemie użytkownika, nie w drugim zestawie checkboxów skilla.
- Żaden z tych skilli nie wymaga nowego stałego agenta. Specjalistyczna delegacja może być opcją środowiska.

## Product discovery

**Potrzeba:** pomysł jest atrakcyjny, lecz nie wiadomo, czy rozwiązuje rzeczywisty i powtarzalny problem.
Łączy inspiracje opportunity-map, Mom Test, shape oraz opcjonalne PRD i roadmapę, bez pięciu obowiązkowych komend.

**Wejście:** pomysł, notatki, tickety lub materiał z rozmów, użytkownik docelowy i ograniczenia.
**Przebieg:** oddzielić ból od rozwiązania → zebrać dowody wcześniejszych zachowań → porównać istniejący sposób,
reuse/buy/complement/build/wait → wybrać najmniejszy eksperyment i kryterium dalszej decyzji.
Brak dowodów prowadzi do planu rozmowy/eksperymentu, nie do fikcyjnej walidacji.
**Wynik:** krótki brief decyzji; przy uzasadnionej skali także PRD i roadmapa pionowych wycinków.
Roadmapa pokazuje kolejność rezultatów, a nie kopię tasków implementacyjnych.
**Granica:** nie kontaktuje respondentów, nie prowadzi ankiet ani nie kupuje usług bez zlecenia.
**Próba odbioru:** z pochlebnych opinii nie wyciąga „potwierdzonego popytu”; rozpoznaje już działające rozwiązanie;
dla małego feature nie wymusza pełnego PRD. Brief pozwala architektowi pominąć rozstrzygnięte pytania.

## Test strategy

**Potrzeba:** istniejący produkt ma testy, ale nie wiadomo, które ważne awarie nadal przejdą niezauważone.
**Wejście:** zachowania produktu, incydenty, istniejące testy, ich koszt i możliwości środowiska.
**Przebieg:** mapa ryzyk → przypisanie realnej ochrony → luki → kolejność małych przyrostów.
Wpływ i prawdopodobieństwo mają dowód lub oznaczoną niepewność, bez udawanej precyzji punktacji.
**Wynik:** plan ochrony najważniejszych zachowań, miary efektu i wybrany pierwszy przyrost dla architekta.
**Granica:** nie jest stanowym drugim executorem. Tester nadal odpowiada za konkretne testy, wyrocznię i fault checks.
**Próba odbioru:** ryzyko utraty danych wyprzedza liczbę niepokrytych getterów; istniejąca wiarygodna ochrona jest
ponownie użyta. Wznowienie wskazuje plan Army, zamiast nadpisywać jego postęp.

## Infra research

**Potrzeba:** trzeba wybrać miejsce uruchomienia projektu z konkretnymi ograniczeniami.
**Wejście:** workload, budżet, regiony/dane, kompetencje utrzymania, wymagania i istniejące umowy/usługi.
**Przebieg:** ustalić kryteria → porównać ograniczony zbiór realnych opcji, w tym istniejącą infrastrukturę →
sprawdzić aktualne oficjalne źródła → wskazać rekomendację, ryzyka i dane wymagające małego eksperymentu.
**Wynik:** decyzja infrastrukturalna z datą źródeł, założeniami kosztu i konsekwencjami utrzymania.
**Granica:** research nie provisionuje zasobów, nie zakłada kont i nie oznacza gotowości aplikacji do wdrożenia.
**Próba odbioru:** przy brakujących danych nie wymyśla ceny ani gwarancji; nie wybiera platformy tylko ze względu
na popularność. Decyzja daje konkretne wejście dla deployment-readiness.

## Deployment readiness

**Potrzeba:** znamy platformę, ale lokalny sukces nie dowodzi, że aplikację można bezpiecznie uruchomić.
**Wejście:** wybrana platforma, repo, docelowe środowisko i zakres dozwolonych operacji.
**Przebieg:** sprawdzić realny build/start, konfigurację, nazwy wymaganych sekretów bez ich wartości,
migracje, health check, logi i recovery; przygotować minimalną konfigurację tylko w zleconym zakresie.
**Wynik:** raport blokad i wykonanych sprawdzeń, projekt konfiguracji oraz konkretny plan wdrożenia/wycofania.
**Granica:** najpierw jedna faktycznie używana platforma; brak uniwersalnego sześcioplatformowego frameworka.
Deployment wymaga zlecenia na wskazane środowisko. Nie uruchamia migracji ani nie wysyła danych w ramach samego audytu.
**Próba odbioru:** brak sekretu, nieudany build i nieodwracalna migracja nie dostają werdyktu „gotowe”.
Raport odróżnia sprawdzenie lokalne od potwierdzenia na środowisku docelowym.

## Project starter

**Potrzeba:** powtarzalnie tworzymy nowe aplikacje po podjęciu decyzji o stacku.
**Wejście:** uzasadniony stack, oficjalny starter i docelowy katalog.
**Przebieg:** sprawdzić aktualne źródło startera i konflikty → pokazać konkretny zakres → wygenerować w ramach
zlecenia → uruchomić rzeczywiste sprawdzenia. Zachować istniejące materiały i nie czyścić katalogu dla wygody.
**Wynik:** szkielet aplikacji i raport komend/wyników; potem opcjonalny bootstrap Army.
**Granica:** nie wybiera produktu, nie instaluje Army obowiązkowo i nie udaje gotowej infrastruktury.
**Próba odbioru:** istniejący plik powoduje bezpieczne rozstrzygnięcie konfliktu, nie nadpisanie;
generator zakończony sukcesem przy nieudanym buildzie nie jest pełnym sukcesem.

## Przekazanie do Army

Przykład: product-discovery kończy się briefem „najpierw ręczny eksport”. Użytkownik przekazuje ten brief
architektowi. Ten odczytuje istniejące decyzje, bada tylko niewiadome techniczne i interaktywnie składa plan.
Po review użytkownik wybiera zakres ship. Gdy później potrzebny jest hosting, infra-research przygotowuje
decyzję, a deployment-readiness sprawdza wybrany wariant. Nie trzeba przejść całego łańcucha dla jednej zmiany.
