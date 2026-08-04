# Audit record: every change from the base build, and why

Three categories: **[BUG]** — the base build did something other than what it
was designed to do; **[GAP]** — one of the six gaps you listed; **[NEW]** — a
mechanic I added, each justified individually (nothing here is decoration).

---

## Part 1 — Bugs found (priority 1)

Ordered by how badly each distorted results. B1, B2, B6 and B7 all fall in the
class you asked me to hunt for: silent wrong behavior, no crash.

### B1. The paper-fallback logic inverted its own design — **most important fix**
*Base build:*
```
if not is-connected? [
  set manual-fallback? true
  let real-c2 item 1 stock-on-hand
  let ledger-error round (real-c2 * reporting-error-rate * environmental-latency-severity)
  set recorded-stock-ledger replace-item 1 recorded-stock-ledger (real-c2 + ledger-error) ]
```
Every offline day this **overwrote the ledger with the current true stock**
plus 8%. So during an outage the ledger was re-anchored to reality daily,
making it *more* accurate than during normal operation (where it lagged 3
days) — the exact opposite of your stated mechanism, and it meant outages
*improved* decision quality. The headline finding of the model would have been
backwards. Also, only C2 was ever touched, and the error was recomputed from
scratch each day rather than accumulating, so outage length had almost no
effect.

*Now:* during outage **and** the sticky recovery period the ledger is frozen
(nothing is revealed), while error accumulates day by day in proportion to
volume actually dispensed. The gap now grows with outage length, and
reconciliation at the end of the recovery period enters the paper backlog in
one batch. Applies to all three classes.

### B2. Duplicate requisitions — reorders stacked every single day
`process-ngo-reorders` had no in-flight check, so a clinic whose ledger sat
below the safety level hatched a **new full-size order every day** while
waiting for delivery. With a 2-day processing lag that is up to 3 concurrent
orders for the same shortfall, each sized "capacity minus believed stock" —
systematically over-ordering, draining RDF capital and the warehouse, and
*masking the very stockouts the model exists to measure*.
*Now:* `c2-order-outstanding?` / `c3-order-outstanding?` flags, cleared when
the order resolves.

### B3. The RDF capital lock was a one-way trap
The base set `rdf-capital-locked? true` when a *single* order was unaffordable
and only unlocked when `rdf-capital > safety-stock × unit-cost` (400 × 15 =
6,000). Because a locked clinic never ordered, never restocked and so never
sold, capital could sit *just below* the threshold forever while the clinic
still held thousands of taka. A permanently frozen agent, no error message.
*Now:* the lock is recomputed daily as "cannot afford a minimum viable batch",
orders are placed at whatever size capital allows (partial ordering), and a
donor recapitalization triggers after 30 locked days so the state is escapable
and *countable*.

### B4. Diverted patients received C2 stock for free
`divert-public-patient` decremented NGO stock without crediting revenue, while
`process-ngo-static-demand` charged retail for the identical transaction.
Since diverted demand is *larger than* the NGO's own walk-in demand at
baseline, the RDF was losing most of its income — biasing the model toward
decapitalization for a reason that has nothing to do with information latency.
*Now:* one shared routine (`serve-from-stock`) handles every dispensing event,
so pricing and bookkeeping cannot diverge by call site.

### B5. Satellite revenue vanished on the shortfall path
When a satellite covered a shortfall from its parent hub's stock, the base
code credited revenue in the sufficient-stock branch but not in the
partial-stock branch. Same class of leak as B4; fixed by the same
consolidation.

### B6. Private shops were never restocked
`setup` gave each shop 100/600/200 units and nothing ever replenished them. In
a 3,650-day run the private market was empty within months, after which the
final stage of your diversion cascade silently did nothing — every diverted
patient fell straight through to "unserved" for ~90% of the run.
*Now:* weekly restock (documented assumption: deep informal wholesale market).

