#!/usr/bin/env python3
"""Plot stacked bar chart: Firebridge vs Ibex compile+run times from CSV."""

import csv, sys, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parents[2]
RUNS = ROOT / "experiments" / "runs"

csv_path = Path(sys.argv[1]) if len(sys.argv) > 1 else max(RUNS.glob("fb_vs_ibex_*.csv"))
print(f"Plotting: {csv_path}")
rows = list(csv.DictReader(open(csv_path)))

labels = [f"{r['R']}×{r['C']}" for r in rows]
fc = [float(r['fb_compile_s'])   for r in rows]
fr = [float(r['fb_run_s'])       for r in rows]
ic = [float(r['ibex_compile_s']) for r in rows]
ir = [float(r['ibex_run_s'])     for r in rows]

n, w = len(rows), 0.35
x = np.arange(n)
CC, RC = '#4878cf', '#6acc65'   # compile/run colours

fig, ax = plt.subplots(figsize=(max(6, n * 2.5), 5))
ax.bar(x - w/2, fc, w, color=CC,                    label='Compile – FB')
ax.bar(x - w/2, fr, w, color=RC, bottom=fc,         label='Run – FB')
ax.bar(x + w/2, ic, w, color=CC, alpha=0.55, hatch='///', label='Compile – Ibex')
ax.bar(x + w/2, ir, w, color=RC, alpha=0.55, hatch='///', label='Run – Ibex', bottom=ic)

ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.set_xlabel('SA size (R×C)')
ax.set_ylabel('Time (s)')
ax.set_title('Firebridge vs Ibex Verilator: Compile & Run Time')
ax.legend()

plt.tight_layout()
out = csv_path.with_suffix('.png')
plt.savefig(out, dpi=150)
print(f"Saved: {out}")
