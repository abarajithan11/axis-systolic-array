# FireBridge README

FireBridge is a simulation harness that lets you run real-world firmware logic in the simulator process and drive an AXI-based RTL design.

It provides:
- **MMIO (register reads/writes) from firmware to RTL** via DPI → SystemVerilog → AXI(-Lite)
- **DDR-like reads/writes from RTL AXI masters** via an AXI-to-byte-memory adapter (DPI byte reads/writes)

This avoids modeling a full CPU core while still exercising realistic firmware flows (configure regs, start DMA, poll status, validate outputs).

---

## Components

### `fb_axi_vip.sv` (SV side)

`fb_axi_vip` is the bridge between C firmware and AXI ports in SystemVerilog.

It has two independent roles:

1) **Drives AXI transactions into DUT slave ports** (register read/write from firmware)
- Signals: `s_axi_*` (outputs from VIP, inputs to DUT)
- `S_COUNT`: number of slave address windows
- `S_AXI_BASE_ADDR[s]`: base addresses used to pick which slave index gets a given MMIO access

2) **Emulates a DDR Memory**
- Signals: `m_axi_*` (inputs from DUT, outputs from VIP)
- `M_COUNT`: number of DUT master ports

Memory congestion emulation:
- `VALID_PROB`, `READY_PROB` randomly gate valid/ready to emulate congestion.
- Read/write bytes through DPI-C:
  - `fb_c_read_ddr8_addr32(addr32, p_mem) -> byte`
  - `fb_c_write_ddr8_addr32(addr32, byte, p_mem)`

Simulation entry:
- After `rstn`, SV gets a pointer to the backing memory and calls firmware:
  - `p_mem = fb_get_mem_p();`
  - `run_sim(p_mem);`
- When firmware returns, SV sets `firebridge_done`.

---

### `fb_fw_wrap.h` (C side API)
Single header used for both simulation and real targets.

Types:
- `fb_reg_t` is `volatile u32` or `volatile u64` depending on `REG_WIDTH`.

MMIO (register read/write) base address (you may add multiple):
```c
fb_reg_t *cfg = (fb_reg_t*)CONFIG_BASEADDR;
```

MMIO access:
- In `SIM` builds these call DPI tasks.
- In non-`SIM` builds they dereference the pointer directly.

```c
fb_write_reg(cfg + REG_OFF, value);
val = fb_read_reg(cfg + REG_OFF);
```

SIM pointer translation for DMA addresses:
- Firmware has host pointers (e.g. `mp->k`)
- DUT expects 32-bit device addresses
- FireBridge maps host pointers into a simulated DDR window (`FB_SIM_DDR_BASE`)

```c
u32 dev_addr = fb_shorten_ptr(host_ptr, mp);  // host -> device addr32
u64 host_ptr = fb_widen_ptr(dev_addr, mp);    // device -> host (used by SV DPI helpers)
```

---

## Testbench wiring (2 slaves, 2 masters)

This is the minimal setup most people want:
- **2 AXI(-Lite) slave windows** for MMIO (e.g., control + debug)
- **2 AXI masters** from the DUT (e.g., two DMAs) serviced by FireBridge “DDR”

### 1) Define counts, buses, instantiate VIP
```systemverilog
module tb;
  logic clk=0, rstn=0, firebridge_done;
  always #5 clk = ~clk;

  localparam int S_COUNT = 2;
  localparam int M_COUNT = 2;

  // VIP -> DUT slave windows (MMIO)
  wire [S_COUNT-1:0][ID_W-1:0]   s_axi_awid;
  wire [S_COUNT-1:0][ADDR_W-1:0] s_axi_awaddr;
  ...
  // DUT masters -> VIP DDR
  wire [M_COUNT-1:0][ID_W-1:0]   m_axi_arid;
  wire [M_COUNT-1:0][ADDR_W-1:0] m_axi_araddr;
  ...

  // Two slave base addrs. Concatenation corresponds to indices [1], [0].
  localparam [S_COUNT-1:0][31:0] S_BASE = {
    32'hA100_0000,  // s=1 (window 1)
    32'hA000_0000   // s=0 (window 0)
  };

  fb_axi_vip #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .S_AXI_BASE_ADDR(S_BASE),
    ...
  ) FB (.*);

  my_ip DUT (
    .clk(clk), .rstn(rstn),
    ...
    .s_axi0_awaddr (s_axi_awaddr[0]),
    .s_axi0_awvalid(s_axi_awvalid[0]),
    .s_axi0_awready(s_axi_awready[0]),
    ...
    .s_axi1_awaddr (s_axi_awaddr[1]),
    .s_axi1_awvalid(s_axi_awvalid[1]),
    .s_axi1_awready(s_axi_awready[1]),
    ...
    .m_axi0_araddr (m_axi_araddr[0]),
    .m_axi0_rdata  (m_axi_rdata [0]),
    ...
    .m_axi1_araddr (m_axi_araddr[1]),
    .m_axi1_rdata  (m_axi_rdata [1]),
    ...
  );

  initial begin
    repeat (2) @(posedge clk);
    rstn = 1;
    wait (firebridge_done);
    $finish;
  end
endmodule
```

---

## Firmware: two MMIO windows + two masters

Define the same base addresses in C firmware:

```c
#define CFG0_BASE 0xA0000000u
#define CFG1_BASE 0xA1000000u

fb_reg_t *cfg0 = (fb_reg_t*)CFG0_BASE;  // slave window 0
fb_reg_t *cfg1 = (fb_reg_t*)CFG1_BASE;  // slave window 1

fb_write_reg(cfg0 + 1, 10); // write 10 to the 2nd register in slave 0
fb_write_reg(cfg1 + 5, 20); // write 20 to the 6th register in slave 0
```

---

## Notes / constraints

- MMIO transactions in `fb_axi_vip` use full strobes for the configured AXI-Lite width.
- Firmware-provided addresses are truncated to `S_AXI_ADDR_WIDTH` when driving `s_axi_*`.
- `S_AXI_BASE_ADDR` must be sorted by increasing address, because `get_s_index()` checks ranges:
  - window 0 covers `[base[0], base[1])`
  - last window covers `[base[last], +inf)`
- `firebridge_done` is asserted when `run_sim()` returns.

---

## Files to read first
- `fb_axi_vip.sv` (interfaces, address decode, DPI entry)
- `fb_fw_wrap.h` (MMIO helpers, pointer translation)
- `firmware.h` (example register programming + DMA flow)
