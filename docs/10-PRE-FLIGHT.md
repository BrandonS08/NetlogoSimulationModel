# Pre-flight: what to verify before running, and what I guessed

Everything standing between the model as it is now and results you can defend.
Ordered by how much damage each item can do. Work down; stop when the remaining
items are ones you're willing to name as limitations.

---

## The single most important fact

**This model has never been executed.** Not once, by anyone. My environment has
no NetLogo runtime and no network route to obtain one, so every claim I've made
about behaviour is derived from reading the code and doing arithmetic on paper.
The structure is verified: brackets balance, all 70 procedures resolve, every
variable is declared, no name collides with a NetLogo primitive, every flow
balances numerically. **None of that is the same as having watched it run.**

Until you complete Tier 0 below, treat every quantitative statement in these
docs — including my calibration figures — as a prediction, not a result.

---

## Tier 0 — Must do. Not optional. (about 40 minutes)

### 0.1 Run all five verification checks in `05-VERIFICATION-CHECKS.md`
These are designed so you can tell pass from fail without reading code. Write
down the numbers you get. If any check fails, stop and send me the numbers —
a failed check is information, and two of them have already caught real
problems in this build.

### 0.2 Confirm the calibration still holds
Since the last docs were written, satellite mechanics, safety stock, storage
capacity, and shock multipliers all changed. My arithmetic says public
availability is still 44–45%. **Verify it.** Defaults, run to completion, read
`public-availability-pct`. Expect 40–50%. Outside that, tell me.

### 0.3 Sanity-check three numbers against intuition
After a default full-length run, look at these and ask whether they are believable
for a clinic network of this size:
- `mean-rdf-capital` — should be *far higher* than it started (1,798,000);
  over ten years at ~900 BDT/day it roughly doubles
- `waste-value-total` — should be tens of thousands of BDT, not millions or zero
- `requisition-fill-rate` — should be high but not exactly 1.00 during shocks

A number that is zero, negative, or absurdly large is a bug signature. You do
not need to know the right answer to spot a wrong one.

### 0.4 Run the pilot, then the full experiment
Only after 0.1–0.3 pass.

---

## Tier 1 — Numbers I guessed that materially affect your results

These are ranked. **#1 and #2 are the ones a sharp reviewer will press on.**

### 1. ~~Manual-record error rate~~ — RESOLVED, now 0.217 from Bekele et al. 2025
*Superseded — see the Addendum at the end of this document. Original text kept
below for the record.*

#### (original entry)
`reporting-error-rate = 0.08`. Every offline day, 8% of dispensed volume goes
unrecorded, biased so the system believes *more* stock remains than truly does.

**Why it matters most:** it sits directly on your causal mechanism. It is the
quantity that converts "the clinic was offline" into "the clinic ordered the
wrong amount." If a reviewer asks one parameter question, it will be this one.

**What I know:** the direction is well supported — missed entries mean
unrecorded consumption, which overstates stock. Your own paper supports the
*context* (Sultana et al.: 100% manual methods, only 16.4% using bin cards, 96%
using a single verification method). And your paper gives the *digital*
comparator: 200 errors per 250,000 entries after OpenMRS (0.08%).

**What I don't know:** the magnitude. 8% is my number, not anyone's finding.

**What to search for:** *"data quality audit" health facility stock cards
LMIC*, *WHO Data Quality Review inventory accuracy*, *stock card versus physical
count discrepancy Bangladesh*. A study reporting the discrepancy between paper
stock cards and physical counts is exactly what you need. Even a range (say
5–20%) lets you cite it and run the range as a sensitivity.

**If you find nothing:** say so explicitly in Limitations, and note that
`environmental-latency-severity` sweeps this parameter across a 4× range in the
experiment — which means your results already show whether conclusions depend
on the value. That is a genuinely good answer.

### 2. ~~Satellite pack size and site consumption~~ — RESOLVED by author
*35-50 patients per one-day session, supplied directly. See Addendum II.*

