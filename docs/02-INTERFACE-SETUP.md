# Deliverable (b): Building the Interface tab, click by click

This document lists **every widget the model needs**, with exact names, ranges
and defaults, and step-by-step click instructions. Follow the phases **in
order** — the code cannot compile until Phase A is done.

**Read Phase A first — it is now empty, and that is the point.** The model
needs no widgets to compile or run. Everything below is optional: buttons make
it clickable, monitors and plots make it watchable. BehaviorSpace needs none of
it.

> **General mechanics, once:** to add any widget in NetLogo, go to the
> **Interface** tab and **right-click on an empty white area**, then choose
> the widget type from the menu (Button, Slider, Switch, Monitor, Plot). A
> dialog opens; fill in the fields exactly as listed below and click **OK**.
> To fix a mistake later, right-click the widget and choose **Edit**. To move
> a widget, right-click it, choose **Select**, then drag it.

---

## Phase A — NOTHING TO DO (this phase is obsolete)

**The code no longer requires any Interface widgets.** It compiles in a
completely empty NetLogo model.

The five research parameters — `grid-failure-rate`,
`environmental-latency-severity`, `bureaucratic-latency-severity`,
`predictive-modeling?` and `demand-shocks?` — used to be sliders and switches
that had to exist, with exactly matching names, before the code would compile.
That coupling caused repeated paste failures: rename a parameter and every line
mentioning it errored until the widget was renamed to match. They are now
ordinary variables inside the code, given their defaults by `setup`.

**If you already built those widgets, delete them** — a widget and a code
variable cannot share a name, and the paste will fail with *"There is already a
global variable called GRID-FAILURE-RATE"*. See `00-START-HERE.md` Step 0a.

You change parameters in one of three ways now, none involving a slider:

| Method | How | Best for |
|---|---|---|
| Scenario buttons | Click `scenario-perfect-info`, etc. | The verification checks — one click sets a whole named condition |
| Command Center | Type `set environmental-latency-severity 3` | Ad-hoc exploration |
| BehaviorSpace | Vary them in the experiment | Data collection |

## Phase B — paste the code

Copy from `model/CodeTab.txt`, paste into the **Code** tab, click **Check**.
It should compile silently with nothing built on the Interface tab.

If you see *"There is already a global variable called ..."*, an old slider or
switch is still present — delete it (Step 0a) and re-check.

---

## Phase C — buttons

### C1. Button: setup
1. Right-click empty space → **Button**.
2. **Commands**: `setup`
3. Leave **Forever** unchecked. Agents dropdown stays **Observer**. Click **OK**.

### C2. Button: go (the main run button)
1. Right-click empty space → **Button**.
2. **Commands**: `go`
3. **Check the "Forever" checkbox** — this makes the button run day after day
   until you click it again to stop.
4. Click **OK**.

### C3. Button: go once (optional but useful for slow-motion checking)
1. Right-click → **Button**. **Commands**: `go`
2. **Display name**: `go once`. Leave Forever **unchecked**. Click **OK**.

### C3b. Buttons: the scenario presets (recommended)

One button per verification condition. Right-click → **Button**, put the
command in **Commands**, leave Forever unchecked.

| Commands | Used by |
|---|---|
| `scenario-baseline` | check 4, calibration |
| `scenario-perfect-info` | check 1, control condition |
| `scenario-worst-case` | check 1, opposite extreme |
| `scenario-predictive-off` | check 2, arm A |
| `scenario-predictive-on` | check 2, arm B |
| `scenario-bureaucracy-only` | environmental fixed, approval slow |
| `scenario-connectivity-only` | approval instant, connectivity bad |

Each performs a full setup and applies its whole condition, so you click one
button and then **go**.

### C4. Button: export log (optional)
1. Right-click → **Button**. **Commands**: `export-requisition-log`
2. **Display name**: `export log`. Leave Forever unchecked. Click **OK**.

*Pressing it after a run writes `requisition-log.csv` (one row per resolved
reorder request: when placed, when resolved, which clinic, which commodity
class, quantity requested, quantity shipped, outcome) into the folder where
your model file is saved.*

---

## Phase D — monitors

Same recipe for each: right-click → **Monitor**, type the **Reporter** exactly
as shown, type the **Display name**, set **Decimal places**, click **OK**.

