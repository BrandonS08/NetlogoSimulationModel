# Deliverable (e): Sanity checks you can run yourself (Sargent-style)

These follow the Sargent verification-and-validation framework: each check
pushes the model to a condition where the correct behavior is *known in
advance*, so you can confirm the implementation matches the design without
reading code.

> **Revision note (v2).** Checks 1 and 2 were corrected after the first test
> round. Check 1 specified the wrong control condition, and check 2 used a
> metric that cannot test the claim it was aimed at. Both errors were in the
> *instructions*, not in the model. Details in `06-CHANGELOG.md` Part 5.

Before starting: complete `02-INTERFACE-SETUP.md`, including the monitors
added in Phase D.2.

> **Run length.** The model runs for **3,650 days (ten years)** and stops on
> its own. For most checks below you do not need to wait for the end — the
> answer is visible within the first few hundred days, and you can click **go**
> again to stop early. Where a check needs the full run, it says so.

---

## Check 1 — Perfect-information degenerate test (extreme-condition test)

**Claim being tested:** the entire true-vs-ledger gap is produced by the
latency machinery and by nothing else.

**The control condition requires THREE settings, not two:**

1. `info-latency-severity` = **0**
2. `grid-failure-rate` = **0**
3. `demand-shocks?` = **Off**  ← this one is essential

*Why shocks must be off:* an active shock adds `shock-grid-risk-add` (0.25) to
the grid-failure rate, by design — a flood knocks out power regardless of the
baseline rate. So with shocks On, clinics still lose connectivity even at
`grid-failure-rate` = 0, still fall back to paper, and the ledger still
freezes during those episodes. That is correct model behavior; the original
version of this check simply did not describe a clean control condition.

**Steps:** set the three controls, click **setup**, then **go**. Watch for a few
hundred days — that is plenty for this check — then stop.

**Expected:**
- "C2 ledger gap" = **0.0** for the whole run
- "ledger age (days)" = **0.0** for the whole run
- "% time on paper" = **0.0**
- the two pens in Plot 1 lie exactly on top of each other
- stockouts still occur (public availability still ~43%) — scarcity comes from
  push rigidity, not information failure

**Then the opposite extreme:** `info-latency-severity` = **3**,
`grid-failure-rate` = **0.4**, `demand-shocks?` = **On**. setup, run ~500 days.
Expect a ledger gap in the hundreds of units, ledger age well above 9 days,
"% time on paper" above 60%, and clearly worse unmet demand.

*If the first condition shows any nonzero gap or paper time, report it — that
would be a real leak. If the second shows no difference, the sliders are not
wired in.*

---

## Check 2 — Predictive modeling fixes timing, NOT data accuracy

**Claim being tested:** the predictive toggle improves reorder timing while
leaving the information system's accuracy untouched.

**Read this before running — it explains why the obvious metric is the wrong
one.** "C2 ledger gap" measures `|ledger − true stock|` in units. The ledger is
a stale snapshot, so that gap is roughly *how much stock moved during the
staleness window*. Anything that makes the stock trajectory **smoother** makes
that number smaller without touching the information system at all — and
smoother stock is exactly what better reorder timing produces. So the gap
falling when you enable predictive modeling is a **real and interpretable
result** (latency costs less when inventory is better managed), but it is
**not** evidence that prediction repaired the data. It cannot test that claim.

The metric that *can* test it is **"ledger age (days)"** — how many days out of
date the ledger is. That depends only on connectivity and
`info-latency-severity`. Order timing cannot change it, so it must come out
statistically identical across the two arms.

**Steps:**
1. `info-latency-severity` = 2, `grid-failure-rate` = 0.25, `demand-shocks?`
   On, `predictive-modeling?` **Off**.
2. setup → go → let it run to completion (day 3,650). Record: **static zero episodes**,
   **unmet @ NGO**, **ledger age (days)**, **% time on paper**.
3. Flip `predictive-modeling?` **On**. setup → go → run to completion. Record
   the same four.
4. **Repeat both arms at least 3 times** and compare averages, not single runs.
   A ten-year run averages over ~20 shock events, so it is far less noisy than a
   short one, but treat differences under ~10% in a single pair as meaningless.
   (For a properly powered answer, the BehaviorSpace experiment does exactly
   this comparison at 20 replications per cell.)

**Expected:**

| Metric | Expected direction | Why |
|---|---|---|
| **ledger age (days)** | **Unchanged** (within ~0.2 days) | The claim under test: prediction cannot repair data currency |
| **% time on paper** | **Unchanged** | Connectivity is independent of ordering |
| **static zero episodes** | **Lower** with predictive On | Earlier reordering at the only agents that carry the information layer |
| unmet @ NGO | Lower, but modestly | Diluted — see note below |
| C2 ledger gap | Lower — and that is fine | Confounded by stock volatility, as explained above |

