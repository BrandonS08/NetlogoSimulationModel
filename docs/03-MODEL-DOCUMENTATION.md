# Deliverable (c): Plain-English walkthrough of every procedure

This is the complete narrative of what the model does, procedure by procedure,
written so you can verify the model matches your research design without
reading code. Each subsystem notes which part of your framework it implements.
Notation: **C1/C2/C3** are the NGO commodity classes, **P1–P4** the public
ones; one tick = one simulated day; money is in BDT (taka).

---

## 1. The cast of agents

| Agent (breed) | Count | Represents | Key state |
|---|---|---|---|
| `regional-hub` | 1 | Single-node proxy for the CMSD/EDCL/SMC national supply layer, now split into **three differentiated channels** (see §8) | `smc-c1-stock`, `edcl-rdf-stock`, `public-channel-stock` |
| `public-cc` | 12 | Government Community Clinics on rigid top-down push allocation | 4-class stock list, stockout trackers |
| `ngo-static` | 3 | NGO hub clinics on a Revolving Drug Fund — **the only agents with information-latency mechanics** | true stock, recorded ledger, RDF capital, latency state machine |
| `ngo-satellite` | 9 (3 per static) | Rotational outreach endpoints, administratively dependent, **no independent finances** | 3-class stock; all revenue flows to the parent hub |
| `private-shop` | 15 | Informal retail pharmacy spillover market | 3-class stock, restocked weekly |
| `requisition` | transient | One reorder request in flight; exists to implement the processing delay and to log outcomes | origin, class, quantity, timestamps, status |

Two variables on each `ngo-static` carry the entire research question:

- **`stock-on-hand`** — physical reality on the shelf.
- **`recorded-stock-ledger`** — what the clinic's information system believes.

**Every reorder decision reads the ledger, never the true stock.** Nothing in
the hardened build weakens this; several base-build bugs that accidentally
*leaked truth into the ledger during outages* were fixed to make it stricter
(see `06-CHANGELOG.md`, B1).

---

## 2. One simulated day (`go`)

Every day, in this order:

1. `reset-daily-trackers` — zero out today's per-clinic request/dispense books.
2. `update-demand-shocks` — monsoon/flood shock clock (start/continue/end).
3. `update-connectivity` — each static clinic draws whether it is online today.
4. `apply-physical-spoilage-and-shrinkage` — waste accrues (outcome 2).
5. `process-public-demand` — patients at the 12 community clinics; shortfalls
   enter the diversion cascade.
6. `process-ngo-static-demand`, `process-ngo-satellite-demand` — patients at
   NGO facilities; sales earn RDF revenue.
7. `track-zero-stock` — records zero-stock episodes (outcomes 3 & 4).
8. `update-ledger-visibility` — the *digital* information pipeline moves one day.
9. `process-manual-paper-fallback` — the *paper* fallback state machine moves.
10. `update-demand-forecast` — weekly forecast refresh (predictive arm).
11. `apply-operating-costs`, `process-capital-lock-and-bailouts` — RDF finances.
12. `process-ngo-reorders` — reorder decisions **read the lagged ledger**.
13. `process-pending-requisitions` — orders whose delay has elapsed resolve
    (fulfilled / partial / lost) and are logged.
14. `run-replenishment-cycles` — push channels, satellite restocking, private
    market restock, on their own calendars.
15. `record-demand-history`, `update-running-metrics` — bookkeeping.

---

## 3. Setup and geography

`setup` builds the world fresh: parameters first (`setup-parameters` is a
single commented registry where every number carries a source tag — [SPEC],
[LIT], [CALIBRATED], or [ASSUMPTION]), then the hub at the center, then
facilities.

`move-to-stylized-location` implements your paper's *uneven facility
distribution*: 55% of facilities land inside one of two population clusters,
the rest scatter, and nothing may sit on top of the hub or another facility.
This is explicitly **stylized, not statistically calibrated** geography — the
clusters create realistic competition for the same nearby NGO facilities
during diversion, which is all the mechanism your research question needs.
(Hardened build: placement can no longer crash when a random draw finds no
eligible patch, and no longer depends on the hub happening to be turtle 0.)

---

## 4. Shocks and connectivity

`update-demand-shocks`: while no shock is active and `demand-shocks?` is On,
each day has a 2-in-365 chance of starting one (~2 events/year — a stylized
monsoon/flood proxy). A shock lasts 7–21 days (uniform; the base build could
never actually produce 21 — off-by-one, fixed). While active:
**demand ×1.8 everywhere** and **grid-failure risk +0.25**.

