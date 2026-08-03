# Parameter cross-check: verifying the model against your research paper

**Why this document exists.** The model was built without access to your
background research paper or your specification document — they were not in
the repository. Every parameter below came either from the summary in your
handoff message, from published sources found independently, or from a stated
assumption. **Nobody has yet checked these against the document they are
supposed to trace back to.** That check is the last substantive task before
your results are defensible, and only you can do it.

**How to use this.** Open your research paper alongside this list and work
down Tier 1. For each row, either confirm the value matches your paper, or
tell me the correct value and I'll change it. Tier 1 is 12 rows and should
take under an hour. Tiers 2 and 3 matter less and can wait.

**Where these live in the code.** All of them sit in one block near the top of
`model/CodeTab.txt`, in a procedure called `setup-parameters`, each tagged
with where it came from. You never need to hunt for them.

---

## Tier 1 — Verify these. They drive the results.

If any of these is wrong, your findings change. These are also the numbers a
reviewer is most likely to ask about.

| # | Parameter | Current value | Where it came from | What to confirm in your paper |
|---|---|---|---|---|
| 1 | NGO static daily demand, C1/C2/C3 | 25 / 55 / 22 units per day | Your handoff summary | Are these daily figures, and are they per static clinic? The variable was named "monthly" in the original code but used as daily — worth confirming which your paper intends. |
| 2 | Public CC patient volume | Normal(38, 5) per clinic-day | WHO/CBHC evaluation 2019 (~40/day by 2016) | Does your paper cite a different figure? Some sources report ~70/day. |
| 3 | Public class split P1/P2/P3/P4 | 15% / 55% / 10% / 20% | Your handoff summary | Confirm against your paper's patient-volume section. |
| 4 | C2 unit cost / retail price | 15 / 22 BDT | Your handoff summary | Confirm the RDF margin. This drives whether the fund is sustainable. |
| 5 | RDF starting capital | 241,000 BDT | Your handoff summary | Confirm, and confirm it's per static clinic rather than network-wide. |
| 6 | Three-stage lag structure | dispensation 1 day, sync 2 days, central processing 2 days | Your handoff summary | **Highest priority.** This is your paper's core framework. Confirm all three. |
| 7 | Paper-fallback stickiness | 3 days after reconnection | Your handoff summary | Confirm — this is the behavioral mechanism your paper argues for. |
| 8 | Reporting error rate on paper | 8% of dispensed volume per offline day, biased toward overstating stock | **Assumption — no source** | Does your paper cite any figure for manual-record error? If so this should change. |
| 9 | Shock parameters | ~2 events/year, 7–21 days, demand ×1.8, grid risk +0.25 | Your handoff summary | Confirm against your monsoon/flood section. |
| 10 | Safety stock / max capacity, C1/C2/C3 | 200/400/150 and 1200/2500/800 | Your handoff summary | Confirm. These set when and how much clinics reorder. |
| 11 | Spoilage & shrinkage | C1 5%/mo, C2 5% + 3% shrinkage, C3 2.5%/mo | C1/C2 from handoff; **C3 is an assumption** | Confirm C1/C2; supply C3 if your paper has it. |
| 12 | Daily clinic operating cost | 800 BDT/day | **My addition — flagged** | Your paper may have cost-recovery figures (Smiling Sun recovered ~17% of costs). If it does, this should be derived from them rather than assumed. If you'd rather drop the mechanism entirely, set it to 0. |

---

## Tier 2 — Check if convenient. Moderate influence.

| Parameter | Current value | Source |
|---|---|---|
| Network sizes | 12 public CCs, 3 statics, 3 satellites each, 15 private shops | Handoff summary |
| Public push interval / channel quotas | every 30 days; 950/3400/650/1300 per month | Calibrated to hit 43% availability |
| Public push targets | 75 / 270 / 50 / 100 | **Calibrated by me**, not from your paper — see note below |
| EDCL C2 channel | 5,600 units every 14 days | Calibrated to roughly match modelled offtake |
| C1 push to NGO statics | 1,600 units/month per static | Calibrated against C1 outflow |
| Satellite demand | C1 ~5/day, C2 ~10/day, C3 ~2/day | Handoff summary; C3 is an assumption |
| Satellite restock targets | 40 / 80 / 30 weekly | Handoff summary; C3 is an assumption |
| Cold-chain storage loss | 1%/month, ×4 under grid stress | **Assumption** — published figures are total wastage (25–46%), which is dominated by open-vial losses the model doesn't simulate |
| Higher-care referral rate | 2% of patients | Handoff summary |
| C3 local wholesale cost / user fee | 10 / 15 BDT | **Assumption** |

