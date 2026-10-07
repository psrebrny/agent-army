# ADR-0001: Samowystarczalni doradcy produktowi, bez cudzych skilli w paczce

- **Data:** 2026-10-07
- **Status:** Zaakceptowana
- **Typ:** produkt | proces
- **Zastępuje:** brak
- **Źródło:** rozmowa z autorem 2026-10-07; analiza [design-docs/2026-10-07-product-advisors-sourcing-decision.md](../../design-docs/2026-10-07-product-advisors-sourcing-decision.md)

## Kontekst

Plan [Doradcy produktowi dla Agent Army](../../design-docs/ARMY-PRODUCT-ADVISORS/00_CORE_MANIFEST.md) (rewizja 1) przewiduje siedmiu doradców, którzy mają prowadzić solo twórcę od pomysłu do sprzedawanego produktu. Istnieją publiczne paczki skilli o podobnym zakresie (m.in. `phuryn/pm-skills`, `coreyhaines31/marketingskills`). Autor nie zna ich jakości, nie wie, jak będą się rozwijać, i słabo ocenia marketing, więc potrzebuje wyników weryfikowalnych metrykami.

Ocena plików na przypiętych commitach wykazała:

- cudze skille są jednorazowe: bez wznawiania, bez wspólnego briefu i każdy zapisuje wyniki w innym miejscu;
- jakość jest nierówna: `strategy-red-team` jest bardzo dobry, a `privacy-policy` obiecuje gotowy do publikacji dokument bez źródeł prawa;
- pełna instalacja obu repo kosztuje ok. 17–20 tys. tokenów opisów w każdej sesji, a własne skille ok. 1,6–1,8 tys.;
- występują kolizje nazw i wyzwalaczy (`product-strategy`, `marketing-ideas`, „GTM”);
- upstream się zmienia: marketingskills v2.0 przemianowała 19 skilli.

## Decyzja

1. Doradcy produktowi są **własnymi skillami paczki**, działającymi w całości bez cudzych skilli. Brak zależności w `apm.yml`.
2. Paczka **nie poleca, nie linkuje i nie wykrywa** cudzych skilli: ani w README, ani w katalogu, ani w samych skillach.
3. Z cudzych skilli bierzemy **wyłącznie pomysły**, przepisane do naszego kontraktu, z **atrybucją** w skillu i w `.apm/SOURCES.md` (repo, plik, commit, licencja, co wzięto). Atrybucja nie jest rekomendacją instalacji.
4. Wchłonięcie cudzej treści (kopia na MIT z przypiętym commitem) jest możliwe tylko po pilocie i tylko przez nowy ADR. Treści na licencji niekomercyjnej (np. CC BY-NC-SA) nie wchłaniamy.
5. Istotne decyzje, produktowe i techniczne, także podjęte w trakcie kodowania, zapisujemy jako ADR w `docs/adr/`, w repo paczki i w repo produktu. ADR jest jedynym źródłem prawdy o decyzjach; dokumenty analityczne i plany odsyłają do ADR.

## Podstawa

- Zweryfikowane w plikach: sekcje 1, 4 i 6 analizy (treść skilli, pomiar opisów, koszty wchłonięcia i zależności).
- Założenie do sprawdzenia: własni doradcy dadzą lepsze decyzje niż szablony pm-skills. Sprawdza to pilot z sekcji 7 analizy.

## Rozważone alternatywy

- **Hybryda z zależnościami** (własna warstwa + zewnętrzne skille jako wymagana instalacja). Odrzucona: kolizje, dwa źródła prawdy o produkcie, brak instalacji przez APM, ryzyko zmian upstreamu.
- **Własne + menu polecanych skilli** (pierwotna rekomendacja analizy). Odrzucona przez autora: link w dokumentacji działa jak rekomendacja niesprawdzonego narzędzia i wymaga utrzymania listy.
- **Pełna zależność od cudzych paczek.** Odrzucona: brak spójności i weryfikowalności, ok. 17–20 tys. tokenów w każdej sesji.

## Konsekwencje

- Więcej pracy autorskiej i utrzymania po naszej stronie. Wiedza marketingowa w rdzeniu jest słabsza, co kompensują rejestr przewidywań, bramka ruchu, red-team planu i `/product-metrics`.
- Brak ryzyka zniknięcia lub przemianowania zależności i mały koszt kontekstu.
- Jeśli autor sam zainstaluje cudzy skill w repo produktu, pliki tego skilla nie są źródłem prawdy, a doradcy o nim nie wiedzą.
- Plan wymaga rewizji 2 (lista zmian: sekcja 10 analizy), w tym rozszerzenia „lekkich ADR-ów” na decyzje produktowe.

## Warunek rewizji

- Pilot pokaże, że szablony pm-skills są nie gorsze od własnych doradców na co najmniej 5 z 8 kryteriów.
- Albo utrzymanie własnych metod marketingowych okaże się nieproporcjonalne do wartości.

## Wdrożenie

Nierozpoczęte. Wymaga rewizji 2 planu i pilota.
