# Gap 5: BehaviorSpace — running many replications and getting variance

A single run of a stochastic model proves nothing; reviewers will ask for
replications and dispersion. This sets that up.

## What the experiment does

It runs every combination of four factors, 10 times each with different random
seeds, and writes one row per run to a spreadsheet file.

| Factor | Values | Why |
|---|---|---|
| `environmental-latency-severity` | 0, 1, 2, 3 | Technical latency: dispensation lag, sync lag, manual-record error. 0 is the perfect-information control. |
| `bureaucratic-latency-severity` | 0, 1, 2, 3 | Administrative latency: the central approval delay. 0 is instant approval. |
| `predictive-modeling?` | true, false | The mitigation arm — the second half of your research question. |
| `demand-shocks?` | true, false | With and without environmental shocks. |

4 × 4 × 2 × 2 = 64 conditions × 10 replications = **640 runs** of 3,650 days
(10 years).

**Why this design, and what changed.** The earlier version varied
`grid-failure-rate` (0.05 / 0.25) and used 20 replications. It has been
replaced by one that varies `bureaucratic-latency-severity` instead, at 10
replications — **the same 640 runs and the same runtime**. Two reasons:

1. Without the bureaucratic dial in the design, the environmental/bureaucratic
   split cannot be analysed at all, and answering *which lever matters more*
   is the reason that dial exists.
2. Ten replications is defensible at a ten-year horizon: each run already
   averages over ~20 shock events, so between-run variance is far smaller than
   it was on short runs. Report the standard deviations and the reader can see
   the precision you achieved.

`grid-failure-rate` is held at its default of **0.1** for every run. It is not
dropped from the study — run it as a separate one-factor sensitivity sweep
(`["grid-failure-rate" 0.05 0.1 0.25 0.4]`, everything else at default, 10
reps = 40 runs, a few minutes) and report it alongside. Two clean experiments
read better than one bloated one.

*If you would rather keep the original design, put `grid-failure-rate` back and
drop `bureaucratic-latency-severity` — but then say in your write-up that the
bureaucratic dial was held constant, because a reviewer will ask why a
parameter you introduced was never varied.*

## Creating it (click by click)

1. In NetLogo, go to **Tools → BehaviorSpace**, then click **New**.
2. Fill in **Experiment name**: `latency-experiment`
3. In the big **Vary variables as follows** box, delete what's there and paste
   exactly this:

```
["environmental-latency-severity" 0 1 2 3]
["bureaucratic-latency-severity" 0 1 2 3]
["predictive-modeling?" true false]
["demand-shocks?" true false]
["grid-failure-rate" 0.1]
```

> ### ⚠️ Every research parameter must be listed here, even the constant ones
>
> The fifth line pins `grid-failure-rate` at its default. A one-element list
> holds a value constant and **adds no runs** — still 64 conditions.
>
> It has to be there. `setup-experiment` preserves what BehaviorSpace assigns,
> but it cannot supply a default for something BehaviorSpace never assigned: an
> unassigned global reads as `0`, and `0` is a legitimate value for all five
> parameters, so "set to zero" and "never set" are indistinguishable.
>
> **A parameter omitted from this box silently runs at zero.** That happened:
> `grid-failure-rate` was left out, ran at 0 instead of 0.1, and connectivity
> never failed outside demand shocks — disabling the information-degradation
> mechanism across all 32 shocks-off conditions. Every `pct-time-on-paper`
> value came back as exactly 0.0. Nothing errored; the results were simply
> meaningless.
>
> **Detection:** in any run with `demand-shocks? = false`, `pct-time-on-paper`
> should be well above zero. If it is exactly 0.0 across every such row,
> `grid-failure-rate` is missing from the Vary box.

4. **Repetitions**: `10`
5. Leave **Sequential run order** checked.
6. In **Measure runs using these reporters**, paste exactly this (one per line):

```
ngo-unmet-patients
ngo-unmet-walkin
ngo-unmet-diverted
waste-value-total
lines-ever-zero
zero-episode-total
zero-episodes-per-line
static-zero-episodes
public-zero-episodes
completely-unserved-patients
coldchain-unserved
private-rescues
reqs-fulfilled-count
reqs-partial-count
reqs-lost-count
requisition-fill-rate
public-availability-pct
public-facility-stockout-pct
public-stockout-inequality
ngo-static-stockout-pct
waste-pct-of-value
pct-time-on-paper
mean-ledger-age-days
mean-ledger-gap-c2
mean-rdf-capital
mean-unverified-revenue
mean-frozen-capital-ratio
phantom-lockout-line-days
pct-stockouts-phantom-caused
effective-bureaucratic-lag
donor-bailouts-total
total-shock-days
```

Your four required outcome metrics are `ngo-unmet-patients`,
`waste-value-total`, `lines-ever-zero` (items that hit zero at any point) and
`zero-episode-total` (how often items hit zero across the run).

