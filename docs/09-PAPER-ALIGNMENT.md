# Aligning the model to the research paper (Sections I & II)

Written after receiving the paper text. Three parts: **what the paper
confirmed**, **what I changed because the paper contradicted the model**, and
**four decisions I need from you**.

Bottom line: the architecture was right. The three-stage latency
decomposition, the offline-first batch-sync behaviour, the behavioural
stickiness toward paper, the three-class NGO commodity structure, and the
dual-nature push/pull clinic agent all match the paper closely. Seven specific
parameters or mechanisms did **not** match, and are now fixed.

---

## Part 1 — What the paper confirmed (no change needed)

- **The three lag points.** §2.2.4 defines point-of-dispensation lag, local
  device synchronization lag, and central processing lag exactly as
  implemented, including that central processing lag is "primarily caused by
  human rather than environmental lag" — which is why it applies after a
  reorder triggers rather than to data flow.
- **Batch sync.** "The system flushes out all of the queued data to the
  central database server as a single batch sync" — the model's pending-update
  queue with batch application on reconnection.
- **Behavioural stickiness.** "Staff grow comfortable resorting to manual
  paper-based inventory management — even in times of stable connection." This
  is the single most important confirmation: the fallback-recovery mechanic
  was the right call, and the paper argues for it directly.
- **Ledger/reality decoupling.** "An offline-first protocol… inherently forces
  a decoupling of the physical movement of stock throughout a network from its
  digital visibility." That is the model's core mechanic, in the paper's words.
- **No warehouse visibility.** "OpenMRS also does not typically integrate
  warehouse or distribution center level tracking… leaving clinicians and
  regional supervisors unaware of upstream stock balances." The model matches:
  clinics cannot see channel stock, and discover shortages only when a
  requisition returns partial or lost.