**About the public push targets:** these were deliberately set so that
simulated availability reproduces the ~43% benchmark from the WHO 2015
Bangladesh situational analysis. That is a legitimate and standard calibration
method — you tune an unobserved input so the model reproduces an observed
output — but you must describe it that way in your methodology, not present
the targets as if they were measured quantities. Suggested wording: *"Push
quotas were calibrated such that simulated essential-medicine availability at
public facilities reproduces the 43% benchmark reported in [source]."*

---

## Tier 3 — Low stakes. Only affects presentation.

| Parameter | Current value | Note |
|---|---|---|
| C1 accounting value | 5 BDT/unit | Only used to price waste; rescales one output linearly |
| P3 dose value | 100 BDT | Same |
| Donor recapitalization | 50,000 BDT after 30 locked days | Assumption; makes decapitalization countable |
| Minimum order batch | 7 days of demand | Assumption |
| Forecast window / noise | 14-day trailing mean, ±5% | Assumption |
| Local procurement lead time | 2 days | Assumption |
| Run length | 3,650 days (BehaviorSpace uses 1,095) | Your choice |

---

## Where extra data would most strengthen the work

If you want to go hunting, these five are worth the effort, in order. The rest
are not worth your time.

1. **Manual-record error rates in paper-based health inventory systems**
   (parameter 8). This is the single least-supported number in the model and
   it sits directly on your causal mechanism. Search terms: *"data quality
   audit" DHIS2 Bangladesh*, *"paper-based" "stock card" accuracy
   discrepancy LMIC*, *WHO Data Quality Review inventory*. Even a rough
   published range would let you replace an assumption with a citation.
2. **Digitization / reporting lag in Bangladesh's health information system**
   (parameter 6). If DHIS2 reporting-completeness or timeliness statistics for
   Bangladesh exist, they would ground the sync-lag stage.
3. **NGO clinic cost recovery** (parameter 12). Smiling Sun/NHSDP evaluations
   report cost-recovery percentages; deriving the operating cost from a
   published recovery rate would convert my flagged assumption into a sourced
   parameter.
4. **Procurement lead times at CMSD/EDCL.** Any published figure for
   requisition-to-delivery time would ground the central processing lag.
5. **Facility-level stockout duration**, not just prevalence. You have the 43%
   availability benchmark; a duration statistic would let you validate a
   *second*, independent output of the model, which is much stronger
   validation than matching one number.

**A caution worth stating:** more parameters sourced is better, but a model
with ten honest assumptions clearly labelled is more credible than one with
ten guesses dressed up as citations. You already have the labelling. Don't
feel obliged to source everything — feel obliged to be accurate about what is
and isn't sourced.

---

## Are all four of your outcome metrics measurable? Yes.

| Your stated metric | Model reporter | Status |
|---|---|---|
| Patients unable to receive needed care at NGO facilities | `ngo-unmet-patients`, split into `ngo-unmet-own` / `ngo-unmet-diverted` | ✅ |
| Total value of expired/wasted inventory | `waste-value-total`, plus unit counts | ✅ |
| Number of items hitting zero stock at any point | `lines-ever-zero` (out of 84 facility×commodity lines) | ✅ |
| Frequency each item hits zero across the run | `zero-episode-total`, `zero-episodes-per-line`, plus `static-` / `satellite-` / `public-zero-episodes` | ✅ — see note |

**One possible gap.** "Frequency each item hits zero" is currently reported as
a total and as an average per line, broken down by facility type. It is *not*
broken down by commodity class — you can't currently read off "how often did
C2 specifically hit zero at statics" as a single number in the BehaviorSpace
output. If your analysis needs per-class frequencies, that's a small addition
(three or four extra reporters) and worth doing before the final run. Tell me
and I'll add it.