`update-connectivity`: each static clinic independently draws today's
connectivity against `effective-grid-failure-rate`. Losing connectivity is
what starts the paper-fallback episode in §7. On reconnection the clinic does
NOT instantly return to digital — that's the stickiness countdown (§7).

---

## 5. Patient demand and the diversion cascade

`process-public-demand`: each community clinic sees ~Normal(38, 5) patients a
day (calibrated to the WHO/CBHC 2019 evaluation figure of ~40 visits/day by
2016). Two percent are routine clinical referrals upward — they are counted in
`routine-referrals` and **no longer draw commodities** (the base build
double-counted them). The rest split across P1–P4 by the fixed fractions
(15% / 55% / 10% / 20%) and draw down stock.

When a class runs dry, `divert-public-patient` runs your paper's chained
cascade, exactly as designed:

- **P1 → C1, P2 → C2, P4 → C3**: the patient walks to the **nearest NGO
  facility** (static or satellite). If it also lacks stock, on to the
  **nearest private shop**. If the shop is also out, the patient is counted in
  `completely-unserved-patients`.
- **P3 (cold-chain) → nobody**: vaccines have no NGO or private substitute, so
  these patients are counted in `coldchain-unserved` (referral to higher-tier
  care). Preserved exactly from the base design.

`serve-from-stock` is the single shared routine for taking units off an NGO
shelf. It also: records the request in the clinic's daily books (feeding the
forecast), and **credits RDF revenue** — C2 at the retail price, C3 at the
diagnostics user fee, C1 free (public ESP commodity). Satellites credit their
parent hub, never themselves. (The base build silently gave away C2 stock to
diverted patients for free, and forgot satellite revenue in the shortfall
branch — both leaks are fixed; see changelog B4/B5.)

`process-ngo-static-demand` / `process-ngo-satellite-demand`: NGO facilities'
own patient load (statics: means 25/55/22 per day for C1/C2/C3; satellites:
5/10/2). A satellite's unmet **C2** patients walk to the parent static hub the
same day — the administrative-dependence mechanic from the base build,
preserved. Whatever the NGO network cannot serve spills to the private shops,
and whatever the shops cannot serve becomes `completely-unserved-patients`.
Every unit the NGO network fails to provide is counted in
`ngo-unmet-patients` (outcome 1).

---

## 6. Physical losses (outcome 2)

`apply-physical-spoilage-and-shrinkage` converts monthly loss rates into daily
draws: C1 spoils at 5%/month, C2 at 5% + 3% shrinkage, C3 at 2.5%/month
(named assumption), and public cold-chain stock (P3) at 1%/month — accelerated
×4 whenever grid stress is high (shock conditions), which is the
refrigeration-failure channel. All losses accumulate in unit counters and in
`waste-value-total`, priced at procurement value per class.

Technical fix worth knowing about: daily losses on realistic stock levels are
fractions of a unit (e.g., 0.017 vaccine doses/day). The base build rounded
these to zero, so **the cold-chain waste counter could never move at all**.
The hardened build uses stochastic rounding (a 0.4-unit expected loss becomes
one whole unit on 40% of days), so long-run waste now matches the intended
rates.

---

## 7. The information layer — the heart of the model

This implements your three-stage latency decomposition plus the paper-fallback
behavior. All of it lives in `update-ledger-visibility`,
`process-manual-paper-fallback`, and `accumulate-paper-error`.

**Connected, digital mode.** Each day the clinic's true closing stock enters a
sync queue and becomes visible to the ledger only
`(dispensation-lag + sync-lag) × environmental-latency-severity` days later (stage 1:
consumption-to-entry delay; stage 2: batching/upload delay). So in the best
connected case the ledger is a faithful photograph of the shelf **as it looked
several days ago** — permanently stale, never fabricated. At severity 0 the
delay collapses to zero and the ledger tracks truth exactly (your
perfect-information control condition).

**Disconnected.** The clinic flips to `manual-fallback?`. Two things happen,
and this is precisely your "nothing gets revealed while disconnected" design:

1. The digital pipeline stops completely — no snapshots are taken and none are
   applied. The ledger **freezes** at its last synced value while the shelf
   keeps emptying, so the true-vs-recorded gap **widens with outage length**.
