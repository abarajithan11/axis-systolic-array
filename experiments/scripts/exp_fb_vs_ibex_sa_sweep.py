#!/usr/bin/env python3
"""Sweep SA sizes: compare Firebridge vs Ibex verilator compile+run times."""

import subprocess, time, csv, shutil
from pathlib import Path
from datetime import datetime

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


def sh(cmd, cwd=None):
    subprocess.run(cmd, shell=True, cwd=cwd or ROOT, check=True)


def timed(cmd, cwd=None):
    t0 = time.perf_counter()
    subprocess.run(cmd, shell=True, cwd=cwd or ROOT, check=True)
    return time.perf_counter() - t0


RUNS = ROOT / "experiments" / "runs"
RUNS.mkdir(parents=True, exist_ok=True)
csv_path = RUNS / f"fb_vs_ibex_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
FIELDS = ["R","C","fb_compile_s","fb_run_s","ibex_compile_s","ibex_run_s"]

csv_f = open(csv_path, "w", newline="")
csv_w = csv.DictWriter(csv_f, fieldnames=FIELDS)
csv_w.writeheader()
csv_f.flush()

for R, C in SIZES:
    print(f"\n=== R={R} C={C} ===")
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    cfg_args = (
        f"--R {R} --C {C} --K {K} --WK {WK} --WX {WX} --WY {WY} "
        f"--VALID_PROB {VALID_PROB} --READY_PROB {READY_PROB} "
        f"--DATA_DIR {DATA_DIR} --WORK_DIR {WORK_DIR} "
        f"--FREQ_MHZ {FREQ_MHZ} --AXI_WIDTH {AXI_WIDTH} "
        f"--AXIL_WIDTH {AXIL_WIDTH} --ADDR_WIDTH {ADDR_WIDTH}"
    )

    # ── Firebridge ───────────────────────────────────────────────────────────
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

    # ── Ibex ─────────────────────────────────────────────────────────────────
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

    row = {"R": R, "C": C,
           "fb_compile_s":   round(fb_compile, 2),
           "fb_run_s":       round(fb_run, 2),
           "ibex_compile_s": round(ibex_compile, 2),
           "ibex_run_s":     round(ibex_run, 2)}
    csv_w.writerow(row)
    csv_f.flush()
    print(row)

csv_f.close()
print(f"\nSaved: {csv_path}")
