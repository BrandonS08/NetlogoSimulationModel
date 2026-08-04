#!/usr/bin/env python3
"""Static checks on model/CodeTab.txt. Run before shipping any code change:

    python3 scripts/check_code.py

Checks: file is pure code (no NetLogo file-format separators, no non-ASCII in
executable text), brackets and parens balance, to/end pair up, every SET target
is declared, and no name collides with a NetLogo primitive or built-in agent
variable. That last check exists because hand-maintained primitive lists missed
LEFT and ST in successive builds; scripts/netlogo-primitives.txt is extracted
from NetLogo's own parser-core/src/main/parse/TokenMapping.scala.
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
src = (ROOT / "model" / "CodeTab.txt").read_text()
clean = '\n'.join(re.sub(r'"[^"]*"', '""', l).split(';')[0] for l in src.split('\n'))
fails = []

def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond: fails.append(msg)

print("pasteability")
check(src.startswith(';;'), "file starts with a comment line")
check('@#$#@' not in src, "no NetLogo file-format separators")
check(not [c for l in src.split('\n') for c in l.split(';')[0] if ord(c) > 127],
      "no non-ASCII characters in executable code")

print("structure")
check(clean.count('(') == clean.count(')'), "parentheses balance")
check(clean.count('[') == clean.count(']'), "brackets balance")
n_to  = len(re.findall(r'^\s*to(?:-report)?\s', clean, re.M))
n_end = len(re.findall(r'^\s*end\s*$', clean, re.M))
check(n_to == n_end, f"to/end pair up ({n_to} procedures)")

def block(name):
    m = re.search(r'^' + name + r'\s*\[(.*?)^\]', clean, re.S | re.M)
    return set(m.group(1).split()) if m else set()

g = block('globals')
owns = set()
for b in ['public-ccs-own','ngo-statics-own','ngo-satellites-own',
          'private-shops-own','regional-hubs-own','requisitions-own']:
    owns |= block(b)
procs  = set(re.findall(r'^\s*to(?:-report)?\s+([a-zA-Z0-9?!*-]+)', clean, re.M))
locals_= set(re.findall(r'\blet\s+([a-zA-Z][\w?!*-]*)', clean))
params = set()
for m in re.finditer(r'^\s*to(?:-report)?\s+[\w?!*-]+\s*\[([^\]]*)\]', clean, re.M):
    params |= set(m.group(1).split())
lam = set(re.findall(r'\[\s*([a-zA-Z][\w?!*-]*)\s*->', clean))
for m in re.finditer(r'\[\s*\[([^\]]*)\]\s*->', clean):
    lam |= set(m.group(1).split())

WIDGETS = set()   # none: all five research parameters are now real globals
BUILTIN_VARS = set("""who color heading xcor ycor shape label label-color breed hidden? size
pen-size pen-mode pxcor pycor pcolor plabel plabel-color end1 end2 link-length
thickness tie-mode""".split())

print("declarations")
setters = set(re.findall(r'(?<!-)\bset\s+([a-zA-Z][\w?!*-]*)', clean))
undeclared = sorted(setters - g - owns - procs - locals_ - params - lam - WIDGETS - BUILTIN_VARS)
check(not undeclared, f"every SET target is declared{'' if not undeclared else ': ' + str(undeclared)}")

print("no interface-widget dependency")
# The recurring paste failure this repo exists to prevent. At commit 35f2ec0 the
# five research parameters were READ throughout the code but declared nowhere --
# they were Interface sliders. Pasting that file into a model without those
# widgets fails on every line that mentions one, with "Nothing named
# ENVIRONMENTAL-LATENCY-SEVERITY has been defined". The SET-target check above
# did not catch it, because an undeclared READ is not a SET.
RESEARCH_PARAMS = ["grid-failure-rate", "environmental-latency-severity",
                   "bureaucratic-latency-severity", "predictive-modeling?",
                   "demand-shocks?"]
for p in RESEARCH_PARAMS:
    used = re.search(r'(?<![\w?!*-])' + re.escape(p) + r'(?![\w?!*-])', clean)
    check(p in g, f"{p} declared as a real global"
                  + ("" if p in g else
                     " -- READ BY THE CODE BUT NEVER DECLARED; this paste will fail"
                     if used else " -- missing from globals"))

print("reserved names (authoritative: NetLogo TokenMapping.scala)")
prims = set((ROOT / "scripts" / "netlogo-primitives.txt").read_text().split())
reserved = prims | BUILTIN_VARS
for label, names in [("locals", locals_), ("parameters", params), ("lambda args", lam),
                     ("procedures", procs), ("globals", g), ("breed vars", owns - BUILTIN_VARS)]:
    clash = sorted(names & reserved)
    check(not clash, f"{label} clear of reserved names{'' if not clash else ': ' + str(clash)}")

print()
if fails:
    print(f"{len(fails)} CHECK(S) FAILED"); sys.exit(1)
print(f"all checks passed  ({n_to} procedures, {len(g)} globals, {len(prims)} primitives screened)")
