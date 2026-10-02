# PR 3 — delegacja, bootstrap i przekazanie do ship

## Cel, profil i stan

- Cel: nowe role i dialog działają w istniejącej instalacji Army bez drugiego orkiestratora.
- Status: `planned`; zależności: PR 1–2.
- Profil: `mid/medium` dla generatora; `strong/high` dla zgodności handoffu i migracji.
- Odczyt: bootstrap.py, bootstrap skill, ship, deskryptory, checker i smoke.
- Zapis docelowy: `.apm/` dla produktu; istniejące `scripts/check.sh`, `scripts/smoke.sh` i dokumentacja dla walidacji.
- Zakaz: zmiany cudzych hooków, konfiguracji właściciela projektu i firmowego pluginu.

## Zadania

- [ ] **3.1. Dostarczyć role istniejącym mechanizmem.**
  Rozszerzyć `ROLES`, mapowanie capabilities i inventory o `planning-analyst` oraz `plan-reviewer`.
  Proponowany poziom: analyst `mid`, reviewer `strong`; konkretne modele wybiera istniejący routing adaptera.
  Nie umieszczać vendor/model ID w przenośnym kontrakcie roli ani nie zmieniać modelu sesji w trakcie pracy.
  Zachować wspólny standard nazw i rendering native/fallback.
  Nowe role muszą pojawić się także przy aktualizacji istniejącego profilu, nie tylko pierwszym bootstrapie.

- [ ] **3.2. Bezpiecznie aktualizować istniejące instalacje.**
  Wykorzystać obecny Incremental Upgrade Review i porównanie materiałów paczki.
  Brakujące role dodawać w uzgodnionym zakresie aktualizacji; zmiany wyspecjalizowanego architekta pokazać jako propozycję.
  Nie nadpisywać ręcznie dostosowanych agentów ani user-owned model routing.
  Obsłużyć kolizję istniejącej lokalnej roli o tej samej nazwie jako konflikt, bez nadpisania.
  Nie przełączać repo do innego targetu i nie zmieniać ownership hooków/pre-commit/CI.

- [ ] **3.3. Włączyć delegację w głównej sesji.**
  `/ship` i bezpośrednia sesja architekta używają tych samych kontraktów.
  Główna sesja uruchamia analityka i recenzenta, zapisuje ich wyniki, przekazuje decyzje architektowi.
  Nie zakładać, że natywny subagent architekt może tworzyć kolejne subagenty lub pytać użytkownika bez pośrednika.
  Na targetach bez delegacji analiza może pozostać lokalna; review wymaga świeżego kontekstu lub jawnego ograniczenia.
  OpenCode nadal nie dostaje fikcyjnego drzewa natywnych agentów.

- [ ] **3.4. Utrzymać dotychczasową granicę wykonania.**
  Przy nowym blueprintcie włączyć interaktywny proces, także gdy późniejsze wykonanie ma być autonomiczne.
  Przy wznowieniu istniejącego planu zachować zgodę, zakres i stan; nie otwierać planowania od zera.
  Bramka blueprintu pokazuje skrót, kryteria, wynik review i zakres wykonania, nie pełny dokument do ponownego czytania.
  Brakujące review lub nieaktualną rewizję raportować przed startem; wyjątek użytkownika musi pozostać jawny.
  Nie tworzyć równoległego pola `execution_mode` obok istniejącego Interaction policy.

- [ ] **3.5. Sprawdzić przekazanie zasad do wykonania i aktualizacji.**
  Zachować istniejące zmiany testera, codera, reviewera, docs-writera i ship opisane w [07](07_BASELINE_RULES.md).
  Plan refaktoru przekazuje prawdziwy passing baseline; nowa funkcja/bugfix nadal respektuje politykę testów.
  Informacja o ryzykach i źródłach kontraktu dociera do właściwych ról bez raportu implementera w pakiecie review.
  W upgrade review pokazać różnice istniejących ról obok dwóch nowych; nie uznawać lokalnej zmiany baseline za wdrożenie.
  Zweryfikować również zakończenie na rekomendacji no change, bez sztucznego PR i startu wykonawcy.

## Weryfikacja

- `scripts/check.sh` — role, skille, deskryptory i wspólne kontrakty.
- `scripts/smoke.sh` — świeże profile, migracje, zachowanie specjalizacji i adaptery.
- `scripts/check.sh --pack` — jeśli APM jest dostępny, istniejąca kontrola dystrybucji.
- Podgląd generatora przez istniejące `--dry-run` uruchomić w scratch repo, nie w źródłowym repo.
- W smoke sprawdzać dokładne oczekiwane role (dotychczasowe plus dwie), nie tylko poluzować liczbę agentów.

## Odbiór i ograniczenia

Nowa instalacja oraz aktualizacja otrzymują dwie role bez utraty obecnych siedmiu i bez uszkodzenia kontroli.
W Claude Code potwierdzić realne wywołania, nie wyłącznie obecność plików.
Inne targety zachowują dotychczasowe możliwości; brak niezależnego review jest uczciwie widoczny.
Przeniesienie rozwiązania do firmowego pluginu pozostaje oddzielną zmianą, nie częścią tego etapu.
