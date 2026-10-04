# Używanie Personal AI Toolkit

Skille są globalne dla Codexa i dostępne jako `$skill-name`. Nie musisz przechodzić całego łańcucha. Każdy może działać samodzielnie; przekazanie do Agent Army jest dodatkową drogą dla zatwierdzonego zadania kodowego.

## Typowe ścieżki

**Pomysł lub niepewny feature:** `$product-discovery` zbiera dowody i rozstrzyga, czy budować, użyć istniejącej opcji, zrobić eksperyment czy poczekać. Gdy głównym problemem jest niewiadoma techniczna, `$project-research` szuka tylko istotnych faktów. `$project-plan` przekształca wybrany rezultat w plan, pytając o istotne decyzje po jednej na raz. `$plan-review` ocenia zapisaną rewizję. Dopiero jawne zlecenie użytkownika rozpoczyna realizację.

**Zmiana w repozytorium:** `$project-research` mapuje kontrakty, zależności i wiarygodne komendy. Jeśli repo ma Agent Army, użyj jej `architect` i `/ship`, aby nie prowadzić dwóch planów. Bez Army można użyć `$project-plan` i przekazać plan do wybranego wykonawcy.

**Jakość istniejącego produktu:** `$test-strategy` identyfikuje scenariusze o największym ryzyku, aktualną ochronę i małe kroki uzupełniające. Przy konkretnej zmianie tester projektu nadal pisze i weryfikuje jej testy.

**Hosting i wdrożenie:** `$infra-research` porównuje opcje na aktualnych źródłach. Po wyborze platformy `$deployment-readiness` sprawdza wskazaną aplikację i środowisko. Oba workflow raportują i planują; żaden nie provisionuje ani nie deployuje bez osobnego, konkretnego zlecenia.

**Nowa aplikacja:** po wyborze stacku `$project-starter` sprawdza aktualny oficjalny starter, konflikt katalogu, zakres plików i komendy weryfikujące, a potem działa wyłącznie w zleceniu.

## Wznawianie

Wznów skill od istniejącego pliku decyzji lub manifestu. `project-plan` czyta zapisany checkpoint i pyta tylko o nierozstrzygnięty temat. `plan-review` zawsze podaje rewizję, którą oceniał. `test-strategy`, research infrastruktury i readiness aktualizują istniejący raport, jeśli użytkownik wskaże go jako źródło prawdy; nie tworzą równoległego statusu prac.

## Przykład krótkiego cyklu

1. `$product-discovery` — ustala, że potrzebny jest eksport raportu i zapisuje uzgodniony brief w istniejących notatkach.
2. `$project-plan` — czyta brief, pyta kolejno o wymagane decyzje, a po każdej aktualizuje plan i checkpoint.
3. `$plan-review` — ocenia dokładną rewizję w świeżej sesji, jeśli można ją zapewnić; w przeciwnym razie jawnie oznacza ograniczenie.
4. Użytkownik wybiera zakres realizacji. W repo Army uruchamia `/ship` i przekazuje plan; poza Army wybiera własny executor. Toolkit nie wykonuje kroku 4 automatycznie.
