#!/usr/bin/env python3
"""Assemble BangladeshHealthClinicLatency.nlogo and docs/01-PASTE-THIS-CODE.md
from the single source of truth model/CodeTab.txt.

Run from the repository root:  python3 scripts/assemble_nlogo.py

The .nlogo is written in the legacy NetLogo 6.4 format, which NetLogo 7.0.x
opens and converts automatically. The user's primary workflow (paste code into
the Code tab, build widgets by hand) does not depend on this file; it exists
as a convenience copy for reviewers who can open .nlogo files directly.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CODE = (ROOT / "model" / "CodeTab.txt").read_text()

SEP = "@#$#@#$#@"

# ---------------------------------------------------------------- interface
def button(x1, y1, x2, y2, code, forever=False, label=None):
    return (f"BUTTON\n{x1}\n{y1}\n{x2}\n{y2}\n{label or 'NIL'}\n{code}\n"
            f"{'T' if forever else 'NIL'}\n1\nT\nOBSERVER\nNIL\nNIL\nNIL\nNIL\n1\n")

def slider(x1, y1, x2, y2, var, lo, hi, default, step):
    return (f"SLIDER\n{x1}\n{y1}\n{x2}\n{y2}\n{var}\n{var}\n{lo}\n{hi}\n"
            f"{default}\n{step}\n1\nNIL\nHORIZONTAL\n")

def switch(x1, y1, x2, y2, var, on):
    return (f"SWITCH\n{x1}\n{y1}\n{x2}\n{y2}\n{var}\n{var}\n{0 if on else 1}\n1\n-1000\n")

def monitor(x1, y1, x2, y2, label, source, decimals):
    return (f"MONITOR\n{x1}\n{y1}\n{x2}\n{y2}\n{label}\n{source}\n{decimals}\n1\n11\n")

def plot(x1, y1, x2, y2, name, xaxis, yaxis, pens):
    pen_lines = "\n".join(f'"{p[0]}" 1.0 0 {p[1]} true "" "{p[2]}"' for p in pens)
    return (f"PLOT\n{x1}\n{y1}\n{x2}\n{y2}\n{name}\n{xaxis}\n{yaxis}\n0.0\n10.0\n0.0\n10.0\n"
            f"true\ntrue\n\"\" \"\"\nPENS\n{pen_lines}\n")

GRAPHICS = """GRAPHICS-WINDOW
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
"""

widgets = [GRAPHICS]
widgets.append(button(10, 10, 95, 43, "setup"))
widgets.append(button(100, 10, 195, 43, "go", forever=True))
widgets.append(button(10, 47, 95, 80, "go", label="go once"))
widgets.append(button(100, 47, 195, 80, "export-requisition-log", label="export log"))
widgets.append(slider(10, 88, 195, 121, "grid-failure-rate", 0, 0.5, 0.1, 0.01))
widgets.append(slider(10, 125, 195, 158, "info-latency-severity", 0, 3, 1, 1))
widgets.append(switch(10, 162, 195, 195, "predictive-modeling?", on=False))
widgets.append(switch(10, 199, 195, 232, "demand-shocks?", on=True))

monitors = [
    ("unmet @ NGO",        "ngo-unmet-patients",             0),
    ("...of which own",    "ngo-unmet-own",                  0),
    ("waste value (BDT)",  "waste-value-total",              0),
    ("lines ever zero",    "lines-ever-zero",                0),
    ("zero episodes",      "zero-episode-total",             0),
    ("fully unserved",     "completely-unserved-patients",   0),
    ("cold-chain refer",   "coldchain-unserved",             0),
    ("pub avail % (avg)",  "public-availability-pct",        1),
    ("pub f-stockout %",   "public-facility-stockout-pct",   1),
    ("ledger age (days)",  "mean-ledger-age-days",           2),
    ("static zero eps",    "static-zero-episodes",           0),
    ("C2 ledger gap",      "mean-ledger-gap-c2",             1),
    ("% time on paper",    "pct-time-on-paper",              1),
    ("shock days",         "total-shock-days",               0),
    ("req fill rate",      "requisition-fill-rate",          2),
    ("mean RDF capital",   "mean-rdf-capital",               0),
    ("donor bailouts",     "donor-bailouts-total",           0),
    ("shock active?",      "shock-active?",                  0),
]
x_cols = [(10, 100), (103, 195)]
y = 240
for i, (label, source, dec) in enumerate(monitors):
    col = x_cols[i % 2]
    row_y = y + (i // 2) * 48
    widgets.append(monitor(col[0], row_y, col[1], row_y + 45, label, source, dec))

widgets.append(plot(722, 10, 1082, 185, "NGO C2: true vs recorded stock", "day", "units",
                    [("true", -13345367, "plot ngo-c2-true-mean"),
                     ("recorded", -2674135, "plot ngo-c2-recorded-mean")]))
widgets.append(plot(722, 190, 1082, 365, "C2 information gap", "day", "units",
                    [("gap", -16777216, "plot mean-ledger-gap-c2")]))
widgets.append(plot(722, 370, 1082, 545, "Public availability today (%)", "day", "%",
                    [("avail", -10899396, "plot public-availability-today-pct")]))
widgets.append(plot(722, 550, 1082, 725, "Cumulative unmet at NGO", "day", "patients",
                    [("unmet", -5298144, "plot ngo-unmet-patients")]))

interface = "\n".join(widgets)

# ---------------------------------------------------------------- info tab
info = """# Bangladesh Health Clinic Information Latency Model (hardened build v2)

