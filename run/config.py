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
    parser.add_argument('--BOARD', default="zcu104", type=str)
    parser.add_argument('--WORK_DIR', default='work', type=str)

    args = parser.parse_args()

    '''
    Each FPGA board allows a specific AXI base address and range.
    '''
    if args.BOARD == "pynq_z2":
        config_baseaddr, config_range = "40000000", "1G"
    elif args.BOARD == "zcu104":
        config_baseaddr, config_range = "B0000000", "256M"
    elif args.BOARD == "zcu102":
        config_baseaddr, config_range = "B0000000", "256M"
    else:
        config_baseaddr, config_range = "40000000", "256M"



    # Ensure the working directory exists
    os.makedirs(args.WORK_DIR, exist_ok=True)

    svh_path = os.path.join(args.WORK_DIR, "config.svh")
    h_path = os.path.join(args.WORK_DIR, "config.h")
    tcl_path = os.path.join(args.WORK_DIR, "config.tcl")

    # Generate config.svh
    with open(svh_path, 'w') as f:
        f.write(f"""
`define R              {args.R}
`define C              {args.C}
`define WK             {args.WK}
`define WX             {args.WX}
`define WY             {args.WY}
`define AXIL_BASE_ADDR 32'h{config_baseaddr}
`define VALID_PROB     {args.VALID_PROB}
`define READY_PROB     {args.READY_PROB}
`define CLK_PERIOD     {int(1000.0 / args.FREQ_MHZ)}
`define AXI_WIDTH      {args.AXI_WIDTH}
`define AXIL_WIDTH     {args.AXIL_WIDTH}
`define ADDR_WIDTH     {args.ADDR_WIDTH}
`define DIR            "{args.DATA_DIR}"
""")

    # Generate config.h
    with open(h_path, 'w') as f:
        f.write(f"""
#define R               {args.R}
#define C               {args.C}
#define K               {args.K}
#define TK              int{args.WK}_t
#define TX              int{args.WX}_t
#define TY              int{args.WY}_t
#define CONFIG_BASEADDR 0x{config_baseaddr}
#define DIR             "{args.DATA_DIR}"
""")

    # Generate config.tcl
    with open(tcl_path, 'w') as f:
        f.write(f"""
set CONFIG_BASEADDR     0x{config_baseaddr.zfill(8)}
set CONFIG_RANGE        {config_range}
set FREQ_MHZ            {args.FREQ_MHZ}
set AXI_WIDTH           {args.AXI_WIDTH}
set BOARD               {args.BOARD}
""")

    print(f"Generated {svh_path}, {h_path}, and {tcl_path} successfully.")
