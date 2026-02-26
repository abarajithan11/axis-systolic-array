import os
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate config.svh, config.h, and config.tcl based on input parameters.")
    parser.add_argument('--R', required=True, type=int)
    parser.add_argument('--C', required=True, type=int)
    parser.add_argument('--K', required=True, type=int)
    parser.add_argument('--WK', default=8, type=int)
    parser.add_argument('--WX', default=8, type=int)
    parser.add_argument('--WY', default=32, type=int)
    parser.add_argument('--VALID_PROB', default=1000, type=int)
    parser.add_argument('--READY_PROB', default=1000, type=int)
    parser.add_argument('--DATA_DIR', required=True, type=str)
    parser.add_argument('--FREQ_MHZ', default=100, type=int)
    parser.add_argument('--AXI_WIDTH', default=128, type=int)
    parser.add_argument('--AXIL_WIDTH', default=32, type=int)
    parser.add_argument('--ADDR_WIDTH', default=32, type=int)
    parser.add_argument('--TARGET', default="sim", type=str)
    parser.add_argument('--WORK_DIR', default='work', type=str)

    args = parser.parse_args()

    # Default AXI base/range per target (strings to match your existing format)
    TARGET_CONFIG_MAP = {
        "sim":     ("B0000000", "16M"),
        "pynq_z2": ("40000000", "1G"),
        "zcu104":  ("B0000000", "256M"),
        "zcu102":  ("B0000000", "256M"),
        "ibex":    ("B0000000", "256M"),
        "boom":    ("2000",     "256M"),
    }
    config_baseaddr, config_range = TARGET_CONFIG_MAP[args.TARGET]

    addr_map = {
        "A_START       " : "0",
        "A_MM2S_0_DONE " : "1",
        "A_MM2S_0_ADDR " : "2",
        "A_MM2S_0_BYTES" : "3",
        "A_MM2S_0_TUSER" : "4",
        "A_MM2S_1_DONE " : "5",
        "A_MM2S_1_ADDR " : "6",
        "A_MM2S_1_BYTES" : "7",
        "A_MM2S_1_TUSER" : "8",
        "A_MM2S_2_DONE " : "9",
        "A_MM2S_2_ADDR " : "A",
        "A_MM2S_2_BYTES" : "B",
        "A_MM2S_2_TUSER" : "C",
        "A_S2MM_DONE   " : "D",
        "A_S2MM_ADDR   " : "E",
        "A_S2MM_BYTES  " : "F",
    }

    # Ensure the working directory exists
    os.makedirs(args.WORK_DIR, exist_ok=True)

    svh_path = os.path.join(args.WORK_DIR, "config.svh")
    h_path = os.path.join(args.WORK_DIR, "config.h")
    tcl_path = os.path.join(args.WORK_DIR, "config.tcl")
    scala_path = os.path.join(args.WORK_DIR, "config.scala")

    # Generate config.svh
    addr_map_sv = "\n".join([f"`define {key} h'{value}" for key, value in addr_map.items()])
    with open(svh_path, 'w') as f:
        f.write(f"""
`define R              {args.R}
`define C              {args.C}
`define WK             {args.WK}
`define WX             {args.WX}
`define WY             {args.WY}
`define VALID_PROB     {args.VALID_PROB}
`define READY_PROB     {args.READY_PROB}
`define CLK_PERIOD     {int(1000.0 / args.FREQ_MHZ)}
`define AXI_WIDTH      {args.AXI_WIDTH}
`define AXIL_WIDTH     {args.AXIL_WIDTH}
`define ADDR_WIDTH     {args.ADDR_WIDTH}
`define DIR            "{args.DATA_DIR}"

`define AXIL_BASE_ADDR 32'h{config_baseaddr}
{addr_map_sv}
""")

    # Generate config.h
    addr_map_c = "\n".join([f"#define {key} 0x{value}" for key, value in addr_map.items()])
    with open(h_path, 'w') as f:
        f.write(f"""
                
#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>
                
#define R               {args.R}
#define C               {args.C}
#define K               {args.K}
#define TK              int{args.WK}_t
#define TX              int{args.WX}_t
#define TY              int{args.WY}_t
#define REG_WIDTH       {args.AXIL_WIDTH}
#define DIR             "{args.DATA_DIR}"

#define CONFIG_BASEADDR 0x{config_baseaddr}
{addr_map_c}

typedef struct {{
  TK k [K][C];
  TX x [K][R];
  TY a [C][R];
  TY y [C][R];
}} Memory_st;

#endif
""")

    # Generate config.tcl
    with open(tcl_path, 'w') as f:
        f.write(f"""
set CONFIG_BASEADDR     0x{config_baseaddr.zfill(8)}
set CONFIG_RANGE        {config_range}
set FREQ_MHZ            {args.FREQ_MHZ}
set AXI_WIDTH           {args.AXI_WIDTH}
set TARGET               {args.TARGET}
""")
    
    # Generate config.scala for Chipyard integration
    with open(scala_path, "w") as f:
        f.write(f"""package chipyard.my_axi_ip

import org.chipsalliance.cde.config.Field

case class MyAxiIPParams(
  baseAddress:   BigInt = 0x{config_baseaddr}L,
  cfgBytes:      Int    = 0x1000,
  axiAddrBits:   Int    = {args.ADDR_WIDTH},
  axiDataBits:   Int    = {args.AXI_WIDTH},
  axiIdBits:     Int    = 6,
  maxBurstBytes: Int    = 32 * ({args.AXI_WIDTH} / 8),
  idCount:       Int    = 1,
  maxFlight:     Int    = 1,
  verilogTop:    String = "my_axi_ip",
  resourcePath:  String = "/vsrc/my_axi_ip_blackbox.sv"
)

case object MyAxiIPKey extends Field[Option[MyAxiIPParams]](None)
""")

    print(f"Generated {svh_path}, {h_path}, {tcl_path}, and {scala_path} successfully.")
