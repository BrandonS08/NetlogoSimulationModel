# Parameter provenance — every value in the model and where it came from

**Auto-derived from `model/CodeTab.txt` (`setup-parameters`), so it cannot drift
out of date.** Regenerate after any parameter change.

Source tags:

| Tag | Meaning |
|---|---|
| `[PAPER ...]` | Taken from your background research paper, section cited in the code comment |
| `[SPEC]` | From your specification document — authoritative for numeric parameters |
| `[AUTHOR]` | Supplied by you directly in conversation |
| `[LIT: ...]` | From a named published source |
| `[CATALOGUE]` | From your inventory proof-of-concept — **prices and cadence only**, no behavioural parameters |
| `[CALIBRATED]` | Tuned so simulated output reproduces a benchmark, or so a flow balances. A *fitted* input, not a measured one — say so in your methodology |
| `[ASSUMPTION]` | A named, deliberate assumption with no source |

---

## Every parameter

| Parameter | Value | Source |
|---|---|---|
| `num-public-ccs` | 12 | [SPEC] |
| `num-ngo-statics` | 3 | [SPEC] |
| `satellites-per-static` | 3 | [SPEC] |
| `num-private-shops` | 15 | [SPEC] |
| `class2-unit-cost` | 15 | [SPEC] |
| `class2-retail-price` | 22 | [SPEC] |
| `class3-unit-cost` | 8.5 | [CATALOGUE] |
| `class3-retail-price` | 12.5 | [ASSUMPTION] |
| `class1-unit-value` | 11 | [CATALOGUE] |
| `p3-unit-value` | 100 | [CATALOGUE] |
| `c-unit-values` | (list class1-unit-value class2-unit-cost class3-unit-cost) | [ASSUMPTION] |
| `daily-operating-cost` | 0 | [PAPER 2.2.3.1] |
| `donor-recap-amount` | 50000 | [ASSUMPTION] |
| `bailout-threshold-days` | 30 | [ASSUMPTION] |
| `min-batch-days` | 7 | [ASSUMPTION] |
| `warehouse-replenish-interval` | 14 | [SPEC] |
| `warehouse-replenish-amount` | 4700 | [CALIBRATED] |
| `public-push-interval` | 30 | [SPEC] |
| `public-channel-replenish` | (list 950 3400 650 1300) | [CALIBRATED] |
| `smc-c1-replenish` | 9000 | [CALIBRATED] |
| `ngo-class1-push-amount` | 2900 | [CALIBRATED] |
| `rollout-days` | (list 2 3 5) | [ASSUMPTION] |
| `shock-extra-rollout-day` | 0 | [ASSUMPTION] |
| `satellite-patients-min` | 35 | [ASSUMPTION] |
| `satellite-patients-max` | 50 | [ASSUMPTION] |
| `satellite-consumable-share` | 0.20 | [ASSUMPTION] |
| `satellite-pack-size` | (list 55 0 11) | [ASSUMPTION] |
| `private-shop-base-stock` | (list 100 600 200) | [SPEC] |
| `fallback-recovery-lag` | 7 | [PAPER 2.2.4] |
| `local-procurement-lag` | 2 | [ASSUMPTION] |
| `reporting-error-rate` | 0.217 | [LIT: Bekele et al. 2025, PLOS Glob Public Health,] |
| `forecast-window-days` | 14 | [ASSUMPTION] |
| `demand-history-days` | 30 | [PAPER 2.2.3.1] |
| `initial-consumption-estimate` | (list 92 101 49) | [ASSUMPTION] |
| `review-period-months` | 1 | [PAPER 2.2.3.1] |
| `c1-monthly-spoilage-rate` | 0.05 | [SPEC] |
| `c2-monthly-spoilage-rate` | 0.05 | [SPEC] |
| `c2-monthly-shrinkage-rate` | 0.03 | [SPEC] |
| `c3-monthly-spoilage-rate` | 0.025 | [ASSUMPTION] |
| `coldchain-monthly-loss-rate` | 0.01 ;; [ASSUMPTION] storage-loss component only (see Limitations: | [ASSUMPTION] |
| `coldchain-outage-accel` | 4 | [SPEC] |
| `c1-heat-sensitive-share` | 0.5 | [CATALOGUE] |
| `mean-daily-patients` | 38 | [LIT: WHO/CBHC evaluation 2019 — CC utilization ~40/day by 2016] |
| `patient-sd` | 5 | [ASSUMPTION] |
| `p-class-fractions` | (list 0.15 0.55 0.10 0.20) | [SPEC] |
| `p-to-c-class-map` | (list 0 1 -1 2) | [SPEC] |
| `higher-care-referral-rate` | 0.02 | [SPEC] |
| `cc-push-target` | (list 75 270 50 100) | [CALIBRATED] |
| `shock-onset-probability` | (2 / 365) | [SPEC] |
| `shock-duration-min` | 7 | [SPEC] |
| `shock-duration-max` | 21 | [SPEC] |
| `shock-demand-multiplier` | 1.8 | [SPEC] |
| `c-shock-multipliers` | (map [ x -> 1 + (x * k) ] flood-shape) | [ASSUMPTION] |
| `p-shock-multipliers` | (list (item 0 c-shock-multipliers) (item 1 c-shock-multipliers) | [ASSUMPTION] |
| `shock-grid-risk-add` | 0.25 | [SPEC] |
| `simulation-length-days` | 3650 | [ASSUMPTION] |

Per-clinic values set inside `setup-ngo-network` rather than the registry:
`rdf-capital` 1,798,000 `[PAPER 2.2.3.1]`; `stock-on-hand` 3400/3750/1830 and
`safety-stock` 650/720/350 and `max-stock-capacity` 4400/4500/2400
`[SPEC-DERIVED]` (preserving the spec's implied 7-day cover at corrected
demand); `mean-daily-demand` 25/55/22 `[SPEC]`; the three lags 1/2/2 `[SPEC]`.

---

## The assumptions, gathered in one place

These are the values with no external source. Everything else traces to your
paper, your spec, your catalogue, a citation, or a flow calculation. Name these
in your Limitations section; do not feel obliged to chase them.

- **`satellite-consumable-share` (0.20)** — share of outreach patients needing an
  administration consumable. The only remaining assumption in the satellite
  mechanic, now that patients-per-session is sourced from you.
- **`coldchain-monthly-loss-rate` (1%/month)** — storage-loss component only.
  Published Bangladeshi vaccine wastage of 25–46% is *total* wastage, dominated
  by open-vial losses the model does not simulate, so it cannot be used directly.
- **`class3-retail-price` (12.5 BDT)** — set to match the C2 margin. The C3
  *cost* (8.5) is from your catalogue; only the user fee is assumed.
- **`patient-sd` (5)**, **`local-procurement-lag` (2 days)**,
  **`min-batch-days` (7)**, **`forecast-window-days` (14)**,
  **`c3-monthly-spoilage-rate` (2.5%/month)**, **`donor-recap-amount` (50,000)**,
  **`bailout-threshold-days` (30)**, **`private-shop-base-stock`** with full
  weekly restock.

## Two things to describe carefully in the write-up

1. **`cc-push-target` is `[CALIBRATED]`, not measured.** It was tuned so
   simulated availability reproduces your 43% benchmark. Standard practice, but
   present it as a fitted input. And do not attribute the 43% figure to Kabir et
   al. — that source reports a *readiness index* of 47, a different measurement.
2. **`reporting-error-rate` (0.217) involves an interpretive step.** Bekele et
   al. 2025 report that 21.7% of manual bin-card *records* disagreed with a
   physical count; the model uses that as the share of *units* mis-posted.
   Better founded than a guess, but not a measurement of the exact quantity.

## Are all four outcome metrics measurable? Yes.

| Your stated metric | Model reporter |
|---|---|
| Patients unable to receive needed care at NGO facilities | `ngo-unmet-patients`, split into `ngo-unmet-walkin` / `ngo-unmet-diverted` |
| Total value of expired/wasted inventory | `waste-value-total` (+ `waste-pct-of-value` against the <2% standard) |
| Items hitting zero stock at any point | `lines-ever-zero` (of 57 facility×commodity lines) |
| Frequency each item hits zero | `zero-episode-total`, `zero-episodes-per-line`, `static-zero-episodes`, `public-zero-episodes` |
