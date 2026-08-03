# Deliverable (d): Named assumptions and deliberate scope limitations

Written in the register of a methodology section's Limitations discussion, so
you can lift material from here directly. Rule followed throughout: a number
is presented as *sourced* only when a real published figure backs it;
everything else is a **named assumption** with its direction of risk stated.

---

## A. What is empirically grounded

| Parameter / target | Value in model | Source |
|---|---|---|
| Public CC daily patient volume | Normal(38, 5) per clinic-day | WHO, *Independent Evaluation of Community Based Health Services in Bangladesh* (2019): utilization rose from ~19 to ~40 patients/day by 2016 |
| Essential-medicine availability at public facilities (calibration target) | Push quotas tuned so simulated availability ≈ 43% | WHO, *Medicines in Health Care Delivery: Bangladesh Situational Analysis* (2015): essential-medicines availability ≈ 43% |
| Facility stockout prevalence (secondary target) | Emergent ≈ 50–65% of facility-days with ≥1 class out | Consistent with the systematic-review literature on essential-medicine stockouts in LMIC community health settings (e.g., PMC9287964) and your paper's ~50% benchmark |
| NGO network structure (statics + dependent satellites, RDF revenue model) | 3 statics × 3 satellites, satellite finances at parent | Smiling Sun / NHSDP program structure (MEASURE Evaluation TR-12-89; USAID OIG audit 5-388-15-006-P): ~323 static clinics, ~8,800 satellite sessions, partial cost recovery |
| Vaccine wastage context | Storage-loss component 1%/mo, ×4 under grid stress | Rural Bangladesh cold-chain studies report *total* wastage of 25–46% for common EPI antigens; see limitation L4 on what share the model represents |
| C2 unit economics (cost 15, retail 22 BDT), RDF starting capital 241,000 BDT, class demand means, lag structure (1d dispensation + 2d sync + 2d processing), shock parameters | as listed | Your project specification document ([SPEC] tags in `setup-parameters`) — treated as authoritative per the handoff instructions |

## B. Named assumptions (no published figure found — deliberate, stated values)

Each entry: value → why it exists → direction of risk if wrong.

1. **C3 local-wholesale unit cost = 10 BDT; C3 user fee = 15 BDT.** Needed to
   give Class 3 the locally-purchased, RDF-funded procurement mechanism your
   paper describes. If margins are too generous, RDF resilience is overstated;
   if too thin, decapitalization is overstated. The qualitative latency
   results do not hinge on the exact margin.
2. **C1 accounting value = 5 BDT/unit; P3 cold-chain value = 100 BDT/dose.**
   Used only to price waste (outcome 2). Changing them rescales
   `waste-value-total` linearly without changing any behavior.
3. **Daily clinic operating cost = 800 BDT.** Introduced (and prominently
   flagged — changelog N1) so that the Revolving Drug Fund's decapitalization
   failure mode is reachable at all; without an outflow besides drug
   purchases, capital grows monotonically and the base build's capital-lock
   logic was dead code. Calibrated to leave a thin positive margin
   (~+200–300 BDT/day) at baseline, consistent with the documented reality
   that Smiling Sun-type networks recover only part of their costs from fees.
4. **Donor recapitalization: 50,000 BDT after 30 consecutive locked days.**
   Mirrors the donor dependence documented for Bangladesh's NGO health
   networks; prevents a decapitalized clinic from becoming a dead agent for
   the remaining years of a run while making every rescue *countable*
   (`donor-bailouts-total`).
5. **Reporting-error rate = 8% of dispensed volume per paper-fallback day,
   biased positive.** The positive direction is defensible (missed paper
   entries = unrecorded consumption = overstated stock — the direction that
   delays reorders); the magnitude is an assumption. `environmental-latency-severity`
   scales it, so the experiment sweeps this uncertainty rather than hiding it.
6. **Local procurement lead time (C3) = 2 days; minimum viable order batch =
   7 days of demand; forecast window = 14 days; forecast noise = ±5%.**
   Operationally plausible round numbers; each is a single named constant in
   `setup-parameters` and can be changed in one place.
7. **Grid-failure baseline = 0.10/day.** This is an *experimental factor*
   (slider, swept in BehaviorSpace), not an empirical claim about any
   particular district.
