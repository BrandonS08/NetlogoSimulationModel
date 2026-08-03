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

### Step 3b — Save right now (Ctrl+S / Cmd+S)

The code you just pasted only exists in memory until you save. Press
**Ctrl+S** (**Cmd+S** on Mac) before doing anything else.

Rule of thumb for the rest of this document: **any time you finish a step that
took effort, press Ctrl+S.** NetLogo does not autosave, and everything you
build — code, widgets, experiments — lives inside the model file.

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
["environmental-latency-severity" 0 1 2 3]
["predictive-modeling?" true false]
["grid-failure-rate" 0.05 0.25]
["demand-shocks?" true false]
```

5. Set **Repetitions** to `20`.
6. Find the box labelled **Measure runs using these reporters**. Delete
   everything in it, and type these lines exactly (one per line):

```
ngo-unmet-patients
ngo-unmet-walkin
ngo-unmet-diverted
waste-value-total
lines-ever-zero
zero-episode-total
zero-episodes-per-line
static-zero-episodes
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
public-stockout-inequality
ngo-static-stockout-pct
waste-pct-of-value
pct-time-on-paper
mean-ledger-age-days
mean-ledger-gap-c2
mean-rdf-capital
mean-unverified-revenue
donor-bailouts-total
total-shock-days
```

7. **Uncheck** the box that says **"Measure runs at every step"**.
   *(Important — leaving it checked produces a 700,000-row file instead of a
   640-row one.)*
8. **Setup commands** should say `setup`. **Go commands** should say `go`.
9. In **Time limit**, type `3650`.
10. Leave everything else alone. Click **OK**.

✅ **You should see:** `latency-experiment` now listed in the BehaviorSpace
window.

---

## Step 5b — SAVE IMMEDIATELY (this is the step people lose work on)

**BehaviorSpace experiments are stored inside your model file, not in NetLogo
itself.** Until you save the model, the experiment exists only in memory. If
NetLogo closes, restarts, or is force-quit, the experiment disappears and it
looks like it was never there.

1. Close the BehaviorSpace window (click the X on it, or the **Close**
   button — *not* Delete).
2. Press **Ctrl+S** (**Cmd+S** on Mac).

✅ **Check it worked:** click **Tools → BehaviorSpace** again.
`latency-experiment` should still be listed. It is now saved permanently and
will be there every time you open this model file.

---

## Step 5c — Do a 2-minute pilot run before the real one

Don't commit to a 45-minute run before knowing the whole pipeline produces a
file. This makes a tiny throwaway version first.

1. **Tools → BehaviorSpace**, select `latency-experiment`, click
   **Duplicate**.
2. In the copy, change the **Experiment name** to `pilot`.
3. Change **Repetitions** to `1`.
4. In the **Vary variables** box, replace the four lines with just these two:

```
["environmental-latency-severity" 0 3]
["predictive-modeling?" true false]
```

5. Change **Time limit** to `200`.
6. Click **OK**, then press **Ctrl+S** to save again.
7. Select `pilot`, click **Run**. Then fill in the run-options dialog exactly
   as described in the box below, using `pilot-test.csv` as the filename and
   leaving **Simultaneous runs in parallel** at `1`.

This runs 4 short simulations and takes well under a minute.

### 📋 The run-options dialog — how to fill it in

This dialog trips people up because it uses **file paths, not checkboxes**.
A blank field means that output type is switched **off**. You turn an output
on by giving it a filename.

| Field | What to do |
|---|---|
| **Spreadsheet output** | Leave blank |
| **Table output** | Click **Browse**, pick a folder, type the filename, click Save. The field should then show a path — this is what turns table output on. |
| **Stats output** | Leave blank |
| **Lists output** | Leave blank |
| **Update view** | **Uncheck** — redrawing the map during runs is slow and pointless here |
| **Update plots & monitors** | **Uncheck** — same reason |
| **Simultaneous runs in parallel** | `1` for the pilot; `4` for the real run |
| **Display parallel run output in command center** | Leave unchecked |

You do not need to click **Disable** on the outputs you aren't using — blank
already means off.

*Why table output and not spreadsheet:* table output writes one row per
simulation run, which is the format you want for averaging in Excel.

✅ **Success:** a progress window appears, counts to 4, closes, and
`pilot-test.csv` exists on your computer with 4 rows of numbers in it.

If that worked, the entire pipeline works, and the only difference for the
real run is that it takes longer. Move on to Step 6.

---

## Step 6 — Run it and get your data

1. **Tools → BehaviorSpace**, select `latency-experiment` (the full one, not
   `pilot`), and click **Run**.
2. The run-options dialog appears. Fill it in using the table in Step 5c,
   with two differences from the pilot:
   - **Table output** filename: `latency-results.csv`
   - **Simultaneous runs in parallel**: set it to `4` (runs four simulations
     at once, cutting the wait roughly fourfold). Drop to `2` if your
     computer struggles.
3. Make sure **Update view** and **Update plots & monitors** are both
   **unchecked** — with 640 runs this makes a large difference to the total
   time.
4. Click **OK**.
5. It will now run 640 simulations. **This takes roughly 1–3.5 hours** at a
   ten-year horizon.
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

1. **Does latency cause harm?** Compare `ngo-unmet-walkin` and
   `static-zero-episodes` across `environmental-latency-severity` 0 → 1 → 2 → 3, with
   `predictive-modeling?` = false. Expect them to rise as severity rises.
2. **Does prediction help?** At each severity level, compare
   `predictive-modeling?` true vs false. Expect `static-zero-episodes` and
   `ngo-unmet-walkin` to fall.
3. **Does prediction fix the data problem? (No — and this is your key finding.)**
   Same comparison, but look at `mean-ledger-age-days` and `pct-time-on-paper`.
   Expect these to be *identical* across the two arms. That is the evidence
   that predictive modeling improves reorder timing without repairing
   information accuracy.

Report averages with standard deviations across the 20 repetitions, never
single runs. When you have the file, send it to me and I'll do the analysis
with you.

---

## 🔧 BehaviorSpace troubleshooting

### "My experiment disappeared"

Almost always the cause is Step 5b: the experiment was never saved, and
NetLogo was closed or restarted at some point after creating it. Experiments
live inside the model file. Nothing is wrong with the model — recreate the
experiment (Step 5, about three minutes) and press **Ctrl+S** immediately
afterwards. Once saved, it stays forever.

A second possibility: you have more than one copy of the model saved
(`BACKUP` and `WORKING`), and the experiment is in the other one. Check the
NetLogo title bar to confirm which file you have open.

### "Tools → BehaviorSpace won't open at all"

Work down this list, in order. Stop as soon as one works.

1. **Is an experiment already running?** Look for a separate window called
   *Running Experiment* — check your taskbar (Windows) or Dock (Mac), and try
   **Alt+Tab** / **Cmd+Tab**. While a run is in progress NetLogo deliberately
   blocks the BehaviorSpace manager from opening. If you find it, everything
   is fine — leave it alone and let it finish.
2. **Is the window open but invisible?** NetLogo remembers where dialog
   windows were last positioned, and if that position is off the edge of your
   current screen — very common after unplugging an external monitor or
   changing resolution — the window opens where you can't see it. The menu
   click "works", nothing appears. Fix: **Alt+Tab** (Windows) or the
   **Window** menu (Mac) to find and select it, then drag it back into view.
3. **Is NetLogo just busy?** A large run makes the interface sluggish for a
   few seconds at a time. Wait 30 seconds and try the menu again.
4. **Restart NetLogo.** Quit completely (force-quit if it won't respond) and
   reopen `clinic-model-WORKING.nlogo`. This is safe — you have backups, and
   the model file on disk is untouched by a hung window. Then check
   **Tools → BehaviorSpace**: if the experiment is listed, you saved it and
   nothing was lost. If the list is empty, redo Step 5 and save with Ctrl+S.

### "NetLogo is frozen — the menus don't respond and it won't even quit"

If clicking Quit flashes something briefly and dumps you back where you were,
there is an **invisible modal dialog** sitting off-screen. NetLogo is waiting
for you to answer a question you cannot see, so it refuses to open menus and
refuses to quit. This is a known Java/NetLogo behavior after a display or
resolution change, and it is not damage.

**First, try to answer the invisible dialog** (30 seconds — if this works you
keep your unsaved work):

1. Click once on the NetLogo window, then press **Escape**. Try the menus.
2. Still stuck? Press **Enter**. Try the menus.
3. Still stuck? Press **Alt+Tab** (Windows) or **Cmd+Tab** (Mac) until you
   land on a NetLogo window that isn't the main one, then — on Windows —
   press **Win+Left arrow** to snap it back onto your visible screen. On Mac,
   check the **Window** menu for a listed window you can't see.

**If the menus respond after any of those:** immediately press **Ctrl+S** to
save, then carry on.

**If none of that works, force-quit.** This is safe. Force-quitting cannot
corrupt or delete your `.nlogo` files — they are sitting on your hard drive
untouched. The only thing lost is work since your last save.

- **Windows:** press **Ctrl+Shift+Esc** to open Task Manager. Find
  **NetLogo** in the list (it may show as `NetLogo 7.0.4` or as
  `Java(TM) Platform SE binary`). Click it once, then click **End task**.
- **Mac:** press **Cmd+Option+Esc** to open Force Quit Applications. Select
  **NetLogo**, click **Force Quit**, confirm.

**If even force-quit won't work, restart the computer.** Windows: Start →
Power → Restart. Mac: Apple menu → Restart. If the screen is fully
unresponsive, hold the physical power button for 10 seconds, then power back
on. This always works, and it cannot harm your files — a hung program cannot
damage a `.nlogo` file that is already written to disk.

Then reopen `clinic-model-WORKING.nlogo` and check what survived:

| Check | If present | If missing |
|---|---|---|
| **Code** tab starts with `;; BANGLADESH HEALTH CLINIC...HARDENED BUILD v2` | Code survived | Redo Steps 1–2, then **Ctrl+S** |
| **Tools → BehaviorSpace** lists `latency-experiment` | Experiment survived | Redo Step 5, then **Ctrl+S** |

Worst case this is about five minutes of redoing. Save after each step this
time and it will not happen again.

### "The run started but I can't tell if it's working"

The progress window shows `Run 37 / 640` style counters and elapsed time. If
that number is climbing, it's working — the full run takes 20–60 minutes.
Don't click in the main NetLogo window while it runs; just leave it.

### "I want to stop a run that's already going"

Click **Abort** in the progress window. Any runs already completed are still
written to the CSV file. Aborting damages nothing.

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
