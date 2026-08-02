# START HERE — the only document you need to run the model

Read nothing else. Follow these steps in order. Each step says exactly what to
click and exactly what you should see afterwards.

**Two things to know before you start:**

1. **You cannot break anything permanently.** Every version of every file is
   stored in GitHub forever. If a step goes wrong, Step 0 gives you a working
   copy on your own computer to fall back on, and the recovery box at the
   bottom gets you back to working in about 30 seconds.
2. **What went wrong last time was my mistake, not yours.** I pointed you at a
   file that begins with 20 lines of English instructions before the code
   starts. Copying the whole page pasted that English into NetLogo, and
   NetLogo complained about every line of it. This document points you at a
   file that contains *nothing but code*, so that cannot happen again.

---

## Step 0 — Make a safety copy (60 seconds, do not skip)

Right now, in NetLogo, with your working model open:

1. Click **File → Save As...**
2. Name it `clinic-model-BACKUP.nlogo` and save it somewhere you'll find it
   (Desktop is fine).
3. Then click **File → Save As...** *again*, name this one
   `clinic-model-WORKING.nlogo`, and save it in the same place.

You now have two identical files. You will work in `WORKING` from here on. If
anything ever goes wrong, open `BACKUP` and you are exactly where you are now.

✅ **You should see:** the NetLogo title bar now says `clinic-model-WORKING`.

---

## Step 1 — Copy the code (one click)

1. Click this link — it opens the code file in your browser:

   **https://github.com/BrandonS08/NetlogoSimulationModel/blob/claude/netlogo-model-hardening-1bwbh4/model/CodeTab.txt**

2. Look at the row of small grey icons at the **top right of the code box**
   (not the top of the whole page). Hover over them until you find the one
   labelled **"Copy raw file"** — it looks like two overlapping squares.
3. Click it once.

That copies the entire file, and nothing but the file, to your clipboard.

✅ **You should see:** a brief "Copied!" tooltip.

❌ **Do NOT** select the text with your mouse and copy it that way, and do not
copy from any other file. The one-click button is the whole point of this step.

---

## Step 2 — Paste it into NetLogo

1. Go back to NetLogo (your `clinic-model-WORKING` window).
2. Click the **Code** tab at the top.
3. Click once anywhere inside the code area, then press **Ctrl+A**
   (**Cmd+A** on a Mac) to select everything that is currently there.
4. Press **Delete**. The Code tab should now be completely empty.
   *This matters: if old code is left behind, NetLogo sees two copies of every
   procedure and reports dozens of "already defined" errors.*
5. Press **Ctrl+V** (**Cmd+V** on a Mac) to paste.

✅ **You should see:** the code area now starts with these exact lines:

```
;; ============================================================================
;; BANGLADESH HEALTH CLINIC INFORMATION LATENCY MODEL — HARDENED BUILD v2
```

❌ **If the first line is anything else** — especially if it says
`# Deliverable` or any English sentence — you copied from the wrong place.
Press Ctrl+Z until it's back to how it was, and redo Step 1.

---

## Step 3 — Confirm it compiled

Click the **Check** button (top of the Code tab).

✅ **Success looks like:** nothing happens. No red bar, no popup, no error
message. Silence means it compiled cleanly. That's it — you're done with code.

❌ **If you get an error message,** don't change anything. Copy the exact text
of the message and send it to me. One error message is a normal, fixable
thing; it is not a sign that anything is broken.

---

## Step 4 — Quick confidence check (2 minutes)

1. Click the **Interface** tab.
2. Click **setup**. You should see the map redraw: a blue square in the
   middle, 12 red circles, 3 green houses with lime triangles linked to them,
   and yellow boxes scattered around.
3. Click **go** and let it run for about 20 seconds, then click **go** again
   to stop it.
4. Look at the plots — lines should be moving.

✅ If setup draws the map and go makes the plots move, the model is working
and you are ready to collect data.

---

## Step 5 — Set up the data collection run

This is the part that produces your actual results. You only do it once.