#### (original entry)
`satellite-pack-size = (45, 0, 9)` and `satellite-site-demand = (30, 0, 6)`
units per team per rollout.

**Why it matters:** outreach now accounts for **~51% of all C1 throughput**
(38.6 of 75.9 units/day per static). It is the biggest single flow in the NGO
network, and both numbers are mine. You told me the catalogue's quantities were
arbitrary, so I did not use them — which left me with nothing.

**What is grounded:** the *cadence* (≈25 sites per static, each visited 1–2×
monthly, ~9–10 teams/week) comes from your own catalogue. Only the quantities
are invented.

**What you can do:** even a rough real figure helps — how many patients does a
typical satellite session see, and roughly how many commodity units does a team
carry? A Smiling Sun or BRAC outreach report, or any satellite-clinic session
report, would anchor this. If you can give me *patients per session*, I can
derive units from your existing per-patient class fractions rather than guessing.

### 3. The 43% availability citation — resolved on your end, one caution remains
You have the citation. Nothing is blocked. The one thing that still matters:
- **Do not attribute it to Kabir et al.** That source gives a *readiness index*
  of 47 — a composite of four domains against a threshold of 70. It is a
  different measurement, and conflating an index score with an availability
  percentage is precisely the error a methods reviewer looks for.

Also describe the calibration honestly. Suggested wording: *"Public-sector push
quotas were calibrated such that simulated essential-medicine availability
reproduces the ~43% benchmark reported in [source]; the quotas are therefore a
fitted input, not an independently measured quantity."* Calibration is standard
practice — presenting a fitted parameter as a measured one is not.

### 4. Cold-chain storage loss — 1%/month, ×4 under grid stress
`coldchain-monthly-loss-rate`, plus the new `c1-heat-sensitive-share = 0.5`
(this second one *is* grounded — 5 of 10 MNACH commodities in your catalogue
carry a temperature flag).

Published Bangladeshi vaccine wastage runs 25–46%, but that is *total* wastage
dominated by open-vial losses at session level, which the model does not
simulate. So the literature figure cannot be used directly. If you can find a
storage-loss-only or cold-chain-break figure, it would replace a guess.

### 5. Class 3 economics — cost 8.5, user fee 12.5 BDT
Cost comes from your catalogue's median consumables price, so it is anchored.
The **user fee is mine**, set to give the same margin as C2. If NGO diagnostic
fees are documented anywhere in your sources, use the real number.

### 6. Smaller assumptions — name them, don't chase them
Not worth research time; just make sure they appear in Limitations:
`patient-sd = 5`, `local-procurement-lag = 2 days`, `min-batch-days = 7`,
`forecast-window-days = 14`, `c3-monthly-spoilage-rate = 2.5%/month`,
`donor-recap-amount = 50,000`, `bailout-threshold-days = 30`,
`private-shop-base-stock` with full weekly restock.

---

## Tier 2 — ~~Two design decisions still unanswered~~ RESOLVED

**Both answered and implemented.** D4 is now first-come-first-served with a
new `public-stockout-inequality` metric; D3 gives each sector independently
drawn population clusters, so cross-type correlation is zero by construction.
See `09-PAPER-ALIGNMENT.md` Part 7. Original text below for the record.


### D3. Should facility placement be statistically independent?
Your χ² test (χ² = 2.250, p = 0.134, V = 0.187) establishes that NGO and public
per-capita concentrations are **independent**. The model currently places both
using the same two population clusters at the same 55% rate, which makes them
**correlated** — mildly contradicting your own finding.

This matters if you cite the χ² result anywhere near the model description; a
reviewer who reads both will notice. The fix is small: cluster the public
clinics, place NGO facilities independently. **Say the word.**

### D4. Proportional rationing vs first-come-first-served
When a supply channel is short, the model rations **proportionally** across
clinics. Your §2.2.4 describes something different: informal requisition by
phone/email where *"the earliest clinics to demand supplies could take on more
inventory than their allotment would regularly allow for… leaving other similar
clinics underserved."*

