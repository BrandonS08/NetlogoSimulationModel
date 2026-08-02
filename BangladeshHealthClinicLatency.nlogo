;; ============================================================================
;; BANGLADESH HEALTH CLINIC INFORMATION LATENCY MODEL — HARDENED BUILD v2
;; ============================================================================
;; Agent-based model of information latency in decentralized NGO health-clinic
;; procurement networks in Bangladesh (NetLogo 7.0.4).
;;
;; CORE MECHANIC (do not "fix"): NGO reorder decisions read the LAGGED,
;; error-corrupted RECORDED-STOCK-LEDGER, never the true STOCK-ON-HAND.
;; The gap between the two is the object of study.
;;
;; IMPORTANT — INTERFACE DEPENDENCY: four globals are defined by Interface
;; widgets, NOT in this file:  grid-failure-rate (slider), info-latency-severity
;; (slider), predictive-modeling? (switch), demand-shocks? (switch).
;; Create those four widgets BEFORE pasting this code, or the compiler will
;; report "Nothing named GRID-FAILURE-RATE". See docs/02-INTERFACE-SETUP.md.
;;
;; STYLE NOTE: every list extraction or reporter call that sits next to an
;; arithmetic operator is wrapped in explicit parentheses, so no expression in
;; this file relies on NetLogo's operator-precedence rules.
;; ============================================================================

breed [ public-ccs      public-cc ]      ;; government Community Clinics (push-supplied, P1-P4)
breed [ ngo-statics     ngo-static ]     ;; NGO static hub clinics (RDF, C1-C3, latency mechanics)
breed [ ngo-satellites  ngo-satellite ]  ;; rotational NGO outreach points (no independent finances)
breed [ private-shops   private-shop ]   ;; informal retail pharmacies (spillover market)
breed [ regional-hubs   regional-hub ]   ;; single-node proxy for CMSD / EDCL / SMC supply layer
breed [ requisitions    requisition ]    ;; short-lived agents: reorder requests in flight

public-ccs-own [
  stock-on-hand      ;; list of 4 numbers: physical units of P1..P4
  zero-flags         ;; list of 4 booleans: is this line currently at zero?
  zero-episodes      ;; list of 4 counts: completed entries into a zero state
  ever-zero          ;; list of 4 booleans: has this line EVER hit zero?
]

ngo-statics-own [
  ;; --- Revolving Drug Fund finances ---
  rdf-capital             ;; SPENDABLE working capital (BDT) — verified sales only
  unverified-revenue      ;; BDT taken at the counter but not yet digitally validated.
                          ;; Paper 2.2.4: "capital legally tied up in medical sales would
                          ;; be useless with the systems required to validate consumption
                          ;; being offline."  This is the financial channel of information
                          ;; latency: an outage freezes purchasing power, not just data.
  rdf-capital-locked?     ;; true while capital cannot buy a minimum viable batch
  days-capital-locked     ;; consecutive days in the locked state

  ;; --- physical vs recorded inventory (THE core mechanic) ---
  stock-on-hand           ;; list of 3: TRUE physical units of C1..C3
  recorded-stock-ledger   ;; list of 3: what the information system BELIEVES
  ledger-snapshot-tick    ;; the day whose reality the ledger currently reflects
                          ;; (ticks - this = ledger age; the clean, trajectory-free
                          ;;  measure of information quality — see docs/05 check 2)
  safety-stock            ;; list of 3: reorder trigger level
  max-stock-capacity      ;; list of 3: order-up-to level
  mean-daily-demand       ;; list of 3: baseline daily demand means (was misnamed average-monthly-cons)
  forecast-daily-demand   ;; list of 3: forecast used only when predictive-modeling? is on
  demand-history          ;; rolling list (max 14 entries) of daily requested-quantity lists
  requested-today         ;; list of 3: units requested from this facility today
  dispensed-today         ;; list of 3: units actually issued today
  paper-error-accum       ;; list of 3: recording error built up while on paper fallback

  ;; --- three-stage latency (paper framework: dispensation, sync, processing) ---
  dispensation-lag        ;; days between physical consumption and digital entry
  sync-lag                ;; additional days from routine batching of uploads
  central-processing-lag  ;; bureaucratic approval days after a reorder triggers

  pending-ledger-updates  ;; queue of (due-tick , stock-snapshot) awaiting sync

  ;; --- connectivity / paper-fallback state machine ---
  manual-fallback?            ;; true while operating on paper registers
  fallback-recovery-countdown ;; behavioral stickiness after reconnection
  last-sync-tick
  is-connected?

  ;; --- procurement state ---
  c2-order-outstanding?   ;; true while a C2 requisition is in flight (prevents duplicate orders)
  c3-order-outstanding?   ;; true while a C3 local purchase is in flight

  ;; --- stockout tracking ---
  zero-flags zero-episodes ever-zero   ;; lists of 3, same semantics as public-ccs
]

ngo-satellites-own [
  parent-hub          ;; the ngo-static this team draws stock from and reports to
  stock-on-hand       ;; list of 3: what the team is carrying TODAY (empty between
                      ;; rollouts). All finances flow through parent-hub.
]

private-shops-own [
  stock-on-hand       ;; list of 3, mirroring C1..C3 so diverted patients map cleanly
]

regional-hubs-own [
  ;; One physical node, three DIFFERENTIATED supply channels (paper 2.2.1, 2.2.3.1).
  smc-c1-stock          ;; SMC Star Network / DGFP push channel: C1 ESP commodities
  ngo-warehouse-stock   ;; SHN central warehouse: C2 retail pharmaceuticals bought from
                        ;; DOMESTIC COMMERCIAL MANUFACTURERS (Square/Incepta/Beximco), then
                        ;; released against clinic requisitions.  NOT the EDCL — EDCL and
                        ;; CMSD serve the public sector only (paper 2.2.1 vs 2.2.3.1).
  public-channel-stock  ;; list of 4: CMSD/EDCL public push channel for P1..P4
  ;; (C3 is bought on the LOCAL wholesale market and never passes through this node.)
]

requisitions-own [
  origin-clinic        ;; the ngo-static that placed the order
  commodity-class      ;; C-class index: 1 = C2, 2 = C3
  order-quantity
  unit-cost
  tick-created
  processing-lag-days  ;; central-processing-lag (C2) or local-procurement-lag (C3)
  source-channel       ;; "ngo-warehouse" or "local-market"
  order-status         ;; "pending" -> "fulfilled" / "partial" / "lost"
]

globals [
  ;; NOTE: grid-failure-rate, info-latency-severity, predictive-modeling?,
  ;; demand-shocks? are Interface widgets and intentionally NOT listed here.

  ;; ---- economics (BDT) ----
  class2-unit-cost class2-retail-price
  class3-unit-cost class3-retail-price
  class1-unit-value p3-unit-value
  c-unit-values            ;; list of 3 procurement values used to price waste
  daily-operating-cost
  donor-recap-amount bailout-threshold-days
  min-batch-days

  ;; ---- network sizes ----
  num-public-ccs num-ngo-statics satellites-per-static num-private-shops

  ;; ---- supply channels & replenishment ----
  warehouse-replenish-interval warehouse-replenish-amount
  public-push-interval public-channel-replenish smc-c1-replenish
  ngo-class1-push-amount
  satellite-pack-size satellite-site-demand private-shop-base-stock
  rollout-days shock-extra-rollout-day

  ;; ---- information / procurement timing ----
  fallback-recovery-lag local-procurement-lag reporting-error-rate
  forecast-window-days demand-history-days
  review-period-months            ;; MSH Box 46-1 maximum-stock formula input

  ;; ---- loss rates ----
  c1-monthly-spoilage-rate c2-monthly-spoilage-rate c2-monthly-shrinkage-rate
  c3-monthly-spoilage-rate coldchain-monthly-loss-rate coldchain-outage-accel

  ;; ---- public facility demand ----
  mean-daily-patients patient-sd p-class-fractions p-to-c-class-map
  higher-care-referral-rate cc-push-target

  ;; ---- geography ----
  cluster-centers

  ;; ---- environmental shocks ----
  shock-active? shock-days-remaining scheduled-shock-day
  shock-duration-min shock-duration-max
  shock-demand-multiplier shock-grid-risk-add total-shock-days

  ;; ---- run control ----
  simulation-length-days

  ;; ---- outcome metrics ----
  ngo-unmet-patients            ;; outcome 1: patients an NGO facility could not serve from stock
  ngo-unmet-own                 ;;   ...of which: the NGO network's own walk-in/satellite patients
  ngo-unmet-diverted            ;;   ...of which: patients diverted in from a public CC stockout
  completely-unserved-patients  ;; patients who got nothing anywhere (NGO and private both failed)
  coldchain-unserved            ;; P3 patients referred to higher care (no NGO/private substitute)
  routine-referrals             ;; ordinary clinical referrals (NOT a supply failure)
  private-rescues               ;; patient-needs absorbed by the informal private market
  total-expired-units total-expired-units-coldchain
  waste-value-total             ;; outcome 2: BDT value of expired/wasted inventory
  reqs-fulfilled-count reqs-partial-count reqs-lost-count
  requisition-log               ;; list of per-requisition outcome rows (gap 4)
  donor-bailouts-total
  avail-line-days total-line-days          ;; running public availability accounting
  facility-stockout-days facility-days     ;; running facility-level stockout accounting
  paper-days-cum                           ;; clinic-days spent on paper fallback
]