2. Error accumulates in the paper registers: each offline day adds
   `(units dispensed that day) × 8% × severity` to `paper-error-accum`. The
   bias is positive by design — missed paper entries mean unrecorded
   dispensing, which makes the system believe **more** stock remains than
   truly does. That is the dangerous direction (it delays reorders), and it is
   the documented failure mode of manual registers.

   *(Base-build contradiction fixed here: the old fallback code re-anchored
   the ledger to near-truth every offline day, which made the ledger MORE
   accurate during outages than during normal operation — the opposite of the
   stated design. See changelog B1, the most important single fix.)*

**Reconnection and stickiness.** When connectivity returns, staff keep using
paper for `fallback-recovery-lag` (3) more days — the behavioral stickiness
from your framework. The ledger stays frozen and paper error keeps accruing.

**Reconciliation.** When the countdown expires, the paper backlog is entered
in one batch: the ledger becomes *true stock + accumulated paper error*, the
error resets, stale in-flight snapshots are discarded, and the digital
pipeline restarts. The residual paper error then persists in the ledger for
one more full sync delay before being washed out — so the gap narrows in
stages, not instantly.

**Forecasting** (`record-demand-history`, `update-demand-forecast`): each
static keeps a 14-day rolling history of everything *requested* from it
(walk-in patients, diverted public patients, satellite restocking pulls).
Weekly, the forecast becomes the trailing mean ± a narrow noise band
(±5%) — the low-noise forecast-band pattern from the Michigan
proof-of-concept, adapted to track real demand trends so it responds to
shocks after a short delay. The forecast reads *patient flow* (observable on
paper day to day), **not** the corrupted stock ledger — clinics can see their
waiting rooms even when their stock data lags.

---

## 8. Procurement and RDF finances

**Reorder decisions** (`process-ngo-reorders`, `reorder-triggered?`):

- *Baseline rule:* order when the **ledger's** C2 (or C3) figure falls to the
  safety stock. Order size = capacity minus the **ledger** figure. Both read
  the corrupted belief; if paper errors overstate stock, orders fire late and
  small — exactly the pathology your paper describes.
- *Predictive rule* (`predictive-modeling?` On): the trigger subtracts
  `forecast × projection-horizon` before comparing to safety stock, where the
  horizon = procurement lead time + known data staleness. Orders fire
  *earlier*, compensating for delay — but quantities still come from the
  lagged ledger. **Predictive modeling fixes timing, not data accuracy** —
  preserved exactly as specified, and verification check 2 lets you see it.
- One order per class may be in flight at a time (`c2-order-outstanding?` /
  `c3-order-outstanding?`). The base build hatched a fresh full-size order
  *every day* the ledger sat below the trigger, silently multiplying
  deliveries several-fold (changelog B2). A clinic knows what it has itself
  ordered — that requires no connectivity.

**Two procurement routes**, per your paper's sourcing distinctions (gap 3):

| | C2 (RDF pharmaceuticals) | C3 (diagnostics/consumables) |
|---|---|---|
| Source | EDCL/wholesale channel at the regional hub | **Local wholesale market** (never touches the hub) |
| Delay | `central-processing-lag` (2 days, bureaucratic approval — stage 3 of your latency framework) | `local-procurement-lag` (2 days delivery, no central approval) |
| Supply limit | Channel stock — can ration or fail | Treated as unconstrained (deep informal market, named assumption) |
| Funding | RDF capital at 15 BDT/unit, resold at 22 | RDF capital at 10 BDT/unit, user fee 15 (named assumptions) |

`process-pending-requisitions` resolves each order once its delay elapses:
ships what supply and the clinic's *current* capital allow — fully
(**fulfilled**), partly (**partial**), or not at all (**lost**) — and appends
one row to `requisition-log` (gap 4). The clinic's outstanding-order flag
clears either way.

**RDF sustainability loop:** sales revenue in, procurement + a daily operating
cost (800 BDT, flagged calibrated assumption — see changelog N1) out. If
capital falls below the cost of a minimum viable batch (7 days of C2), the
clinic is *capital-locked*: it cannot order, so it cannot sell, so it cannot
recover — the RDF decapitalization spiral. After 30 consecutive locked days a
donor recapitalization grant (50,000 BDT) arrives and is counted in
`donor-bailouts-total`, so decapitalization events are measurable instead of
silently absorbing the rest of the run. (The base build's lock could freeze a
clinic forever *while it still held plenty of cash* — a threshold livelock,
changelog B3.)

