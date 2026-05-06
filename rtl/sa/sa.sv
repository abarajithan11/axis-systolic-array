`timescale 1ns/1ps
`include "config.svh"
`define DIAG(a, b) (a+b)
`define MIN(a, b) ((a) < (b) ? (a) : (b))
`define MAX(a, b) ((a) > (b) ? (a) : (b))

module sa #(
    parameter RE=4, CE=8, WX=4, WK=8, WY=16, LM=1, LA=1, OC=CE
    // rows, columns, x_width, k_width, y_width, multiplier latency, accumulator latency
  )(
    input  logic clk, rstn,
    input  logic s_valid_0, s_last_0, m_ready_0,
    input  logic x_ready, k_ready,
    output logic s_ready_0, m_valid_0, m_last_0,
    output logic en_mac, en_shift,
    output logic x_valid, x_last, k_valid, k_last,
    input  logic [RE-1:0][WX-1:0] xi_data,
    input  logic [CE-1:0][WK-1:0] ki_data,
    input  logic [RE-1:0][WY-1:0] ri_data,
    output logic [RE-1:0][WX-1:0] xo_data,
    output logic [CE-1:0][WK-1:0] ko_data,
    output logic [RE-1:0][WY-1:0] ro_data
  );

  genvar r, c, d;
  localparam D  = `DIAG(RE,CE)-1; // length of diagonal
  localparam DM = `MAX(D, OC);
  localparam WD = `MAX(1, $clog2(DM));

  logic [RE-1:0][CE-1:0][WX-1:0] xo;
  logic [RE-1:0][CE-1:0][WK-1:0] ko;
  logic [RE-1:0][CE-1:0][WY-1:0] ro;

  logic [D-1:0] en_copy, en_copy_next, a_valid, a_valid_next, m_first;
  logic [LM+LA+D-1:0] valid, vlast;

  logic s_ready_next, m_valid_next, m_last_next;
  logic en_mac_next, en_shift_next, shifting, shifting_next;
  logic s_hsk, m_hsk, input_block, input_block_next, copying, copying_next, mac_stall_next;
  logic copy_start, copy_last_en, shift_start, shift_last, boundary_ready;
  logic [CE-1:0] copy_ready_col;
  logic [WD-1:0] c_shift_col, c_shift_col_next;
  logic [WD-1:0] c_copy_diag, c_copy_diag_next;
  logic [WD-1:0] copy_col_next;

  for (r=0; r<RE; r=r+1) begin:PER
    for (c=0; c<CE; c=c+1) begin:PEC
      pe #(.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) PE (
        .clk     (clk),
        .rstn    (rstn),
        .en_mac  (en_mac),
        .en_shift(en_shift),
        .m_first (m_first[`DIAG(r,c)]),
        .m_valid (valid[LM+`DIAG(r,c)]),
        .r_copy  (en_copy[`DIAG(r,c)]),
        .ki      (r == 0 ? ki_data[c] : ko[r-1][c]),
        .xi      (c == 0 ? xi_data[r] : xo[r][c-1]),
        .ri      (c == 0 ? ri_data[r] : ro[r][c-1]),
        .ko      (ko[r][c]),
        .xo      (xo[r][c]),
        .ro      (ro[r][c])
      );
  end end

  for (r=0; r<RE; r=r+1) begin
    assign xo_data[r]   = xo[r][CE-1];
    assign ro_data[r]   = ro[r][CE-1];
  end

  for (c=0; c<CE; c=c+1)
    assign ko_data[c] = ko[RE-1][c];

  n_delay #(.N(LM+LA+D), .W(1)) VALID (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk            ), .o(), .d(valid));
  n_delay #(.N(LM+LA+D), .W(1)) VLAST (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk && s_last_0), .o(), .d(vlast));

  assign x_valid = valid[CE];
  assign k_valid = valid[RE];
  assign x_last  = vlast[CE];
  assign k_last  = vlast[RE];

  counter #(.MAX(D), .W(WD)) COPY_COUNTER (
    .clk(clk), .rstn(rstn),
    .start(copy_start), .en_active(en_mac),
    .cnt(c_copy_diag), .cnt_n(c_copy_diag_next),
    .active(copying), .active_n(copying_next),
    .last(), .last_n(), .last_en(copy_last_en)
  );

  counter #(.MAX(OC), .W(WD)) SHIFT_COUNTER (
    .clk(clk), .rstn(rstn),
    .start(shift_start), .en_active(m_hsk),
    .cnt(c_shift_col), .cnt_n(c_shift_col_next),
    .active(shifting), .active_n(shifting_next),
    .last(shift_last), .last_n(), .last_en()
  );

  for (d=0; d<D; d=d+1) begin
    always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
      if (!rstn)            m_first[d] <= 1'b1;
      else if (valid[LM+d]) m_first[d] <= vlast[LM+d];
    end
  end

  always_comb begin
    input_block_next = input_block;
    if (s_hsk && s_last_0) input_block_next = 1'b1;
    if (copy_last_en)      input_block_next = 1'b0;
  end

  always_comb begin
    s_hsk          = s_valid_0 && s_ready_0;
    m_hsk          = m_valid_0 && m_ready_0;
    boundary_ready = x_ready && k_ready;
    copy_start     = en_mac && a_valid_next[0];
    shift_start    = !shifting && en_copy[D-1];
    copy_ready_col = !shifting ? '1 : c_shift_col >= WD'(CE) ? '0 : (CE'(1) << c_shift_col) - CE'(1);
    copy_col_next  = `MIN(c_copy_diag_next, WD'(CE-1));
    mac_stall_next = (shifting_next && copying_next && ((c_shift_col >= WD'(CE)) || (copy_col_next >= c_shift_col))) || !boundary_ready;
    s_ready_next   = !mac_stall_next && !input_block_next;
    en_mac_next    = !mac_stall_next;
  end

  for (d=0; d<D; d=d+1) begin
    assign a_valid_next[d] = en_mac ? vlast[LM+LA+d-1] : a_valid[d];
    assign en_copy_next[d] = a_valid_next[d] && en_mac_next && copy_ready_col[`MIN(d, CE-1)];
  end

  always_comb begin
    en_shift_next = 1'b0;
    m_valid_next  = m_valid_0;
    m_last_next   = m_last_0;

    if (!shifting) begin
      m_valid_next = en_copy[D-1];
      m_last_next  = en_copy[D-1] && (OC == 1);
    end else if (!m_valid_0) begin
      m_valid_next = 1'b1;
      m_last_next  = shift_last;
    end else if (m_hsk) begin
      en_shift_next = !m_last_0;
      m_valid_next  = 1'b0;
      m_last_next   = 1'b0;
    end
  end

  always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
    if (!rstn) begin
      en_mac      <= 1'b0;
      en_shift    <= 1'b0;
      en_copy     <= '0;
      s_ready_0   <= 1'b0;
      m_valid_0   <= 1'b0;
      m_last_0    <= 1'b0;
      a_valid     <= '0;
      input_block <= 1'b0;
    end else begin
      en_mac      <= en_mac_next;
      en_shift    <= en_shift_next;
      en_copy     <= en_copy_next;
      s_ready_0   <= s_ready_next;
      m_valid_0   <= m_valid_next;
      m_last_0    <= m_last_next;
      a_valid     <= a_valid_next;
      input_block <= input_block_next;
    end
  end

endmodule