### B7. The public warehouse was decorative
`public-warehouse-stock` was initialized, replenished every 14 days, and
**never decremented by anything**. The monthly push used
`max list current target`, which conjures stock from nothing. So the public
supply channel could never constrain public availability — which matters
because gap 2 asks you to reproduce a *supply-driven* 43% availability
benchmark.
*Now:* pushes draw down a real channel balance with proportional rationing
when the channel is short.

### B8. `max list current target` was the wrong operator for a push
Beyond B7, `max` means a clinic holding *more* than target keeps the surplus
and receives nothing, while one at zero jumps to target — but stock is never
*added to* an existing partial balance. `push-need` (target − current, floored
at zero) is the standard top-up rule and is what the base clearly intended.

### B9. Routine referrals were double-counted as commodity demand
`process-public-demand` computed `referred-out` from total patients, added it
to the unserved counter, and then **still generated commodity demand for the
full patient count**, so the 2% referred patients also consumed drugs. Also,
these routine referrals were summed into `total-unserved-referrals` together
with cold-chain supply failures — mixing a normal clinical event with a
stockout outcome in one metric.
*Now:* referred patients leave before commodities are drawn, and the two
concepts are separate metrics (`routine-referrals` vs `coldchain-unserved`).

### B10. Waste counters could never increment
`round (stock × rate / 30)` on realistic stock levels is `round(0.017)` = 0 for
cold chain, every day, forever — the cold-chain waste metric was structurally
pinned at zero, and NGO C1/C3 waste was heavily under-counted. This is a
particularly nasty silent bug: outcome metric 2 would simply have read 0.
*Now:* stochastic rounding preserves the expected loss rate.

### B11. Shock duration could never reach its maximum
`shock-duration-min + random (max - min)` yields 7–20, never 21. One-line
off-by-one. Also `total-shock-days` (the diagnostic counter) missed the first
day of every event; both fixed.

### B12. `setup` never called `reset-ticks` in the right place
The base called `reset-ticks` immediately after `clear-all`, before creating
any agents. Plot pens then evaluate against an empty world. Moved to the end
of `setup`, which is the documented NetLogo convention.

### B13. Fragile agent placement could crash setup
`move-to one-of patches with [...]` returns `nobody` if no patch qualifies, and
`move-to nobody` is a runtime error. With 40 agents, exclusion radii and
`not any? turtles-here`, an unlucky seed could exhaust the candidate set.
The base also used `distance turtle 0`, which assumes the hub is turtle 0 —
true only by creation-order accident.
*Now:* cascading fallbacks, and distances measured from coordinates and named
cluster patches rather than a turtle ID.

### B14. Dead variables and unreachable code
`public-ccs-own [recorded-stock-ledger]`, `ngo-satellites-own
[recorded-stock-ledger]`, `private-shops-own [unit-price-markup]` and
`public-ccs-own [push-target]`/`last-sync-tick` were written but never read
(only NGO statics have information mechanics). `resupply-ngo-satellites` was
also defined but called from inside `run-replenishment-cycles` *after* its own
`ticks mod 7` guard — harmless, but the double guard hid the schedule.
Removed/cleaned so nothing in the file is inert.

### B15. Satellite Class 3 was a one-shot buffer
Satellites were given C3 stock at setup but weekly resupply only covered C1 and
C2, so their C3 line died permanently and quietly.

### B16. `average-monthly-cons` held daily values
The variable name said monthly; it was used as a daily mean everywhere
(`random-normal (item 0 average-monthly-cons) 5` per day). Renamed
`mean-daily-demand`. No behavior change — but a reviewer reading the code
would have flagged it as a 30× units error, which is a credibility problem.

---

## Part 2 — The operator-precedence audit (what I actually found)

You asked me to check every list extraction followed by an arithmetic
operator. I did, and I also verified the underlying claim against NetLogo's
parser source, because the fix depends on which way the parse actually goes.

**Finding: NetLogo parses `item 0 mylist * factor` as `(item 0 mylist) * factor`
— the intuitive reading. The mechanism described in your handoff is backwards.**

Evidence, in order of strength:

