# Deliverable (e): Sanity checks you can run yourself (Sargent-style)

These follow the Sargent verification-and-validation framework: each check
pushes the model to a condition where the correct behavior is *known in
advance*, so you can confirm the implementation matches the design without
reading code. Expected values are ranges, because the model is stochastic —
if a result lands far outside the stated range on two consecutive tries,
something is wrong and worth reporting.

Before starting: complete `02-INTERFACE-SETUP.md` through Phase F.

---

## Check 1 — Perfect-information degenerate test (extreme-condition test)

**Claim being tested:** the entire true-vs-ledger gap is produced by the
latency machinery and by nothing else.

1. Set `info-latency-severity` to **0** and `grid-failure-rate` to **0**.
   Leave `predictive-modeling?` Off, `demand-shocks?` On.
2. Click **setup**, then **go**; let it run ~500 days.
3. **Expected:** the "C2 ledger gap" monitor stays at **0.0 the entire run**
   (the two pens in Plot 1 lie exactly on top of each other), and
   "% time on paper" stays at 0. Stockouts still occur (public availability
   still ~40–50%) — scarcity comes from push rigidity, not from information
   failure.
4. Now set `info-latency-severity` to **3** and `grid-failure-rate` to
   **0.4**, press setup, run ~500 days. **Expected:** ledger gap typically in
   the **hundreds of units**, "% time on paper" above **60%**, and visibly
   worse "unmet @ NGO" and "zero episodes" than step 3.

*If step 3 shows any nonzero gap, the latency machinery is leaking — report
it. If step 4 shows no difference from step 3, the sliders are not wired in.*

## Check 2 — Predictive modeling fixes timing, NOT data accuracy (the design's signature)

**Claim being tested:** the predictive toggle improves reorder timing while
leaving the ledger's corruption untouched — the deliberate separation at the
center of your research design.

1. Set `info-latency-severity` **2**, `grid-failure-rate` **0.25**,
   `demand-shocks?` On, `predictive-modeling?` **Off**.
2. setup → go → run to day **1000** (watch the tick counter). Write down:
   "unmet @ NGO", "zero episodes", and "C2 ledger gap".
3. Flip `predictive-modeling?` **On**. setup → go → run to day 1000 again.
   Write down the same three numbers.
4. **Expected:** "unmet @ NGO" and "zero episodes" **clearly lower** with
   predictive On (typically tens of percent, though single runs vary), but
   "C2 ledger gap" **statistically unchanged** — same order of magnitude,
   no systematic improvement.

*If the gap collapses when predictive turns On, the forecast is illegally
repairing the ledger — that would violate the core design and should be
reported. If unmet does not improve at all across several paired tries, the
predictive arm is inert.*

## Check 3 — Shock switch and outage extremes

**Claim being tested:** the shock system and connectivity machinery respond to
their controls and nothing fires when disabled.

1. `demand-shocks?` **Off**, everything else at defaults (grid 0.1,
   severity 1, predictive Off). setup → run ~800 days.
   **Expected:** "shock active?" reads *false* the whole run; cold-chain
   referrals grow slowly and smoothly; waste value grows steadily without
   bursts.
2. `demand-shocks?` **On**, `grid-failure-rate` **0.5**. setup → run ~800 days.
   **Expected:** "% time on paper" climbs toward **75–95%** (with stickiness,
   clinics are nearly always on paper), "req fill rate" drops noticeably below
   the step-1 run, "donor bailouts" is often nonzero, and Plot 1 shows long
   flat shelves in the "recorded" pen (frozen ledger) while the "true" pen
   keeps falling — the visual signature of your core mechanic.

## Check 4 — Calibration benchmark replication (validation against your paper)

1. All defaults (grid 0.1, severity 1, predictive Off, shocks On).
2. setup → run to at least day **1000**.
3. **Expected:** "pub avail % (avg)" settles in the **40–50%** band
   (benchmark: WHO 2015 figure of 43%), and "pub f-stockout %" in roughly
   **50–65%** (benchmark: ~50% daily stockout prevalence). Because four
   aggregated classes cannot reproduce both statistics exactly at once
   (they are defined on different denominators in the source literature),
   landing in these bands — with the saw-tooth push cycle visible in Plot 3 —
   is the honest pass criterion. Record the achieved values in your
   methodology section.

*If availability sits far above 50%, lower the `cc-push-target` list slightly
in `setup-parameters` (it is one line, tagged [CALIBRATED]); if far below
40%, raise it. Each entry ≈ (class daily demand) × (days of coverage);
13 days of coverage per 30-day cycle produced the target band analytically.*