---

## 9. Replenishment channels (gap 1: differentiating CMSD/EDCL/SMC)

The regional hub remains a single node on the map — your deliberate
simplification — but its warehouse is now split into three channels whose
logistics differ the way your paper describes:

- **`public-channel-stock`** (CMSD/EDCL → public CCs): receives a fixed
  monthly quota, and the monthly push now actually **draws it down** (in the
  base build, pushes materialized from nothing and the public warehouse
  variable was never touched — changelog B7). If total need exceeds channel
  stock, every clinic receives a proportional ration.
- **`smc-c1-stock`** (SMC/DGFP donor channel → NGO C1 push): same monthly
  cadence and rationing, feeding the fixed C1 push to NGO statics.
- **`edcl-rdf-stock`** (EDCL/wholesale → NGO C2 requisitions): replenished
  every 14 days; sized so normal offtake just about clears (~400 units/day
  supply vs ~390/day modeled demand), so shock periods produce genuine
  partial and lost requisitions.
- **C3 never passes through the hub** — bought locally (§8).

`resupply-ngo-satellites` (weekly): satellites top up to their targets
(40/80/30) from the parent hub's physical shelf. The transfer is booked into
the hub's demand history, so forecasts see total offtake. Satellite C3 is now
restocked too — in the base build the satellites' C3 shelf was a one-shot
buffer that silently died (changelog B15).

`restock-private-shops` (weekly): shops reset to their base stock — the deep
informal wholesale market assumption. In the base build shops were never
restocked, so the private market silently emptied a few months in and the
entire diversion cascade dead-ended for the rest of a 10-year run
(changelog B6).

---

## 10. The four outcome metrics (and how each is defined)

1. **`ngo-unmet-patients`** — every unit of patient need presented at an NGO
   facility (walk-in, diverted from a public CC, or satellite referral) that
   the NGO network could not serve from stock, counted at the moment of
   failure regardless of whether a private shop later rescued the patient.
2. **`waste-value-total`** — BDT value of all expired/spoiled units (NGO
   C1/C2/C3 spoilage and shrinkage + public cold-chain losses), priced at
   procurement value. Unit counts are kept separately
   (`total-expired-units`, `total-expired-units-coldchain`).
3. **`lines-ever-zero`** — a "line" is one commodity class at one facility
   (12 CCs × 4) + (3 statics × 3) + (9 satellites × 3) = 84 lines. This counts
   how many ever hit zero during the run.
4. **`zero-episode-total`** — total number of distinct zero-stock episodes
   (a line entering zero counts once until it recovers above zero), with
   `zero-episodes-per-line` and per-class `ngo-zero-episodes` breakdowns.

Supporting metrics: `completely-unserved-patients`, `coldchain-unserved`,
`routine-referrals`, `private-rescues`, requisition counters and
`requisition-fill-rate`, `public-availability-pct` and
`public-facility-stockout-pct` (the two calibration benchmarks),
`mean-ledger-age-days`, `mean-ledger-gap-c2`, `pct-time-on-paper`,
`mean-rdf-capital`, `donor-bailouts-total`, `total-shock-days`.

### Two measurement cautions you need for the write-up

**1. Metrics 1, 3 and 4 are diluted by components that cannot respond to the
treatment.** Public community clinics run on a rigid push cycle with no
information mechanics at all, and satellites restock to fixed weekly targets.
Both contribute large, essentially constant amounts to `ngo-unmet-patients`,
`lines-ever-zero` and `zero-episode-total`. Only the three NGO statics carry
the latency layer, so a change in `environmental-latency-severity` or
`predictive-modeling?` can only move the static component. Always report the
decomposition alongside the total — `ngo-unmet-walkin` vs `ngo-unmet-diverted`,
and `static-zero-episodes` vs `satellite-zero-episodes` vs
`public-zero-episodes`. A reviewer who sees only the totals will conclude the
treatment effect is small; the decomposition shows where it actually lives.

**2. `mean-ledger-gap-c2` is confounded by stock volatility, and
`mean-ledger-age-days` is not.** The gap measures `|belief − reality|` in
units, which is roughly how much stock moved during the staleness window. Any
intervention that smooths the stock trajectory shrinks the gap without
improving the information system at all. So the gap is a valid measure of *how
costly* staleness is, but not of *how stale the data is*. Ledger age — how
many days out of date the ledger is — depends only on connectivity and
severity, and is the metric to cite when demonstrating that predictive
modeling leaves data accuracy untouched. Both are reported; use them for
different claims.