Full plain-English documentation lives in the repository docs/ folder:
01 pasteable code, 02 interface setup, 03 procedure walkthrough,
04 assumptions & limitations, 05 verification checks, 06 changelog, 07 BehaviorSpace.

Core mechanic: NGO reorder decisions read a lagged, error-corrupted ledger
(recorded-stock-ledger), never true stock-on-hand. The gap between the two is
the object of study. This is intentional - do not "fix" it.
"""

# ------------------------------------------------------------- turtle shapes
shapes = """default
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
"""

link_shapes = """default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
"""

# ------------------------------------------------------------ behaviorspace
metrics = [
    "ngo-unmet-patients", "ngo-unmet-own", "ngo-unmet-diverted",
    "waste-value-total", "lines-ever-zero",
    "zero-episode-total", "zero-episodes-per-line",
    "static-zero-episodes", "satellite-zero-episodes", "public-zero-episodes",
    "completely-unserved-patients", "coldchain-unserved", "private-rescues",
    "reqs-fulfilled-count", "reqs-partial-count", "reqs-lost-count",
    "requisition-fill-rate", "public-availability-pct",
    "public-facility-stockout-pct", "pct-time-on-paper",
    "mean-ledger-age-days", "mean-ledger-gap-c2",
    "mean-rdf-capital", "donor-bailouts-total", "total-shock-days",
]
metric_xml = "\n    ".join(f"<metric>{m}</metric>" for m in metrics)
behaviorspace = f"""<experiments>
  <experiment name="latency-experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1095"/>
    {metric_xml}
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
</experiments>"""

# ------------------------------------------------------------------ assemble
nlogo = "\n".join([
    CODE.rstrip() + "\n",
    SEP, interface,
    SEP, info,
    SEP, shapes,
    SEP, "NetLogo 6.4.0",
    SEP, "",                    # preview commands
    SEP, "",                    # system dynamics
    SEP, behaviorspace,
    SEP, "",                    # hubnet client
    SEP, link_shapes,
    SEP, "0",                   # model settings
    SEP, "",
])
(ROOT / "BangladeshHealthClinicLatency.nlogo").write_text(nlogo)

# ------------------------------------------- docs/01 (pasteable code block)
doc01 = f"""# Deliverable (a): the complete Code tab

**What this is:** the entire replacement Code tab for the model, as one block.

**Before you paste** — the code refers to four Interface widgets
(`grid-failure-rate`, `info-latency-severity`, `predictive-modeling?`,
`demand-shocks?`). Create those four widgets FIRST, following steps 1-6 of
`02-INTERFACE-SETUP.md`. If you paste the code before the widgets exist,
NetLogo shows an error like "Nothing named GRID-FAILURE-RATE has been
defined" — that is expected, and it disappears once the widgets exist.

**How to paste:**
1. Open NetLogo 7.0.4 and click the **Code** tab.
2. Select everything already there (Ctrl+A / Cmd+A) and delete it.
3. Copy everything inside the code fence below (from the first `;;` line to
   the very last line) and paste it in.
4. Click **Check**. With the four widgets in place it should compile with no
   errors.

```netlogo
{CODE.rstrip()}
```
"""
(ROOT / "docs").mkdir(exist_ok=True)
(ROOT / "docs" / "01-PASTE-THIS-CODE.md").write_text(doc01)

print("wrote BangladeshHealthClinicLatency.nlogo and docs/01-PASTE-THIS-CODE.md")