8. **C3 spoilage = 2.5%/month; satellite C3 demand ≈ 2/day; satellite stock
   targets 40/80/30.** Modest values completing mechanics the base build left
   half-specified.
9. **Private-shop stocking (100/600/200) with full weekly restock** — the
   "deep informal wholesale market" assumption: the private sector's own
   supply chain is outside scope, so shops act as a capacity-limited but
   reliably restocked absorber. If real shops also fail during shocks, the
   model *understates* completely-unserved patients — a conservative bias
   worth stating in your write-up.
10. **Patient class-need fractions (15/55/10/20) and one-class-per-patient.**
    From the specification's structure; real patients can need several
    commodity classes at once, which would raise all shortfall counts
    proportionally.

## C. Deliberate scope limitations (design decisions, not oversights)

- **L1. Class-level aggregation.** The ~40 named public commodities and the
  four C2 subgroups are simulated as pooled classes; the named lists justify
  class parameters instead of being separate variables (handoff gap 6,
  preserved by instruction). Consequence: the model cannot show *substitution
  within a class*, and item-level stockout frequencies are proxied by
  class-level lines.
- **L2. Single-node supply hub.** CMSD, EDCL and SMC remain one map location.
  The hardening differentiates their *channels* (separate stocks, cadences,
  rationing and routes — including C3 bypassing the hub entirely), which is
  what your paper's sourcing distinctions actually require; multi-echelon
  transport modeling stays out of scope.
- **L3. Compressed network ratios.** 12 CCs : 3 statics : 9 satellites : 15
  shops is a stylized subdistrict. The real satellite-to-static ratio is ~27:1
  (Smiling Sun), and real CC density is far higher. Results are about
  *mechanisms and relative differences between experimental arms*, not
  absolute national projections.
- **L4. Cold-chain waste is storage-loss only.** Published total vaccine
  wastage (25–46%) is dominated by open-vial session losses, which are not
  modeled. The model's cold-chain channel represents the
  storage/outage-driven component only, so its wastage output should be
  compared against that component, not the headline literature figures.
- **L5. Public-side information systems are not modeled.** Community clinics
  are pure rigid push per your paper; only NGO statics carry latency
  mechanics. The 43%-availability pathology at CCs is reproduced through
  quota rigidity alone.
- **L6. Prices are static.** No inflation, no private-shop price response to
  shortages (`unit-price-markup` was removed as dead weight). Affordability
  barriers to patients are out of scope.
- **L7. Patients are daily aggregate counts,** not individual agents with
  care-seeking behavior, and geography enters only through "nearest facility"
  choice in the diversion cascade.
- **L8. No seasonality beyond stochastic shocks.** Monsoon is a probabilistic
  shock process, not a calendar season.
- **L9. Paper-record error is deterministic in magnitude** (proportional to
  dispensed volume) with a positive sign. A stochastic error with occasional
  undercounting would be a reasonable sensitivity extension; the deterministic
  version was chosen so severity comparisons stay clean.
- **L10. The forecast reads true patient flow** (14-day trailing mean), on the
  argument that clinics observe their waiting rooms daily even when stock
  records lag. If real demand data were also corrupted, predictive modeling
  would perform *worse* than modeled — meaning the model, if anything,
  flatters the predictive arm; state this when interpreting results.

## D. Verification status — read before citing results

The code in this build was verified **statically**: line-by-line audit,
mechanical bracket/structure checks, defensive parenthesization of every
expression adjacent to an infix operator (the NetLogo parsing hazard from the
handoff), and arithmetic walk-throughs of every flow balance (documented in
`06-CHANGELOG.md`). It was **not executed** before delivery, because the
build environment had no network route to any NetLogo runtime. Two
consequences:

1. Run the three checks in `05-VERIFICATION-CHECKS.md` before trusting any
   output; they are designed to catch both compile-time and behavioral
   failures quickly.
2. The calibration targets (43% availability, ~50% facility stockout-days)
   were tuned analytically (push quota ≈ 13 days of demand per 30-day cycle).
   The two monitors exist precisely so you can confirm the achieved values
   and, if needed, nudge `cc-push-target` in `setup-parameters` — the
   documentation tells you which single line to edit.
