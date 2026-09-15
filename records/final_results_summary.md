# Canonical Policy reproduction — final results summary

All reported evaluations use 50 test episodes with seeds 100000–100049 and checkpoints at epoch 249 unless stated otherwise.

| Task / policy | Training seed | Metric | Result |
|---|---:|---|---:|
| Stack D1, CP-SO2 | 42 | binary success | 42/50 = 84% |
| Stack D1, CP-SO2 | 43 | binary success | 38/50 = 76% |
| Stack D1, CP-SO3 | 42 | binary success | 36/50 = 72% |
| Stack D1, CP-SO3 | 43 | binary success | 38/50 = 76% |
| NutAssembly D0, CP-SO2 | 43 | graded evaluator mean | 0.42 |
| NutAssembly D0, CP-SO2 | 43 | full completion (score 1.0) | 12/50 = 24% |

Stack D1 averages are 80% for CP-SO2 and 74% for CP-SO3 across the two training seeds. NutAssembly D0 currently has one audited run; its evaluator emits partial scores, so both the graded mean and binary full-completion rate are recorded.

## Protocol note

The paper aggregates evaluation over the last 10 training epochs. These records evaluate the final epoch-249 checkpoint independently, so the numbers are a reproduction under a documented protocol rather than a claim of exact paper-protocol equivalence.