**Use "static zero episodes", not the headline "zero episodes" total.** The
total covers 57 commodity lines, of which 48 belong to public clinics running a
rigid 30-day push with no information mechanics whatsoever. Those cannot respond
to the predictive toggle at all, so they contribute a large constant that buries
the effect; only the 9 static lines carry the signal. The same dilution applies
to "unmet @ NGO", which is why "...of which own" exists as a separate monitor.
(Satellites are excluded from stockout tracking entirely — they hold nothing
between rollouts, so an empty team is normal operation, not a stockout.)

*If **ledger age** drops when predictive turns On, that is a genuine violation
of the design — report it. If **static zero episodes** shows no improvement
across three paired runs, the predictive arm is inert.*

---

## Check 3 — Shock switch and outage extremes

1. `demand-shocks?` **Off**, defaults otherwise (grid 0.1, severity 1,
   predictive Off). setup → run to completion. Expect "shock active?" *false*
   for the entire run, and smooth growth in cold-chain referrals and waste.
2. `demand-shocks?` **On**, `grid-failure-rate` **0.5**. setup → run to completion.
   Expect "% time on paper" climbing toward 75–95%, "req fill rate" clearly
   below the step-1 run, "donor bailouts" often nonzero, and Plot 1 showing
   long flat shelves in the "recorded" pen (frozen ledger) while the "true"
   pen keeps falling.

---

## Check 4 — Calibration benchmark replication (validation)

1. All defaults (grid 0.1, severity 1, predictive Off, shocks On).
2. setup → run to completion (day 3,650).
3. Expect "pub avail % (avg)" in the **40–50%** band (benchmark: WHO 2015
   figure of 43%) and "pub f-stockout %" in roughly **50–65%**.

**Expect these to be tight** — see check 5 for why. Over 3,650 days the average
is taken across ~175,000 commodity-line-days, so it converges hard on the same
value every run. That stability is correct behaviour, not a bug.

*If availability sits far outside the band, adjust the `cc-push-target` list in
`setup-parameters` — one line, tagged [CALIBRATED]. Each entry ≈ class daily
demand × days of coverage; 13 days per 30-day cycle gives 13/30 = 43.3%.*

---

## Check 5 — Confirming stochastic variability is real

Worth running because the calibration monitors look suspiciously stable, and
you should be able to explain why to a reviewer.

**Why the stable ones are stable.** `pub avail %` is a running average over
12 clinics × 4 commodity lines × 3,650 days ≈ **175,000 line-days**. By the law
of large numbers its standard error is a fraction of a percentage point, so it
converges to the same value every run. On top of that, the mechanism driving
it is nearly deterministic: push to target every 30 days, deplete at a
near-constant rate, cross zero around day 13. Randomness averages out almost
completely. A cumulative average over tens of thousands of events landing on
the same number each run is exactly what a correctly working stochastic model
does — the same reason a fair coin flipped 48,000 times always lands near 50%.

**How to confirm the randomness is genuinely there.** Run the model 3 times
with identical settings (defaults, full 3,650-day run) and compare these
*low-aggregation* monitors, which should visibly differ each run:

| Monitor | Expect across runs |
|---|---|
| **shock days** (`total-shock-days`) | Wide swings. Shocks arrive at ~2/year with 7–21 day durations, so a ten-year run lands anywhere from roughly 150 to 400 shock-days. |
| **donor bailouts** | Often differs, sometimes 0 vs several |
| **static zero episodes** | Should differ by several percent |
| **mean RDF capital** | Should differ noticeably |

If those three vary run to run while `pub avail %` stays pinned near 43%, the
random number generator is working correctly and the stability is a property
of the *metric*, not of the model.

**One thing that would break it:** do **not** add `random-seed` to `setup`.
That would make every run identical. The model does not do this, and
BehaviorSpace assigns independent seeds automatically.

**For your write-up:** report the calibration figures as point values (they are
stable by construction), and report the four *outcome* metrics as means with
standard deviations across BehaviorSpace replications, since those are the
ones with meaningful run-to-run variance.

---

## Check 6 — The two independent validation benchmarks (added with the Bekele source)

Unlike check 4, **nothing in the model was tuned to hit these**. They are
predictions, which makes them real validation rather than a consistency check.

1. Defaults (grid 0.1, severity 1, predictive Off, shocks On). setup → run to
   completion.
2. Read two monitors:

| Monitor | Expected | Benchmark |
|---|---|---|
| `NGO stockout %` | roughly **5–15%** | Bekele et al. 2025: average daily stock-out of 8.33% in functioning facilities using bin-card management |
| `waste % of value` | roughly **0.5–3%** | USAID/DELIVER standard: unusable items should be <2% of total item value |

**How to read the result honestly.** Landing inside both ranges is meaningful
external validation and should be reported. Landing outside is *not
necessarily* a failure — Bekele's facilities are Ethiopian public hospitals and
health centres, not Bangladeshi NGO clinics, so a systematic difference is
plausible and can be discussed. What matters is that you report the achieved
value either way, and do not quietly retune the model to hit a number it was
never fitted to.

If `NGO stockout %` comes out near zero, that is worth investigating — it would
suggest the statics are over-supplied and the latency mechanism has nothing to
bite on.
