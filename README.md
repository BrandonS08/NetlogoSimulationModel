# Bangladesh Health Clinic Information Latency Model

A NetLogo 7.0.4 agent-based model of **information latency in decentralized
NGO health-clinic procurement networks in Bangladesh**, and of the extent to
which predictive demand modeling can mitigate its effects on medical waste and
inventory shortages during demand fluctuations.

**Core mechanic:** NGO clinics make reorder decisions from a lagged,
error-corrupted `recorded-stock-ledger` — never from true `stock-on-hand`. The
widening and narrowing gap between the two is the object of study, not a bug.

---

## Start here

### 👉 **[docs/00-START-HERE.md](docs/00-START-HERE.md)** — the only document you need to get the model running and collecting data.

Everything below is reference material for the write-up. You do not need to
read any code, and you never need to open more than one file to run the model.

| Doc | What it gives you |
|---|---|
| **[docs/00-START-HERE.md](docs/00-START-HERE.md)** | **Start here.** Load the code, verify it, run the experiment, get your data file |
| [docs/01-PASTE-THIS-CODE.md](docs/01-PASTE-THIS-CODE.md) | Where the code lives (the code itself is in `model/CodeTab.txt`) |
| **[docs/02-INTERFACE-SETUP.md](docs/02-INTERFACE-SETUP.md)** | Every widget, click by click, in the order to build them |
| **[docs/03-MODEL-DOCUMENTATION.md](docs/03-MODEL-DOCUMENTATION.md)** | Plain-English walkthrough of every procedure |
| **[docs/04-ASSUMPTIONS-AND-LIMITATIONS.md](docs/04-ASSUMPTIONS-AND-LIMITATIONS.md)** | What is sourced, what is a named assumption, what is out of scope |
| **[docs/05-VERIFICATION-CHECKS.md](docs/05-VERIFICATION-CHECKS.md)** | Four checks you can run yourself to confirm correct behavior |
| **[docs/06-CHANGELOG.md](docs/06-CHANGELOG.md)** | Every bug found in the previous build and why each fix was needed |
| **[docs/07-BEHAVIORSPACE.md](docs/07-BEHAVIORSPACE.md)** | Running 640 replications and aggregating with variance |
| [docs/08-PARAMETER-CROSSCHECK.md](docs/08-PARAMETER-CROSSCHECK.md) | Parameter-by-parameter provenance checklist |
| [docs/09-PAPER-ALIGNMENT.md](docs/09-PAPER-ALIGNMENT.md) | What the research paper confirmed and what it changed |
| **[docs/10-PRE-FLIGHT.md](docs/10-PRE-FLIGHT.md)** | **Read before running: what to verify, every number I guessed, ranked by impact** |

**If you are setting the model up from scratch for the first time:** build the
four widgets in `02` Phase A first, then follow `00-START-HERE.md`.

## Files

- `model/CodeTab.txt` — the model source, and the single source of truth.
- `BangladeshHealthClinicLatency.nlogo` — convenience copy with the interface
  and BehaviorSpace experiment already built in, for anyone who can open
  `.nlogo` files directly. Not needed for the paste-into-Code-tab workflow.
- `scripts/assemble_nlogo.py` — regenerates the `.nlogo` and `docs/01` from
  `model/CodeTab.txt`, so the three can never drift apart. Run
  `python3 scripts/assemble_nlogo.py` after any code edit.

## Verification status

The code was verified **statically** — line-by-line audit, structural checks,
declaration/usage cross-checks, defensive parenthesization, and arithmetic
walkthroughs of every stock and cash flow. It was **not executed** before
delivery: the build environment had no network route to a NetLogo runtime.
Run the checks in `docs/05` before trusting any output. This is stated again
in `docs/04` §D, where it belongs for your methodology write-up.
