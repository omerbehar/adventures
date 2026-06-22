# Prototype: intent-translation (the magistrate)

> **PROTOTYPE — NOT FOR PRODUCTION.** Throwaway build. Never imported by `lib/`.
> Date: 2026-06-22 · Path: HTML (single file) · Concept doc: `design/gdd/game-concept.md`

## The question this answers

The concept's **prototype kill-criterion**: does *classify-don't-score* keep the
magistrate scene's **decisive-move threshold stable run-to-run**?

**Hypothesis.** If a player expresses the decisive move — invoking the leverage facet
(the magistrate took bribes) — in their own varied words, the pipeline collapses the
persuasion threshold to its trivial value **consistently**. We accept it if, across
N≈20 runs of ~5 natural phrasings, the decisive-move outcome holds **≥95%**, and Stage B
+ the Resolver are **100% deterministic** given a fixed classification.

**Riskiest assumption (tested first):** that an LLM classifying evaluative/social intent
is stable enough run-to-run that the threshold never flips.

## How to run

1. Open `prototype.html` by double-clicking it (any modern browser — no server, no install).
2. **Play offline:** leave Stage A on *Heuristic stub*, pick a class, type actions. Try:
   - `what do I know about this magistrate?` (a discovery move → reveals the scandal)
   - `I remind him I know about the bribes` (the decisive move → threshold collapses → acquittal)
   - `I threaten to ruin him publicly` (intimidation path → wins but spikes suspicion)
3. **Run the real kill-criterion:** switch Stage A to *Claude Haiku*, paste an API key
   (see below), set N=20, choose "Scandal already discovered", click **Run stability test**.
   Read the **Stable %** column — PASS = ≥95% on every phrasing.
4. Click **Stage B determinism self-test** to confirm the deterministic half (1000 runs).

> The heuristic stub is deterministic by construction (always 100%) — it proves the
> plumbing and lets you play, but it does **not** test the LLM bet. Only the Claude
> classifier mode measures the real kill-criterion.

## How to get an endpoint / API key

Stage A is a real LLM call. The prototype uses **Claude Haiku** (`claude-haiku-4-5`) —
the same model your ADR-0007 assigns to Tier-2 disambiguation. To get a key:

1. Go to **https://console.anthropic.com** and sign in (or create an account).
2. Add a small amount of credit under **Billing** (classification calls are cheap —
   Haiku is ~$1 / 1M input tokens; a full N=20 × 5-phrasing run is a fraction of a cent).
3. Open **API keys → Create key**, copy the `sk-ant-...` value.
4. Paste it into the prototype's key field. It lives **in memory only** — it is never
   stored, logged, or sent anywhere except `api.anthropic.com`.

**Security caveats (important — this is a local-dev throwaway):**
- Calling the API directly from a browser requires the
  `anthropic-dangerous-direct-browser-access: true` header, which means **the key is
  exposed to client-side code**. Fine for a prototype you run on your own machine; **never
  deploy this file or commit a key.** In production (ADR-0004/0007) Stage A runs
  **service-side** and the key never reaches the client — this prototype deliberately
  shortcuts that to test the bet cheaply.
- If the browser blocks the request (CORS/network policy), run the page from a context
  that allows the direct-browser header, or port the harness to a tiny Node/Dart script
  using the same Messages API call.

## What maps to the architecture

| Prototype piece | ADR it mirrors |
|---|---|
| `classify_intent` strict tool-use call (names axis/channel/ordinal/facet, no number) | ADR-0004 Stage A |
| `scoreStageB()` deterministic class-colored tables | ADR-0004 Stage B |
| `SCENE` (entities, conditional thresholds, meter, reactive lockdown, narration keys) | ADR-0003 |
| `IfFacet` collapse = the decisive move | ADR-0003 / Pillar 3 |
| `resolve()` pure per-beat engine, authored-key narration | ADR-0006 / Pillar 2 |
| class multipliers (same words differ per class) | Pillar 5 / ADR-0004 |

## Explicitly cut

Save/load, scene-graph (multiple nodes), the Scene Compiler, the Tier 0/1/2/3 cascade,
token-budget instrumentation, accounts, real visual identity. This tests **one scene** and
**one measurement** — nothing else.

## Verdict

To be filled in after a real Claude-classifier run — see `REPORT.md`.