1. **NetLogo's parser source.** In `ExpressionParser.scala`, arguments are
   parsed by `parseArgExpression`, which passes *the enclosing reporter's own
   precedence* as the floor: `parseExpressionInternal(tokens, false,
   syntax.precedence, goalType, scope)`. `parseMore` then absorbs a trailing
   infix operator only `if (syntax.isInfix && syntax.precedence > precedence)`.
   Ordinary prefix reporters such as `item` carry
   `Syntax.NormalPrecedence = 10`, and arithmetic operators sit **below** it.
   So an argument expression *stops* at `*` — it does not swallow it.
2. **Your own base code proves it at runtime.** It contains
   `filter [ u -> item 0 u <= ticks ] pending-ledger-updates`, executed every
   tick. Under the "greedy" reading this would be `item 0 (u <= ticks)`, which
   throws a type error immediately. You report the model runs, so NetLogo must
   be parsing `(item 0 u) <= ticks`.

**But your symptom description was right, and there is a real bug of this
family** — it just bites in the opposite direction. Because a prefix
reporter's argument *stops* at an infix operator, the operator attaches to the
**outer** expression instead. Commands are parsed with
`CommandPrecedence = 0`, so they *do* absorb trailing infix operators. That
makes this line silently wrong:

```netlogo
set stock replace-item 0 stock item 0 stock - 5      ;; WRONG
```
It parses as `set stock ((replace-item 0 stock (item 0 stock)) - 5)` — a list
minus a number — producing a runtime error pointing at `set`, nowhere near the
real mistake. That matches "confusing runtime errors far from the actual
cause" exactly. The correct form is what the hardened build uses everywhere:

```netlogo
set stock replace-item 0 stock ((item 0 stock) - 5)  ;; RIGHT
```

**What I did:** every list extraction, `count`, `sum`, `mean`, `floor` and
user-defined reporter call adjacent to an arithmetic or comparison operator in
the file is now individually parenthesized, so no expression depends on
precedence rules at all. This is correct under either reading, and it is the
habit to keep. Genuine precedence traps that remain worth knowing:
`of` / `with` / `in-radius` bind *tighter* than normal arguments; variadic
primitives like `list` need explicit parentheses for anything other than two
arguments (`(list a b c)`); and `-` is binary unless parenthesized, so `(- x)`
is required for negation.

**Two real precedence-adjacent defects were found and fixed:** the
`max list current target` misuse in B8, and `min list` / `max list` forms in
the base which happen to parse correctly but were rewritten as
`min (list ...)` / `max (list ...)` so the intent is explicit.

---

## Part 3 — The six gaps

### GAP 1 — CMSD / EDCL / SMC differentiation
The hub stays one map node (your simplification, preserved), but its single
`warehouse-stock` list is replaced by three channels with genuinely different
logistics: `public-channel-stock` (CMSD/EDCL → public CCs, monthly quota,
proportional rationing), `smc-c1-stock` (SMC/DGFP donor → NGO C1 push,
monthly), `edcl-rdf-stock` (EDCL/wholesale → NGO C2, 14-day cycle,
requisition-pull). Class 3 now bypasses the hub entirely (GAP 3). This is the
part of the distinction that affects behavior; multi-echelon transport
modeling remains out of scope (limitation L2).

### GAP 2 — Calibration to 43% availability / ~50% stockout
Public stock is now driven by one interpretable quantity: **days of coverage
per 30-day push cycle**. Class demand per clinic-day is
`38 patients × 0.98 × class fraction`, so 13 days of coverage yields
`13/30 = 43.3%` availability, matching the WHO Bangladesh situational-analysis
figure. `cc-push-target` was therefore set to **(75, 270, 50, 100)** — replacing
the base's uncalibrated (150, 400, 60, 200) — and initial stock now starts at
the push target instead of an unrelated third value. Channel quotas
(950, 3400, 650, 1300 per month) cover 12 clinics × target with ~5% headroom.
Because all four classes share one push cycle, facility-level stockout-days
land around 55–60%, consistent with the ~50% benchmark. Two monitors report
both statistics so you can verify rather than take my word, and
`05-VERIFICATION-CHECKS.md` check 4 tells you which single line to nudge.

