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
availability is still 44–45%. **Verify it.** Defaults, run to day 90, read
`public-availability-pct`. Expect 40–50%. Outside that, tell me.

### 0.3 Sanity-check three numbers against intuition
After a default 90-day run, look at these and ask whether they are believable
for a clinic network of this size:
- `mean-rdf-capital` — should be *higher* than it started (1,798,000), growing
  ~900 BDT/day/clinic
- `waste-value-total` — should be tens of thousands of BDT, not millions or zero
- `requisition-fill-rate` — should be high but not exactly 1.00 during shocks

A number that is zero, negative, or absurdly large is a bug signature. You do
not need to know the right answer to spot a wrong one.

### 0.4 Run the pilot, then the full experiment
Only after 0.1–0.3 pass.

---

## Tier 1 — Numbers I guessed that materially affect your results

These are ranked. **#1 and #2 are the ones a sharp reviewer will press on.**

### 1. Manual-record error rate — 8% per offline day ⚠️ weakest number in the model
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
`info-latency-severity` sweeps this parameter across a 4× range in the
experiment — which means your results already show whether conclusions depend
on the value. That is a genuinely good answer.

### 2. Satellite pack size and site consumption ⚠️ now the largest flow in the model
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

### 3. The 43% availability citation ⚠️ not a modelling problem, a sourcing one
You've confirmed the figure is accurate, but I have never seen its source. Two
requirements for the write-up:
- **Supply the citation.** You cannot publish a calibration target without one.
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

## Tier 2 — Two design decisions still unanswered

Both were raised in `09-PAPER-ALIGNMENT.md` Part 3 and never resolved.

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
| "Why does the shock always happen?" | Deliberate. At ~2 events/year a 90-day window would contain a shock only 39% of the time, making the shock arm indistinguishable from the control. Shock *presence* is controlled; shock *timing* is randomised. Standard design for a rare event in a short observation window. |
| "Why is the reorder formula fed bad data?" | That is the research design, not an error. The MSH maximum-stock formula (Box 46-1) is implemented exactly as your paper specifies; the latency corrupts one named input to it — Stock On Hand. |
| "Why can't predictive modelling fix the data?" | By construction. Forecasting changes reorder *timing*; it cannot repair a stale ledger. `mean-ledger-age-days` is statistically identical across both arms — that's the evidence. |
| "Are commodity classes aggregated?" | Yes, deliberately. The named commodities and their sourcing citations are documented in `03-MODEL-DOCUMENTATION.md` §11 as justification for class-level parameters. |

---

## What "done" looks like

You are ready to run the final experiment when:

- [ ] All five verification checks pass, numbers recorded
- [ ] Public availability lands in 40–50% on a default 90-day run
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
