# Metrics

## Decision questions
- Does onboarding lead runners to a saved training plan in their first session?

## Funnel
onboarding_started → onboarding_step2_completed → plan_created

## Events
| name | trigger | properties | source |
|---|---|---|---|
| onboarding_started | first onboarding screen shown | platform (string) | analytics |
| onboarding_step2_completed | goals and schedule saved | platform (string) | analytics |
| plan_created | first training plan saved | platform (string), weeks (int) | analytics |

## Data sources
| source | holds | link | access | personal data | last pulled |
|---|---|---|---|---|---|
| analytics | funnel events | https://analytics.example/runplan/funnels | connector `analytics` | none in exports | 2026-10-27 |
| errors | server errors with stack traces | https://errors.example/runplan | connector `error-tracker` | user emails in events | never |
| app-logs | request lines with duration | — | pull command in `.agent-army/stores.json` | emails and IPs in raw lines | never |

## Collection status
verified (2026-10-15, plan_created reconciled with the plans table for one week; no duplicates)

## Reads
(none yet)