### GAP 3 — Class 3 funding and procurement
The base's flat periodic top-up (`if below safety then jump to capacity`, free,
from nowhere) is gone. C3 is now purchased on the **local wholesale market**
per your paper: RDF-funded at 10 BDT/unit, recovered at a 15 BDT user fee,
2-day delivery, no central approval, ordered through the same requisition
mechanism as C2 so it appears in the outcome log — and, critically, it now
competes for the same RDF capital, which is what makes it a real procurement
decision rather than free restocking.

### GAP 4 — Requisition outcome logging
Every requisition now terminates as `fulfilled`, `partial` or `lost`, with
running counters, a `requisition-fill-rate` reporter, and a `requisition-log`
row per order (tick placed, tick resolved, clinic, class, quantity requested,
quantity shipped, outcome). The `export log` button writes it to CSV for
analysis outside NetLogo. Note the base build had **no** `partial` state — an
order that could only be half-filled was recorded as a total loss and shipped
nothing.

### GAP 5 — BehaviorSpace
See `07-BEHAVIORSPACE.md`: a 4 × 2 × 2 × 2 design (severity × predictive ×
grid-failure × shocks) at 20 replications, reporting your four outcome metrics
plus diagnostics.

### GAP 6 — Commodity subgroups
Preserved as class-level aggregation, as you instructed. The named commodities
are documented as the justification for class parameters in
`03-MODEL-DOCUMENTATION.md` §11, with an explicit note about the one table you
need to paste in from your paper.

---

## Part 4 — New mechanics (each justified, nothing speculative)

### N1. Daily operating cost — **flag this one**
This is the only addition that changes headline behavior, so I want it
visible. The base RDF had **no outflow except drug purchases**, so capital grew
monotonically forever and the capital-lock code was unreachable — the RDF was
not a revolving fund, it was an infinite one. Since "can the fund survive
demand shocks under information delay" is part of your research question, I
added a daily operating cost (800 BDT/clinic, calibrated to leave a thin
positive baseline margin). **If you would rather not carry this assumption,
set `daily-operating-cost` to 0 in `setup-parameters`** — the model runs fine,
capital simply never binds, and you lose the decapitalization failure mode.

### N2. Donor recapitalization (paired with N1)
Prevents a decapitalized clinic from becoming a permanently dead agent, and
converts "this arm bankrupts clinics" into a countable metric
(`donor-bailouts-total`) instead of a silent absorbing state.

### N3. Demand-responsive forecasting
The base "forecast" was `mean-daily-demand × random noise` — a constant with
jitter, carrying no information about actual demand, so predictive modeling
could not respond to a shock and the predictive arm was close to a no-op.
Replaced with a 14-day trailing mean of observed demand. This is what makes
your second research question answerable at all. The forecast deliberately
reads *patient flow*, not the corrupted stock ledger (limitation L10).

### N4. Projection horizon includes known data staleness
When predictive modeling is on, the reorder trigger projects demand over
*procurement lead time + known ledger staleness*, rather than lead time alone.
A manager who knows their data is three days old plans for it. Without this,
the predictive arm could not compensate for latency, which is precisely the
mitigation your question asks about.

### N5. Unmet-demand decomposition
`ngo-unmet-patients` is now split into `ngo-unmet-walkin` and
`ngo-unmet-diverted`. The diverted component is driven by the (latency-free)
public push cycle and is large, so it dilutes the latency signal in the
headline number. Reporting both lets you show the effect cleanly instead of
having a reviewer ask why the treatment effect looks small.

### N7. Ledger age and metric decomposition (added in revision v2)
See Part 5 below — added in response to the first test round, to make the
model's central claim measurable.

### N6. Stockout episode tracking
Outcome metrics 3 and 4 require distinguishing "hit zero at some point" from
"hit zero repeatedly". The base had one flat counter
(`total-stockout-events`) that actually counted *patients*, not events, and no
per-line state at all — it could not have answered either question.

---

## Part 5 — Revision v2: corrections after the first test round