- **Three commodity classes**, their sourcing vectors, and the dual-nature
  agent ("passive recipients of public pushes… while simultaneously being
  directly involved as a cash-constrained market buyer").
- **Satellite dependence on the parent static** for consumption data and
  reorder calculations (§2.3, final paragraph).
- **Expiratory waste destroying rolling capital** as the RDF failure mode
  (§2.2.5).

## Part 2 — Seven changes made because the paper contradicted the model

### P1. Order quantity now uses the Maximum Stock formula — **most important**
Your paper specifies the rule outright: *"the agentic simulation model
introduced in this study will utilize the maximum stock approach… Order
Quantity = [Average Monthly Consumption × Review Period] + (Safety Stock) −
(Stock On Hand) (MSH, 46.8, Box 46-1)."*

The model was using `order = capacity − believed stock`, a different rule.
Now implemented exactly as specified, with Average Monthly Consumption
computed from each clinic's own observed 30-day demand history ("governed
strictly by localized monthly consumption data"), review period = 1 month.

**The research-critical detail:** "Stock On Hand" in the formula is fed from
`recorded-stock-ledger`, not true stock. The formula is correct; the number
going into it is stale; the order is therefore wrong by exactly the size of
the information gap. This is now a much cleaner statement of your thesis than
the old rule allowed, because the error enters a formula your paper cites
rather than one I invented.

### P2. RDF capital was understated ~7.5×
The paper: SHN's RDF ≈ **241 million** Taka in 2024, across **134** permanent
registered facilities ⇒ ~1.8 million Taka per static clinic. The model had
241,000 per clinic — the right digits at the wrong scale. Now 1,798,000.

### P3. Operating costs no longer charged to the RDF
I had added a daily operating cost so the fund could fail. **The paper says
that cannot happen:** "all earned capital must be rolled over and strictly
contained within the RDF," and RDF capital "is inflexible and cannot be used
for any means other than drug procurement." SHN's own accounts show 100% of
medical-sales gross profit swept into the RDF, leaving the *general* fund at a
6.5M Taka loss. Operating cost is now **0** and the mechanism is documented as
off. My invented assumption is gone; your paper replaced it.

### P4. New: revenue is only spendable once digitally verified
This replaces P3's mechanism with the one the paper actually describes:
*"If demand spiked during some form of connective outage, capital legally tied
up in medical sales would be useless with the systems required to validate
consumption being offline."*

Sales revenue now lands in `unverified-revenue` and converts to spendable
`rdf-capital` only when the clinic syncs. During an outage the clinic takes
money at the counter but **cannot use it to reorder**. This gives information
latency a direct financial channel — an outage now freezes purchasing power,
not just data — and it is measurable via the new `mean-unverified-revenue`
monitor. This is the most substantive addition from the paper, and I think
it is the strongest single mechanism in the model now.

### P5. C2 does not come from the EDCL
The model called the NGO's C2 supply channel `edcl-rdf-stock`. Per §2.2.1 vs
§2.2.3.1, EDCL and CMSD serve the **public** sector; NGO retail pharmaceuticals
are bought from **domestic commercial manufacturers** (Square, Incepta,
Beximco; 98% domestic supply, top 10 ≈ 67% of market) into the network's own
central warehouses. Renamed `ngo-warehouse-stock` throughout. A reviewer who
knows Bangladeshi pharmaceutical procurement would have caught this
immediately.

### P6. Run length is now 90 days
§I: "track and record data over 90 day simulation periods." Was 3,650 (and
1,095 in the experiment). Now 90 everywhere. Demand history is seeded with a
full month at baseline so Average Monthly Consumption is well defined from
day 1 — a 90-day run has no room for a warm-up period.

### P7. Paper-fallback stickiness raised from 3 days to 7
§2.2.4: staff digitise records at "end-of-week or even end-of-month batch
logging." End-of-week = 7 days. Three days was my guess; the paper is
specific. (End-of-month behaviour would be 30 — worth a sensitivity run.)

**Also:** the paper gives a *digital* error rate after OpenMRS adoption of 200
errors per 250,000 entries (0.08%). That is now cited as the justification for
modelling digital-mode error as zero — a sourced simplification rather than an
unexamined one. The *manual* error rate (8%) remains the model's least
supported number.

---

## Part 3 — Four decisions I need from you

### D1. Where does the 43% availability benchmark come from? ⚠️ blocking
Your handoff said your paper cites "roughly 43% EML drug availability and 50%
stockout rate" for Community Clinics, and I calibrated the entire public-sector
supply to reproduce it. **That figure is not in the text you sent.** What
Section II contains is a *readiness index* of **47** for Community Clinics
(Kabir et al.) — a composite of four domains (guidelines/staff, basic
equipment, diagnostic facility, essential medicine) against a threshold of 70.

A readiness index of 47 and an availability rate of 43% are **not the same
thing**, and presenting one as the other would be a serious methodological
error. Three possibilities:

1. The 43%/50% figure is elsewhere in your paper (a section you didn't send) —
   send me the sentence and citation and we're done.
2. It came from the WHO 2015 situational analysis, which I found
   independently and which does state ~43% availability. Then it needs to be
   cited as WHO 2015, not as Kabir et al.
3. There is no such figure and the calibration target should change.

Until this resolves, describe the calibration as targeting the WHO 2015
figure, and do **not** cite Kabir et al. for it.

### ~~D2. Satellite patient volume~~ — RESOLVED, and my framing was wrong
You corrected this: satellites do not take *patients* from the static, they
take *inventory*. See Part 4 below — the mechanic is rebuilt.

### D3. Should facility placement be statistically independent?
Your χ² test (χ² = 2.250, p = 0.134, V = 0.187) establishes that NGO and public
per-capita concentrations are **independent**. The model currently places both
using the same two population clusters at the same 55% rate, which makes them
*correlated* — mildly contradicting your own finding. Fix is easy: cluster the
public clinics, place NGO facilities independently. Worth doing if you plan to
cite the χ² result near the model description.

### D4. Rationing rule during shortages
The model rations a short channel **proportionally** across clinics. §2.2.4
describes something different: informal requisition by phone/email where "the
earliest clinics to demand supplies could take on more inventory than their
allotment would regularly allow for… leaving other similar clinics
underserved." That is first-come-first-served, and it produces *inequality*
between clinics that proportional rationing hides. Lower priority than D1–D2,
but it is a real difference and an easy switch.

---

## What this means for your write-up

The alignment work strengthens the project in a specific way worth naming: the
model's ordering rule is now a **published formula from a standard reference**
(MSH Box 46-1) rather than something invented for the simulation, and the
information-latency mechanism corrupts one named input to it. That is a much
easier thing to defend than "the model reorders when stock looks low."

The honest remaining weaknesses, in order: the manual-record error rate (still
unsourced), D1 above (a calibration target whose provenance is unclear), and
the compressed network scale (12 public clinics and 3 statics standing in for
a national system).

---

## Part 4 — Satellite rollouts rebuilt (and what the price catalogue supplied)

### The correction
The model treated satellites as standing clinics with their own daily patient
stream, restocked to fixed targets once a week. That was wrong. Satellites are
**teams that draw stock from the static, run a mini-clinic at an outlying site
for a day, and return** — they compete with the static for *inventory*, not for
patients. Rebuilt accordingly:

- **Rollout days.** Teams depart three days a week (Tue/Wed/Fri), one per
  satellite agent — nine departures per week per static. Cadence taken from the
  price/logistics catalogue: ~25 coverage sites per static, each visited 1–2×
  per month, ~10 teams/week. During a shock a fourth rollout day is added
  (~×1.33; the catalogue's monsoon factor is ~×1.45).
- **Commodity mix.** Packs are ESP/MNACH-dominated — vitamins, maternal items,
  contraceptives, ORS — plus the consumables needed to administer them, and
  **no C2 at all**, since outreach teams are not retail pharmacies. This was a
  real error before: satellites were consuming ~10 units/day of RDF retail
  pharmaceuticals they would never have carried.
- **Departure and return.** The static's books record the whole pack as issued
  when the team leaves, and reconcile against actual use when it returns. This
  is a second latency channel, layered on top of the digital one.
- **Between rollouts satellites hold nothing**, so they are now excluded from
  stockout tracking — an empty team is normal, not a stockout. Tracked lines
  drop from 84 to **57** (12 public CCs × 4, plus 3 statics × 3). Unmet
  outreach demand is still counted, in `ngo-unmet-own`, where it belongs.
- **Diverted public patients now route to statics only.** Sending a walk-in to
  a team that is out in the field on a given day made no sense.

**Pack size and site demand remain assumptions** (45 C1 + 9 C3 packed;
~30 C1 + ~6 C3 consumed). You told me the catalogue's quantities were
arbitrary, so I did not use them. These are the two numbers in the satellite
mechanic with no external basis — flagged accordingly.

### What the price catalogue was used for
Only prices, and only where they replaced pure assumptions:

| Parameter | Was | Now | Basis |
|---|---|---|---|
| C1 unit value (waste pricing) | 5 BDT (assumed) | **11 BDT** | median of the MNACH class |
| C3 unit cost | 10 BDT (assumed) | **8.5 BDT** | median of the Consumables & Diagnostics class |
| C3 user fee | 15 BDT (assumed) | **12.5 BDT** | cost × 1.47, matching the C2 margin |
| Cold-chain dose value | 100 BDT (assumed) | **100 BDT** | MR vaccine price — the assumption was right |

C2 cost/retail (15/22) were left alone: those came from your specification
document, which is authoritative for numeric parameters.

Nothing behavioural was taken from the catalogue. Its demand rates, stock
levels, patient volumes and flood multipliers are all untouched.

---

## Part 5 — Things in the catalogue I'd like permission to use

You offered, so here are the four worth asking about, most useful first.

1. **Flood demand multipliers.** The catalogue models a post-flood window of
   roughly 0–30 days with per-item demand multipliers reaching 10–25× for
   flood-sensitive items (IV fluids, ORS, anti-venom), rather than a flat
   uplift. The model currently applies a single ×1.8 to everything, from your
   spec document. A shock that hits *some* commodity classes hard and others
   barely is both more realistic and more interesting for your question, since
   it stresses exactly the classes with the longest information paths. **May I
   apply class-differentiated shock multipliers** — say C1 and C3 strongly
   affected, C2 moderately — rather than one flat number? If yes, I'd also want
   to know whether ×1.8 or the catalogue's steeper range should govern.

2. **Cold-chain / temperature sensitivity flags.** The catalogue marks items as
   `coldChain`, `tempSensitive` and `highTempSensitive`. The model applies
   cold-chain spoilage only to the public P3 class; NGO C1 contains vaccines
   (you mentioned satellites carrying them) and heat-sensitive items with no
   spoilage acceleration during outages. **May I extend outage-accelerated
   spoilage to the vaccine/heat-sensitive share of C1?** This would let power
   failures damage NGO stock, not just delay NGO information — a second
   physical consequence of the same environmental shock.

3. **Two-clinic rural/urban contrast.** The catalogue distinguishes a rural
   site from an urban one with markedly different patient volumes and starting
   stock. Your paper's §2.1 makes a great deal of uneven distribution, and
   Section I says "a series of closed-ecosystem models" — plural. **Should the
   statics be differentiated into rural and urban profiles** rather than three
   identical clinics? This is the change I am least sure you want, since it
   adds a dimension to every result table.

4. **Patient volumes for NGO statics.** The catalogue gives daily patient
   ranges per static clinic. The model instead uses per-class demand means from
   your spec document. These may disagree. **Do you want me to check them
   against each other**, and if they conflict, which wins?

Answer any subset — each is independent, and the model is complete and runnable
without all four.

---

## Part 6 — Decisions applied, and the full re-scaling audit

### Your answers, as implemented

| Decision | Outcome |
|---|---|
| 43% benchmark | **Accurate, source outside the supplied text.** Calibration unchanged. ⚠️ You must supply the citation for the write-up, and it must **not** be attributed to Kabir et al. — that source gives a *readiness index* of 47, a different measurement. |
| Class-differentiated shock multipliers | **Yes** — implemented, see below |
| Heat spoilage for NGO C1 | **Yes** — implemented, see below |
| Rural/urban static profiles | **Declined** — three identical statics retained |
| Patient-volume cross-check | Spec wins. Checked: they agree. The spec's per-class demand implies roughly 50–100 patient-equivalents/day at a static, and the catalogue's rural clinic runs 40–60/day. Same order of magnitude, no change made. |

### Class-differentiated shocks
The specification's ×1.8 is preserved **exactly**, as the demand-weighted mean
across classes; the catalogue supplies only the *shape*. Catalogue flood
sensitivity per class (share of items affected × mean multiplier) gives relative
excess demand of about 1.5 : 3.0 : 10.0 for MNACH : pharmaceuticals :
consumables. Scaling that so the weighted mean lands on 1.8 gives:

| Class | Shock multiplier |
|---|---|
| C1 / P1 / P3 (MNACH, vaccines) | **×1.30** |
| C2 / P2 (pharmaceuticals) | **×1.61** |
| C3 / P4 (consumables, diagnostics) | **×3.02** |

These are **derived in code** from `shock-demand-multiplier`, not hard-coded, so
changing the aggregate rescales every class and the weighted mean always holds.

Why this matters for your argument: consumables and diagnostics take the
heaviest hit — they are the flood-response commodities — and C3 also has the
shortest lead time and thinnest buffer. The shock now lands hardest exactly
where the information system is least forgiving, which a flat ×1.8 could not
express.

### Heat spoilage on NGO Class 1
Five of ten MNACH commodities in the catalogue carry a cold-chain or
temperature-sensitivity flag (2 cold-chain including MR vaccine, 2 high-temp,
1 temp). That 50% share of C1 now spoils at the ×4 outage rate when the grid is
failing. **One environmental shock now has two physical consequences at NGO
clinics** — it damages stock *and* delays information — where previously it only
delayed information.

### Re-scaling audit
You asked me to make sure things scale across the board. The satellite rebuild
raised C1 and C3 throughput substantially, which invalidated several buffers.
All flows re-derived and re-balanced:

| Quantity | Before | Now | Basis |
|---|---|---|---|
| C1 push per static | 1,600/mo | **2,400/mo** | true C1 offtake is 2,277/mo (own 25/day + outreach 38.6/day + diverted 12.3/day) |
| SMC channel | 5,000/mo | **7,500/mo** | covers 3 × 2,400 with headroom |
| C2 warehouse | 5,600/14d | **4,700/14d** | C2 demand *fell* when satellites stopped carrying retail stock; 336/day supply vs 303/day demand = 11% headroom, so shocks ration |
| Safety stock | 200/400/150 | **550/720/330** | preserves the spec's implied **7-day cover** at corrected demand (now 7.2 / 7.1 / 7.1 days) |
| Storage capacity | 1,200/2,500/800 | **3,200/4,500/2,000** | ~30% above the MSH formula's maximum stock level, so the cap is a real but rarely-binding limit instead of silently overriding the paper's order rule |
| Opening stock | 800/1,500/500 | **2,400/3,000/1,400** | near formula target, so a 90-day run isn't dominated by a startup transient |

Verified after re-scaling: public availability **44–45%** (target ~43%); the
MSH formula governs ordering in all three classes rather than hitting the
storage cap; the C2 warehouse and the P2 public channel both ration during
shock periods, as intended; C1 push covers demand in a normal month and goes
just tight in a shock month.

### ⚠️ An honest finding: the capital lock cannot fire
At the paper's capitalization the revolving fund holds **~940 days of drug
purchasing** per clinic. The lock threshold is ~10,600 BDT against 1.8M in the
fund, so `rdf-capital-locked?` and the donor-bailout path are effectively
unreachable, and the new verified-revenue mechanic — although it correctly
freezes takings during outages — never actually blocks an order.

This is not a bug, and I am not going to hide it by shrinking the capital to
make the mechanism look important. It is what the paper's own figures imply:
SHN's RDF is well capitalized and growing 13.3% a year, and the strain the
paper describes falls on the *general* fund, not the RDF.

**Two legitimate ways to use this.** Report it as a finding — at SHN's actual
capitalization, information latency harms *availability* but not *solvency*.
And run the sensitivity experiment it suggests: vary starting RDF capital
downward and find the point at which latency begins causing financially-driven
stockouts. That answers "how much working capital does a network need before
information delay stops threatening it?", which is a genuinely interesting
question a smaller NGO would care about, and it turns an inert mechanism into
a result. Say the word and I'll add the capital sweep to BehaviorSpace.


---

## Part 7 — D3 and D4 resolved

### D4 — First-come-first-served rationing (implemented)

Proportional rationing is gone. When a supply channel cannot cover total need,
facilities are now served **in turn, each taking its full requirement until the
channel is empty**; whoever arrives after that gets nothing. Applied in three
places:

- **Public monthly push** — clinics served in randomised order per cycle
- **SMC C1 push to NGO statics** — same
- **C2 warehouse requisitions** — resolved **oldest order first**, which is the
  literal FCFS reading: an earlier requisition draws before a later one, and a
  late order can be lost entirely rather than merely shortened

This follows §2.2.4: *"the earliest clinics to demand supplies could take on
more inventory than their allotment would regularly allow for… leaving other
similar clinics underserved."*

**Order is randomised each cycle** rather than fixed. Nothing in the sources
says which clinics are consistently faster, and inventing a persistent "speed"
attribute would be an assumption with no basis. Worth one line in Limitations:
if faster clinics are systematically the same ones — better connected, closer
to the store — then real inequality would be *persistent* rather than
transient, and worse than modelled.

**New metric: `public-stockout-inequality`.** Standard deviation of per-clinic
stockout-days as a percentage of the mean. This is what makes the change
worth having — proportional rationing made every clinic short by the same
fraction, so shortage was invisible as a *distributional* phenomenon. Under
FCFS the same total shortfall lands unevenly. It supports a claim your paper
gestures at but could not previously demonstrate: **information latency does
not merely cause shortages, it determines who bears them.** Expect this metric
to rise with `info-latency-severity` and during shocks.

### D3 — Cross-type independent placement (implemented, as you specified)

Your clarification was the important part: the χ² result establishes that NGO
and public placement are independent **of each other**, and says nothing about
NGO-vs-NGO or public-vs-public clustering. The implementation matches that
exactly:

- Each sector gets **its own pair of population cluster centres**, drawn
  independently at setup
- Within-sector clustering is retained at the same 55% rate — a stylization,
  since you have no data either way, and unchanged from before
- Cross-sector correlation is now **zero by construction**, not by tuning

Cluster centres are also **redrawn every run** rather than fixed at two
hard-coded patches, so results are not an artefact of one arbitrary map, and
geographic variation enters the replication variance where it belongs.

You can now cite the χ² test alongside the model description without a reviewer
finding a contradiction between them.