| # | Reporter (type exactly)          | Display name       | Decimals | What it tells you |
|---|----------------------------------|--------------------|----------|-------------------|
| 1 | `ngo-unmet-patients`             | unmet @ NGO        | 0 | Outcome 1: patients an NGO facility could not serve from stock |
| 2 | `waste-value-total`              | waste value (BDT)  | 0 | Outcome 2: BDT value of all expired/spoiled inventory |
| 3 | `lines-ever-zero`                | lines ever zero    | 0 | Outcome 3: facility×commodity lines that have hit zero at least once (max 57) |
| 4 | `zero-episode-total`             | zero episodes      | 0 | Outcome 4: total distinct zero-stock episodes across all lines |
| 5 | `completely-unserved-patients`   | fully unserved     | 0 | Patients who got nothing anywhere (NGO and private both failed) |
| 6 | `coldchain-unserved`             | cold-chain refer   | 0 | P3 patients referred upward (no NGO/private substitute exists) |
| 7 | `public-availability-pct`        | pub avail % (avg)  | 1 | Calibration benchmark: should hover near ~43% |
| 8 | `public-facility-stockout-pct`   | pub f-stockout %   | 1 | Calibration benchmark: share of facility-days with ≥1 class out, ~50–65% |
| 9 | `mean-ledger-gap-c2`             | C2 ledger gap      | 1 | THE core research variable: units of disagreement between true stock and the ledger |
| 10 | `pct-time-on-paper`             | % time on paper    | 1 | Share of clinic-days spent on manual paper fallback |
| 11 | `requisition-fill-rate`         | req fill rate      | 2 | Share of reorder requests fully fulfilled |
| 12 | `mean-rdf-capital`              | mean RDF capital   | 0 | Average working capital of the three NGO hubs (BDT) |
| 13 | `donor-bailouts-total`          | donor bailouts     | 0 | Times a decapitalized clinic needed donor rescue |
| 14 | `shock-active?`                 | shock active?      | 0 | true while a monsoon/flood shock is running |

Monitors 1–4 are your four BehaviorSpace outcome metrics; 7–8 are the
calibration benchmarks from your paper; 9–10 are the information-latency
diagnostics. 5, 6, 11–14 are supporting diagnostics — add them if you have
screen space, in this priority order.

### Phase D.2 — four monitors added in revision v2 (add these now)

These came out of the first test round: the original monitor set could not
actually demonstrate the model's central claim, and two of them are needed by
the corrected check 2 in `05-VERIFICATION-CHECKS.md`. Add them the same way as
the others. You do **not** need to rebuild anything else — but you do need to
re-paste the Code tab from `01-PASTE-THIS-CODE.md` first, since these
reporters are new.

| Reporter (type exactly)   | Display name        | Decimals | What it tells you |
|---------------------------|---------------------|----------|-------------------|
| `mean-ledger-age-days`    | ledger age (days)   | 2 | **The clean measure of information quality**: how many days out of date the ledger is. Unlike the gap monitor, this cannot be moved by better ordering — which is exactly what makes it the right test of "predictive modeling doesn't fix data accuracy". |
| `static-zero-episodes`    | static zero eps     | 0 | Zero-stock episodes at NGO static hubs only — the **only** facilities with information mechanics, so the only place a latency or predictive effect can appear. |
| `ngo-unmet-walkin`        | ...of which walk-in | 0 | Unmet demand from the NGO network's own walk-in and outreach patients, as opposed to public-clinic spillover. |
| `public-stockout-inequality` | stockout inequality | 1 | Spread of stockout burden across public clinics. Rises under first-come-first-served rationing — shows that latency decides *who* goes short, not just how much. |
| `ngo-static-stockout-pct` | NGO stockout %      | 1 | Validation benchmark: compare against ~8.33% (Bekele et al. 2025). |
| `waste-pct-of-value`      | waste % of value    | 2 | Validation benchmark: compare against the <2% USAID/DELIVER standard. |
| `mean-unverified-revenue` | unverified takings  | 0 | Money taken at the counter that cannot yet be spent because the sale is unsynced. Spikes during outages. |
| `effective-bureaucratic-lag` | effective bureaucratic lag (days) | 2 | Stage-3 approval delay actually in force — `central-processing-lag × bureaucratic-latency-severity`. Reads 2.00 at the default. **Type the reporter name exactly as shown**, not the multiplication expression: `central-processing-lag` is a per-clinic variable and a monitor cannot read it directly. |
| `total-shock-days`        | shock days          | 0 | Cumulative days spent under environmental shock — a high-variance metric, useful for confirming run-to-run randomness (check 5). |

