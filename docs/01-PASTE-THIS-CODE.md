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

The code refers to five Interface widgets that must exist first:
`grid-failure-rate` (slider), `environmental-latency-severity` (slider),
`bureaucratic-latency-severity` (slider), `predictive-modeling?` (switch) and
`demand-shocks?` (switch). If they are missing, NetLogo reports
`Nothing named GRID-FAILURE-RATE has been defined`.
Building them is Phase A of [02-INTERFACE-SETUP.md](02-INTERFACE-SETUP.md);
if you already built them in an earlier session, there is nothing to redo.