1. In NetLogo, click **Tools → BehaviorSpace**.
2. Click **New**.
3. In **Experiment name**, type: `latency-experiment`
4. Find the large box labelled **Vary variables as follows**. Delete
   everything in it, and type these four lines exactly:

```
["info-latency-severity" 0 1 2 3]
["predictive-modeling?" true false]
["grid-failure-rate" 0.05 0.25]
["demand-shocks?" true false]
```

5. Set **Repetitions** to `20`.
6. Find the box labelled **Measure runs using these reporters**. Delete
   everything in it, and type these lines exactly (one per line):

```
ngo-unmet-patients
ngo-unmet-own
ngo-unmet-diverted
waste-value-total
lines-ever-zero
zero-episode-total
static-zero-episodes
satellite-zero-episodes
public-zero-episodes
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
mean-ledger-age-days
mean-ledger-gap-c2
mean-rdf-capital
donor-bailouts-total
total-shock-days
```

7. **Uncheck** the box that says **"Measure runs at every step"**.
   *(Important — leaving it checked produces a 700,000-row file instead of a
   640-row one.)*
8. **Setup commands** should say `setup`. **Go commands** should say `go`.
9. In **Time limit**, type `1095`.
10. Leave everything else alone. Click **OK**.

✅ **You should see:** `latency-experiment` now listed in the BehaviorSpace
window.

---

## Step 6 — Run it and get your data

1. With `latency-experiment` selected, click **Run**.
2. A box appears asking what output you want. **Check "Table output"** and
   leave the others unchecked.
3. It asks where to save. Name it `latency-results.csv`, save it next to your
   model file, click **OK**.
4. On the next small dialog, leave the defaults and click **OK**.
5. It will now run 640 simulations. **This takes roughly 20–60 minutes.**
   A progress window shows how many runs are done. Leave the computer alone
   and go do something else.

✅ **When it finishes:** you have `latency-results.csv` — that is your dataset.
640 rows, one per simulated run, with all 24 measurements on each.

---

## What to do with the results file

Open `latency-results.csv` in Excel or Google Sheets. The first six lines are
header junk from NetLogo — delete those six rows so the column names are on
row 1.

Each row is one simulation run. The first few columns tell you the settings
used; the rest are the results.

The three comparisons your paper needs, all done by averaging the 20 runs in
each condition:

1. **Does latency cause harm?** Compare `ngo-unmet-own` and
   `static-zero-episodes` across `info-latency-severity` 0 → 1 → 2 → 3, with
   `predictive-modeling?` = false. Expect them to rise as severity rises.
2. **Does prediction help?** At each severity level, compare
   `predictive-modeling?` true vs false. Expect `static-zero-episodes` and
   `ngo-unmet-own` to fall.
3. **Does prediction fix the data problem? (No — and this is your key finding.)**
   Same comparison, but look at `mean-ledger-age-days` and `pct-time-on-paper`.
   Expect these to be *identical* across the two arms. That is the evidence
   that predictive modeling improves reorder timing without repairing
   information accuracy.

Report averages with standard deviations across the 20 repetitions, never
single runs. When you have the file, send it to me and I'll do the analysis
with you.

---

## 🛟 Recovery box — if anything at all goes wrong

**"I broke the model."** Close NetLogo without saving. Open
`clinic-model-BACKUP.nlogo`. You are back to a working model. Nothing is lost.

**"I got an error message."** Don't fix it yourself. Copy the exact wording and
send it to me. Error messages are information, not damage.

**"The Code tab looks wrong."** Press Ctrl+Z (Cmd+Z) repeatedly to undo, or
just close without saving and reopen your backup.

**"I deleted something in GitHub."** You can't — nothing you do in NetLogo
touches GitHub, and GitHub keeps every past version regardless.

**"I don't know what these files in GitHub are."** You only ever need one:
`model/CodeTab.txt`, the file from Step 1. The others are written
documentation for your paper and for the professors — `03` explains how the
model works in plain English, `04` is your limitations section, `06` is the
record of what was fixed and why. None of them is something you have to run,
install, or maintain. They are there so that when a professor asks "how do you
know this is right?", the answer is written down.