The model was built and run for the first time here. Three observations came
back. **None of them was a model bug** — two were defects in my verification
instructions and one was a correct observation about a metric's statistical
properties. Recording them because the reasoning belongs in the methodology
write-up.

### V1. Check 1 specified an incomplete control condition — *doc fix*
*Reported:* with `environmental-latency-severity` = 0 and `grid-failure-rate` = 0,
"% time on paper" was above zero and the two pens in Plot 1 were very slightly
apart, where the check said both should be exactly zero.

*Cause:* the check left `demand-shocks?` On. An active shock adds
`shock-grid-risk-add` (0.25) to the grid-failure rate — a flood cuts power
regardless of the baseline rate — so clinics still disconnected, still fell
back to paper, and the ledger still froze during those episodes. The observed
pen separation is that freeze, correctly rendered. Note it was *small*, which
is itself confirmation the code is right: with severity 0 the paper error term
is `dispensed × 0.08 × 0` = exactly zero, so the only divergence is the freeze
itself, with no error component on top.

*Fix:* check 1 now requires `demand-shocks?` Off as the third control setting,
and explains why. Model unchanged.

### V2. Check 2 used a metric that cannot test its own claim — *metric fix*
*Reported:* enabling `predictive-modeling?` cut the C2 ledger gap from 1,018 to
739 (the check said it should be unchanged), while total zero episodes rose
slightly, 3,574 → 3,642 (the check said they should fall).

*Cause, part one — the gap.* `mean-ledger-gap-c2` is `|ledger − true|` in
units. Since the ledger is a stale snapshot, that quantity is approximately
*how much stock moved during the staleness window*. Better reorder timing
produces a smoother stock trajectory — no deep crashes followed by large
restock jumps — so the same staleness translates into a smaller numeric gap.
The information pipeline is untouched; only the trajectory it is sampling
changed. The metric was the wrong instrument, and the check's expectation was
naive. The 27% reduction is a **real and reportable secondary finding**
(staleness becomes less costly when inventory is better managed), but it is
not evidence about data accuracy.

*Fix:* added `ledger-snapshot-tick` per clinic and the reporter
`mean-ledger-age-days` — how many days out of date the ledger is. This depends
only on connectivity draws and `environmental-latency-severity`, and is mathematically
incapable of responding to order timing, so it is the correct test of "does
prediction repair the data?". Together with `pct-time-on-paper` it gives two
independent invariants that must hold across the predictive arms.

*Cause, part two — the zero episodes.* `zero-episode-total` counts all 84
facility×class lines. Public community clinics (48 lines) run a rigid 30-day
push with **no information mechanics at all**, and satellites (27 lines)
restock to fixed weekly targets. Neither can respond to the predictive toggle.
Only the 9 static lines can. So the headline total is roughly 90% inert with
respect to the treatment, and a 1.9% single-run movement in it is noise, not a
sign reversal.

*Fix:* added `static-zero-episodes`, `satellite-zero-episodes` and
`public-zero-episodes`. Check 2 now reads the statics-only figure, and requires
three paired runs rather than one, since single-run differences under ~10% are
not interpretable. This is the same dilution problem already handled for
outcome metric 1 by N5, now extended to metrics 3 and 4.

*Model behavior unchanged by either fix* — these are new observables, not new
mechanics.

### V3. Calibration metrics show almost no run-to-run variation — *correct
observation, no defect*
*Reported:* the calibration figures landed on the stated target or mid-range on
essentially every run, raising a reasonable question about whether the
stochastic machinery was working.

*Assessment: this is the expected behavior, and worth being able to defend.*
`public-availability-pct` is a cumulative average over 12 clinics × 4 lines ×
1,000 days ≈ 48,000 line-days; its standard error is a fraction of a
percentage point. The underlying mechanism is also close to deterministic —
push to target every 30 days, deplete at a near-constant rate, cross zero
around day 13 — so `13/30 = 43.3%` is a structural property, not a sampling
outcome. Stability here is the law of large numbers, the same reason 48,000
fair coin flips always land near 50%.

