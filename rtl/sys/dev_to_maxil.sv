`timescale 1ns/1ps

// Ibex "device" side (memory target) -> AXI-Lite Master bridge.
// - Accepts 32-bit word-aligned reads/writes from Ibex LSU device-side protocol
//   (data_req_i/... ; gnt+single-cycle rvalid completion)
// - Issues single-beat AXI-Lite transactions with WSTRB mapped from data_be_i.
// - One outstanding request at a time (AXI-Lite allows independent channels, but we serialize).
// - For stores: produces rvalid to Ibex as completion (rdata ignored).
// - For loads : returns read data with rvalid.
// - data_err_o derives from AXI-Lite BRESP/RRESP != OKAY.
//
// NOTE: Ibex LSU presents word-aligned addresses. Misaligned handling is not required here.
module dev_to_maxil #(
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 32  // must be 32 here
)(
  input  logic                      clk,
  input  logic                      rst_n,

  // -------- Ibex device-side (memory target) --------
  input  logic                      data_req_i,
  input  logic [31:0]               data_addr_i,    // word aligned
  input  logic                      data_we_i,
  input  logic [3:0]                data_be_i,
  input  logic [31:0]               data_wdata_i,
  output logic                      data_gnt_o,     // 1-cycle pulse when accepted
  output logic                      data_rvalid_o,  // 1-cycle pulse on completion
  output logic                      data_err_o,     // valid with rvalid_o
  output logic [31:0]               data_rdata_o,   // valid with rvalid_o (reads)

  // -------- AXI-Lite Master --------
  output logic [AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
  output logic                      M_AXI_AWVALID,
  input  logic                      M_AXI_AWREADY,

  output logic [AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
  output logic [AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
  output logic                        M_AXI_WVALID,
  input  logic                        M_AXI_WREADY,

  input  logic [1:0]                M_AXI_BRESP,
  input  logic                      M_AXI_BVALID,
  output logic                      M_AXI_BREADY,

  output logic [AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
  output logic                      M_AXI_ARVALID,
  input  logic                      M_AXI_ARREADY,

  input  logic [AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
  input  logic [1:0]                M_AXI_RRESP,
  input  logic                      M_AXI_RVALID,
  output logic                      M_AXI_RREADY
);

  // ---------------- Internal latches ----------------
  typedef enum logic [2:0] {
    S_IDLE, S_W_AW, S_W_W, S_W_B, S_R_AR, S_R_R, S_RESP
  } state_e;

  state_e             state, nstate;

  // Latched request
  logic [31:0]        req_addr;
  logic               req_we;
  logic [3:0]         req_be;
  logic [31:0]        req_wdata;

  // Error/data capture
  logic               resp_err;
  logic [31:0]        resp_rdata;

  // Handshake qualify
  wire aw_hs = M_AXI_AWVALID & M_AXI_AWREADY;
  wire w_hs  = M_AXI_WVALID  & M_AXI_WREADY;
  wire b_hs  = M_AXI_BVALID  & M_AXI_BREADY;
  wire ar_hs = M_AXI_ARVALID & M_AXI_ARREADY;
  wire r_hs  = M_AXI_RVALID  & M_AXI_RREADY;

  // Accept request
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= S_IDLE;
      req_addr   <= '0;
      req_we     <= 1'b0;
      req_be     <= '0;
      req_wdata  <= '0;
      resp_err   <= 1'b0;
      resp_rdata <= '0;
    end else begin
      state <= nstate;

      // Latch completion info
      if (M_AXI_BVALID) begin
        resp_err <= (M_AXI_BRESP != 2'b00); // not OKAY
      end
      if (M_AXI_RVALID) begin
        resp_err   <= (M_AXI_RRESP != 2'b00);
        resp_rdata <= M_AXI_RDATA;
      end

      // Latch request on accept (pulse gnt)
      if (state == S_IDLE && data_req_i && data_gnt_o) begin
        req_addr  <= data_addr_i;
        req_we    <= data_we_i;
        req_be    <= data_be_i;
        req_wdata <= data_wdata_i;
      end
    end
  end

  // Next-state logic
  always_comb begin
    nstate = state;
    unique case (state)
      S_IDLE: begin
        if (data_req_i) begin
          if (data_we_i) nstate = S_W_AW;
          else           nstate = S_R_AR;
        end
      end

      // WRITE: address then data (can proceed in parallel if ready)
      S_W_AW: begin
        if (aw_hs) begin
          if (M_AXI_WVALID) begin
            if (w_hs) nstate = S_W_B;
            else      nstate = S_W_W;
          end else begin
            nstate = S_W_W;
          end
        end
      end
      S_W_W: begin
        if (w_hs) nstate = S_W_B;
      end
      S_W_B: begin
        if (b_hs) nstate = S_RESP;
      end

      // READ
      S_R_AR: begin
        if (ar_hs) nstate = S_R_R;
      end
      S_R_R: begin
        if (r_hs) nstate = S_RESP;
      end

      // Single-cycle response back to Ibex
      S_RESP: begin
        nstate = S_IDLE;
      end

      default: nstate = S_IDLE;
    endcase
  end

  // AXI-Lite master driving + Ibex response pulses
  // Defaults
  always_comb begin
    // AXI defaults
    M_AXI_AWADDR  = req_addr;
    M_AXI_AWVALID = (state == S_W_AW) && !aw_hs; // keep until handshake
    M_AXI_WDATA   = req_wdata;
    M_AXI_WSTRB   = req_be;
    M_AXI_WVALID  = (state == S_W_W || state == S_W_AW) && !(w_hs && state != S_W_B) && (state != S_W_B);
    M_AXI_BREADY  = (state == S_W_B); // ready to consume BRESP immediately

    M_AXI_ARADDR  = req_addr;
    M_AXI_ARVALID = (state == S_R_AR) && !ar_hs;
    M_AXI_RREADY  = (state == S_R_R); // ready to consume RDATA immediately

    // Ibex handshakes
    data_gnt_o    = (state == S_IDLE) && data_req_i; // accept immediately (1-cycle pulse)
    data_rvalid_o = (state == S_RESP);               // 1-cycle pulse
    data_err_o    = resp_err;
    data_rdata_o  = resp_rdata;
  end

endmodule
