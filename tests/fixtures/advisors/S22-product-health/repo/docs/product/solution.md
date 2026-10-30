# Solution

## Style
Modular monolith (ADR-002).

## Observability
| target | value | measured by | alert |
|---|---|---|---|
| p95 response time, save plan (`POST /plans`) | < 800 ms | app logs | none yet |
| error rate, `POST /plans` | < 1% | app logs, error tracker | error tracker, any 500 |
| uptime | 99.5% monthly | uptime check | email to founder |

## Open technical risks
- recipes-api (third-party) latency is unknown under load.
