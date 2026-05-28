#!/usr/bin/env python3
"""Sweep SA sizes: compare Firebridge vs Ibex verilator compile+run times."""

import subprocess, time, shutil
from pathlib import Path
from datetime import datetime

import pandas as pd

# ── Knobs ────────────────────────────────────────────────────────────────────
SIZES                        = [
    (2, 2),        # 4 PEs
    (64, 64),      # 4096
    (64, 128),     # 8192
    (111, 111),    # 12321
    (128, 128),    # 16384
    (143, 143),    # 20449
    (128, 192),    # 24576
    (169, 170),    # 28730
    (181, 181),    # 32761
    (192, 192),    # 36864
    (202, 203),    # 41006
    (213, 212),    # 45156
    (221, 222),    # 49062
    (231, 231),    # 53361
    (239, 240),    # 57360
    (248, 248),    # 61504
    (256, 256),    # 65536
]
K, WK, WX, WY                = 16, 8, 8, 32
VALID_PROB, READY_PROB       = 1000, 1000
AXI_WIDTH, AXIL_WIDTH, ADDR_WIDTH, FREQ_MHZ = 32, 32, 32, 100

# Resume knobs. Set RESUME_LAST_CSV=True to append to the newest prior sweep
# CSV and skip size pairs or stages that already have timings.
RESUME_LAST_CSV              = True
CSV_PATH                     = None  # Optional explicit Path/string instead of latest CSV.
# ─────────────────────────────────────────────────────────────────────────────

ROOT     = Path(__file__).resolve().parents[2]   # axis-systolic-array/
IBEX_SOC = ROOT / "ibex-soc"
FB_DIR   = ROOT / "firebridge"
WORK_DIR = ROOT / "run" / "work"
DATA_DIR = WORK_DIR / "data"

FUSESOC_OPTS = (
    "--RV32E=0 --RV32M=ibex_pkg::RV32MFast --RV32B=ibex_pkg::RV32BNone "
    "--RegFile=ibex_pkg::RegFileFF --BranchTargetALU=0 --WritebackStage=0 "
    "--ICache=0 --ICacheECC=0 --ICacheScramble=0 --BranchPredictor=0 "
    "--DbgTriggerEn=0 --SecureIbex=0 --PMPEnable=0 --PMPGranularity=0 "
    "--PMPNumRegions=4 --MHPMCounterNum=0 --MHPMCounterWidth=40"
)

RUNS = ROOT / "experiments" / "runs"
FIELDS = ["R","C","fb_compile_s","fb_run_s","ibex_compile_s","ibex_run_s"]


def sh(cmd, cwd=None):
    subprocess.run(cmd, shell=True, cwd=cwd or ROOT, check=True)


def timed(cmd, cwd=None):
    t0 = time.perf_counter()
    subprocess.run(cmd, shell=True, cwd=cwd or ROOT, check=True)
    return time.perf_counter() - t0


def latest_csv():
    csvs = list(RUNS.glob("fb_vs_ibex_*.csv"))
    if not csvs:
        return None
    return max(csvs, key=lambda p: p.stat().st_mtime)


def step_done(row, *fields):
    return all(pd.notna(row[field]) and str(row[field]).strip() for field in fields)


def load_results(csv_path):
    if csv_path.exists():
        df = pd.read_csv(csv_path)
        for field in FIELDS:
            if field not in df:
                df[field] = pd.NA
        df = df[FIELDS].dropna(subset=["R", "C"])
        df["R"] = df["R"].astype(int)
        df["C"] = df["C"].astype(int)
        return df.drop_duplicates(subset=["R", "C"], keep="last").reset_index(drop=True)

    return pd.DataFrame(columns=FIELDS)


def write_results(csv_path, df):
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = csv_path.with_suffix(csv_path.suffix + ".tmp")
    df.to_csv(tmp_path, index=False)
    tmp_path.replace(csv_path)


RUNS.mkdir(parents=True, exist_ok=True)
if RESUME_LAST_CSV and CSV_PATH:
    raise SystemExit("RESUME_LAST_CSV and CSV_PATH are mutually exclusive")

if RESUME_LAST_CSV:
    csv_path = latest_csv()
    if csv_path is None:
        csv_path = RUNS / f"fb_vs_ibex_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        print(f"[resume] no previous CSV found; creating {csv_path}")
    else:
        print(f"[resume] using latest CSV: {csv_path}")
elif CSV_PATH:
    csv_path = Path(CSV_PATH)
    print(f"[resume] using CSV: {csv_path}")
else:
    csv_path = RUNS / f"fb_vs_ibex_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

results = load_results(csv_path)
write_results(csv_path, results)

