# Business case: PetPal

## Inputs
| name | value | unit/period | source or A-n |
|---|---|---|---|
| platform fee | 15% | of GMV per booking; returned on refund | pricing page |
| average booking | 80 | PLN | A-2 |
| payment processing | 1.4% of GMV + 1 PLN | per booking, paid by PetPal | provider price list, 2026-09-01 |
| fixed costs | 900 | PLN/month (hosting 120, SMS 80, accounting 300, marketing 400) | A-3 |
| starting cash | 6,000 | PLN, 2026-10-01 | bank statement |

## Model
GMV = bookings × average booking · revenue = 15% × GMV · variable cost = 1.4% × GMV + 1 × bookings ·
gross margin = revenue − variable cost · profit = gross margin − fixed costs.

## Scenarios (October 2026)
| | low | base | high |
|---|---|---|---|
| bookings | 60 | 120 | 200 |
| GMV (PLN) | 4,800 | 9,600 | 16,000 |
| revenue (PLN) | 720 | 1,440 | 2,400 |
| variable cost (PLN) | 127.20 | 254.40 | 424.00 |
| gross margin (PLN) | 592.80 | 1,185.60 | 1,976.00 |
| profit (PLN) | −307.20 | 285.60 | 1,076.00 |

## Break-even
About 92 bookings a month at 80 PLN (900 / (12 − 1.12 − 1) ≈ 91.1).

## Conversation state
- Settled: take rate 15%, fixed costs. Open: actual booking volume (A-1: 120 bookings in month 1).