That is FCFS, and it produces **inequality between clinics** that proportional
rationing averages away — arguably an interesting result in itself, since it
means information latency doesn't just cause shortages, it distributes them
unfairly. Easy switch if you want it.

---

## Tier 3 — Things that are fine but you must be able to explain

Not problems. But if a professor asks, you need an answer, so here they are
with the answers.

| They might ask | Your answer |
|---|---|
| "Why does the capital lock never trigger?" | It can't, at the capitalization your paper implies (~940 days of purchasing per clinic). That's a finding, not a bug: at SHN's real capitalization, latency harms availability but not solvency. The mechanism is implemented and measurable via `mean-unverified-revenue`; a capital sweep would find where it starts to bind. |
| "Why 3 clinics and 12 community clinics?" | Stylized subdistrict preserving structural ratios, not a national projection. Results are about mechanisms and differences between arms, not absolute magnitudes. |
| "How are shocks generated?" | Stochastic onset at ~2 events/year, the specification's rate. Over a 3,650-day run that yields ~20 monsoon/flood events, so shock frequency is reproduced rather than imposed. Duration 7–21 days, uniform. |
| "Why is the reorder formula fed bad data?" | That is the research design, not an error. The MSH maximum-stock formula (Box 46-1) is implemented exactly as your paper specifies; the latency corrupts one named input to it — Stock On Hand. |
| "Why can't predictive modelling fix the data?" | By construction. Forecasting changes reorder *timing*; it cannot repair a stale ledger. `mean-ledger-age-days` is statistically identical across both arms — that's the evidence. |
| "Are commodity classes aggregated?" | Yes, deliberately. The named commodities and their sourcing citations are documented in `03-MODEL-DOCUMENTATION.md` §11 as justification for class-level parameters. |

---

## What "done" looks like

You are ready to run the final experiment when:

- [ ] All five verification checks pass, numbers recorded
- [ ] Public availability lands in 40–50% on a default full-length run
- [ ] The three sanity numbers in 0.3 look believable
- [ ] You've supplied the 43% citation, and it is not Kabir et al.
- [ ] Tier 1 #1 and #2 are either sourced, or explicitly named as assumptions
      in your Limitations section
- [ ] D3 and D4 answered (either way — "kept as-is, here's why" is a valid answer)
- [ ] You can answer every question in the Tier 3 table in your own words

That last one is the real test. If you can explain each of those without
reading from a script, you understand the model well enough to defend it —
which is what the letter you're hoping for actually depends on.

---

## A note on what makes this credible

The instinct to want the model "absolutely perfect" before running is a good
one, but perfection is not the standard and never has been. Every simulation
paper contains assumptions. What separates a defensible model from an
indefensible one is whether the author knows exactly which numbers are
assumptions, how much they matter, and what would change if they were wrong.

You are, right now, in an unusually strong position on that axis. You have a
complete audit trail of every defect found and fixed (`06`), a parameter-level
provenance list (`08`), a record of what your source document changed and why
(`09`), and this document. Very little undergraduate work has that. Almost no
high-school work does.

The two things that would genuinely weaken you are: presenting a fitted
parameter as a measured one, and presenting an unrun model's predicted
behaviour as an observed result. Both are entirely avoidable, and both are
avoided by finishing Tier 0 and being precise in your write-up about item 3.

---

# ADDENDUM — Two papers supplied, and what they changed

Two sources were provided after this document was written:

- **Bekele A. et al. (2025).** *Inventory management performance of essential
  medicines in public health facilities of Jimma Zone, Southwest Ethiopia.*
  PLOS Global Public Health 5(4): e0004379.
- **Larsen E. et al. (2019).** *Continuing Patient Care during Electronic
  Health Record Downtime.* Applied Clinical Informatics 10(3): 495–504.

Between them they resolve **Tier 1 item #1** — the weakest number in the model.

## The manual-record error rate is now sourced

