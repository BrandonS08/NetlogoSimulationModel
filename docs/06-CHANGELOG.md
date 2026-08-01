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
  let ledger-error round (real-c2 * reporting-error-rate * info-latency-severity)
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
`ngo-unmet-patients` is now split into `ngo-unmet-own` and
`ngo-unmet-diverted`. The diverted component is driven by the (latency-free)
public push cycle and is large, so it dilutes the latency signal in the
headline number. Reporting both lets you show the effect cleanly instead of
having a reviewer ask why the treatment effect looks small.

### N6. Stockout episode tracking
Outcome metrics 3 and 4 require distinguishing "hit zero at some point" from
"hit zero repeatedly". The base had one flat counter
(`total-stockout-events`) that actually counted *patients*, not events, and no
per-line state at all — it could not have answered either question.
