# Deliverable (b): Building the Interface tab, click by click

This document lists **every widget the model needs**, with exact names, ranges
and defaults, and step-by-step click instructions. Follow the phases **in
order** — the code cannot compile until Phase A is done.

Widget decision (from Part D of the handoff): the three research parameters
(`grid-failure-rate`, `info-latency-severity`, `predictive-modeling?`) are now
**real Interface widgets**, not values hard-coded in `setup`. This was not
optional: BehaviorSpace (deliverable 5) can only vary parameters that live in
widgets without `setup` overwriting them. A fourth widget, `demand-shocks?`,
was added so you can switch environmental shocks off for controlled
comparisons — your research question explicitly contrasts conditions with and
without environmental shocks, so you need a clean off switch.

> **General mechanics, once:** to add any widget in NetLogo, go to the
> **Interface** tab and **right-click on an empty white area**, then choose
> the widget type from the menu (Button, Slider, Switch, Monitor, Plot). A
> dialog opens; fill in the fields exactly as listed below and click **OK**.
> To fix a mistake later, right-click the widget and choose **Edit**. To move
> a widget, right-click it, choose **Select**, then drag it.

---

## Phase A — the four parameter widgets (do this BEFORE pasting the code)

### A1. Slider: `grid-failure-rate`
1. Right-click empty space → **Slider**.
2. In **Global variable**, type exactly: `grid-failure-rate`
3. **Minimum**: `0`   **Increment**: `0.01`   **Maximum**: `0.5`   **Value**: `0.1`
4. Leave "vertical?" unchecked. Click **OK**.

*What it is:* the probability, each day, that an NGO static clinic has no
connectivity (power/network failure). At the default 0.1, a clinic is offline
roughly one day in ten — this is the environmental-infrastructure factor from
your paper's information-latency framework, and one of the two main
experimental dials.

### A2. Slider: `info-latency-severity`
1. Right-click empty space → **Slider**.
2. **Global variable**: `info-latency-severity`
3. **Minimum**: `0`   **Increment**: `1`   **Maximum**: `3`   **Value**: `1`
4. Click **OK**.

*What it is:* a multiplier applied to the dispensation lag and sync lag (the
first two stages of your paper's three-stage latency decomposition) and to the
paper-record error rate. `0` = a perfect, instantly-synced information system
(the control condition); `1` = baseline; `3` = severely degraded digitization.

### A3. Switch: `predictive-modeling?`
1. Right-click empty space → **Switch**.
2. **Global variable**: `predictive-modeling?`
3. Click **OK**. Make sure the switch shows **Off** (click it if not).

*What it is:* the second half of your research question. When On, each NGO
clinic projects its forecast demand across its known procurement and data
delays and reorders earlier. Critically, the forecast is applied **on top of
the lagged ledger** — it improves reorder *timing* but cannot repair *data
accuracy*. That separation is deliberate and is preserved in the code.

### A4. Switch: `demand-shocks?`
1. Right-click empty space → **Switch**.
2. **Global variable**: `demand-shocks?`
3. Click **OK**. Make sure it shows **On**.

*What it is:* enables the monsoon/flood shock system (probabilistic onset,
7–21 day duration, elevated demand and elevated grid-failure risk). Turn Off
for shock-free control runs.

---

## Phase B — paste the code

Now follow `01-PASTE-THIS-CODE.md`: paste the whole code block into the
**Code** tab and click **Check**. It should compile silently. If you see
*"Nothing named GRID-FAILURE-RATE has been defined"* (or similar), one of the
four Phase A widgets is missing or its name has a typo — the names must match
letter for letter, including the `?` on the two switches.

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
| 3 | `lines-ever-zero`                | lines ever zero    | 0 | Outcome 3: facility×commodity lines that have hit zero at least once (max 84) |
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