---

## 11. Commodity taxonomy (gap 6 — documentation, not simulation)

Class-level aggregation is **preserved by design**: each class is simulated as
one pooled inventory, and the named commodities below justify the class
parameters instead of being simulated separately. This is the deliberate
complexity/rigor tradeoff from the handoff, and the right one for an
agent-based study of *information dynamics* rather than *formulary detail*.

| Class | Contents (from your taxonomy) | Sourcing story the class parameters encode |
|---|---|---|
| P1 | Family Planning / Maternal health commodities | DGFP/SMC vertical push channel |
| P2 | EDCL Essential Medicines (the ~40-item CC list) | CMSD/EDCL monthly allocation |
| P3 | Cold-chain vaccines / emergency commodities | EPI cold chain; no private substitute |
| P4 | Diagnostics / consumables | CMSD kits + local supplement |
| C1 | ESP / contraceptives at NGO clinics | Push-sourced (SMC/DGFP), free to patients |
| C2 | RDF retail pharmaceuticals — four subgroups, below | Revolving Drug Fund purchase & resale; the network's operating revenue |
| C3 | Diagnostics / consumables at NGO clinics | Locally purchased from wholesalers, RDF-funded |

### The named commodities behind each NGO class (paper §2.2.3.1)

These are the real commodity groups the class-level parameters describe. They
are documented here rather than simulated separately — the deliberate
complexity/rigour tradeoff.

**C1 — public-endorsed ESP commodities (MNACH-FP).** Long- and short-acting
contraceptives (oral contraceptive pills e.g. Femicon; injectable
contraceptives Soma-Sect/DMPA; condoms; emergency contraceptive pills),
micronutrient supplements, oral rehydration salts, maternal health packs.
*Sourcing:* vertical push from the SMC Star Network and DGFP. The SMC is the
**only** private-sector source for injectable contraceptives, so facility
purchasing autonomy over this class is near zero — which is exactly why C1 is
modelled as a pure push with no reorder logic.

**C2 — commercial retail pharmaceuticals, four subgroups** (Rahman et al.
163–165):

| Subgroup | Named commodities | Modelling relevance |
|---|---|---|
| Antimicrobials | Amoxicillin, Azithromycin, Ciprofloxacin, Cefuroxime | The paper notes these are "prone to sudden, climate-driven demand surges during monsoons or waterborne disease outbreaks" — the direct justification for applying the shock demand multiplier to C2 |
| Chronic disease | Amlodipine, Losartan (antihypertensives), Metformin (oral hypoglycemic) | Steady baseline demand; stockouts here are continuity-of-care failures |
| Vitamins & minerals | Calcium, Vitamin D3, Vitamins B1/B6/B12 | High turnover, low unit value |
| General primary care / OTC | Omeprazole, esomeprazole (antiulcerants), Paracetamol, antihistamines, water purification tablets | Highest turnover; drives day-to-day RDF revenue |

*Sourcing:* decentralized requisition from domestic commercial manufacturers —
Bangladesh's pharmaceutical sector supplies 98% of domestic demand for this
class, with the top 10 producers holding ~67% of the market (Square, Incepta,
Beximco ≈ 36% in 2018). Purchased into SHN's own central warehouses, then
released against clinic requisitions. **This channel is not the EDCL** — EDCL
and CMSD serve the public sector only.

**C3 — clinical diagnostics and medical consumables.** Blood glucose testing
strips, rapid diagnostic test kits (malaria, dengue), pregnancy test kits,
sterile syringes, saline infusion sets, PPE. *Sourcing:* decentralized local
purchase orders from commercial medical supply wholesalers.

*Why this class matters more than its size suggests:* the paper's Rakhal Gonj
example — glucometers rendered useless because the strips and batteries were
absent — is the clearest illustration in the whole document of a low-cost
consumable stockout disabling a high-value capability. The model reproduces
the mechanism (C3 stockouts block service delivery) but not the
complementarity between specific items, which is a stated limitation.

**Still needed from your paper:** the forty named public-sector commodities
behind P1–P4. Section II as supplied establishes the CMSD/EDCL split (512 vs
224 procurement-list items; ≥70% of government facility medicines from EDCL;
EDL expanded to 295 medicines in January 2026) but does not enumerate the
forty. Add that table here when you have it.
