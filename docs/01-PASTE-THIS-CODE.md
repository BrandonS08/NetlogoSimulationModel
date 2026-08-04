# Deliverable (a): the complete Code tab

## ⚠️ Do not copy code from this page

This page deliberately contains **no code**. An earlier version embedded the
code below a block of English instructions, and copying the whole page pasted
that English into NetLogo, which reported an error on every line of it.

**Copy the code from the file that contains nothing but code:**

> **[model/CodeTab.txt](../model/CodeTab.txt)**

Open it on GitHub and use the **"Copy raw file"** button at the top right of
the code box — one click, guaranteed complete, no prose.

Step-by-step instructions, including what to check afterwards and how to undo
if something looks wrong, are in **[00-START-HERE.md](00-START-HERE.md)**.

## What the Code tab needs in order to compile

**Nothing.** It compiles in a completely empty NetLogo model.

The five research parameters — `grid-failure-rate`,
`environmental-latency-severity`, `bureaucratic-latency-severity`,
`predictive-modeling?` and `demand-shocks?` — are ordinary variables declared
in the code. They used to be Interface widgets that had to exist first, with
exactly matching names, which is what caused the repeated paste failures.

**If you still have those sliders or switches, delete them before pasting.** A
widget and a code variable cannot share a name, so the paste will otherwise
fail with *"There is already a global variable called GRID-FAILURE-RATE"*.
This is a one-time step — see [00-START-HERE.md](00-START-HERE.md) Step 0a.
