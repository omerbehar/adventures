# Prototype Report: intent-translation (the magistrate)

> **Date:** 2026-06-22 · **Path:** HTML + headless harness · **Status:** ✅ PLAYTESTED (real Claude Haiku run) · **Verdict: PIVOT**

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
- **Status: PASS — ran headlessly 2026-06-22** via `node harness.mjs` (no key required):
  - Stage B determinism: PASS for all three classes (1000 runs each → byte-identical vector).
  - Class divergence (Pillar 5): same classification → Diplomat 21=win, Scholar 15=win
    (collapsed threshold), Assassin 9=advance (not a persuader). Working as designed.
  - Decisive-move mechanic: discover → reveal `scandal_known` → leverage → threshold
    collapses → win (Diplomat/Scholar). Working.
- **Design signal surfaced:** a *threat-framed* decisive move ("if he convicts me, everyone
  hears how he was paid off") routed to intimidation (Diplomat weak there) and did NOT win.
  Candidate fixes for later: apply the `IfFacet` collapse to intimidation too, or have
  Stage A treat "invokes scandal" as dominant regardless of tone. The real classifier run
  will show how often players phrase the decisive move as a threat.

### The real bet (Stage A stability) — KILL-CRITERION
- **Measured 2026-06-22** with Claude Haiku (`claude-haiku-4-5`), strict tool use, via
  `harness.mjs` (PROBE=5, N=20, class=diplomat, state=known).

**Stage A classification is NOT stable run-to-run at the axis/channel/ordinal level.**
Probe (5× per phrasing): 4 of 5 phrasings produced 2–3 *different* `(axis/channel/ordinal)`
classifications. The same sentence "I let slip that the scandal… could become public" was
labelled social, force, AND stealth across three runs. Only one phrasing was single-valued.

**BUT the leverage facet was detected with 100% stability** — `invokesScandalFacet: true`
in **every one of the 25 classifications**, across all phrasings and all axis disagreements.
The model is reliable about *what leverage is invoked*; it is unreliable about *which scalar
axis* the action is.

**Outcome stability was misleading.** The N=20 run showed 100% for the first phrasings — but
only because every divergent classification happens to map to `advance` (a *loss* of the
decisive move) for the Diplomat: scandal-leverage reads as intimidation/deception, where the
Diplomat is weak (×0.6), so nothing clears a win threshold. Where a *winning* classification
was possible (phrasing 5, "I calmly mention the gold…": persuasion 1/5 → win, insight 4/5 →
advance), the outcome flips → ~80% → UNSTABLE. So the decisive move both (a) rarely lands and
(b) when it can, depends on a coin-flip axis label.

**Operational finding:** the N=20 run aborted at phrasing 3 with `API 400: Grammar
compilation timed out` — strict-tool-use grammar compilation intermittently times out under
repeated calls. Needs retry/backoff or a non-strict + repair path (relevant to ADR-0007).

## Best / worst / surprise
- **Best:** facet recognition (`invokesScandalFacet`) was rock-solid (100%/25) — the model is
  dependable at naming *leverage*, which is the part the decisive move actually needs.
- **Worst:** single-axis classification is genuinely noisy for social intent — the exact
  variance the concept feared, and it silently produced "stable" losing outcomes.
- **Surprise:** the scene masked the instability. Stability-by-degenerate-collapse (everything
  fails the same way) looked like a PASS until the probe exposed the underlying variance.

## Verdict: PIVOT

The core idea is sound, but the **first mechanization of classify-don't-score is not stable
enough** and the decisive-move mapping is wrong. Do not spend on content yet. The fix is
specific and cheap (see `PIVOT-NOTE.md`):
1. **Key the decisive-move collapse on the reliably-detected facet** (`invokesScandalFacet`),
   not on a brittle single `primaryAxis`/magnitude. The model is stable about the facet.
2. **Let Stage A name multiple axes** (as ADR-0004 actually envisions), so incidental
   axis-label variance can't flip the outcome.
3. Add retry/backoff (or non-strict + repair) for the strict-tool grammar 400.
Re-run this harness after (1)+(2) before re-deciding.

## Notes
- The deterministic half (Stage B + Resolver) ran PASS headlessly — classify-don't-score did
  correctly quarantine all variance into Stage A, which is exactly where the harness caught it.
- Heuristic-stub mode reports 100% by construction — plumbing only, not evidence about the bet.