Bekele et al. physically counted stock at 20 public health facilities and
compared it against the manual bin-card records. **Mean bin-card accuracy was
78.3%** — a **21.7% discrepancy rate** — with per-item accuracy ranging from
60% (Doxycycline 100mg) to 95% (Tetracycline eye ointment). Report-transfer
accuracy from bin card to resupply form was separately 87.37%.

`reporting-error-rate` changes from **0.08 (my guess) → 0.217 (measured)**.

**The interpretive step, stated plainly:** Bekele reports the share of
*records* that disagree with a physical count; the model needs the share of
*units* mis-posted. Treating one as the other is an assumption, and it is now
documented as such in the code comment and in `04-ASSUMPTIONS-AND-LIMITATIONS`.
It is a far better-founded assumption than a number with no source, but it is
not a measurement of the quantity the model actually uses. Say so in your
methodology.

**Two reasons the new value is conservative:**

1. Bekele's facilities use bin cards as their **routine** system. In this
   model paper is an **emergency fallback**, and Larsen et al. found that
   emergency downtime paper records were *"significantly fragmented"* with
   *"not all documentation completed"* — worse conditions than routine
   bin-card keeping.
2. The **positive bias is now directly evidenced**, not assumed. Bekele found
   *"losses and adjustments"* filled in only **35%** of records — the
   least-completed data component of all (vs. stock-on-hand and consumption at
   100%). Unrecorded depletion is exactly what makes a system believe more
   stock remains than truly does, which is the direction the model implements.

What this means in practice, at the corrected demand scale:

| Severity | 7 days on paper | 14 days on paper |
|---|---|---|
| 1 | C2 ledger overstated by ~153 units (5% of stock) | ~307 (10%) |
| 2 | ~307 (10%) | ~613 (20%) |
| 3 | ~460 (15%) | ~920 (31%) |

C2 safety stock is 720, so at high severity a long outage can push the believed
figure far enough above reality to **suppress a reorder entirely**. That is the
pathology your paper describes, now driven by a measured parameter.

## Two new validation benchmarks (this is the bigger win)

Before these papers the model had **exactly one** external validation target —
the 43% availability figure, which is Bangladesh-public-sector-specific and
whose citation you still owe me. Bekele supplies two more, and crucially they
constrain the **NGO side**, which previously had no external check at all.

| New monitor | Benchmark | Source |
|---|---|---|
| `ngo-static-stockout-pct` | **~8.33%** of commodity-line-days stocked out | Bekele: average daily stock-out across essential medicines in functioning facilities using bin-card management |
| `waste-pct-of-value` | **<2%** of total item value | USAID/DELIVER standard for unusable items, applied by Bekele |

Both are now Interface monitors and BehaviorSpace metrics. **Check 6 in
`05-VERIFICATION-CHECKS.md` covers them.** A model that reproduces three
independent published benchmarks — public availability, NGO stockout rate, and
waste fraction — is in a substantially stronger position than one that
reproduces a single number it was tuned to hit.

Note the honest asymmetry: the 43% figure is a *calibration target* (I tuned
push quotas to hit it). These two are *predictions* — nothing was tuned to
reach them. If the model lands near them anyway, that is genuine validation and
worth saying so explicitly in your write-up.

## Corroboration that changed nothing (but is citable)

- **Larsen et al.** describe a total downtime of ~48 hours followed by ~48
  hours of partial restoration as systems came back incrementally — a
  **staged, multi-day recovery**, which is what the model's outage-plus-sticky-
  recovery structure represents. Your own paper's "end-of-week or even
  end-of-month batch logging" remains the basis for the 7-day value; Larsen
  corroborates that recovery is not instantaneous.
- **Larsen et al.** also found service delays during downtime averaging +62%
  turnaround time, with interviewees reporting the true figure was much larger
  than the paper records showed — i.e. *the downtime records themselves
  understate downtime harm.* Worth one sentence in your discussion: real-world
  measurement of this phenomenon is biased downward by the same information
  failure being studied.
