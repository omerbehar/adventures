# PIVOT note — intent-translation (the magistrate)

> Date: 2026-06-22 · Carry-forward for the next prototype iteration.

## Original hypothesis
Classify-don't-score keeps the magistrate's decisive-move threshold stable run-to-run
(≥95% same outcome over N≈20 × ~5 phrasings; Stage B + Resolver 100% deterministic).

## What worked — keep it
- **Deterministic half is solid.** Stage B class-colored tables + the pure Resolver are
  100% deterministic (1000-run self-test PASS). classify-don't-score correctly isolates all
  variance into Stage A.
- **Facet recognition is stable.** Across 25 real Haiku classifications, `invokesScandalFacet`
  was `true` 25/25 — every phrasing, despite wild axis disagreement. The model is dependable
  about *what leverage is invoked*.
- **Class divergence (Pillar 5) is real and legible.** Same classification resolves
  differently per class.

## What to change — the single most important thing
**Key the decisive-move collapse on the reliably-detected facet, not on a brittle single
scalar-axis classification.** Real Haiku output classified the *same* scandal-leverage sentence
as social/intimidation, insight/deception, force/intimidation, stealth/intimidation across
runs — but always flagged the scandal facet. The current Resolver keys the collapse on
`social.persuasion` magnitude, so it only fires when the model happens to pick persuasion
(~1 in 5). Move the collapse trigger to the facet the model names reliably.

Secondary (also required before re-test):
- **Let Stage A name *multiple* axes** with per-axis ordinals (ADR-0004 already envisions a
  multi-axis CapabilityVector). A single `primaryAxis` discards nuance and lets incidental
  label variance flip outcomes.
- **Handle the strict-tool grammar 400 ("Grammar compilation timed out")** with retry/backoff
  or a non-strict + JSON-repair path. Feeds ADR-0007's structured-output discipline.

## Revised hypothesis (for the next run)
If the decisive-move collapse keys on the facet the model identifies reliably
(`invokesScandalFacet`) and Stage A may name multiple axes, the decisive-move *outcome* will
be stable run-to-run (≥95%) even though incidental axis labels vary — and the decisive move
will actually land for the Diplomat.

## How to re-test
Adjust the Resolver's persuade-collapse trigger to `world.facets.has("scandal_known") &&
vector.invokesScandal` **alone** (drop the persuasion-magnitude gate for the collapsed path,
or add a dedicated "leverage" path), allow multi-axis classification, then re-run
`harness.mjs` with the real key (PROBE=5, N=20). Compare Stable %.