The randomness is genuinely present; it simply lives in the low-aggregation
metrics. `total-shock-days` (a Poisson-style process with only ~6 events per
3-year run), `donor-bailouts-total`, `static-zero-episodes` and
`mean-rdf-capital` all vary visibly run to run. Check 5 was added so this can
be demonstrated rather than asserted, and it also documents the one thing that
*would* break variability: adding `random-seed` to `setup`, which the model
deliberately does not do.

*Guidance for the write-up:* report calibration figures as point values (they
are stable by construction) and the four outcome metrics as means with
standard deviations across BehaviorSpace replications.


---

## Part 6 — Latency split into environmental and bureaucratic dials

### Why
A single `info-latency-severity` slider scaled all three stages of the paper's
latency framework at once. That conflated two causes §2.2.4 explicitly
separates: stages 1–2 (dispensation lag, device sync lag) are environmental and
technical — grid failure, bandwidth, digitization gaps — while stage 3 (central
processing lag) is *"primarily caused by human rather than environmental lag"*.
With one dial, the relative contribution of connectivity failure versus
administrative slowness could not be measured, and "which policy lever matters
more" was unanswerable.

### What changed in the code

| Tag | Change |
|---|---|
| [D5-1] | `info-latency-severity` → `environmental-latency-severity`. Pure rename across 6 sites; no logic altered in `update-ledger-visibility`, `accumulate-paper-error`, or the `staleness` term. |
| [D5-2] | New Interface slider `bureaucratic-latency-severity` (0–3, step 0.25, default 1). Widget count 4 → 5. |
| [D5-3a] | `projection-horizon`: the C2 `lead` becomes `(central-processing-lag * bureaucratic-latency-severity)`. C3 keeps `local-procurement-lag` unscaled — a commercial delivery time, not part of the information framework. |
| [D5-3b] | `process-ngo-reorders`: the lag passed to `place-requisition` becomes the same product, so the dial moves *real* order arrival, not just the clinic's internal estimate. |
| [D5-4] | New reporter `effective-bureaucratic-lag`. Implemented as a reporter rather than the inline expression originally requested, because `central-processing-lag` is `ngo-statics-own` and a monitor evaluates in observer context, where a direct reference is a runtime error. |
| [D5-5] | Comments describing one dial covering all three stages rewritten to describe the two dials separately. |

**Behaviour-neutral at default.** At `bureaucratic-latency-severity = 1` the
product is `2 × 1 = 2`, exactly the previous constant. Nothing changes until the
dial moves. At `0`, requisitions resolve on the tick they are placed — the
correct degenerate case for instant approval.

### The experiment was redesigned to match

Introducing a parameter and never varying it would have been worse than not
introducing it — a reviewer would ask why. The BehaviorSpace design now varies
`environmental-latency-severity` × `bureaucratic-latency-severity` ×
`predictive-modeling?` × `demand-shocks?`, at 10 replications:
**64 conditions × 10 = 640 runs, the same count and runtime as before.**

`grid-failure-rate` moves out of the factorial and is held at its default 0.1,
with a separate 40-run one-factor sweep suggested instead. Replications drop
20 → 10, which is defensible at a ten-year horizon since each run already
averages over ~20 shock events.

This makes the design answer a third question alongside the original two:
**which lever matters more, connectivity or bureaucracy** — and whether fixing
one helps when the other is still bad, which would mean piecemeal reform fails.

### Also corrected in this pass
Stale figures in the documentation: tracked commodity lines stated as 84 in two
places when satellites were excluded and the true count is 57, and a
BehaviorSpace warning citing 1,095 rows per run at a 3,650-day horizon.


---

## Part 7 — Interface widgets removed as a dependency

### The recurring failure this fixes
Four separate paste failures traced to the same root cause. Five globals were
supplied by Interface widgets rather than declared in the code, so the Code tab
could only compile if those widgets already existed with letter-perfect names.
Every parameter rename then required a synchronized manual widget edit, and any
mismatch produced *"Nothing named X has been defined"* on every line mentioning
the name — which reads, correctly, as the code being "riddled with errors" when
the code is fine and one widget is misnamed.