If screen space is tight, `ledger age (days)` and `static zero eps` are the two
that matter; the other two are convenience.

### Phase D.3 — phantom overstock lockout monitors (add these now)

These expose the model's sharpest failure mode: a line that is **physically
empty while the ledger still reads above the reorder trigger**, so the reorder
rule sees a well-stocked clinic and declines to order. The stockout is not
merely unnoticed — the information system is prolonging it. Re-paste the Code
tab first; these reporters are new.

| Reporter (type exactly)   | Display name        | Decimals | What it tells you |
|---------------------------|---------------------|----------|-------------------|
| `phantom-lockout-line-days` | phantom lockout days | 0 | Cumulative NGO static commodity-line-days spent physically empty with an above-trigger ledger. |
| `pct-stockouts-phantom-caused` | % stockouts phantom | 1 | Share of all static zero-stock line-days that were in that state — **the share of stockouts the information system was concealing rather than merely reporting late**. This is the number to quote in the discussion. |
| `mean-frozen-capital-ratio` | frozen capital ratio | 3 | Financial twin: share of clinic takings collected but unspendable pending digital validation. Spikes with the same outages. **Type this name, not `frozen-rdf-capital-ratio`** — the latter is a per-clinic reporter and a monitor evaluates in observer context, where it errors. |

Expect `% stockouts phantom` to rise with `environmental-latency-severity` and
to fall when `predictive-modeling?` is on, while `ledger age (days)` stays flat
across that same comparison — together those three monitors tell the whole
story in one screenshot.

---

## Phase E — plots

For each: right-click → **Plot**, set **Name**, X axis label `day`, then edit
the pen(s) in the pen table at the bottom of the dialog. To edit a pen, click
the **pencil icon** on its row; put the command listed below into **Update
commands**. To add a second pen, click **Add Pen** first. Then click **OK**.
(Leave "Setup commands" and the plot-level update commands empty; leave
auto-scaling on.)

### Plot 1 — "NGO C2: true vs recorded stock"  ← the money plot
- Pen `true` → Update commands: `plot ngo-c2-true-mean`
- Pen `recorded` (Add Pen, rename it, pick a different color) → Update
  commands: `plot ngo-c2-recorded-mean`

*This is the picture of your whole thesis: the red line (what the information
system believes) trailing and diverging from the blue line (physical reality)
whenever outages hit.*

### Plot 2 — "C2 information gap"
- Pen `gap` → Update commands: `plot mean-ledger-gap-c2`

### Plot 3 — "Public availability today (%)"
- Pen `avail` → Update commands: `plot public-availability-today-pct`

*Shows the saw-tooth of the 30-day push cycle: availability near 100% right
after a push, decaying to near 0% before the next one — averaging ~43%.*

### Plot 4 — "Cumulative unmet at NGO"
- Pen `unmet` → Update commands: `plot ngo-unmet-patients`

---

## Phase F — first smoke test

1. Click **setup**. You should see: a green world, one blue square in the
   center (the regional hub), 12 red circles (community clinics), 3 green
   houses (NGO statics) with 3 lime triangles each (satellites, connected by
   dark-green lines), and 15 yellow boxes (private shops), mostly clustered
   in two neighborhoods.
2. Click **go**. The day counter (top of the view) should start climbing.
   Plot 1 should show two lines that mostly track each other, with the
   "recorded" line lagging slightly behind reality; Plot 3 should show a
   saw-tooth.
3. Let it run to at least day 400, then check monitor 7: it should read
   roughly 40–50. If it does, the model is reproducing your paper's ~43%
   availability benchmark. Then run the checks in `05-VERIFICATION-CHECKS.md`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "Nothing named X has been defined" on Check | A Phase A widget is missing or misspelled | Compare widget names letter-for-letter, including `?` and hyphens |
| A monitor shows nothing / an error | Typo in its Reporter field | Re-copy the reporter name from the table above |
| Everything compiles but `setup` errors | Code was pasted incompletely | Re-paste the entire block from `01-PASTE-THIS-CODE.md` |
| Plots stay empty | Pen update command missing/typo | Edit the pen, re-copy the `plot ...` command |