**Analyse the decomposed columns, not only the totals.** `ngo-unmet-walkin` and
`static-zero-episodes` isolate the facilities that actually carry the
information layer; the totals also contain public-clinic and satellite
components that are structurally incapable of responding to either treatment
and will flatten your effect sizes. `mean-ledger-age-days` is the
trajectory-independent measure of information quality — see
`03-MODEL-DOCUMENTATION.md` §10 for why it and `mean-ledger-gap-c2` support
different claims.

7. **Uncheck** "Measure runs at every step". You want one row per run, not
   3,650 rows per run — leaving this checked produces a multi-million-row file.
8. **Setup commands**: **`setup-experiment`**   **Go commands**: `go`

   > ⚠️ It must be `setup-experiment`, not `setup`. The five research
   > parameters are ordinary globals, and `clear-all` inside plain `setup`
   > would wipe whatever BehaviorSpace assigned before restoring the
   > defaults — every run would come out identical and you would not be
   > told. `setup-experiment` preserves them across `clear-all`.
9. **Stop condition**: leave empty.
10. **Time limit**: `3650`
11. Click **OK**, then **Run**.
12. In the run dialog choose **Table output**, pick a filename
    (e.g. `latency-results.csv`), set **Simultaneous runs in parallel** to the
    number of processor cores you have (leave the default if unsure), and
    click **OK**.

## Runtime expectations

640 runs × 3,650 days. Expect roughly **1–3.5 hours** on a typical laptop with
parallel runs set to 4. Start it and leave it overnight if need be.

**A legitimate way to halve it:** at a ten-year horizon each run already
contains ~20 shock events, so between-run variance is much lower than it was on
short runs and 20 replications is more than you need. **10 repetitions is
defensible** — report whatever you used, and report the standard deviations so
the reader can see the precision you actually achieved.

## Reading the output

The CSV has six header lines before the data; delete them (or skip them on
import) so the column-name row is first. Each row is one run: the factor
columns tell you the condition, the metric columns the results.

For each condition, compute the **mean and standard deviation** of each
outcome across the 10 replications. The three comparisons your paper needs:

1. **Latency dose-response** — outcomes vs `environmental-latency-severity`, holding
   `predictive-modeling?` false. Expect unmet demand, waste and zero-episodes
   to rise monotonically with severity.
2. **Mitigation effect** — predictive true vs false at each severity level.
   Expect `static-zero-episodes`, `ngo-unmet-walkin` and
   `pct-stockouts-phantom-caused` to fall, while `mean-ledger-age-days` and
   `pct-time-on-paper` stay **statistically identical** — that pair of results
   is the finding worth emphasizing: prediction changes how the clinic *reads*
   its data without making the data any better. (`mean-ledger-gap-c2` will also
   fall; that is a genuine secondary result about staleness becoming *less
   costly*, not evidence of better data. Do not present it as the latter.)

   Two checks that keep this claim honest. At
   `environmental-latency-severity = 0` the predictive and naive arms should be
   **indistinguishable on every metric** — there is no staleness window to
   correct, so the mitigation is a no-op and any difference there is noise or a
   bug. And watch `waste-value-total` as severity rises: forecast-driven
   ordering can overshoot, so if waste climbs in the predictive arm, report it.
   A mitigation with a cost is a more credible finding than a free win.

2b. **How much of the damage was concealment** — `pct-stockouts-phantom-caused`
   deserves its own line in the results. It is the share of NGO static
   zero-stock line-days that occurred while the ledger read *above* the reorder
   trigger: stockouts the information system was actively prolonging, not
   merely reporting late. It should rise with `environmental-latency-severity`
   (more unrecorded dispensing) and fall with `predictive-modeling?` (the
   trigger discounts the ledger before comparing). This is the cleanest single
   number for the argument that the failure is informational rather than
   logistical — nothing about supply or money changed, only what the system
   believed.
3. **Which lever matters more** — the comparison this design exists for. Hold
   everything else fixed and compare the effect of moving
   `environmental-latency-severity` from 0→3 against moving
   `bureaucratic-latency-severity` from 0→3, on `ngo-unmet-walkin` and
   `static-zero-episodes`. Whichever produces the larger swing is the lever
   your policy discussion should lead with. Also check the interaction: if
   fixing one only helps when the other is already low, that is a finding in
   itself — it would mean piecemeal reform does not work.
4. **Interaction with prediction** — whether the predictive benefit shrinks as severity rises
   (does forecasting still help when the underlying data is badly degraded?).
   This is the most interesting result the design can produce, and it directly
   answers "to what extent can predictive demand modeling mitigate these
   effects under conditions of information delay."

Report means with standard deviations or 95% confidence intervals
(`mean ± 1.96 × SD / √10`), never single-run numbers.

## Note on the seed

BehaviorSpace assigns each run a different random seed automatically, so the
10 repetitions are genuinely independent. Do not add a `random-seed` call to
`setup` — that would make every replication identical and silently destroy the
variance estimate.
