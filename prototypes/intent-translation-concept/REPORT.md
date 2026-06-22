# Prototype Report: intent-translation (the magistrate)

> **Date:** 2026-06-22 · **Path:** HTML · **Status:** ⏳ AWAITING PLAYTEST (real classifier run)

## Hypothesis

If a player expresses the decisive move — invoking the leverage facet (the magistrate
took bribes) — in their own varied words, the classify-don't-score pipeline collapses the
persuasion threshold consistently. **Accept if:** ≥95% same decisive-move outcome across
N≈20 runs of ~5 phrasings, and Stage B + Resolver are 100% deterministic.

## Riskiest assumption

LLM Stage-A classification of evaluative/social intent is stable enough run-to-run that
the decisive-move threshold does not flip.

## Results

### Deterministic half (Stage B + Resolver)
- **Status:** built; provable via the in-page "Stage B determinism self-test" (1000 runs →
  identical vector). By construction the scorer and resolver use no clocks/RNG/IO, so this
  is expected to PASS. *(Confirm by clicking the button.)*

### The real bet (Stage A stability) — KILL-CRITERION
- **Status:** ⏳ NOT YET MEASURED. Requires running the harness with Stage A = Claude Haiku
  and a real API key (see `README.md`). This environment had no key/endpoint available, so
  the number that decides PROCEED/PIVOT/KILL has not been produced.
- **To complete:** open `prototype.html`, switch Stage A to Claude Haiku, N=20, "Scandal
  already discovered", **Run stability test**, and record the Stable % per phrasing below.

| Phrasing | Stable % | Outcomes | Verdict |
|---|---|---|---|
| _(fill from a real run)_ | | | |

## Best / worst / surprise

_To be captured during the real playtest (see `/prototype` Phase 6 questions)._

## Verdict

**PENDING.** Decision rule:
- **PROCEED** if every phrasing holds ≥95% on the Claude classifier — the core bet survives
  this scene; move to finalize design + architecture per the concept's Path B.
- **PIVOT** if outcomes flip run-to-run — tune ordinal granularity / Stage B tables / the
  classify prompt and re-measure before any content spend.
- **KILL** only after repeated PIVOTs fail to stabilize the decisive-move threshold.

## Notes

- The deterministic half being trivially stable is the *point* of classify-don't-score: it
  quarantines all run-to-run variance into Stage A, where this harness can measure it.
- Heuristic-stub mode always reports 100% — it validates plumbing and enables offline play,
  but is not evidence about the LLM bet.
