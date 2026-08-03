#!/usr/bin/env python3
"""Regenerate docs/01-PASTE-THIS-CODE.md from model/CodeTab.txt.

Run from the repository root:  python3 scripts/assemble_nlogo.py

model/CodeTab.txt is the single source of truth and is pure NetLogo code with
nothing else in it. This script only keeps the pointer doc in step with it.

A .nlogo convenience copy used to be generated here and was removed: it was
never opened in NetLogo (no runtime is available in the build environment), and
because a .nlogo file embeds the interface, info tab and shapes after a
@#$#@#$#@ separator, copying from it instead of CodeTab.txt pastes a large
block of non-code into the Code tab. It caused that exact mistake twice, so the
repository now contains exactly one file anyone should ever copy from.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CODE = (ROOT / "model" / "CodeTab.txt").read_text()

# ------------------------------------------- docs/01 (pasteable code block)
doc01 = """# Deliverable (a): the complete Code tab

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

The code refers to four Interface widgets that must exist first:
`grid-failure-rate` (slider), `info-latency-severity` (slider),
`predictive-modeling?` (switch) and `demand-shocks?` (switch). If they are
missing, NetLogo reports `Nothing named GRID-FAILURE-RATE has been defined`.
Building them is Phase A of [02-INTERFACE-SETUP.md](02-INTERFACE-SETUP.md);
if you already built them in an earlier session, there is nothing to redo.
"""
(ROOT / "docs").mkdir(exist_ok=True)
(ROOT / "docs" / "01-PASTE-THIS-CODE.md").write_text(doc01)

print("wrote docs/01-PASTE-THIS-CODE.md")
