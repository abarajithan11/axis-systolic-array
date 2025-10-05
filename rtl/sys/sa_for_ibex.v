`timescale 1ns/1ps
`include "config.svh"

// ------------------------------------------------------------
// sa_for_ibex
// - 1x Ibex *device* port (CPU -> AXI-Lite config of SA core)
// - 4x Ibex *host* ports (SA DMA -> system memory)
//   * host0 <- m_axi_mm2s_0  (read)
//   * host1 <- m_axi_mm2s_1  (read)
//   * host2 <- m_axi_mm2s_2  (read)
//   * host3 <- m_axi_s2mm    (write)
// All unused AXI ready/valid inputs are tied LOW (1'b0).
// ------------------------------------------------------------
module sa_for_ibex #(
  parameter int AXI_WIDTH       = `AXI_WIDTH,
  parameter int AXI_ID_WIDTH    = 6,
  parameter int AXI_ADDR_WIDTH  = 32,
  parameter int AXIL_WIDTH      = 32,
  parameter int AXIL_ADDR_WIDTH = 32,
  parameter int STRB_WIDTH      = AXIL_WIDTH/8
  
)(
  input  logic clk,
  input  logic rstn,

  // -------------------- Ibex DEVICE port (CPU -> SA registers) --------------------
  input  logic        dev_req_i,
  input  logic [31:0] dev_addr_i,
  input  logic        dev_we_i,
  input  logic [3:0]  dev_be_i,
  input  logic [31:0] dev_wdata_i,
  output logic        dev_gnt_o,
  output logic        dev_rvalid_o,
  output logic        dev_err_o,
  output logic [31:0] dev_rdata_o,

  // -------------------- Ibex HOST ports (SA DMA -> system memory) -----------------
  // host0 (read)
  output logic        host0_req_o,
  output logic [31:0] host0_addr_o,
  output logic        host0_we_o,
  output logic [3:0]  host0_be_o,
  output logic [31:0] host0_wdata_o,
  input  logic        host0_gnt_i,
  input  logic        host0_rvalid_i,
  input  logic        host0_err_i,
  input  logic [31:0] host0_rdata_i,

  // host1 (read)
  output logic        host1_req_o,
  output logic [31:0] host1_addr_o,
  output logic        host1_we_o,
  output logic [3:0]  host1_be_o,
  output logic [31:0] host1_wdata_o,
  input  logic        host1_gnt_i,
  input  logic        host1_rvalid_i,
  input  logic        host1_err_i,
  input  logic [31:0] host1_rdata_i,

  // host2 (read)
  output logic        host2_req_o,
  output logic [31:0] host2_addr_o,
  output logic        host2_we_o,
  output logic [3:0]  host2_be_o,
  output logic [31:0] host2_wdata_o,
  input  logic        host2_gnt_i,
  input  logic        host2_rvalid_i,
  input  logic        host2_err_i,
  input  logic [31:0] host2_rdata_i,

  // host3 (write)
  output logic        host3_req_o,
  output logic [31:0] host3_addr_o,
  output logic        host3_we_o,
  output logic [3:0]  host3_be_o,
  output logic [31:0] host3_wdata_o,
  input  logic        host3_gnt_i,
  input  logic        host3_rvalid_i,
  input  logic        host3_err_i,
  input  logic [31:0] host3_rdata_i
);

  // ---------------- AXI-Lite wires (dev_to_maxil -> SA "top") ----------------
  logic [AXIL_ADDR_WIDTH-1:0]  axil_awaddr;
  logic                        axil_awvalid;
  logic                        axil_awready;
  logic [AXIL_WIDTH-1:0]       axil_wdata;
  logic [STRB_WIDTH-1:0]       axil_wstrb;
  logic                        axil_wvalid;
  logic                        axil_wready;
  logic [1:0]                  axil_bresp;
  logic                        axil_bvalid;
  logic                        axil_bready;
  logic [AXIL_ADDR_WIDTH-1:0]  axil_araddr;
  logic                        axil_arvalid;
  logic                        axil_arready;
  logic [AXIL_WIDTH-1:0]       axil_rdata;
  logic [1:0]                  axil_rresp;
  logic                        axil_rvalid;
  logic                        axil_rready;

  // ---------------- AXI4 wires (SA masters -> host bridges) ----------------
  localparam int DW   = AXI_WIDTH;
  localparam int STRB = DW/8;

  // mm2s_0 (READ)
  logic [AXI_ID_WIDTH-1:0]      axi0_arid, axi0_rid;
  logic [AXI_ADDR_WIDTH-1:0]    axi0_araddr;
  logic [7:0]                   axi0_arlen;
  logic [2:0]                   axi0_arsize;
  logic [1:0]                   axi0_arburst;
  logic                         axi0_arvalid, axi0_arready;
  logic [DW-1:0]                axi0_rdata;
  logic [1:0]                   axi0_rresp;
  logic                         axi0_rlast, axi0_rvalid, axi0_rready;

  // mm2s_1 (READ)
  logic [AXI_ID_WIDTH-1:0]      axi1_arid, axi1_rid;
  logic [AXI_ADDR_WIDTH-1:0]    axi1_araddr;
  logic [7:0]                   axi1_arlen;
  logic [2:0]                   axi1_arsize;
  logic [1:0]                   axi1_arburst;
  logic                         axi1_arvalid, axi1_arready;
  logic [DW-1:0]                axi1_rdata;
  logic [1:0]                   axi1_rresp;
  logic                         axi1_rlast, axi1_rvalid, axi1_rready;

  // mm2s_2 (READ)
  logic [AXI_ID_WIDTH-1:0]      axi2_arid, axi2_rid;
  logic [AXI_ADDR_WIDTH-1:0]    axi2_araddr;
  logic [7:0]                   axi2_arlen;
  logic [2:0]                   axi2_arsize;
  logic [1:0]                   axi2_arburst;
  logic                         axi2_arvalid, axi2_arready;
  logic [DW-1:0]                axi2_rdata;
  logic [1:0]                   axi2_rresp;
  logic                         axi2_rlast, axi2_rvalid, axi2_rready;

  // s2mm (WRITE)
  logic [AXI_ID_WIDTH-1:0]      axiw_awid, axiw_bid;
  logic [AXI_ADDR_WIDTH-1:0]    axiw_awaddr;
  logic [7:0]                   axiw_awlen;
  logic [2:0]                   axiw_awsize;
  logic [1:0]                   axiw_awburst;
  logic                         axiw_awvalid, axiw_awready;
  logic [DW-1:0]                axiw_wdata;
  logic [STRB-1:0]              axiw_wstrb;
  logic                         axiw_wlast, axiw_wvalid, axiw_wready;
  logic [1:0]                   axiw_bresp;
  logic                         axiw_bvalid, axiw_bready;

  // Make local offset addresses for AXI-Lite
  logic [AXIL_ADDR_WIDTH-1:0]  axil_awaddr_off, axil_araddr_off;
  assign axil_awaddr_off = axil_awaddr;
  assign axil_araddr_off = axil_araddr;

  // ---------------- Instantiate SA core ----------------
  top u_sa (
    .clk  (clk),
    .rstn (rstn),

    // AXI-Lite slave (config)
    .s_axil_awaddr (axil_awaddr_off),
    .s_axil_awprot (3'b000),
    .s_axil_awvalid(axil_awvalid),
    .s_axil_awready(axil_awready),
    .s_axil_wdata  (axil_wdata),
    .s_axil_wstrb  (axil_wstrb),
    .s_axil_wvalid (axil_wvalid),
    .s_axil_wready (axil_wready),
    .s_axil_bresp  (axil_bresp),
    .s_axil_bvalid (axil_bvalid),
    .s_axil_bready (axil_bready),
    .s_axil_araddr (axil_araddr_off),
    .s_axil_arprot (3'b000),
    .s_axil_arvalid(axil_arvalid),
    .s_axil_arready(axil_arready),
    .s_axil_rdata  (axil_rdata),
    .s_axil_rresp  (axil_rresp),
    .s_axil_rvalid (axil_rvalid),
    .s_axil_rready (axil_rready),

    // m_axi_mm2s_0 (READ) -> host0
    .m_axi_mm2s_0_arid    (axi0_arid),
    .m_axi_mm2s_0_araddr  (axi0_araddr),
    .m_axi_mm2s_0_arlen   (axi0_arlen),
    .m_axi_mm2s_0_arsize  (axi0_arsize),
    .m_axi_mm2s_0_arburst (axi0_arburst),
    .m_axi_mm2s_0_arlock  (),     // unused sideband
    .m_axi_mm2s_0_arcache (),
    .m_axi_mm2s_0_arprot  (),
    .m_axi_mm2s_0_arvalid (axi0_arvalid),
    .m_axi_mm2s_0_arready (axi0_arready),
    .m_axi_mm2s_0_rid     (axi0_rid),
    .m_axi_mm2s_0_rdata   (axi0_rdata),
    .m_axi_mm2s_0_rresp   (axi0_rresp),
    .m_axi_mm2s_0_rlast   (axi0_rlast),
    .m_axi_mm2s_0_rvalid  (axi0_rvalid),
    .m_axi_mm2s_0_rready  (axi0_rready),

    // m_axi_mm2s_1 (READ) -> host1
    .m_axi_mm2s_1_arid    (axi1_arid),
    .m_axi_mm2s_1_araddr  (axi1_araddr),
    .m_axi_mm2s_1_arlen   (axi1_arlen),
    .m_axi_mm2s_1_arsize  (axi1_arsize),
    .m_axi_mm2s_1_arburst (axi1_arburst),
    .m_axi_mm2s_1_arlock  (),
    .m_axi_mm2s_1_arcache (),
    .m_axi_mm2s_1_arprot  (),
    .m_axi_mm2s_1_arvalid (axi1_arvalid),
    .m_axi_mm2s_1_arready (axi1_arready),
    .m_axi_mm2s_1_rid     (axi1_rid),
    .m_axi_mm2s_1_rdata   (axi1_rdata),
    .m_axi_mm2s_1_rresp   (axi1_rresp),
    .m_axi_mm2s_1_rlast   (axi1_rlast),
    .m_axi_mm2s_1_rvalid  (axi1_rvalid),
    .m_axi_mm2s_1_rready  (axi1_rready),

    // m_axi_mm2s_2 (READ) -> host2
    .m_axi_mm2s_2_arid    (axi2_arid),
    .m_axi_mm2s_2_araddr  (axi2_araddr),
    .m_axi_mm2s_2_arlen   (axi2_arlen),
    .m_axi_mm2s_2_arsize  (axi2_arsize),
    .m_axi_mm2s_2_arburst (axi2_arburst),
    .m_axi_mm2s_2_arlock  (),
    .m_axi_mm2s_2_arcache (),
    .m_axi_mm2s_2_arprot  (),
    .m_axi_mm2s_2_arvalid (axi2_arvalid),
    .m_axi_mm2s_2_arready (axi2_arready),
    .m_axi_mm2s_2_rid     (axi2_rid),
    .m_axi_mm2s_2_rdata   (axi2_rdata),
    .m_axi_mm2s_2_rresp   (axi2_rresp),
    .m_axi_mm2s_2_rlast   (axi2_rlast),
    .m_axi_mm2s_2_rvalid  (axi2_rvalid),
    .m_axi_mm2s_2_rready  (axi2_rready),

    // m_axi_s2mm (WRITE) -> host3
    .m_axi_s2mm_awid    (axiw_awid),
    .m_axi_s2mm_awaddr  (axiw_awaddr),
    .m_axi_s2mm_awlen   (axiw_awlen),
    .m_axi_s2mm_awsize  (axiw_awsize),
    .m_axi_s2mm_awburst (axiw_awburst),
    .m_axi_s2mm_awlock  (),
    .m_axi_s2mm_awcache (),
    .m_axi_s2mm_awprot  (),
    .m_axi_s2mm_awvalid (axiw_awvalid),
    .m_axi_s2mm_awready (axiw_awready),
    .m_axi_s2mm_wdata   (axiw_wdata),
    .m_axi_s2mm_wstrb   (axiw_wstrb),
    .m_axi_s2mm_wlast   (axiw_wlast),
    .m_axi_s2mm_wvalid  (axiw_wvalid),
    .m_axi_s2mm_wready  (axiw_wready),
    .m_axi_s2mm_bid     (axiw_bid),
    .m_axi_s2mm_bresp   (axiw_bresp),
    .m_axi_s2mm_bvalid  (axiw_bvalid),
    .m_axi_s2mm_bready  (axiw_bready)
  );

  // ---------------- dev_to_maxil: Ibex device -> AXI-Lite master ----------------
  dev_to_maxil #(
    .AXI_ADDR_WIDTH(AXIL_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXIL_WIDTH)
  ) u_cfg (
    .clk   (clk),
    .rst_n (rstn),

    // Ibex device-side
    .data_req_i    (dev_req_i),
    .data_addr_i   (dev_addr_i),
    .data_we_i     (dev_we_i),
    .data_be_i     (dev_be_i),
    .data_wdata_i  (dev_wdata_i),
    .data_gnt_o    (dev_gnt_o),
    .data_rvalid_o (dev_rvalid_o),
    .data_err_o    (dev_err_o),
    .data_rdata_o  (dev_rdata_o),

    // AXI-Lite master
    .M_AXI_AWADDR  (axil_awaddr),
    .M_AXI_AWVALID (axil_awvalid),
    .M_AXI_AWREADY (axil_awready),

    .M_AXI_WDATA   (axil_wdata),
    .M_AXI_WSTRB   (axil_wstrb),
    .M_AXI_WVALID  (axil_wvalid),
    .M_AXI_WREADY  (axil_wready),

    .M_AXI_BRESP   (axil_bresp),
    .M_AXI_BVALID  (axil_bvalid),
    .M_AXI_BREADY  (axil_bready),

    .M_AXI_ARADDR  (axil_araddr),
    .M_AXI_ARVALID (axil_arvalid),
    .M_AXI_ARREADY (axil_arready),

    .M_AXI_RDATA   (axil_rdata),
    .M_AXI_RRESP   (axil_rresp),
    .M_AXI_RVALID  (axil_rvalid),
    .M_AXI_RREADY  (axil_rready)
  );

  // ---------------- saxi_to_host instances ----------------

  // === mm2s_0 (READ) -> host0 ===
  saxi_to_host #(
    .AXI_ID_WIDTH   (AXI_ID_WIDTH),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (DW)
  ) u_h0 (
    .clk   (clk),
    .rst_n (rstn),

    // AR/R from SA master
    .s_axi_arid    (axi0_arid),
    .s_axi_araddr  (axi0_araddr),
    .s_axi_arlen   (axi0_arlen),
    .s_axi_arsize  (axi0_arsize),   // expect 3'b010 for 32-bit data
    .s_axi_arburst (axi0_arburst),  // expect INCR (2'b01)
    .s_axi_arvalid (axi0_arvalid),
    .s_axi_arready (axi0_arready),

    .s_axi_rid     (axi0_rid),
    .s_axi_rdata   (axi0_rdata),
    .s_axi_rresp   (axi0_rresp),
    .s_axi_rlast   (axi0_rlast),
    .s_axi_rvalid  (axi0_rvalid),
    .s_axi_rready  (axi0_rready),

    // AW/W/B not used by this read path — tie inputs low
    .s_axi_awid    ('0),
    .s_axi_awaddr  ('0),
    .s_axi_awlen   ('0),
    .s_axi_awsize  (3'b010),
    .s_axi_awburst (2'b01),
    .s_axi_awvalid (1'b0),
    .s_axi_awready (),

    .s_axi_wdata   ('0),
    .s_axi_wstrb   ('0),
    .s_axi_wlast   (1'b0),
    .s_axi_wvalid  (1'b0),
    .s_axi_wready  (),

    .s_axi_bid     (),
    .s_axi_bresp   (),
    .s_axi_bvalid  (),
    .s_axi_bready  (1'b0),   // tie unused READY low

    // Ibex host port 0
    .data_req_o    (host0_req_o),
    .data_addr_o   (host0_addr_o),
    .data_we_o     (host0_we_o),
    .data_be_o     (host0_be_o),
    .data_wdata_o  (host0_wdata_o),
    .data_gnt_i    (host0_gnt_i),
    .data_rvalid_i (host0_rvalid_i),
    .data_err_i    (host0_err_i),
    .data_rdata_i  (host0_rdata_i)
  );

  // === mm2s_1 (READ) -> host1 ===
  saxi_to_host #(
    .AXI_ID_WIDTH   (AXI_ID_WIDTH),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (DW)
  ) u_h1 (
    .clk   (clk),
    .rst_n (rstn),

    .s_axi_arid    (axi1_arid),
    .s_axi_araddr  (axi1_araddr),
    .s_axi_arlen   (axi1_arlen),
    .s_axi_arsize  (axi1_arsize),
    .s_axi_arburst (axi1_arburst),
    .s_axi_arvalid (axi1_arvalid),
    .s_axi_arready (axi1_arready),

    .s_axi_rid     (axi1_rid),
    .s_axi_rdata   (axi1_rdata),
    .s_axi_rresp   (axi1_rresp),
    .s_axi_rlast   (axi1_rlast),
    .s_axi_rvalid  (axi1_rvalid),
    .s_axi_rready  (axi1_rready),

    .s_axi_awid    ('0),
    .s_axi_awaddr  ('0),
    .s_axi_awlen   ('0),
    .s_axi_awsize  (3'b010),
    .s_axi_awburst (2'b01),
    .s_axi_awvalid (1'b0),
    .s_axi_awready (),

    .s_axi_wdata   ('0),
    .s_axi_wstrb   ('0),
    .s_axi_wlast   (1'b0),
    .s_axi_wvalid  (1'b0),
    .s_axi_wready  (),

    .s_axi_bid     (),
    .s_axi_bresp   (),
    .s_axi_bvalid  (),
    .s_axi_bready  (1'b0),

    .data_req_o    (host1_req_o),
    .data_addr_o   (host1_addr_o),
    .data_we_o     (host1_we_o),
    .data_be_o     (host1_be_o),
    .data_wdata_o  (host1_wdata_o),
    .data_gnt_i    (host1_gnt_i),
    .data_rvalid_i (host1_rvalid_i),
    .data_err_i    (host1_err_i),
    .data_rdata_i  (host1_rdata_i)
  );

  // === mm2s_2 (READ) -> host2 ===
  saxi_to_host #(
    .AXI_ID_WIDTH   (AXI_ID_WIDTH),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (DW)
  ) u_h2 (
    .clk   (clk),
    .rst_n (rstn),

    .s_axi_arid    (axi2_arid),
    .s_axi_araddr  (axi2_araddr),
    .s_axi_arlen   (axi2_arlen),
    .s_axi_arsize  (axi2_arsize),
    .s_axi_arburst (axi2_arburst),
    .s_axi_arvalid (axi2_arvalid),
    .s_axi_arready (axi2_arready),

    .s_axi_rid     (axi2_rid),
    .s_axi_rdata   (axi2_rdata),
    .s_axi_rresp   (axi2_rresp),
    .s_axi_rlast   (axi2_rlast),
    .s_axi_rvalid  (axi2_rvalid),
    .s_axi_rready  (axi2_rready),

    .s_axi_awid    ('0),
    .s_axi_awaddr  ('0),
    .s_axi_awlen   ('0),
    .s_axi_awsize  (3'b010),
    .s_axi_awburst (2'b01),
    .s_axi_awvalid (1'b0),
    .s_axi_awready (),

    .s_axi_wdata   ('0),
    .s_axi_wstrb   ('0),
    .s_axi_wlast   (1'b0),
    .s_axi_wvalid  (1'b0),
    .s_axi_wready  (),

    .s_axi_bid     (),
    .s_axi_bresp   (),
    .s_axi_bvalid  (),
    .s_axi_bready  (1'b0),

    .data_req_o    (host2_req_o),
    .data_addr_o   (host2_addr_o),
    .data_we_o     (host2_we_o),
    .data_be_o     (host2_be_o),
    .data_wdata_o  (host2_wdata_o),
    .data_gnt_i    (host2_gnt_i),
    .data_rvalid_i (host2_rvalid_i),
    .data_err_i    (host2_err_i),
    .data_rdata_i  (host2_rdata_i)
  );

  // === s2mm (WRITE) -> host3 ===
  saxi_to_host #(
    .AXI_ID_WIDTH   (AXI_ID_WIDTH),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (DW)
  ) u_h3 (
    .clk   (clk),
    .rst_n (rstn),

    // AW/W/B from SA write master
    .s_axi_awid    (axiw_awid),
    .s_axi_awaddr  (axiw_awaddr),
    .s_axi_awlen   (axiw_awlen),
    .s_axi_awsize  (axiw_awsize),    // expect 3'b010
    .s_axi_awburst (axiw_awburst),   // expect INCR
    .s_axi_awvalid (axiw_awvalid),
    .s_axi_awready (axiw_awready),

    .s_axi_wdata   (axiw_wdata),
    .s_axi_wstrb   (axiw_wstrb),
    .s_axi_wlast   (axiw_wlast),
    .s_axi_wvalid  (axiw_wvalid),
    .s_axi_wready  (axiw_wready),

    .s_axi_bid     (axiw_bid),
    .s_axi_bresp   (axiw_bresp),
    .s_axi_bvalid  (axiw_bvalid),
    .s_axi_bready  (axiw_bready),

    // AR/R not used by this write path — tie inputs low
    .s_axi_arid    ('0),
    .s_axi_araddr  ('0),
    .s_axi_arlen   ('0),
    .s_axi_arsize  (3'b010),
    .s_axi_arburst (2'b01),
    .s_axi_arvalid (1'b0),
    .s_axi_arready (),

    .s_axi_rid     (),
    .s_axi_rdata   (),
    .s_axi_rresp   (),
    .s_axi_rlast   (),
    .s_axi_rvalid  (),
    .s_axi_rready  (1'b0),

    // Ibex host port 3
    .data_req_o    (host3_req_o),
    .data_addr_o   (host3_addr_o),
    .data_we_o     (host3_we_o),
    .data_be_o     (host3_be_o),
    .data_wdata_o  (host3_wdata_o),
    .data_gnt_i    (host3_gnt_i),
    .data_rvalid_i (host3_rvalid_i),
    .data_err_i    (host3_err_i),
    .data_rdata_i  (host3_rdata_i)
  );

endmodule