- **Bekele's stock-out causes** map onto the model's failure modes almost
  one-to-one: insufficient supply 55% (channel rationing), stock-out at the
  resupply point 40% (partial/lost requisitions), expiration 35% (spoilage),
  order modification at replenishment 30% (rationed partial fulfilment). The
  model generates all four without being built to.

## What these papers do NOT resolve

- **Satellite pack size and site consumption** (Tier 1 #2) — still my numbers.
  Neither paper covers outreach logistics. Patients-per-session is still the
  single most valuable figure you could bring me.
- **The 43% citation** (Tier 1 #3) — still outstanding, still must not be
  attributed to Kabir et al.
- **Emergency ordering.** Bekele found all facilities placed emergency orders
  in six months, 45% of them more than five. The model has no emergency-order
  path — a clinic that discovers a shortfall waits for the normal cycle. This
  is now a *named gap* rather than an oversight; adding it would be a genuine
  extension, and it would likely *reduce* modelled stockouts.
- **Cold-chain storage loss rate** — neither paper covers it.


---

# ADDENDUM II — Satellite quantities derived, not guessed

You supplied: **a satellite session serves 35–50 patients and lasts one day.**
That closes Tier 1 #2, which was the largest un-evidenced flow in the model.

**How patients became commodity units.** The model already has a convention,
used by the public-clinic routine: one patient draws one unit of the commodity
they came for. Applying it consistently:

| Quantity | Value | Basis |
|---|---|---|
| Patients per session | **35–50, uniform** | Author |
| C1 (ESP/MNACH) units per session | **= patients** | One commodity per patient, model convention |
| C2 units | **0** | Outreach teams are not retail pharmacies |
| C3 units per session | **20% of patients** | [ASSUMPTION] share needing an administration consumable — syringe for an injectable contraceptive or vaccine, or a test strip |
| Pack carried | **55 C1, 11 C3** | Top of the patient range plus ~10% margin; teams cannot restock mid-session |

Only the 20% consumable share remains an assumption, and it is a small one —
it affects C3 throughput by a few units per day. The dominant flow, C1, is now
derived directly from your figure rather than invented.

**One-day sessions** were already modelled correctly: teams draw stock at
departure, dispense for the day, and return the remainder the same tick,
holding nothing in between.

## Re-scaling that followed

Outreach C1 draw rose from ~39 to ~55 units/day per static, so every downstream
buffer moved again:

| Quantity | Was | Now |
|---|---|---|
| C1 push per static | 2,400/mo | **2,900/mo** |
| SMC donor channel | 7,500/mo | **9,000/mo** |
| Safety stock (C1/C2/C3) | 550/720/330 | **650/720/350** |
| Storage capacity | 3,200/4,500/2,000 | **4,400/4,500/2,400** |
| Opening stock | 2,400/3,000/1,400 | **3,400/3,750/1,830** |
| AMC warm start | 76/101/46 | **92/101/49** |
| Shock demand shares | 0.34/0.45/0.21 | **0.38/0.42/0.20** |

Verified after re-scaling:

- Per-static throughput **92.0 / 100.9 / 49.4** units per day (C1/C2/C3)
- All three classes now **open exactly at their MSH maximum stock level**
  (3,410 / 3,748 / 1,832 target vs 3,400 / 3,750 / 1,830 opening) — no startup
  transient in either direction
- Safety stock is **7.1 days of cover in all three classes**, preserving the
  specification's implied intent
- Storage capacity clears the formula target in every class, so the MSH rule
  governs ordering and is never silently overridden
- C1 supply is sustainable long-run: 2,900/month pushed against ~2,826/month
  average demand once the ~7.7% of days under shock conditions are included —
  a ~2.6% margin, tight in a shock month, which is the intended pressure
- Shock multipliers recompute to **1.31 / 1.63 / 3.09** with a demand-weighted
  mean of **1.81**, still matching the specification's 1.8
