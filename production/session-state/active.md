# Active Session State

## Session Extract — /architecture-review 2026-06-22
- Verdict: CONCERNS → all items actioned same day (see Resolution Addendum in report)
- Requirements: 31 total — 29 covered, 2 partial (deferred-acceptable), 0 open gaps
- TR registry: tr-registry.yaml v1 (31 IDs); TR-client-001 closed by ADR-0009
- GDD revision flags: None
- ADRs: all 9 Accepted (0001–0009). Engine refinements (N1,N3,N4,N6,N7,N8) folded into
  ADR-0001/0003/0006; integration seams ①②③ reconciled across 0001/0003/0007; N5 in ADR-0009.
- Artifacts added: ADR-0009 (client/UI); test scaffold (pubspec, analysis_options, tests/,
  CI workflow); UX (accessibility-requirements.md, ux/interaction-patterns.md);
  systems-index.md (lightweight map, per-system GDDs deferred to post-prototype)
- Report: docs/architecture/architecture-review-2026-06-22.md

## Session Extract — /prototype intent-translation 2026-06-22
- Concept: intent-translation (the magistrate social scene)
- Hypothesis: classify-don't-score keeps the decisive-move threshold stable run-to-run
  (≥95% same outcome over N≈20 × ~5 phrasings; Stage B + Resolver 100% deterministic)
- Path: HTML (single file) — prototypes/intent-translation-concept/prototype.html
- Built: magistrate Scene Model (ADR-0003), Stage A classifier (heuristic stub + Claude
  Haiku strict-tool-use adapter, ADR-0004), deterministic Stage B tables, pure Resolver
  (ADR-0006), stability harness measuring the kill-criterion
- Status: PLAYTESTED 2026-06-22 with real Claude Haiku (claude-haiku-4-5) via harness.mjs.
- Verdict: PIVOT. Deterministic half PASS. Stage A axis/channel classification is NOT stable
  run-to-run (4/5 phrasings gave 2-3 distinct axis labels) — but invokesScandalFacet was 25/25
  stable. Outcome looked stable only by degenerate collapse (all losing); flips where a win is
  possible. Decisive move rarely lands (scandal-leverage reads as intimidation, Diplomat weak).
  Op note: strict-tool grammar 400 "Grammar compilation timed out" under repeated calls.
- Fix (PIVOT-NOTE.md): key the decisive-move collapse on the reliably-detected facet, not a
  brittle single primaryAxis; let Stage A name multiple axes (per ADR-0004); add retry for the
  strict-tool 400. Re-run harness.mjs after the fix.
- ACTION FOR USER: the API key was pasted into chat — ROTATE/REVOKE it in the Console.
