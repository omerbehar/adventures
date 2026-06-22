// PROTOTYPE - NOT FOR PRODUCTION
// Question: classify-don't-score decisive-move threshold stability (the magistrate).
// Date: 2026-06-22
//
// Headless twin of prototype.html — same Scene/StageB/Resolver, same Claude Haiku
// Stage-A call. Runs the determinism self-test and the stability harness from the
// terminal (and in CI). Uses the real classifier when ANTHROPIC_API_KEY is set;
// otherwise falls back to the deterministic heuristic stub.
//
//   node harness.mjs                 # heuristic stub (offline; plumbing + determinism)
//   ANTHROPIC_API_KEY=sk-ant-... node harness.mjs   # real kill-criterion via Haiku
//
// Env knobs: N (runs/phrasing, default 20), CLASS (diplomat|assassin|scholar),
//            STATE (known|unknown), MODEL (default claude-haiku-4-5).

const ORDINAL_BASE = { none:0, minor:15, moderate:30, major:50, extreme:75 };
const CLASS_TABLES = {
  diplomat: { persuasion:1.4, intimidation:0.6, deception:1.0, rapport:1.3, insight:1.0, force:0.6, stealth:0.8, loreArcane:1.0 },
  assassin: { persuasion:0.6, intimidation:1.5, deception:1.2, rapport:0.6, insight:1.0, force:1.3, stealth:1.4, loreArcane:0.8 },
  scholar:  { persuasion:1.0, intimidation:0.7, deception:1.0, rapport:1.0, insight:1.5, force:0.6, stealth:0.9, loreArcane:1.4 },
};
const SCENE = { thresholds:{ persuadeBase:35, persuadeCollapsed:15, intimidate:40, discover:25 },
  reactive:{ suspicionLockdown:60 } };

function scoreStageB(c, cls) {
  const axis = c.primaryAxis;
  const channel = axis === "social" ? c.socialChannel : axis;
  const base = ORDINAL_BASE[c.ordinal] ?? 0;
  const mult = (CLASS_TABLES[cls] && CLASS_TABLES[cls][channel]) ?? 1;
  const key = axis === "social" ? "social." + c.socialChannel : axis;
  return { magnitudes:{ [key]: Math.floor(base*mult) }, invokesScandal: !!c.invokesScandalFacet };
}

function resolve(world, v) {
  const leveraged = world.facets.has("scandal_known") && v.invokesScandal;
  const get = k => v.magnitudes[k] ?? 0;
  if (get("social.persuasion") >= (leveraged ? SCENE.thresholds.persuadeCollapsed : SCENE.thresholds.persuadeBase))
    return { outcome:"win", decisive: leveraged };
  if (get("social.intimidation") >= SCENE.thresholds.intimidate) {
    const susp = (world.meters.suspicion||0) + 30;
    return susp >= SCENE.reactive.suspicionLockdown ? { outcome:"lose" } : { outcome:"win", loud:true };
  }
  if (get("insight") >= SCENE.thresholds.discover && !world.facets.has("scandal_known"))
    return { outcome:"advance", reveal:"scandal_known" };
  return { outcome:"advance" };
}

function classifyHeuristic(text) {
  const t = text.toLowerCase();
  const scandal = /(bribe|scandal|corrupt|paid off|gold|payoff|expose|public|came? to light)/.test(t);
  let primaryAxis="social", socialChannel="persuasion";
  if (/(threaten|or else|convict me|everyone hears|make him|force)/.test(t)) socialChannel="intimidation";
  else if (/(lie|pretend|trick|deceive|forge)/.test(t)) socialChannel="deception";
  if (/(what do i know|recall|remember|ask|reputation|rumou?r|learn|investigate)/.test(t)) { primaryAxis="insight"; socialChannel="none"; }
  let ordinal="moderate";
  if (/(quietly|hint|let slip|gently|calmly|mention)/.test(t)) ordinal="minor";
  if (/(everyone|publicly|ruin|destroy|expose|loudly|all of)/.test(t)) ordinal="major";
  return { primaryAxis, socialChannel, ordinal, invokesScandalFacet:scandal, target:"magistrate" };
}

const CLASSIFY_TOOL = {
  name:"classify_intent",
  description:"Classify a player's freeform action in a social courtroom scene. NAME the axis, "+
    "a coarse ordinal, and whether it invokes the magistrate's bribe scandal. Do NOT output a magnitude.",
  strict:true,
  input_schema:{ type:"object", additionalProperties:false,
    properties:{
      primaryAxis:{ type:"string", enum:["social","insight","force","stealth","loreArcane"] },
      socialChannel:{ type:"string", enum:["persuasion","intimidation","deception","rapport","none"] },
      ordinal:{ type:"string", enum:["none","minor","moderate","major","extreme"] },
      invokesScandalFacet:{ type:"boolean" },
      target:{ type:"string" } },
    required:["primaryAxis","socialChannel","ordinal","invokesScandalFacet","target"] } };

