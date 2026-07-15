# Prototypes Index

The project's record of what was prototyped and what was learned.

## Concept prototypes

| Concept | Date | Path | Verdict | Report |
|---|---|---|---|---|
| intent-translation (the magistrate) | 2026-06-22 | HTML | 🔁 PIVOT (real Haiku run) | [REPORT](intent-translation-concept/REPORT.md) · [PIVOT](intent-translation-concept/PIVOT-NOTE.md) |

## Notes

- **intent-translation** tests the concept's prototype kill-criterion: run-to-run
  stability of the decisive-move threshold under classify-don't-score. The deterministic
  half (Stage B tables + Resolver) is built and self-testable offline; the LLM-stability
  measurement awaits a run with a real Claude Haiku classifier + API key (see the
  prototype README).