for R, C in SIZES:
    print(f"\n=== R={R} C={C} ===")
    matches = results.index[(results["R"] == R) & (results["C"] == C)]
    if len(matches):
        row_i = matches[0]
    else:
        row_i = len(results)
        results.loc[row_i, FIELDS] = [R, C, pd.NA, pd.NA, pd.NA, pd.NA]

    row = results.loc[row_i]
    if step_done(row, "fb_compile_s", "fb_run_s", "ibex_compile_s", "ibex_run_s"):
        print("[skip] complete row already exists in CSV")
        continue

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    cfg_args = (
        f"--R {R} --C {C} --K {K} --WK {WK} --WX {WX} --WY {WY} "
        f"--VALID_PROB {VALID_PROB} --READY_PROB {READY_PROB} "
        f"--DATA_DIR {DATA_DIR} --WORK_DIR {WORK_DIR} "
        f"--FREQ_MHZ {FREQ_MHZ} --AXI_WIDTH {AXI_WIDTH} "
        f"--AXIL_WIDTH {AXIL_WIDTH} --ADDR_WIDTH {ADDR_WIDTH}"
    )

    if step_done(row, "fb_compile_s", "fb_run_s"):
        print("[FB] skip: timings already in CSV")
    else:
        # ── Firebridge ───────────────────────────────────────────────────────
        print("[FB] setup...")
        sh(f"python3 config.py {cfg_args} --TARGET sim", cwd=ROOT / "run")
        sh(f"python3 run/golden.py --R {R} --K {K} --C {C} --DIR {DATA_DIR}")
        sh("rm -rf run/work/V* run/work/verilated* run/work/*.o "
           "run/work/*.a run/work/*.d run/work/*.mk run/work/*.gch")

        clk_half_ts = 1000 // FREQ_MHZ // 2
        print("[FB] compile...")
        fb_compile = timed(
            f"verilator --top top_axi_int_tb -F sources_axi_int.txt ../../c/sim.c "
            f"--cc --exe --build -j 0 --Wno-BLKANDNBLK --Wno-INITIALDLY "
            f"-Irun -CFLAGS -DTB_MODULE=top_axi_int_tb -CFLAGS -DFB_MODULE=fb_axi_vip "
            f"-CFLAGS -DSIM -CFLAGS -g --Mdir ../run/work "
            f"-CFLAGS -Irun/work -CFLAGS -I{FB_DIR} "
            f"-CFLAGS -DCLK_HALF_TS={clk_half_ts} "
            f"--trace-fst -CFLAGS -g --timing {FB_DIR}/fb_top_verilator_wrap.cpp",
            cwd=ROOT / "run"
        )
        print(f"[FB] compile: {fb_compile:.1f}s")

        print("[FB] run...")
        fb_run = timed("./Vtop_axi_int_tb", cwd=WORK_DIR)
        print(f"[FB] run: {fb_run:.1f}s")

        results.loc[row_i, ["fb_compile_s", "fb_run_s"]] = [
            round(fb_compile, 2),
            round(fb_run, 2),
        ]
        write_results(csv_path, results)
        row = results.loc[row_i]

    if step_done(row, "ibex_compile_s", "ibex_run_s"):
        print("[Ibex] skip: timings already in CSV")
    else:
        # ── Ibex ─────────────────────────────────────────────────────────────
        print("[Ibex] setup...")
        sh(f"python3 config.py {cfg_args} --TARGET ibex", cwd=ROOT / "run")
        sh("make -C examples/sw/simple_system/hello_test clean", cwd=IBEX_SOC)
        if (IBEX_SOC / "build").exists():
            shutil.rmtree(IBEX_SOC / "build")

        print("[Ibex] compile (firmware + fusesoc)...")
        t0 = time.perf_counter()
        sh("make sw-simple-hello", cwd=IBEX_SOC)
        sh(f"fusesoc --cores-root=. run --target=sim --setup --build "
           f"lowrisc:ibex:ibex_simple_system {FUSESOC_OPTS}", cwd=IBEX_SOC)
        ibex_compile = time.perf_counter() - t0
        print(f"[Ibex] compile: {ibex_compile:.1f}s")

        print("[Ibex] run...")
        ibex_run = timed(
            "build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system "
            "-t --raminit=examples/sw/simple_system/hello_test/hello_test.vmem",
            cwd=IBEX_SOC
        )
        print(f"[Ibex] run: {ibex_run:.1f}s")

        results.loc[row_i, ["ibex_compile_s", "ibex_run_s"]] = [
            round(ibex_compile, 2),
            round(ibex_run, 2),
        ]
        write_results(csv_path, results)
        row = results.loc[row_i]

    print(row.to_dict())

print(f"\nSaved: {csv_path}")
