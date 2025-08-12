`timescale 1ns/1ps

module saxi_to_host #(
  parameter int AXI_ID_WIDTH    = 4,
  parameter int AXI_ADDR_WIDTH  = 32,
  parameter int AXI_DATA_WIDTH  = 32,   // must be 32
  parameter int AXI_STRB_WIDTH  = AXI_DATA_WIDTH/8
)(
  input  wire                         clk,
  input  wire                         rst_n,

  // ---------------- AXI4-Slave: Read Address ----------------
  input  wire [AXI_ID_WIDTH-1:0]      s_axi_arid,
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
  input  wire [7:0]                   s_axi_arlen,   // beats-1
  input  wire [2:0]                   s_axi_arsize,  // must be 3'b010
  input  wire [1:0]                   s_axi_arburst, // INCR only (2'b01)
  input  wire                         s_axi_arvalid,
  output reg                          s_axi_arready,

  // ---------------- AXI4-Slave: Read Data --------------------
  output reg  [AXI_ID_WIDTH-1:0]      s_axi_rid,
  output reg  [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  output reg  [1:0]                   s_axi_rresp,   // OKAY=2'b00, SLVERR=2'b10
  output reg                          s_axi_rlast,
  output reg                          s_axi_rvalid,
  input  wire                         s_axi_rready,

  // ---------------- AXI4-Slave: Write Address ----------------
  input  wire [AXI_ID_WIDTH-1:0]      s_axi_awid,
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
  input  wire [7:0]                   s_axi_awlen,   // beats-1
  input  wire [2:0]                   s_axi_awsize,  // must be 3'b010
  input  wire [1:0]                   s_axi_awburst, // INCR only
  input  wire                         s_axi_awvalid,
  output reg                          s_axi_awready,

  // ---------------- AXI4-Slave: Write Data -------------------
  input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
  input  wire [AXI_STRB_WIDTH-1:0]    s_axi_wstrb,
  input  wire                         s_axi_wlast,
  input  wire                         s_axi_wvalid,
  output reg                          s_axi_wready,

  // ---------------- AXI4-Slave: Write Response ---------------
  output reg  [AXI_ID_WIDTH-1:0]      s_axi_bid,
  output reg  [1:0]                   s_axi_bresp,   // OKAY=2'b00, SLVERR=2'b10
  output reg                          s_axi_bvalid,
  input  wire                         s_axi_bready,

  // ---------------- Ibex LSU host port -----------------------
  output reg                          data_req_o,
  output reg  [31:0]                  data_addr_o,   // word aligned
  output reg                          data_we_o,
  output reg  [3:0]                   data_be_o,
  output reg  [31:0]                  data_wdata_o,
  input  wire                         data_gnt_i,
  input  wire                         data_rvalid_i,
  input  wire                         data_err_i,
  input  wire [31:0]                  data_rdata_i
);

  // ---------------- Parameters / Local ----------------
  localparam logic [1:0] AXI_BURST_INCR = 2'b01;
  localparam logic [1:0] RESP_OKAY      = 2'b00;
  localparam logic [1:0] RESP_SLVERR    = 2'b10;

  // Sanity: we implement 32-bit only
  // (Synthesis-time assert; Verilator will warn as well)
  initial begin
    if (AXI_DATA_WIDTH != 32) begin
      $error("AXI_DATA_WIDTH must be 32");
    end
  end

  typedef enum logic [2:0] {IDLE, R_ACTIVE, W_ACTIVE, ISSUE, WAIT_RSP} eng_e;
  eng_e eng_state, eng_state_n;

  // Read command regs
  reg                  rd_cmd_valid;
  reg [AXI_ID_WIDTH-1:0] rd_id;
  reg [31:0]           rd_addr;     // word aligned
  reg [7:0]            rd_len;      // beats remaining (inclusive count)
  reg                  rd_busy;     // burst accepted (address latched)

  // Write command regs
  reg                  wr_cmd_valid;
  reg [AXI_ID_WIDTH-1:0] wr_id;
  reg [31:0]           wr_addr;     // word aligned
  reg [7:0]            wr_len;      // beats remaining (inclusive count)
  reg                  wr_busy;     // burst accepted

  // Write data buffer for current beat
  reg [31:0]           wr_data_q;
  reg [3:0]            wr_strb_q;
  reg                  wr_data_valid;

  // Engine request/response bookkeeping
  reg                  cur_is_write;     // which type the engine is servicing
  reg                  have_grant;       // LSU grant observed for issued req
  reg                  error_seen;       // sticky error within a burst

  // Next-beat address increment (32-bit, INCR)
  function automatic [31:0] next_addr(input [31:0] a);
    next_addr = a + 32'd4;
  endfunction

  // ---------------- AXI Address Acceptance ----------------
  wire ar_ok = s_axi_arvalid &&
               (s_axi_arsize == 3'b010) &&
               (s_axi_arburst == AXI_BURST_INCR) &&
               (s_axi_araddr[1:0] == 2'b00) &&    // word-aligned
               !rd_busy && !wr_busy && (eng_state==IDLE); // simple serialize

  wire aw_ok = s_axi_awvalid &&
               (s_axi_awsize == 3'b010) &&
               (s_axi_awburst == AXI_BURST_INCR) &&
               (s_axi_awaddr[1:0] == 2'b00) &&
               !rd_busy && !wr_busy && (eng_state==IDLE);

  // arready/awready asserted only when we can accept
  always @(*) begin
    s_axi_arready = ar_ok;
    s_axi_awready = aw_ok;
  end

  // Latch read/write command when accepted
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_cmd_valid <= 1'b0;
      rd_busy      <= 1'b0;
      wr_cmd_valid <= 1'b0;
      wr_busy      <= 1'b0;
      rd_id        <= '0;
      wr_id        <= '0;
      rd_addr      <= '0;
      wr_addr      <= '0;
      rd_len       <= 8'd0;
      wr_len       <= 8'd0;
    end else begin
      if (ar_ok) begin
        rd_cmd_valid <= 1'b1;
        rd_busy      <= 1'b1;
        rd_id        <= s_axi_arid;
        rd_addr      <= s_axi_araddr;
        rd_len       <= s_axi_arlen + 8'd1; // beats
      end else if (eng_state==IDLE && rd_cmd_valid && !rd_busy) begin
        // not used
        rd_cmd_valid <= rd_cmd_valid;
      end

      if (aw_ok) begin
        wr_cmd_valid <= 1'b1;
        wr_busy      <= 1'b1;
        wr_id        <= s_axi_awid;
        wr_addr      <= s_axi_awaddr;
        wr_len       <= s_axi_awlen + 8'd1;
      end
    end
  end

  // ---------------- Write Data Channel Handling ----------------
  // Accept WDATA beat when in W_ACTIVE and we're ready for a new beat.
  // We only buffer one beat at a time since LSU is serialized.

  // Ready to take next W beat when: write burst active, engine idle or ready to issue
  wire want_wbeat = (eng_state==W_ACTIVE) && !wr_data_valid;
  always @(*) begin
    s_axi_wready = want_wbeat;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_data_q     <= '0;
      wr_strb_q     <= '0;
      wr_data_valid <= 1'b0;
    end else begin
      // capture a W beat
      if (s_axi_wvalid && s_axi_wready) begin
        wr_data_q     <= s_axi_wdata;
        wr_strb_q     <= s_axi_wstrb;
        wr_data_valid <= 1'b1;
      end
      // once LSU request for this beat is granted (and later responded), we will clear it in state machine
      if ((eng_state==WAIT_RSP) && have_grant && data_rvalid_i) begin
        wr_data_valid <= 1'b0;
      end
    end
  end

  // ---------------- AXI Read Data / Write Response ----------------
  // Default outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rlast  <= 1'b0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= RESP_OKAY;
      s_axi_rid    <= '0;

      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= RESP_OKAY;
      s_axi_bid    <= '0;
    end else begin
      // R channel: drive when read LSU response arrives
      if (data_rvalid_i && !cur_is_write && (eng_state==WAIT_RSP)) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rdata  <= data_rdata_i;
        s_axi_rresp  <= (data_err_i || error_seen) ? RESP_SLVERR : RESP_OKAY;
        s_axi_rid    <= rd_id;
        s_axi_rlast  <= (rd_len == 8'd1); // this beat is last
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
        s_axi_rlast  <= 1'b0;
      end

      // B channel: only once per write burst (after last LSU write response)
      if (data_rvalid_i && cur_is_write && (eng_state==WAIT_RSP) && (wr_len==8'd1)) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= (data_err_i || error_seen) ? RESP_SLVERR : RESP_OKAY;
        s_axi_bid    <= wr_id;
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  // ---------------- LSU Engine FSM ----------------
  // Single engine that serializes read/write bursts into LSU single-beat ops.
  // Sequence: pick R or W burst -> ISSUE request -> wait grant -> wait response -> next beat or finish.

  // choose which side to service (simple policy: prefer write if wr_cmd_valid else read)
  wire pick_write = wr_cmd_valid;
  wire pick_read  = rd_cmd_valid && !wr_cmd_valid;

  // progress flags
  reg [31:0] issue_addr;
  reg [3:0]  issue_be;
  reg [31:0] issue_wdata;

  // latch have_grant, error_seen
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      eng_state   <= IDLE;
      cur_is_write<= 1'b0;
      have_grant  <= 1'b0;
      error_seen  <= 1'b0;
    end else begin
      eng_state <= eng_state_n;

      // track grant during ISSUE/WAIT_RSP
      if (eng_state==ISSUE) begin
        if (data_req_o && data_gnt_i) have_grant <= 1'b1;
      end else if (eng_state==WAIT_RSP && data_rvalid_i) begin
        have_grant <= 1'b0;
      end

      // sticky error within a burst; cleared when burst finishes
      if (eng_state==WAIT_RSP && data_rvalid_i && data_err_i) begin
        error_seen <= 1'b1;
      end
      if (eng_state==IDLE) begin
        error_seen <= 1'b0;
      end
    end
  end

  // Beat counters & addresses update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // nothing
    end else begin
      // Decrement after response is consumed (for read, when R is accepted; for write, when response returns)
      if (eng_state==WAIT_RSP && data_rvalid_i) begin
        if (cur_is_write) begin
          // write beat completed
          if (wr_len != 0) begin
            wr_len  <= wr_len - 8'd1;
            wr_addr <= next_addr(wr_addr);
          end
          // clear beat buffer happens above when rvalid_i
        end else begin
          // read beat completed
          if (rd_len != 0) begin
            rd_len  <= rd_len - 8'd1;
            rd_addr <= next_addr(rd_addr);
          end
        end
      end

      // When bursts complete, clear busy/cmd_valid
      if (eng_state==WAIT_RSP && data_rvalid_i) begin
        if (cur_is_write && wr_len==8'd1) begin
          wr_busy      <= 1'b0;
          wr_cmd_valid <= 1'b0;
        end
        if (!cur_is_write && rd_len==8'd1) begin
          rd_busy      <= 1'b0;
          rd_cmd_valid <= 1'b0;
        end
      end
    end
  end

  // Compute current issue fields
  always @(*) begin
    if (eng_state==W_ACTIVE || (eng_state==ISSUE && cur_is_write)) begin
      issue_addr  = wr_addr;
      issue_be    = wr_strb_q;
      issue_wdata = wr_data_q;
    end else begin
      issue_addr  = rd_addr;
      issue_be    = 4'hF; // full word read
      issue_wdata = 32'h00000000;
    end
  end

  // FSM transitions & LSU driving
  always @(*) begin
    eng_state_n  = eng_state;
    data_req_o   = 1'b0;
    data_addr_o  = 32'd0;
    data_we_o    = 1'b0;
    data_be_o    = 4'h0;
    data_wdata_o = 32'd0;
    case (eng_state)
      IDLE: begin
        if (pick_write) begin
          // start write burst
          eng_state_n  = W_ACTIVE;
        end else if (pick_read) begin
          eng_state_n  = R_ACTIVE;
        end
      end

      W_ACTIVE: begin
        // need a buffered W beat to issue
        if (wr_data_valid) begin
          eng_state_n  = ISSUE;
        end
      end

      R_ACTIVE: begin
        // immediately issue a read beat
        eng_state_n = ISSUE;
      end

      ISSUE: begin
        // drive LSU request
        data_req_o   = 1'b1;
        data_addr_o  = issue_addr;
        data_we_o    = cur_is_write;
        data_be_o    = issue_be;
        data_wdata_o = issue_wdata;

        if (data_gnt_i) begin
          eng_state_n = WAIT_RSP;
        end
      end

      WAIT_RSP: begin
        // Hold until LSU responds – then either next beat or finish burst.
        if (data_rvalid_i) begin
          if (cur_is_write) begin
            if (wr_len==8'd1) begin
              eng_state_n = IDLE;
            end else begin
              eng_state_n = W_ACTIVE; // next write beat
            end
          end else begin
            if (rd_len==8'd1) begin
              eng_state_n = IDLE;
            end else begin
              eng_state_n = R_ACTIVE; // next read beat
            end
          end
        end
      end

      default: eng_state_n = IDLE;
    endcase
  end

  // Set cur_is_write when entering a burst
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur_is_write <= 1'b0;
    end else begin
      if (eng_state==IDLE) begin
        if (pick_write)      cur_is_write <= 1'b1;
        else if (pick_read)  cur_is_write <= 1'b0;
      end
    end
  end

endmodule
