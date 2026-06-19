# Performance Audit — [area / Task-ID]
- **Date:** [YYYY-MM-DD]

## How to measure (do this first)
- **Tool / benchmark:** [profiler / load test / query log]
- **Metric & target:** [e.g. p95 latency, queries per request, bundle size]

## Hotspots (ranked by expected gain)
### [HIGH|MED|LOW] [Title]
- **Location:** `path:line`
- **Cost:** [why it's expensive — complexity / N+1 / I/O in loop / alloc]
- **Proposal:** [change]
- **Expected gain:** [estimate]
- **Verify:** [measure before/after, or assert query count in a test]

## Needs measurement before changing
- [hypotheses to confirm first]
