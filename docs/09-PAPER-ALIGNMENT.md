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

### D2. How much patient volume should satellites carry?
The paper is emphatic that "frontline fulfillment of patient demand occurs
overwhelmingly at satellite clinics and other lower-tier endpoints," and SHN
has ~134 permanent facilities against 9,000–10,000 total clinics. The model
currently puts only ~33% of NGO patient volume through satellites.

One caution on the 90.8% figure (Sajib et al.): read carefully, it compares
*satellite clinics plus field medical officers* against *hospital ships* in
Friendship's three-tier structure — it is not a static-vs-satellite split, so
it does not license setting satellites to 90.8% directly.

My recommendation: raise satellites to roughly **70%** of NGO patient volume,
and document each satellite agent as representing a cluster of rotational
sessions rather than a single site. Tell me a number and I'll set it. This
matters because satellite consumption reaches the hub's books only at weekly
restocking — so the more volume sits at satellites, the longer the information
path, which is your thesis.

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
