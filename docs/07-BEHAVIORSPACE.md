# Gap 5: BehaviorSpace — running many replications and getting variance

A single run of a stochastic model proves nothing; reviewers will ask for
replications and dispersion. This sets that up.

## What the experiment does

It runs every combination of four factors, 20 times each with different random
seeds, and writes one row per run to a spreadsheet file.

| Factor | Values | Why |
|---|---|---|
| `info-latency-severity` | 0, 1, 2, 3 | The latency dose-response — the primary independent variable. 0 is the perfect-information control. |
| `predictive-modeling?` | true, false | The mitigation arm — the second half of your research question. |
| `grid-failure-rate` | 0.05, 0.25 | Low vs high infrastructure disruption, which drives paper fallback. |
| `demand-shocks?` | true, false | With and without environmental shocks. |

4 × 2 × 2 × 2 = 32 conditions × 20 replications = **640 runs** of 1,095 days
(3 years). That is enough for means with confidence intervals in every cell.

## Creating it (click by click)

1. In NetLogo, go to **Tools → BehaviorSpace**, then click **New**.
2. Fill in **Experiment name**: `latency-experiment`
3. In the big **Vary variables as follows** box, delete what's there and paste
   exactly this:

```
["info-latency-severity" 0 1 2 3]
["predictive-modeling?" true false]
["grid-failure-rate" 0.05 0.25]
["demand-shocks?" true false]
```

4. **Repetitions**: `20`
5. Leave **Sequential run order** checked.
6. In **Measure runs using these reporters**, paste exactly this (one per line):

```
ngo-unmet-patients
ngo-unmet-own
ngo-unmet-diverted
waste-value-total
lines-ever-zero
zero-episode-total
zero-episodes-per-line
completely-unserved-patients
coldchain-unserved
private-rescues
reqs-fulfilled-count
reqs-partial-count
reqs-lost-count
requisition-fill-rate
public-availability-pct
public-facility-stockout-pct
pct-time-on-paper
mean-ledger-gap-c2
mean-rdf-capital
donor-bailouts-total
total-shock-days
```

The first four lines are your four required outcome metrics
(`lines-ever-zero` = items that hit zero at any point;
`zero-episode-total` = how often items hit zero across the run).

7. **Uncheck** "Measure runs at every step". You want one row per run, not
   1,095 rows per run — leaving this checked produces a 700,000-row file.
8. **Setup commands**: `setup`   **Go commands**: `go`
9. **Stop condition**: leave empty.
10. **Time limit**: `1095`
11. Click **OK**, then **Run**.
12. In the run dialog choose **Table output**, pick a filename
    (e.g. `latency-results.csv`), set **Simultaneous runs in parallel** to the
    number of processor cores you have (leave the default if unsure), and
    click **OK**.

## Runtime expectations

640 runs × 1,095 days. Expect roughly **20–60 minutes** on a typical laptop
with parallel runs enabled. Start it and leave it. If that's too long, drop
`grid-failure-rate` to a single value (0.25) to halve it, or reduce
repetitions to 10 — but report whatever you used.

## Reading the output

The CSV has six header lines before the data; delete them (or skip them on
import) so the column-name row is first. Each row is one run: the factor
columns tell you the condition, the metric columns the results.

For each condition, compute the **mean and standard deviation** of each
outcome across the 20 replications. The three comparisons your paper needs:

1. **Latency dose-response** — outcomes vs `info-latency-severity`, holding
   `predictive-modeling?` false. Expect unmet demand, waste and zero-episodes
   to rise monotonically with severity.
2. **Mitigation effect** — predictive true vs false at each severity level.
   Expect unmet demand and zero-episodes to fall, and — the finding worth
   emphasizing — `mean-ledger-gap-c2` to stay **unchanged**, demonstrating that
   prediction fixes timing without fixing data accuracy.
3. **Interaction** — whether the predictive benefit shrinks as severity rises
   (does forecasting still help when the underlying data is badly degraded?).
   This is the most interesting result the design can produce, and it directly
   answers "to what extent can predictive demand modeling mitigate these
   effects under conditions of information delay."

Report means with standard deviations or 95% confidence intervals
(`mean ± 1.96 × SD / √20`), never single-run numbers.

## Note on the seed

BehaviorSpace assigns each run a different random seed automatically, so the
20 repetitions are genuinely independent. Do not add a `random-seed` call to
`setup` — that would make every replication identical and silently destroy the
variance estimate.