The design was defensible in the abstract and wrong for this project: it put a
fragile manual step in front of every single code delivery.

### What changed
All five research parameters — `grid-failure-rate`,
`environmental-latency-severity`, `bureaucratic-latency-severity`,
`predictive-modeling?`, `demand-shocks?` — are now ordinary globals declared in
the code. **The file compiles in a completely empty NetLogo model.** No widget
is required to compile or to run.

Because `clear-all` wipes globals, and BehaviorSpace assigns them *before*
setup runs, the setup path is split:

| Procedure | Behaviour | Used by |
|---|---|---|
| `setup` | `clear-all`, restore the five to their defaults, build | Interactive runs |
| `setup-experiment` | Save the five into locals, `clear-all`, restore them, build | **BehaviorSpace** |

Local `let` variables survive `clear-all` where globals do not; that is the
mechanism. **BehaviorSpace must use `setup-experiment` as its setup command.**
With plain `setup` every run would silently reset to defaults and produce
identical results across all conditions — a failure that reports no error at
all, which is why it is called out in both `00-START-HERE.md` and `07`.

### Named scenarios replace slider fiddling
Seven `scenario-` procedures each perform a full setup and apply one named
condition: `scenario-perfect-info`, `scenario-worst-case`,
`scenario-predictive-off`, `scenario-predictive-on`, `scenario-baseline`,
`scenario-bureaucracy-only`, `scenario-connectivity-only`. A verification check
is now one button click instead of setting three or four controls by hand. This
is safe because none of the five parameters is read during setup — they are all
consumed at runtime — so applying them after the build is equivalent.

The last two are new and exist because of the latency split in Part 6: they
isolate bureaucratic latency with connectivity perfect, and the reverse.

### Migration cost, once
A widget and a global cannot share a name, so existing sliders and switches
must be **deleted** or the paste fails with *"There is already a global
variable called GRID-FAILURE-RATE"*. Deleting five widgets, or starting from
`File → New`, is a one-time step. After it, no code delivery ever again depends
on Interface state.

---

## Part 8 — Predictive arm made internally consistent; phantom lockout measured

Two changes. The first closes a contradiction inside the mitigation arm; the
second adds a metric for the failure mode the model was built to expose but
could not previously count.

### [D6-1] The predictive arm corrected timing but not quantity

**The inconsistency.** `reorder-triggered?` projected forecast demand across
the pipeline horizon — lead time *plus* known ledger staleness — to decide
**when** to order. `max-stock-order-quantity` then computed **how much** from
the face-value ledger, ignoring the same staleness window the trigger had just
finished reasoning about.

So the predictive clinic fired at the right moment and then asked for the wrong
amount, under-ordering by roughly (forecast daily demand × staleness days) —
about 300 units of C2 at the default dial, 900 at severity 3. The arm was
half-implemented, and the shortfall grew with exactly the dial the study
varies, which would have suppressed the measured mitigation effect most where
the effect is most interesting.

**The fix.** When `predictive-modeling?` is on, the order rule now estimates
true on-hand stock before applying the MSH formula:

```
Estimated Stock = Recorded Ledger - (Forecast Daily Demand x Staleness Days)   [floored at 0]
Order Quantity  = (AMC x Review Period) + Safety Stock - Estimated Stock       [floored at 0,
                                                                                capped by storage room]
```

When it is off, the formula is untouched: `(AMC × Review Period) + Safety Stock
− Recorded Ledger`, exactly as before. The naive arm is bit-for-bit unchanged,
so nothing already run against it is invalidated.

**One definition, two consumers.** The staleness window is now the single
reporter `ledger-staleness-days` = (dispensation-lag + sync-lag) ×
`environmental-latency-severity`. Both `projection-horizon` (timing) and
`max-stock-order-quantity` (quantity) read it, so the two halves cannot drift
apart as the dials move — which is how they came apart in the first place. The
stage-3 approval delay is deliberately **not** in this window: it is a
procurement lead time, not a data-currency problem, so it belongs in the
horizon and nowhere else.