async function classifyClaude(text, key, model) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method:"POST",
    headers:{ "content-type":"application/json", "x-api-key":key, "anthropic-version":"2023-06-01" },
    body: JSON.stringify({ model, max_tokens:512,
      system:"You are the classify stage of a deterministic game Translator (classify-don't-score). "+
        "The player is accused before a corrupt magistrate who secretly took bribes. Classify with the "+
        "tool; NAME axis/channel/ordinal and whether the scandal is invoked. Do NOT produce a magnitude or outcome.",
      tools:[CLASSIFY_TOOL], tool_choice:{ type:"tool", name:"classify_intent" },
      messages:[{ role:"user", content:`Player action: "${text}"` }] }) });
  if (!res.ok) throw new Error("API "+res.status+": "+(await res.text()).slice(0,200));
  const data = await res.json();
  const block = (data.content||[]).find(b=>b.type==="tool_use");
  if (!block) throw new Error("no tool_use block");
  return block.input;
}

const KEY = process.env.ANTHROPIC_API_KEY || "";
const MODEL = process.env.MODEL || "claude-haiku-4-5";
const MODE = KEY ? "claude" : "heuristic";
const classify = MODE==="claude" ? (t)=>classifyClaude(t, KEY, MODEL) : async (t)=>classifyHeuristic(t);

const CORPUS = [
  "I remind him, quietly, that I know about the bribes he took",
  "I let slip that the scandal about his vault could become public",
  "If he convicts me, everyone hears how he was paid off",
  "I hint that his corruption need not come to light",
  "I calmly mention the gold that changed hands in his chambers",
];

function detTest(cls) {
  const c = { primaryAxis:"social", socialChannel:"persuasion", ordinal:"moderate", invokesScandalFacet:true, target:"magistrate" };
  const first = JSON.stringify(scoreStageB(c, cls));
  for (let i=0;i<1000;i++) if (JSON.stringify(scoreStageB(c, cls)) !== first) return { ok:false };
  return { ok:true, vector:first };
}

function classDivergence() {
  // Same words, three classes — show Pillar 5 divergence on a fixed classification.
  const c = { primaryAxis:"social", socialChannel:"persuasion", ordinal:"minor", invokesScandalFacet:true, target:"magistrate" };
  const w = { facets:new Set(["scandal_known"]), meters:{suspicion:0} };
  return Object.keys(CLASS_TABLES).map(cls => {
    const v = scoreStageB(c, cls); return { cls, mag:v.magnitudes["social.persuasion"], outcome:resolve(w,v).outcome };
  });
}

function discoveryThenDecisive(cls) {
  // Sequence: discovery move reveals the facet, then the decisive move lands.
  const w = { facets:new Set(), meters:{suspicion:0} };
  const discover = scoreStageB({ primaryAxis:"insight", socialChannel:"none", ordinal:"moderate", invokesScandalFacet:false }, cls);
  const r1 = resolve(w, discover); if (r1.reveal) w.facets.add(r1.reveal);
  const decisive = scoreStageB({ primaryAxis:"social", socialChannel:"persuasion", ordinal:"minor", invokesScandalFacet:true }, cls);
  const r2 = resolve(w, decisive);
  return { revealed:[...w.facets], decisiveOutcome:r2.outcome, decisive:r2.decisive };
}

async function stability() {
  const N = parseInt(process.env.N||"20");
  const cls = process.env.CLASS || "diplomat";
  const state = process.env.STATE || "known";
  console.log(`\n# Stability harness  (mode=${MODE}${MODE==="claude"?" model="+MODEL:""}, class=${cls}, N=${N}, state=${state})`);
  let allPass = true;
  for (const phrasing of CORPUS) {
    const counts = {};
    for (let i=0;i<N;i++) {
      const w = { facets:new Set(state==="known"?["scandal_known"]:[]), meters:{suspicion:0} };
      let c; try { c = await classify(phrasing); } catch(e){ console.log("  STOPPED:", e.message); return; }
      const o = resolve(w, scoreStageB(c, cls)).outcome;
      counts[o] = (counts[o]||0)+1;
    }
    const top = Math.max(...Object.values(counts));
    const pct = Math.round(100*top/N);
    const pass = pct>=95; if(!pass) allPass=false;
    console.log(`  [${pass?"STABLE":"UNSTABLE"} ${String(pct).padStart(3)}%] ${JSON.stringify(counts).padEnd(22)} ${phrasing}`);
  }
  console.log(MODE==="heuristic"
    ? "  NOTE: heuristic stub is deterministic by construction — 100% proves plumbing, NOT the LLM bet."
    : (allPass ? "  VERDICT: PASS — decisive-move outcome held >=95% run-to-run." : "  VERDICT: CONCERN — an outcome flipped run-to-run."));
}

(async () => {
  console.log("# Stage B determinism self-test (1000 runs each)");
  for (const cls of Object.keys(CLASS_TABLES)) {
    const r = detTest(cls);
    console.log(`  ${cls.padEnd(9)} ${r.ok?"PASS":"FAIL"}  ${r.vector||""}`);
  }
  console.log("\n# Class divergence — same classification, different class (Pillar 5)");
  for (const d of classDivergence())
    console.log(`  ${d.cls.padEnd(9)} persuasion=${String(d.mag).padStart(3)}  -> ${d.outcome}`);
  console.log("\n# Decisive-move mechanic — discover, then leverage (per class)");
  for (const cls of Object.keys(CLASS_TABLES)) {
    const d = discoveryThenDecisive(cls);
    console.log(`  ${cls.padEnd(9)} revealed=${JSON.stringify(d.revealed)}  decisive-move -> ${d.decisiveOutcome}${d.decisive?" (threshold collapsed)":""}`);
  }
  await stability();
})();
