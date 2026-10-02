# Jak będziemy używać rozszerzonego architekta

To docelowy przebieg po implementacji. Nowe role i opisany proces nie zostały jeszcze wdrożone.
Nadal korzystasz z Army i dotychczasowego wejścia do architekta; nie instalujesz osobnego toolkitu.

## 1. Zlecasz planowanie

Przykład polecenia do sesji mającej dostęp do roli architekta:

> Użyj architekta Army. Chcę uprościć import materiałów do second braina.
> Przygotujmy cały plan przez rozmowę, po jednym temacie. Na razie bez implementacji.

Nie zakładamy uniwersalnej komendy `/architect`: sposób wyboru roli zależy od narzędzia i adaptera.
Gdy `/ship` potrzebuje nowego blueprintu, korzysta z tego samego procesu przed dotychczasową bramką wykonania.

## 2. Architekt sprawdza, co wiadomo

Najpierw czyta właściwe instrukcje i materiały. Gdy problem jest niejasny, zleca analitykowi
sprawdzenie diagnozy i źródeł. Nie wymaga od Ciebie zatwierdzania każdego wywołania agenta.
Przy prostej i dobrze opisanej zmianie może wykonać krótkie rozpoznanie sam.

Otrzymujesz krótkie ustalenia: co wiemy, czego nie wiemy i o czym musimy zdecydować.

## 3. Wspólnie tworzymy cały plan

Architekt: „Proponuję najpierw generować propozycję uporządkowania plików, zanim dodamy ich przenoszenie.
To pozwoli sprawdzić reguły. Czy pierwsza wersja ma tylko pokazywać wynik, czy również przenosić pliki?”

Ty: „Tylko pokazywać.”

Architekt zapisuje decyzję i omawia następny istotny temat. Nie pokazuje ponownie całego dokumentu.
Możesz wrócić do wcześniejszego wyboru, poprosić o wyjaśnienie albo zlecić mu rozstrzygnięcie drobiazgów.
Plan zostaje w `design-docs/<Task-ID>/`; duże zadanie zachowuje manifest i pliki PR.

## 4. Recenzent sprawdza plan

Po uzgodnieniu całości koordynator uruchamia recenzenta w świeżym kontekście.
Recenzent czyta cel, decyzje, plan i źródła. Sprawdza sens zakresu, założenia, zależności i kryteria sukcesu.
Nie przepisuje dokumentu sam i nie zastępuje późniejszego review kodu.

Architekt wraca z krótkim wynikiem. Braki techniczne poprawia w ramach ustaleń,
a wybory zmieniające zakres lub cel omawia z Tobą. Istotna zmiana wraca do właściwego review.

## 5. Ty wybierasz dalszy krok

Na końcu dostajesz skrót i linki do planu, a nie wielki blok do pierwszego przeczytania.
Możesz zakończyć na planie lub przejść do istniejącego `/ship` z wybranym zakresem.
Interaktywne planowanie może zakończyć się autonomicznym wykonaniem; to osobna decyzja.
Nie powstaje nowy Work, Review ani drugi system postępu.

## Opcjonalne wejścia spoza Army

Jeśli powstaną opisane w [10](10_OPTIONAL_SKILLS.md) osobne skille, możesz najpierw zweryfikować potrzebę
w product-discovery i przekazać jego brief architektowi. Przy istniejącym produkcie test-strategy może
wskazać pierwszy przyrost ochrony do zaplanowania. Żaden z tych skilli nie będzie obowiązkowym początkiem ship.
Wybór hostingu i gotowość wdrożenia pozostaną odrębnymi workflow. Dziś są to propozycje, nie dostępne komendy.

## 6. Przerwa i wznowienie

> Wznów planowanie tego zadania z design-docs. Wróć do ostatniej otwartej decyzji.

Architekt odczytuje zapisany temat, pytanie, decyzje i dowody. Nie potrzebuje całej poprzedniej rozmowy.
Jeżeli materiały zmieniły się od ostatniej sesji, najpierw wskazuje istotne rozbieżności.
Wznowienie planowania nie rozpoczyna implementacji.

## Użycie po dalszych etapach Army

Po PR 5 można zlecić adapt-army przegląd reguł, a bootstrap pokaże konkretny raport gotowości repo.
Po PR 6 army-status poda zbiorczy stan planów, oczekujące decyzje i źródła ostatnich wyników, bez ich zmieniania.
Jeśli wykonamy warunkowy PR 7, tester otrzyma procedurę pracy na działającej aplikacji przeglądarkowej.
To funkcje planowane; nie są wymagane do korzystania z architekta po PR 1–4.

## Ograniczenia

Na narzędziu bez świeżego kontekstu recenzenta brak niezależnego review pozostaje jawny.
Można przekazać pakiet do nowej sesji; lokalna samoocena nie jest przedstawiana jako niezależna kontrola.
Obecna praca, zgody i wyspecjalizowane role nie są resetowane przez aktualizację Army.