;; ============================================================================
;; SETUP
;; ============================================================================

to setup
  clear-all
  setup-parameters
  setup-geography
  setup-public-facilities
  setup-ngo-network
  setup-private-retail
  reset-ticks
end

to setup-parameters
  ;; Source tags:
  ;;  [SPEC]        from the project specification / prior build session
  ;;  [LIT: ...]    calibrated against a named published source
  ;;  [CALIBRATED]  tuned so simulated output reproduces a cited benchmark
  ;;  [ASSUMPTION]  named deliberate assumption; no published figure found

  ;; ---- network sizes (stylized subdistrict; ratios, not national counts) ----
  set num-public-ccs        12     ;; [SPEC]
  set num-ngo-statics       3      ;; [SPEC]
  set satellites-per-static 3      ;; [SPEC] (real ratio far higher: ~323 statics vs ~8,800
                                   ;;  satellites in the Smiling Sun network -> see Limitations)
  set num-private-shops     15     ;; [SPEC]

  ;; ---- economics, BDT ----
  set class2-unit-cost      15     ;; [SPEC]
  set class2-retail-price   22     ;; [SPEC] RDF margin ~47%
  ;; C3 and C1 unit values below come from the commodity price catalogue in the
  ;; author's inventory proof-of-concept (median per-unit BDT within each class),
  ;; which is a price reference only — none of its behavioural parameters are used.
  set class3-unit-cost      8.5    ;; [CATALOGUE] median Consumables & Diagnostics unit price
  set class3-retail-price   12.5   ;; [ASSUMPTION] cost x ~1.47, matching the C2 RDF margin
  set class1-unit-value     11     ;; [CATALOGUE] median MNACH/ESP unit price (waste pricing only)
  set p3-unit-value         100    ;; [CATALOGUE] MR vaccine unit price — corroborates the
                                   ;; value previously assumed for one cold-chain dose
  set c-unit-values         (list class1-unit-value class2-unit-cost class3-unit-cost)
  set daily-operating-cost  0      ;; [PAPER 2.2.3.1] The RDF is strictly ring-fenced: "all
                                   ;; earned capital must be rolled over and strictly contained
                                   ;; within the RDF", and RDF capital "cannot be used for any
                                   ;; means other than drug procurement". Operating costs fall on
                                   ;; the separate general fund (which runs at a loss). An earlier
                                   ;; build charged operations to the RDF; the paper contradicts
                                   ;; that, so it is switched off. Set >0 only to test a scenario
                                   ;; where ring-fencing breaks down.
  set donor-recap-amount    50000  ;; [ASSUMPTION] donor recapitalization grant
  set bailout-threshold-days 30    ;; [ASSUMPTION] locked days before a donor steps in
  set min-batch-days        7      ;; [ASSUMPTION] smallest economically sensible order (days of demand)

  ;; ---- supply channels (gap 1: differentiated CMSD / EDCL / SMC proxies) ----
  set warehouse-replenish-interval 14                      ;; [SPEC]
  set warehouse-replenish-amount   5600                    ;; [CALIBRATED] ~400 units/day vs ~390/day modeled offtake
  set public-push-interval    30                      ;; [SPEC]
  set public-channel-replenish (list 950 3400 650 1300)  ;; [CALIBRATED] ~= 12 CCs x push target + 5%
  set smc-c1-replenish        5000                    ;; [CALIBRATED] covers 3 x ngo-class1-push-amount
  set ngo-class1-push-amount  1600                    ;; [CALIBRATED] was 800; see docs/06-CHANGELOG.md
  ;; ---- satellite outreach rollouts ----
  ;; Satellites do NOT compete with the static for patients; they DRAW STOCK from
  ;; it and run a mini-clinic at an outlying site for a day. What matters for this
  ;; model is that inventory leaves the static's shelf and is consumed off-site.
  ;; Cadence [CATALOGUE]: ~25 coverage sites per static, each visited 1-2x/month,
  ;; teams departing ~10x/week. Here 3 satellite agents x 3 rollout days = 9/week.
  set rollout-days (list 2 3 5)     ;; Tue / Wed / Fri within each 7-day cycle
  set shock-extra-rollout-day 0     ;; monsoon adds a 4th rollout day (~x1.33 frequency;
                                    ;; the catalogue's monsoon factor is ~x1.45)
  ;; Outreach commodity mix is overwhelmingly ESP/MNACH — vitamins, maternal items,
  ;; contraceptives, ORS — plus the consumables needed to administer them. Teams
  ;; are not retail pharmacies, so they carry NO C2.
  set satellite-pack-size   (list 45 0 9)   ;; [ASSUMPTION] units packed per team per rollout
  set satellite-site-demand (list 30 0 6)   ;; [ASSUMPTION] mean units consumed at a site
  set private-shop-base-stock (list 100 600 200)      ;; [SPEC]

  ;; ---- information & procurement timing (days) ----
  set fallback-recovery-lag   7      ;; [PAPER 2.2.4] staff "grow comfortable resorting to manual
                                     ;; paper-based inventory management — even in times of stable
                                     ;; connection", digitising at "end-of-week or even end-of-month
                                     ;; batch logging". End-of-week = 7 days (was 3).
  set local-procurement-lag   2      ;; [ASSUMPTION] local wholesaler delivery time for C3
  set reporting-error-rate    0.08   ;; [ASSUMPTION] share of paper-recorded flow mis-captured.
                                     ;; Still unsourced. For contrast, the paper gives a DIGITAL
                                     ;; error rate after OpenMRS of 200 per 250,000 entries
                                     ;; (0.08%) — which is why digital-mode error is modelled as
                                     ;; zero. Manual error is ~2 orders of magnitude larger here;
                                     ;; the magnitude is the assumption, the direction is not.
  set forecast-window-days    14     ;; [ASSUMPTION] trailing window for demand forecasting
  set demand-history-days     30     ;; [PAPER 2.2.3.1] monthly consumption data drives ordering
  set review-period-months    1      ;; [PAPER 2.2.3.1] review period in the MSH maximum-stock
                                     ;; formula; monthly matches "localized monthly consumption
                                     ;; data" and the pharmacist's "weekly/monthly" reporting duty

  ;; ---- loss rates (monthly fractions) ----
  set c1-monthly-spoilage-rate  0.05   ;; [SPEC]
  set c2-monthly-spoilage-rate  0.05   ;; [SPEC]
  set c2-monthly-shrinkage-rate 0.03   ;; [SPEC]
  set c3-monthly-spoilage-rate  0.025  ;; [ASSUMPTION] reagents/consumables expire more slowly
  set coldchain-monthly-loss-rate 0.01 ;; [ASSUMPTION] storage-loss component only (see Limitations:
                                       ;;  published TOTAL wastage incl. open-vial is 25-46%)
  set coldchain-outage-accel    4      ;; [SPEC] refrigeration loss multiplier under grid stress

  ;; ---- public facility demand ----
  set mean-daily-patients 38           ;; [LIT: WHO/CBHC evaluation 2019 — CC utilization ~40/day by 2016]
  set patient-sd          5            ;; [ASSUMPTION]
  set p-class-fractions   (list 0.15 0.55 0.10 0.20)   ;; [SPEC]
  set p-to-c-class-map    (list 0 1 -1 2)              ;; [SPEC] P3 has no NGO/private substitute
  set higher-care-referral-rate 0.02                   ;; [SPEC]
  set cc-push-target      (list 75 270 50 100)         ;; [CALIBRATED] ~13 days of class demand, so that
                                       ;; average availability ~43% (WHO Bangladesh situational
                                       ;; analysis 2015) and ~50-60% of facility-days have >=1
                                       ;; class stocked out. Verify with the two monitors.

  ;; ---- environmental shocks (monsoon/flood proxy) ----
  set shock-active?           false
  set shock-days-remaining    0
  ;; SHOCK AS AN EXPERIMENTAL FACTOR, not a rare random event.
  ;; The paper studies 90-day periods. At a background rate of ~2 events/year a
  ;; random-onset shock would appear in only ~39% of runs, so a "shocks on" arm
  ;; would be mostly indistinguishable from "shocks off" and the environmental
  ;; half of the research question would be untestable. Instead, demand-shocks?
  ;; = On means this 90-day period CONTAINS one shock (read it as a monsoon
  ;; season), with its ONSET DAY randomised so timing is still stochastic.
  ;; This controls shock presence and randomises shock timing — the standard
  ;; way to make a rare event analysable in a short observation window.
  set scheduled-shock-day (1 + random (max (list 1 (simulation-length-days - shock-duration-max))))
  set shock-duration-min      7           ;; [SPEC]
  set shock-duration-max      21          ;; [SPEC]
  set shock-demand-multiplier 1.8         ;; [SPEC]
  set shock-grid-risk-add     0.25        ;; [SPEC]
  set total-shock-days        0

  ;; ---- run control ----
  set simulation-length-days 90           ;; [PAPER Section I] "track and record data over 90 day
                                          ;; simulation periods". NOTE: at the paper's shock rate
                                          ;; of ~2/year, only ~39% of 90-day runs contain a shock
                                          ;; at all — see docs/09 for how to handle this.

  ;; ---- metrics ----
  set ngo-unmet-patients 0
  set ngo-unmet-own 0
  set ngo-unmet-diverted 0
  set completely-unserved-patients 0
  set coldchain-unserved 0
  set routine-referrals 0
  set private-rescues 0
  set total-expired-units 0
  set total-expired-units-coldchain 0
  set waste-value-total 0
  set reqs-fulfilled-count 0
  set reqs-partial-count 0
  set reqs-lost-count 0
  set requisition-log []
  set donor-bailouts-total 0
  set avail-line-days 0
  set total-line-days 0
  set facility-stockout-days 0
  set facility-days 0
  set paper-days-cum 0
end

to setup-geography
  resize-world -15 15 -15 15
  set-patch-size 16
  ask patches [ set pcolor 61 ]

  create-regional-hubs 1 [
    set shape "square"
    set color blue
    set size 2.5
    setxy 0 0
    set smc-c1-stock 5000
    set ngo-warehouse-stock 10000
    set public-channel-stock (list 950 3400 650 1300)
  ]

  ;; two stylized population clusters (uneven facility distribution, Section 2.x)
  set cluster-centers (list (patch 8 8) (patch -8 -7))
end

to move-to-stylized-location [ min-dist-from-hub ]
  ;; 55% of facilities land inside a population cluster, the rest disperse.
  ;; Robust fallbacks guarantee this can never crash on an empty patch set.
  let pool no-patches
  ifelse (random-float 1.0) < 0.55
    [ let anchor one-of cluster-centers
      set pool patches with [
        ((distance anchor) < 6) and
        ((distancexy 0 0) > min-dist-from-hub) and
        (not any? turtles-here) ] ]
    [ set pool patches with [
        ((distancexy 0 0) > min-dist-from-hub) and
        ((distancexy 0 0) < (max-pxcor - 1)) and
        (not any? turtles-here) and
        ((distance (item 0 cluster-centers)) > 5) and
        ((distance (item 1 cluster-centers)) > 5) ] ]
  if not any? pool [
    set pool patches with [ ((distancexy 0 0) > min-dist-from-hub) and (not any? turtles-here) ] ]
  if not any? pool [
    set pool patches with [ not any? turtles-here ] ]
  move-to one-of pool
end

to setup-public-facilities
  create-public-ccs num-public-ccs [
    set shape "circle"
    set color red
    set size 1.2
    move-to-stylized-location 3
    set stock-on-hand cc-push-target        ;; start freshly pushed
    set zero-flags    (list false false false false)
    set zero-episodes (list 0 0 0 0)
    set ever-zero     (list false false false false)
  ]
end

to setup-ngo-network
  create-ngo-statics num-ngo-statics [
    set shape "house"
    set color green
    set size 1.8
    move-to-stylized-location 5

    ;; [PAPER 2.2.3.1] SHN's RDF was ~241 MILLION Taka in 2024, across 134 permanent
    ;; registered facilities => ~1.8 million Taka of revolving capital per static
    ;; clinic. An earlier build used 241,000 per clinic, understating it ~7.5x.
    set rdf-capital 1798000
    set unverified-revenue 0
    set rdf-capital-locked? false
    set days-capital-locked 0

    set stock-on-hand         (list 800 1500 500)    ;; [SPEC]
    set recorded-stock-ledger (list 800 1500 500)
    set ledger-snapshot-tick  0
    set safety-stock          (list 200 400 150)     ;; [SPEC]
    set max-stock-capacity    (list 1200 2500 800)   ;; [SPEC]

    set mean-daily-demand     (list 25 55 22)        ;; [SPEC]
    set forecast-daily-demand mean-daily-demand
    ;; seeded with a full month at the baseline rate so Average Monthly Consumption
    ;; is well-defined from day 1 (a 90-day run has no time for a warm-up period)
    set demand-history        (n-values demand-history-days [ -> mean-daily-demand ])
    set requested-today       (list 0 0 0)
    set dispensed-today       (list 0 0 0)
    set paper-error-accum     (list 0 0 0)

    set dispensation-lag       1    ;; [SPEC] paper framework stage 1
    set sync-lag               2    ;; [SPEC] paper framework stage 2
    set central-processing-lag 2    ;; [SPEC] paper framework stage 3

    set pending-ledger-updates []
    set manual-fallback? false
    set fallback-recovery-countdown 0
    set last-sync-tick 0
    set is-connected? true

    set c2-order-outstanding? false
    set c3-order-outstanding? false

    set zero-flags    (list false false false)
    set zero-episodes (list 0 0 0)
    set ever-zero     (list false false false)
  ]

  ask ngo-statics [
    let my-hub self
    hatch-ngo-satellites satellites-per-static [
      set shape "triangle"
      set color lime
      set size 1.0
      set parent-hub my-hub

      let spot one-of patches in-radius 4 with [ (not any? turtles-here) and ((distance my-hub) > 1) ]
      if spot = nobody [ set spot one-of patches in-radius 4 with [ not any? turtles-here ] ]
      if spot != nobody [ move-to spot ]
      create-link-from my-hub [ set color green - 2 set thickness 0.2 ]

      set stock-on-hand (list 0 0 0)   ;; empty between rollouts: teams carry stock, they don't hold it
    ]
  ]
end

to setup-private-retail
  create-private-shops num-private-shops [
    set shape "box"
    set color yellow
    set size 1.0
    let target-clinic one-of (turtle-set public-ccs ngo-statics ngo-satellites)
    move-to one-of [ patches in-radius 3 ] of target-clinic
    set stock-on-hand private-shop-base-stock
  ]
end

;; ============================================================================
;; MAIN LOOP — one tick = one day
;; ============================================================================

to go
  if ticks >= simulation-length-days [ stop ]

  reset-daily-trackers
  update-demand-shocks
  update-connectivity
  apply-physical-spoilage-and-shrinkage

  process-public-demand
  process-ngo-static-demand
  run-satellite-rollouts
  track-zero-stock

  update-ledger-visibility
  process-manual-paper-fallback
  update-demand-forecast

  apply-operating-costs
  process-capital-lock-and-bailouts
  process-ngo-reorders
  process-pending-requisitions

  ;; measured BEFORE replenishment, so availability reflects what patients
  ;; actually faced during the day rather than the post-delivery shelf
  update-running-metrics

  run-replenishment-cycles
  record-demand-history

  tick
end

to reset-daily-trackers
  ask ngo-statics [
    set requested-today (list 0 0 0)
    set dispensed-today (list 0 0 0)
  ]
end

;; ============================================================================
;; ENVIRONMENTAL SHOCKS & CONNECTIVITY
;; ============================================================================

to update-demand-shocks
  ifelse shock-active?
    [ set shock-days-remaining (shock-days-remaining - 1)
      if shock-days-remaining <= 0 [ set shock-active? false ] ]
    [ if demand-shocks? and (ticks = scheduled-shock-day) [
        set shock-active? true
        ;; +1 makes shock-duration-max attainable (an earlier build had an off-by-one)
        set shock-days-remaining (shock-duration-min + random ((shock-duration-max - shock-duration-min) + 1))
      ] ]
  ;; counted after the state machine settles, so the first day of a shock is
  ;; included (the base build's equivalent counter missed one day per event)
  if shock-active? [ set total-shock-days (total-shock-days + 1) ]
end

to-report effective-grid-failure-rate
  ifelse shock-active?
    [ report min (list 1.0 (grid-failure-rate + shock-grid-risk-add)) ]
    [ report grid-failure-rate ]
end

to-report shock-multiplier
  ifelse shock-active? [ report shock-demand-multiplier ] [ report 1 ]
end

to update-connectivity
  ask ngo-statics [
    let was-connected? is-connected?
    set is-connected? ((random-float 1.0) >= effective-grid-failure-rate)
    ;; on reconnection, staff keep using paper registers for a few days
    if (not was-connected?) and is-connected? and manual-fallback? [
      set fallback-recovery-countdown fallback-recovery-lag
    ]
  ]
end

;; ============================================================================
;; PHYSICAL LOSSES (waste channel — outcome metric 2)
;; ============================================================================

;; Integer rounding of tiny daily fractions would floor them to zero forever
;; (in the base build the cold-chain waste counter could NEVER increment for
;; realistic stock sizes).  Stochastic rounding preserves the expected value:
;; 0.4 expected units/day becomes one whole unit on ~40% of days.
to-report stochastic-round [ x ]
  let whole floor x
  ifelse (random-float 1.0) < (x - whole)
    [ report whole + 1 ]
    [ report whole ]
end

to apply-physical-spoilage-and-shrinkage
  ask ngo-statics [
    let losses (list
      (stochastic-round ((item 0 stock-on-hand) * (c1-monthly-spoilage-rate / 30)))
      (stochastic-round ((item 1 stock-on-hand) * ((c2-monthly-spoilage-rate + c2-monthly-shrinkage-rate) / 30)))
      (stochastic-round ((item 2 stock-on-hand) * (c3-monthly-spoilage-rate / 30))))
    (foreach (list 0 1 2) losses [ [ c-idx loss ] ->
      if loss > 0 [
        set stock-on-hand replace-item c-idx stock-on-hand (max (list 0 ((item c-idx stock-on-hand) - loss)))
        set total-expired-units (total-expired-units + loss)
        set waste-value-total (waste-value-total + (loss * (item c-idx c-unit-values)))
      ]
    ])
  ]

  ;; public cold-chain (P3): storage losses accelerate under grid stress
  ask public-ccs [
    let p3-stock (item 2 stock-on-hand)
    let accel ifelse-value (effective-grid-failure-rate > 0.3) [ coldchain-outage-accel ] [ 1 ]
    let p3-loss stochastic-round (p3-stock * ((coldchain-monthly-loss-rate * accel) / 30))
    if p3-loss > 0 [
      set stock-on-hand replace-item 2 stock-on-hand (max (list 0 (p3-stock - p3-loss)))
      set total-expired-units-coldchain (total-expired-units-coldchain + p3-loss)
      set waste-value-total (waste-value-total + (p3-loss * p3-unit-value))
    ]
  ]
end

;; ============================================================================
;; PATIENT DEMAND & THE DIVERSION CASCADE
;; public CC -> mapped NGO class (nearest static/satellite) -> private shop
;; -> counted as completely unserved.  P3 (cold chain) has no substitute and
;; becomes a higher-care referral instead.
;; ============================================================================

to process-public-demand
  ask public-ccs [
    let total-patients max (list 0 (round (random-normal mean-daily-patients patient-sd)))
    ;; routine clinical referrals leave before commodities are drawn
    ;; (the base build double-counted them as commodity demand)
    let referred round (total-patients * higher-care-referral-rate)
    set routine-referrals (routine-referrals + referred)
    let seeking (total-patients - referred)

    let needs (map [ f -> round (seeking * f * shock-multiplier) ] p-class-fractions)
    (foreach (list 0 1 2 3) needs [ [ p-idx need ] ->
      if need > 0 [
        let avail (item p-idx stock-on-hand)
        ifelse avail >= need
          [ set stock-on-hand replace-item p-idx stock-on-hand (avail - need) ]
          [ set stock-on-hand replace-item p-idx stock-on-hand 0
            divert-public-patient (need - avail) p-idx ]
      ]
    ])
  ]
end

to divert-public-patient [ patient-count p-idx ]   ;; runs as a public-cc
  let c-idx (item p-idx p-to-c-class-map)
  ifelse c-idx = -1
    [ ;; P3 cold chain: no NGO or private substitute exists — refer upward
      set coldchain-unserved (coldchain-unserved + patient-count) ]
    [ let remaining patient-count
      let nearest-ngo min-one-of ngo-statics [ distance myself ]
      if nearest-ngo != nobody [
        ask nearest-ngo [ set remaining (serve-from-stock c-idx remaining) ]
      ]
      if remaining > 0 [
        set ngo-unmet-patients (ngo-unmet-patients + remaining)
        set ngo-unmet-diverted (ngo-unmet-diverted + remaining)
        set remaining (send-to-private remaining c-idx)
      ]
      if remaining > 0 [
        set completely-unserved-patients (completely-unserved-patients + remaining)
      ]
    ]
end

;; Serve AMOUNT units of class C-IDX from THIS NGO facility's physical stock.
;; Runs in the serving facility's own context (callers use ASK to switch to it).
;; Credits RDF revenue for paid classes (C2 retail, C3 user fee) — satellites
;; credit their parent hub.  Reports the UNFILLED remainder.
to-report serve-from-stock [ c-idx amount ]
  let avail (item c-idx stock-on-hand)
  let issued min (list avail amount)
  note-facility-flow c-idx amount issued
  if issued > 0 [
    set stock-on-hand replace-item c-idx stock-on-hand (avail - issued)
    credit-ngo-revenue c-idx issued
  ]
  report (amount - issued)
end

to note-facility-flow [ c-idx requested issued ]   ;; runs as an NGO facility
  ;; only statics keep daily books; satellite flows reach the hub's books
  ;; later, through the weekly restocking pull
  if breed = ngo-statics [
    set requested-today replace-item c-idx requested-today ((item c-idx requested-today) + requested)
    set dispensed-today replace-item c-idx dispensed-today ((item c-idx dispensed-today) + issued)
  ]
end

to credit-ngo-revenue [ c-idx units ]   ;; runs as an NGO facility
  if units <= 0 [ stop ]
  let price 0
  if c-idx = 1 [ set price class2-retail-price ]   ;; C2: RDF retail sale
  if c-idx = 2 [ set price class3-retail-price ]   ;; C3: diagnostics user fee
  if price = 0 [ stop ]                            ;; C1 is free (public ESP commodity)
  ;; Revenue is booked as UNVERIFIED. It becomes spendable RDF capital only when
  ;; the clinic's sales data reaches the system (see release-verified-revenue).
  ifelse breed = ngo-satellites
    [ let hub parent-hub
      ask hub [ set unverified-revenue (unverified-revenue + (units * price)) ] ]
    [ set unverified-revenue (unverified-revenue + (units * price)) ]
end

;; Called at each successful sync (digital or paper reconciliation): validated
;; sales convert into spendable capital.  While a clinic is offline this does not
;; run, so takings accumulate but cannot fund a requisition.
to release-verified-revenue   ;; runs as an ngo-static
  set rdf-capital (rdf-capital + unverified-revenue)
  set unverified-revenue 0
end

;; Spillover into the informal private market.  Reports the still-unserved
;; remainder.  Shops restock weekly (deep wholesale market assumption).
to-report send-to-private [ amount c-idx ]
  let nearest-shop min-one-of private-shops [ distance myself ]
  if nearest-shop = nobody [ report amount ]
  let avail [ item c-idx stock-on-hand ] of nearest-shop
  let sold min (list avail amount)
  if sold > 0 [
    ask nearest-shop [ set stock-on-hand replace-item c-idx stock-on-hand (avail - sold) ]
    set private-rescues (private-rescues + sold)
  ]
  report (amount - sold)
end

to process-ngo-static-demand
  ask ngo-statics [
    let m shock-multiplier
    let needs (list
      (max (list 0 (round ((random-normal (item 0 mean-daily-demand) 5) * m))))
      (max (list 0 (round ((random-normal (item 1 mean-daily-demand) 8) * m))))
      (max (list 0 (round ((random-normal (item 2 mean-daily-demand) 4) * m)))))
    (foreach (list 0 1 2) needs [ [ c-idx need ] ->
      if need > 0 [
        let unfilled (serve-from-stock c-idx need)
        if unfilled > 0 [
          set ngo-unmet-patients (ngo-unmet-patients + unfilled)
          set ngo-unmet-own (ngo-unmet-own + unfilled)
          let still-unserved (send-to-private unfilled c-idx)
          if still-unserved > 0 [
            set completely-unserved-patients (completely-unserved-patients + still-unserved) ]
        ]
      ]
    ])
  ]
end

;; ---------------------------------------------------------------------------
;; SATELLITE OUTREACH ROLLOUTS
;;
;; A satellite is not a standing clinic with its own patient stream competing
;; with the static. It is a team that, on rollout days, LOADS STOCK FROM THE
;; STATIC, travels to an outlying site, runs a mini-clinic for the day, and
;; brings the remainder back. The mechanism that matters here is that inventory
;; leaves the static's shelf and is consumed off-site.
;;
;; This is also a latency amplifier, which is why it belongs in this model: the
;; static's books show the whole pack issued at departure, and only reconcile
;; against what was actually used when the team returns.
;; ---------------------------------------------------------------------------

to-report rollout-day?
  let day (ticks mod 7)
  if member? day rollout-days [ report true ]
  ;; monsoon conditions push more teams into the field
  report (shock-active? and (day = shock-extra-rollout-day))
end

to run-satellite-rollouts
  if not rollout-day? [ stop ]
  ask ngo-satellites [
    ;; --- load out from the parent static ---
    let loaded (list 0 0 0)
    let hub parent-hub
    (foreach (list 0 1 2) satellite-pack-size [ [ c-idx want ] ->
      if want > 0 [
        let taken 0
        ask hub [
          let avail (item c-idx stock-on-hand)
          set taken min (list avail want)
          if taken > 0 [
            set stock-on-hand replace-item c-idx stock-on-hand (avail - taken)
            ;; the static books the whole pack as issued the moment it departs
            note-facility-flow c-idx want taken
          ]
        ]
        set loaded replace-item c-idx loaded taken
      ]
    ])
    set stock-on-hand loaded

    ;; --- run the mini-clinic for the day ---
    let m shock-multiplier
    (foreach (list 0 1 2) satellite-site-demand [ [ c-idx mean-need ] ->
      if mean-need > 0 [
        let need max (list 0 (round ((random-normal mean-need (mean-need / 4)) * m)))
        if need > 0 [
          let unfilled (serve-from-stock c-idx need)
          if unfilled > 0 [
            ;; an outreach site has no pharmacy next door: unmet need at a
            ;; rollout is simply unmet, and the patient is not counted as
            ;; rescued by the private market
            set ngo-unmet-patients (ngo-unmet-patients + unfilled)
            set ngo-unmet-own (ngo-unmet-own + unfilled)
            set completely-unserved-patients (completely-unserved-patients + unfilled)
          ]
        ]
      ]
    ])

    ;; --- return the remainder to the static ---
    (foreach (list 0 1 2) [ c-idx ->
      let left (item c-idx stock-on-hand)
      if left > 0 [
        ask hub [
          set stock-on-hand replace-item c-idx stock-on-hand ((item c-idx stock-on-hand) + left)
          ;; the return credit reverses the over-issue booked at departure
          set requested-today replace-item c-idx requested-today
              (max (list 0 ((item c-idx requested-today) - left)))
          set dispensed-today replace-item c-idx dispensed-today
              (max (list 0 ((item c-idx dispensed-today) - left)))
        ]
        set stock-on-hand replace-item c-idx stock-on-hand 0
      ]
    ])
  ]
end

;; ============================================================================
;; STOCKOUT EPISODE TRACKING (outcome metrics 3 & 4)
;; A "line" is one commodity class at one facility.  An episode begins when a
;; line goes from positive stock to zero (checked once daily, after demand).
;; ============================================================================

;; Satellites are deliberately EXCLUDED: they hold nothing between rollouts, so
;; an empty satellite is normal operation, not a stockout. Their supply failures
;; are captured where they belong — as unmet outreach patients in ngo-unmet-own.
;; Tracked lines: (12 public CCs x 4 classes) + (3 statics x 3 classes) = 57.
to track-zero-stock
  ask (turtle-set public-ccs ngo-statics) [ update-zero-tracking ]
end

to update-zero-tracking   ;; runs as any facility
  foreach (range (length stock-on-hand)) [ i ->
    ifelse (item i stock-on-hand) <= 0
      [ if not (item i zero-flags) [
          set zero-flags    replace-item i zero-flags true
          set zero-episodes replace-item i zero-episodes ((item i zero-episodes) + 1)
          set ever-zero     replace-item i ever-zero true
        ] ]
      [ set zero-flags replace-item i zero-flags false ]
  ]
end

;; ============================================================================
;; THE INFORMATION LAYER (core of the research question)
;;
;; Connected + digital: each day's true closing stock enters a sync queue and
;; becomes visible to the ledger only (dispensation-lag + sync-lag) x severity
;; days later.  The ledger is therefore permanently STALE, never wrong-on-
;; purpose.
;;
;; Disconnected (or still in the sticky paper-fallback period): NOTHING is
;; revealed to the ledger at all — it stays frozen at its last synced value
;; while true stock keeps moving, so the gap WIDENS with outage length.
;; Meanwhile error accumulates in the paper registers in proportion to actual
;; dispensing volume (missed entries overstate remaining stock).
;;
;; Recovery: after reconnection the clinic keeps using paper for
;; fallback-recovery-lag days (behavioral stickiness).  Then the paper backlog
;; is entered in one batch: ledger = true stock + accumulated paper error.
;; The digital pipeline restarts and washes the residual error out only after
;; another full sync delay.
;; ============================================================================

to update-ledger-visibility
  ask ngo-statics [
    if is-connected? and (not manual-fallback?) [
      let total-lag ((dispensation-lag + sync-lag) * info-latency-severity)
      ;; each queued entry is (due-tick , stock-snapshot , tick-the-snapshot-was-taken)
      set pending-ledger-updates lput (list (ticks + total-lag) stock-on-hand ticks) pending-ledger-updates
      let ready filter [ u -> (item 0 u) <= ticks ] pending-ledger-updates
      if not empty? ready [
        set recorded-stock-ledger (item 1 (last ready))
        set ledger-snapshot-tick (item 2 (last ready))
        set pending-ledger-updates filter [ u -> (item 0 u) > ticks ] pending-ledger-updates
        set last-sync-tick ticks
        release-verified-revenue
      ]
    ]
  ]
end

to process-manual-paper-fallback
  ask ngo-statics [
    ifelse not is-connected?
      [ set manual-fallback? true
        accumulate-paper-error ]
      [ if manual-fallback? [
          ifelse fallback-recovery-countdown > 0
            [ set fallback-recovery-countdown (fallback-recovery-countdown - 1)
              accumulate-paper-error ]
            [ ;; backlog data entry: paper registers (with their errors) become the ledger
              set recorded-stock-ledger (map [ [ tru err ] -> max (list 0 (round (tru + err))) ]
                                             stock-on-hand paper-error-accum)
              set paper-error-accum (list 0 0 0)
              set pending-ledger-updates []      ;; stale in-flight snapshots are superseded
              set manual-fallback? false
              set last-sync-tick ticks
              ;; the backlog is current as of today — accurate in DATE, but still
              ;; carrying the paper error in its VALUES
              set ledger-snapshot-tick ticks
              release-verified-revenue ]
        ] ]
  ]
end

to accumulate-paper-error   ;; runs as an ngo-static
  ;; missed paper entries scale with the volume actually dispensed that day;
  ;; the bias is positive: unrecorded dispensing makes the system believe MORE
  ;; stock remains than truly does
  set paper-error-accum (map [ [ err disp ] -> err + (disp * reporting-error-rate * info-latency-severity) ]
                             paper-error-accum dispensed-today)
end

;; ---------- demand forecasting (predictive-modeling? arm) ----------

to record-demand-history
  ask ngo-statics [
    set demand-history lput requested-today demand-history
    ;; 30 days retained: the full window feeds Average Monthly Consumption in the
    ;; maximum-stock formula, the most recent 14 feed the predictive forecast
    if (length demand-history) > demand-history-days [
      set demand-history but-first demand-history ]
  ]
end

;; the most recent FORECAST-WINDOW-DAYS entries of the consumption history
to-report recent-demand-history   ;; runs as an ngo-static
  let n (length demand-history)
  let w min (list n forecast-window-days)
  report sublist demand-history (n - w) n
end

to update-demand-forecast
  ;; Weekly refresh: trailing mean of OBSERVED demand (patient flow is visible
  ;; on paper day-to-day even when the stock ledger lags) with a narrow noise
  ;; band.  Used ONLY for reorder TIMING when predictive-modeling? is on —
  ;; order QUANTITIES still come from the lagged ledger, by design.
  if (ticks mod 7) = 0 [
    ask ngo-statics [
      let recent recent-demand-history
      set forecast-daily-demand (list
        ((mean (map [ d -> item 0 d ] recent)) * (0.95 + random-float 0.10))
        ((mean (map [ d -> item 1 d ] recent)) * (0.95 + random-float 0.10))
        ((mean (map [ d -> item 2 d ] recent)) * (0.95 + random-float 0.10)))
    ]
  ]
end

;; ============================================================================
;; RDF FINANCES & PROCUREMENT
;; ============================================================================

to apply-operating-costs
  ;; staff/overhead share funded from the RDF margin; keeps the decapitalization
  ;; failure mode reachable (see docs/06-CHANGELOG.md, change N1)
  ask ngo-statics [
    set rdf-capital max (list 0 (rdf-capital - daily-operating-cost))
  ]
end

to process-capital-lock-and-bailouts
  ask ngo-statics [
    ;; locked = cannot afford even a minimum viable batch of C2
    set rdf-capital-locked? (rdf-capital < ((minimum-c2-batch) * class2-unit-cost))
    ifelse rdf-capital-locked?
      [ set days-capital-locked (days-capital-locked + 1)
        if days-capital-locked >= bailout-threshold-days [
          set rdf-capital (rdf-capital + donor-recap-amount)
          set donor-bailouts-total (donor-bailouts-total + 1)
          set days-capital-locked 0
        ] ]
      [ set days-capital-locked 0 ]
  ]
end

to-report minimum-c2-batch   ;; runs as an ngo-static
  report round (min-batch-days * (item 1 mean-daily-demand))
end

;; Average Monthly Consumption, computed from the clinic's own OBSERVED demand
;; history — "localized monthly consumption data" (paper 2.2.3.1, citing MSH).
to-report average-monthly-consumption [ c-idx ]
  report ((mean (map [ d -> item c-idx d ] demand-history)) * 30)
end

;; THE MAXIMUM STOCK APPROACH — the order-quantity rule the paper specifies:
;;   Order Quantity = (Average Monthly Consumption x Review Period)
;;                    + Safety Stock - Stock On Hand      (MSH 46.8, Box 46-1)
;;
;; "Stock On Hand" is deliberately read from RECORDED-STOCK-LEDGER, not from
;; true stock.  That substitution is the entire research design: the formula is
;; correct, the number fed into it is stale, and the resulting order is wrong
;; by exactly the size of the information gap.
;;
;; The result is floored at zero (a clinic that believes it is over-stocked
;; orders nothing) and capped by physical storage capacity.
to-report max-stock-order-quantity [ c-idx ]
  let amc (average-monthly-consumption c-idx)
  let believed (item c-idx recorded-stock-ledger)
  let raw ((amc * review-period-months) + (item c-idx safety-stock) - believed)
  let storage-room ((item c-idx max-stock-capacity) - believed)
  report max (list 0 (round (min (list raw storage-room))))
end

;; Reorder decisions.  DELIBERATE: both the trigger and the order quantity read
;; RECORDED-STOCK-LEDGER (the lagged, possibly corrupted belief), never
;; STOCK-ON-HAND.  Predictive modeling changes only WHEN an order fires (it
;; projects forecast demand over the pipeline horizon); it cannot repair the
;; ledger itself — that separation is the research design.
to process-ngo-reorders
  ask ngo-statics [
    ;; ---- C2: RDF pharmaceuticals via the EDCL/wholesale hub channel ----
    if (not c2-order-outstanding?) and (not rdf-capital-locked?) [
      if (reorder-triggered? 1) [
        let desired (max-stock-order-quantity 1)
        let affordable floor (rdf-capital / class2-unit-cost)
        let qty min (list desired affordable)
        if qty > 0 [
          place-requisition 1 qty class2-unit-cost central-processing-lag "ngo-warehouse"
          set c2-order-outstanding? true
        ]
      ]
    ]
    ;; ---- C3: diagnostics/consumables bought on the LOCAL wholesale market ----
    ;; (gap 3 fix: RDF-funded local purchase, short lead time, no central approval)
    ;; The capital lock applies here too: a decapitalized clinic freezes ALL
    ;; procurement, otherwise cheap C3 buying would drain the cash it needs to
    ;; climb back out of the lock.
    if (not c3-order-outstanding?) and (not rdf-capital-locked?) [
      if (reorder-triggered? 2) [
        let desired (max-stock-order-quantity 2)
        let affordable floor (rdf-capital / class3-unit-cost)
        let qty min (list desired affordable)
        if qty > 0 [
          place-requisition 2 qty class3-unit-cost local-procurement-lag "local-market"
          set c3-order-outstanding? true
        ]
      ]
    ]
  ]
end

to-report reorder-triggered? [ c-idx ]   ;; runs as an ngo-static
  let believed (item c-idx recorded-stock-ledger)
  let trigger-level (item c-idx safety-stock)
  ifelse predictive-modeling?
    [ let fc (item c-idx forecast-daily-demand)
      report (believed - (fc * (projection-horizon c-idx))) <= trigger-level ]
    [ report believed <= trigger-level ]
end

to-report projection-horizon [ c-idx ]   ;; runs as an ngo-static
  ;; the clinic knows its own institutional delays and projects demand across
  ;; them: procurement lead time + how stale it knows its data to be
  let staleness ((dispensation-lag + sync-lag) * info-latency-severity)
  let lead ifelse-value (c-idx = 1) [ central-processing-lag ] [ local-procurement-lag ]
  report (lead + staleness)
end

to place-requisition [ c-idx qty cost-per lag-days source ]   ;; runs as an ngo-static
  hatch-requisitions 1 [
    set shape "default"
    set color white
    set size 0.6
    set origin-clinic myself
    set commodity-class c-idx
    set order-quantity qty
    set unit-cost cost-per
    set tick-created ticks
    set processing-lag-days lag-days
    set source-channel source
    set order-status "pending"
  ]
end

to process-pending-requisitions
  ask requisitions with [ order-status = "pending" ] [
    if (ticks - tick-created) >= processing-lag-days [
      let clinic origin-clinic
      let c-idx commodity-class
      let qty order-quantity
      let cost-per unit-cost
      let hub one-of regional-hubs

      ;; supply constraint: the hub channel can ration; the local wholesale
      ;; market is treated as unconstrained (documented assumption)
      let supply-cap qty
      if source-channel = "ngo-warehouse" [ set supply-cap [ ngo-warehouse-stock ] of hub ]
      ;; financial constraint re-checked at delivery time
      let affordable floor (([ rdf-capital ] of clinic) / cost-per)
      let shipped max (list 0 (min (list qty supply-cap affordable)))

      ifelse shipped > 0
        [ if source-channel = "ngo-warehouse" [
            ask hub [ set ngo-warehouse-stock (ngo-warehouse-stock - shipped) ] ]
          ask clinic [
            set stock-on-hand replace-item c-idx stock-on-hand ((item c-idx stock-on-hand) + shipped)
            set rdf-capital (rdf-capital - (shipped * cost-per))
          ]
          ifelse shipped = qty
            [ set order-status "fulfilled"
              set reqs-fulfilled-count (reqs-fulfilled-count + 1) ]
            [ set order-status "partial"
              set reqs-partial-count (reqs-partial-count + 1) ] ]
        [ set order-status "lost"
          set reqs-lost-count (reqs-lost-count + 1) ]

      ;; gap 4 fix: every terminal outcome is logged for later analysis
      set requisition-log lput (list tick-created ticks ([ who ] of clinic)
                                     (word "C" (c-idx + 1)) qty shipped order-status)
                               requisition-log

      ;; the clinic knows its own order was resolved (no connectivity needed —
      ;; goods either arrived or a rejection notice came back)
      ask clinic [
        ifelse c-idx = 1
          [ set c2-order-outstanding? false ]
          [ set c3-order-outstanding? false ]
      ]
      die
    ]
  ]
end

;; ============================================================================
;; REPLENISHMENT CYCLES (push channels, satellites, private market)
;; ============================================================================

to run-replenishment-cycles
  ;; EDCL/wholesale C2 channel restocks every 14 days
  if (ticks > 0) and ((ticks mod warehouse-replenish-interval) = 0) [
    ask regional-hubs [ set ngo-warehouse-stock (ngo-warehouse-stock + warehouse-replenish-amount) ]
  ]

  ;; monthly: channel deliveries arrive, then the rigid top-down pushes go out
  if (ticks > 0) and ((ticks mod public-push-interval) = 0) [
    ask regional-hubs [
      set public-channel-stock (map [ [ cur add ] -> cur + add ] public-channel-stock public-channel-replenish)
      set smc-c1-stock (smc-c1-stock + smc-c1-replenish)
    ]
    run-public-push
    run-ngo-c1-push
  ]

  ;; weekly private-market restock (satellite rollouts run in the demand phase)
  if (ticks > 0) and ((ticks mod 7) = 0) [ restock-private-shops ]
end

to-report push-need [ p-idx ]   ;; runs as a public-cc
  report max (list 0 ((item p-idx cc-push-target) - (item p-idx stock-on-hand)))
end

to run-public-push
  ;; base-build bug fix: pushes now actually DRAW DOWN the public channel, and
  ;; are rationed proportionally when the channel cannot cover total need
  let hub one-of regional-hubs
  foreach (list 0 1 2 3) [ p-idx ->
    let total-need sum [ push-need p-idx ] of public-ccs
    let avail [ item p-idx public-channel-stock ] of hub
    let ration-factor 1.0
    if total-need > 0 [ set ration-factor min (list 1.0 (avail / total-need)) ]
    let shipped-total sum [ floor ((push-need p-idx) * ration-factor) ] of public-ccs
    ask public-ccs [
      let grant floor ((push-need p-idx) * ration-factor)
      if grant > 0 [
        set stock-on-hand replace-item p-idx stock-on-hand ((item p-idx stock-on-hand) + grant) ]
    ]
    ask hub [
      set public-channel-stock replace-item p-idx public-channel-stock
          (max (list 0 ((item p-idx public-channel-stock) - shipped-total)))
    ]
  ]
end

to run-ngo-c1-push
  ;; SMC/donor C1 push to NGO statics, rationed the same way
  let hub one-of regional-hubs
  let total-need (ngo-class1-push-amount * (count ngo-statics))
  let avail [ smc-c1-stock ] of hub
  let ration-factor 1.0
  if total-need > 0 [ set ration-factor min (list 1.0 (avail / total-need)) ]
  let grant floor (ngo-class1-push-amount * ration-factor)
  if grant > 0 [
    ask ngo-statics [
      set stock-on-hand replace-item 0 stock-on-hand ((item 0 stock-on-hand) + grant) ]
    ask hub [ set smc-c1-stock max (list 0 (smc-c1-stock - (grant * (count ngo-statics)))) ]
  ]
end

to restock-private-shops
  ;; deep informal wholesale market assumption: shops fully restock weekly
  ask private-shops [ set stock-on-hand private-shop-base-stock ]
end

;; ============================================================================
;; RUNNING METRICS & REPORTERS (monitors, plots, BehaviorSpace)
;; ============================================================================

to update-running-metrics
  set avail-line-days (avail-line-days + (sum [ length filter [ s -> s > 0 ] stock-on-hand ] of public-ccs))
  set total-line-days (total-line-days + (4 * (count public-ccs)))
  set facility-stockout-days (facility-stockout-days
      + (count public-ccs with [ not empty? filter [ s -> s <= 0 ] stock-on-hand ]))
  set facility-days (facility-days + (count public-ccs))
  set paper-days-cum (paper-days-cum + (count ngo-statics with [ manual-fallback? ]))
end

;; ---- outcome metrics 3 & 4 ----
to-report lines-ever-zero
  report sum [ length filter [ b -> b ] ever-zero ] of (turtle-set public-ccs ngo-statics)
end

to-report zero-episode-total
  report sum [ sum zero-episodes ] of (turtle-set public-ccs ngo-statics)
end

to-report zero-episodes-per-line
  let n sum [ length zero-episodes ] of (turtle-set public-ccs ngo-statics)
  ifelse n > 0 [ report (zero-episode-total / n) ] [ report 0 ]
end

to-report ngo-zero-episodes [ c-idx ]
  report sum [ item c-idx zero-episodes ] of ngo-statics
end

;; Decomposition of outcome metric 4 by facility type.  The headline total is
;; dominated by the 48 public-clinic lines, which run on a rigid 30-day push
;; with no information mechanics at all and therefore CANNOT respond to the
;; latency or predictive settings.  Only the 9 static lines carry the
;; information layer, so STATIC-ZERO-EPISODES is where a treatment effect can
;; actually appear.  (docs/05 check 2)
to-report static-zero-episodes
  report sum [ sum zero-episodes ] of ngo-statics
end

to-report public-zero-episodes
  report sum [ sum zero-episodes ] of public-ccs
end

;; Share of outcome 1 attributable to the NGO network's own patients rather
;; than to spillover from public-facility stockouts.  Useful because the
;; diverted component is driven mainly by the (latency-free) public push
;; cycle, so it dilutes the latency signal in the headline metric.
to-report ngo-unmet-own-share
  ifelse ngo-unmet-patients > 0
    [ report ngo-unmet-own / ngo-unmet-patients ]
    [ report 0 ]
end

;; ---- calibration monitors (gap 2 benchmarks) ----
to-report public-availability-pct        ;; running average, target ~43%
  report 100 * avail-line-days / (max (list 1 total-line-days))
end

to-report public-availability-today-pct  ;; livelier, for plotting
  report 100 * (sum [ length filter [ s -> s > 0 ] stock-on-hand ] of public-ccs)
             / (4 * (count public-ccs))
end

to-report public-facility-stockout-pct   ;; share of facility-days with >=1 class out
  report 100 * facility-stockout-days / (max (list 1 facility-days))
end

;; ---- information-layer monitors ----

;; THE clean test of information quality.  How many days out of date is the
;; ledger?  This depends only on connectivity draws and info-latency-severity —
;; never on stock levels, order timing or the predictive toggle.  Use this,
;; not the gap below, to show that predictive modeling leaves DATA ACCURACY
;; untouched while improving reorder TIMING.  (docs/05 check 2)
to-report mean-ledger-age-days
  report mean [ ticks - ledger-snapshot-tick ] of ngo-statics
end

;; Units of disagreement between belief and reality.  IMPORTANT CAVEAT: this
;; is confounded by stock volatility.  A stale snapshot of a SMOOTH stock
;; trajectory is numerically closer to the truth than an equally stale
;; snapshot of a CRASHING one, so any intervention that stabilises stock will
;; shrink this number without improving the information system at all.
;; Interpret it as "how costly is the staleness", not "how stale is the data".
to-report mean-ledger-gap-c2
  report mean [ abs ((item 1 recorded-stock-ledger) - (item 1 stock-on-hand)) ] of ngo-statics
end

to-report ngo-c2-true-mean
  report mean [ item 1 stock-on-hand ] of ngo-statics
end

to-report ngo-c2-recorded-mean
  report mean [ item 1 recorded-stock-ledger ] of ngo-statics
end

to-report pct-statics-on-paper-now
  report 100 * (count ngo-statics with [ manual-fallback? ]) / (count ngo-statics)
end

to-report pct-time-on-paper
  report 100 * paper-days-cum / (max (list 1 (ticks * (count ngo-statics))))
end

;; ---- procurement monitors ----
to-report requisition-fill-rate
  let total (reqs-fulfilled-count + reqs-partial-count + reqs-lost-count)
  ifelse total > 0 [ report reqs-fulfilled-count / total ] [ report 1 ]
end

to-report mean-rdf-capital
  report mean [ rdf-capital ] of ngo-statics
end

;; Takings that exist physically but cannot yet be spent because the sale has
;; not been digitally validated.  This is the financial cost of information
;; latency (paper 2.2.4) and should rise sharply during connectivity outages.
to-report mean-unverified-revenue
  report mean [ unverified-revenue ] of ngo-statics
end

;; ---- raw requisition log export (optional; press the button after a run) ----
to export-requisition-log
  let fname "requisition-log.csv"
  carefully [ file-delete fname ] [ ]
  file-open fname
  file-print "tick_created,tick_resolved,clinic_who,commodity_class,qty_requested,qty_shipped,status"
  foreach requisition-log [ entry ->
    file-print (word (item 0 entry) "," (item 1 entry) "," (item 2 entry) ","
                     (item 3 entry) "," (item 4 entry) "," (item 5 entry) "," (item 6 entry))
  ]
  file-close
  user-message (word "Exported " (length requisition-log)
                     " requisition outcomes to requisition-log.csv "
                     "(saved in the folder the model file is in).")
end

@#$#@#$#@
GRAPHICS-WINDOW
210
10
714
515
-1
-1
16.0
1
10
1
1
1
0
0
0
1
-15
15
-15
15
0
0
1
ticks
30.0

BUTTON
10
10
95
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
10
195
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
47
95
80
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
47
195
80
export log
export-requisition-log
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
88
195
121
grid-failure-rate
grid-failure-rate
0
0.5
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
10
125
195
158
info-latency-severity
info-latency-severity
0
3
1
1
1
NIL
HORIZONTAL

SWITCH
10
162
195
195
predictive-modeling?
predictive-modeling?
1
1
-1000

SWITCH
10
199
195
232
demand-shocks?
demand-shocks?
0
1
-1000

MONITOR
10
240
100
285
unmet @ NGO
ngo-unmet-patients
0
1
11

MONITOR
103
240
195
285
...of which own
ngo-unmet-own
0
1
11

MONITOR
10
288
100
333
waste value (BDT)
waste-value-total
0
1
11

MONITOR
103
288
195
333
lines ever zero
lines-ever-zero
0
1
11

MONITOR
10
336
100
381
zero episodes
zero-episode-total
0
1
11

MONITOR
103
336
195
381
fully unserved
completely-unserved-patients
0
1
11

MONITOR
10
384
100
429
cold-chain refer
coldchain-unserved
0
1
11

MONITOR
103
384
195
429
pub avail % (avg)
public-availability-pct
1
1
11

MONITOR
10
432
100
477
pub f-stockout %
public-facility-stockout-pct
1
1
11

MONITOR
103
432
195
477
ledger age (days)
mean-ledger-age-days
2
1
11

MONITOR
10
480
100
525
static zero eps
static-zero-episodes
0
1
11

MONITOR
103
480
195
525
C2 ledger gap
mean-ledger-gap-c2
1
1
11

MONITOR
10
528
100
573
% time on paper
pct-time-on-paper
1
1
11

MONITOR
103
528
195
573
shock days
total-shock-days
0
1
11

MONITOR
10
576
100
621
req fill rate
requisition-fill-rate
2
1
11

MONITOR
103
576
195
621
mean RDF capital
mean-rdf-capital
0
1
11

MONITOR
10
624
100
669
unverified takings
mean-unverified-revenue
0
1
11

MONITOR
103
624
195
669
donor bailouts
donor-bailouts-total
0
1
11

MONITOR
10
672
100
717
shock active?
shock-active?
0
1
11

PLOT
722
10
1082
185
NGO C2: true vs recorded stock
day
units
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"true" 1.0 0 -13345367 true "" "plot ngo-c2-true-mean"
"recorded" 1.0 0 -2674135 true "" "plot ngo-c2-recorded-mean"

PLOT
722
190
1082
365
C2 information gap
day
units
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"gap" 1.0 0 -16777216 true "" "plot mean-ledger-gap-c2"

PLOT
722
370
1082
545
Public availability today (%)
day
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"avail" 1.0 0 -10899396 true "" "plot public-availability-today-pct"

PLOT
722
550
1082
725
Cumulative unmet at NGO
day
patients
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"unmet" 1.0 0 -5298144 true "" "plot ngo-unmet-patients"

@#$#@#$#@
# Bangladesh Health Clinic Information Latency Model (hardened build v2)

Full plain-English documentation lives in the repository docs/ folder:
01 pasteable code, 02 interface setup, 03 procedure walkthrough,
04 assumptions & limitations, 05 verification checks, 06 changelog, 07 BehaviorSpace, 08 parameter cross-check, 09 paper alignment.

Core mechanic: NGO reorder decisions read a lagged, error-corrupted ledger
(recorded-stock-ledger), never true stock-on-hand. The gap between the two is
the object of study. This is intentional - do not "fix" it.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

circle
false
0
Circle -7500403 true true 0 0 300

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

square
false
0
Rectangle -7500403 true true 30 30 270 270

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@

@#$#@#$#@

@#$#@#$#@
<experiments>
  <experiment name="latency-experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="90"/>
    <metric>ngo-unmet-patients</metric>
    <metric>ngo-unmet-own</metric>
    <metric>ngo-unmet-diverted</metric>
    <metric>waste-value-total</metric>
    <metric>lines-ever-zero</metric>
    <metric>zero-episode-total</metric>
    <metric>zero-episodes-per-line</metric>
    <metric>static-zero-episodes</metric>
    <metric>public-zero-episodes</metric>
    <metric>completely-unserved-patients</metric>
    <metric>coldchain-unserved</metric>
    <metric>private-rescues</metric>
    <metric>reqs-fulfilled-count</metric>
    <metric>reqs-partial-count</metric>
    <metric>reqs-lost-count</metric>
    <metric>requisition-fill-rate</metric>
    <metric>public-availability-pct</metric>
    <metric>public-facility-stockout-pct</metric>
    <metric>pct-time-on-paper</metric>
    <metric>mean-ledger-age-days</metric>
    <metric>mean-ledger-gap-c2</metric>
    <metric>mean-rdf-capital</metric>
    <metric>mean-unverified-revenue</metric>
    <metric>donor-bailouts-total</metric>
    <metric>total-shock-days</metric>
    <enumeratedValueSet variable="info-latency-severity">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predictive-modeling?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-failure-rate">
      <value value="0.05"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="demand-shocks?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