**What this does not change — and the claim to be careful about.** Predictive
modeling still does not repair the data. It corrects the *known* delay only; it
cannot see `paper-error-accum`, the unrecorded dispensing that accrues during an
outage, because that error is invisible to the clinic by construction.
`mean-ledger-age-days` and `pct-time-on-paper` remain untouched by the toggle,
so verification check 2 still works and still tests a real claim.

The wording in the write-up does need to change. "Predictive modeling fixes
timing, not data accuracy" is now too narrow. The accurate framing is that the
arm separates **latency the clinic can reason about from corruption it cannot**
— it changes how a delayed ledger is *read*, not how good the ledger is. Docs
02, 03, 05 and 07 have been updated to that framing.

**Two honesty checks added to the docs.** At `environmental-latency-severity =
0` the staleness discount is exactly zero, so the perfect-information control
remains a true control and the arms must agree on the C2 decision end-to-end
(check 2b — with the expected C3 exception documented there). And because
forecast-driven ordering can overshoot, `waste-value-total` may *rise* in the
predictive arm; docs 05 and 07 now instruct that this be reported rather than
buried. A mitigation with a cost is a more credible result than a free win.

### [D6-2] Phantom overstock lockout is now counted

**What it is.** `accumulate-paper-error` gives recording error a positive bias
by design: dispensing during an outage goes unrecorded, so the system believes
more stock remains than truly does. Push that far enough and a line reaches

> physical stock ≤ 0 **while** the recorded ledger reads **above** the reorder
> trigger.

Under the naive arm the reorder rule reads that ledger, sees a comfortably
stocked clinic, and declines to order. The stockout is not merely unnoticed —
it is **actively prolonged by the information system**. Stock cannot arrive
because the system does not believe it is needed.

This is the model's sharpest illustration of the thesis and the one failure
mode that cannot be explained away as ordinary supply shortage: supply is
willing, capital is available, and the order is simply never placed. The
mechanism was already in the model. It had no name and no counter.

**What was added.**

| Addition | Kind | Role |
|---|---|---|
| `phantom-locked?` | `ngo-statics-own`, list of 3 booleans | Per-line state, refreshed each tick |
| `phantom-lockout-days-cum` | global | Cumulative static commodity-line-days in the state |
| `check-phantom-lockout [ c-idx ]` | turtle reporter | The condition itself |
| `phantom-lockout-line-days` | reporter | The cumulative count, for monitors and BehaviorSpace |
| `pct-stockouts-phantom-caused` | reporter | Share of static zero-stock line-days that were phantom |
| `frozen-rdf-capital-ratio` | turtle reporter | Financial twin: takings collected but unspendable |
| `mean-frozen-capital-ratio` | reporter | Observer-context wrapper, so it can go on a monitor |

**Where it is measured, and why there.** In `update-running-metrics`, which the
`go` loop runs *after* `process-ngo-reorders` and *before*
`run-replenishment-cycles`. So a counted line is one whose reorder decision was
genuinely taken against today's ledger, and it shares a denominator basis with
`static-stockout-line-days` computed in the same pass — which matters, because
`pct-stockouts-phantom-caused` is the ratio of the two.

**How to read it — a caveat that belongs in the write-up.** The metric records
a *state*, not a per-arm outcome: empty shelf plus above-trigger ledger. The
same state can occur under `predictive-modeling?` and **not** block the order,
because the trigger discounts the ledger by forecast demand before the
comparison. That is precisely what makes it worth reporting: hold the state
fixed, and the two arms differ in whether it becomes a lockout. Do not describe
it as "reorders blocked" without naming the arm.

`pct-stockouts-phantom-caused` is the cleanest single number for the argument
that the failure is informational rather than logistical: nothing about supply
or money changed between the arms, only what the system believed.

### [D6-3] Incidental fix

The docstring for `mean-ledger-age-days` had drifted above
`effective-bureaucratic-lag` in an earlier edit, so each reporter carried the
other's explanation. Comments only; no behavior change.
