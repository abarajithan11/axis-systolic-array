`timescale 1ns/1ps
`include "config.svh"
`define DIAG(a, b) (a+b)
`define MIN(a, b) ((a) < (b) ? (a) : (b))
`define MAX(a, b) ((a) > (b) ? (a) : (b))

module axis_sa #(
    parameter  R=4, C=8, WX=4, WK=8, WY=16, LM=1, LA=1
    // rows, columns, x_width, k_width, y_width, multiplier latency, accumulator latency
  )(
    input  logic clk, rstn,
    input  logic s_valid, s_last, m_ready,
    output logic s_ready, m_valid, m_last,
    input  logic [R-1:0][WX-1:0] sx_data,
    input  logic [C-1:0][WK-1:0] sk_data,
    output logic [R-1:0][WY-1:0] m_data
  );

  genvar r, c, d;
  localparam D  = `DIAG(R,C)-1; // length of diagonal
  localparam WD = `MAX(1, $clog2(D));

  logic [R-1:0][WX-1:0] xi_delayed;
  logic [C-1:0][WK-1:0] ki_delayed, sk_reversed;
  logic [R-1:0][C-1:0][WX-1:0] xo;
  logic [R-1:0][C-1:0][WK-1:0] ko;
  logic [R-1:0][C-1:0][WY-1:0] ro;

  logic [D-1:0] en_copy, en_copy_next, a_valid, a_valid_next, m_first, copy_req;
  logic [LM+LA+D-1:0] valid, vlast;

  logic s_ready_next, m_valid_next, m_last_next;
  logic en_mac, en_mac_next, en_shift, en_shift_next, shifting, shifting_next;
  logic s_hsk, m_hsk, input_block, input_block_next, copying, copying_next, mac_stall_next;
  logic copy_start, copy_last_en, shift_start, shift_last, shift_draining;
  logic [C-1:0] copy_ready_col;
  logic [WD-1:0] c_shift_col, c_shift_col_next;
  logic [WD-1:0] c_copy_diag, c_copy_diag_next;
  logic [WD-1:0] copy_col_next;

  // ---------- DATAPATH ----------

  // Reverse the columns of K matrix, so that outputs come out with C=0 first.
  for (c=0; c<C; c=c+1)
    assign sk_reversed[c] = sk_data[C-1-c];

  // Triangular buffer for x and k.
  tri_buffer #(.W(WX), .N(R)) TRI_X (.clk(clk), .rstn(rstn), .cen(en_mac), .x(s_hsk ? sx_data     : '0), .y(xi_delayed));
  tri_buffer #(.W(WK), .N(C)) TRI_K (.clk(clk), .rstn(rstn), .cen(en_mac), .x(s_hsk ? sk_reversed : '0), .y(ki_delayed));

  for (r=0; r<R; r=r+1) begin:PER
    for (c=0; c<C; c=c+1) begin:PEC

      pe #(.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) PE (
        .clk     (clk),
        .rstn    (rstn),
        .en_mac  (en_mac),
        .en_shift(en_shift),
        .m_first (m_first[`DIAG(r,c)]),
        .m_valid (valid[LM+`DIAG(r,c)]),
        .r_copy  (en_copy[`DIAG(r,c)]),
        .ki      (r == 0 ? ki_delayed[c] : ko[r-1][c]),
        .xi      (c == 0 ? xi_delayed[r] : xo[r][c-1]),
        .ri      (c == 0 ? WY'(0)        : ro[r][c-1]),
        .ko      (ko[r][c]),
        .xo      (xo[r][c]),
        .ro      (ro[r][c])
      );
  end end

  for (r=0; r<R; r=r+1)
    assign m_data[r] = ro[r][C-1];


  // ---------- CONTROL PATH ----------

  n_delay #(.N(LM+LA+D), .W(1)) VALID (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk          ), .o(), .d(valid));
  n_delay #(.N(LM+LA+D), .W(1)) VLAST (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk && s_last), .o(), .d(vlast));

  counter #(.MAX(D), .W(WD)) COPY_COUNTER (
    .clk(clk), .rstn(rstn),
    .start(copy_start), .en_active(en_mac),
    .cnt(c_copy_diag), .cnt_n(c_copy_diag_next),
    .active(copying), .active_n(copying_next),
    .last(), .last_n(), .last_en(copy_last_en)
  );

  counter #(.MAX(C), .W(WD)) SHIFT_COUNTER (
    .clk(clk), .rstn(rstn),
    .start(shift_start), .en_active(m_hsk),
    .cnt(c_shift_col), .cnt_n(c_shift_col_next),
    .active(shifting), .active_n(shifting_next),
    .last(shift_last), .last_n(), .last_en()
  );

  for (d=0; d<D; d=d+1) begin
    always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
      if (!rstn)            m_first[d] <= 1'b1;
      else if (en_mac && valid[LM+d]) m_first[d] <= vlast[LM+d];
    end
  end
  
  always_comb begin
    input_block_next = input_block;
    if (s_hsk && s_last) input_block_next = 1'b1;
    if (en_copy_next[D-1]) input_block_next = 1'b0;
  end

  always_comb begin
    s_hsk          = s_valid && s_ready;
    m_hsk          = m_valid && m_ready;
    shift_draining = shifting && !(m_hsk && m_last);
    copy_start     = en_mac && copy_req[0] && !shift_draining;
    shift_start    = !shifting && en_copy[D-1];
    copy_ready_col = !shifting ? '1 : (C'(1) << c_shift_col) - C'(1);
    copy_col_next  = `MIN(c_copy_diag_next, WD'(C-1));
    mac_stall_next = (shifting_next && copying_next && (copy_col_next >= c_shift_col))
                   || (copy_req[0] && shift_draining);
    s_ready_next   = !mac_stall_next && !input_block_next;
    en_mac_next    = !mac_stall_next;
  end

  for (d=0; d<D; d=d+1) begin
    assign copy_req[d]     = a_valid[d] | (en_mac & vlast[LM+LA+d-1]);
    assign en_copy_next[d] = copy_req[d] && en_mac_next && copy_ready_col[`MIN(d, C-1)];
    assign a_valid_next[d] = copy_req[d] & ~en_copy_next[d];
  end

  always_comb begin
    en_shift_next = 1'b0;
    m_valid_next  = m_valid;
    m_last_next   = m_last;

    if (!shifting) begin
      m_valid_next = en_copy[D-1];
      m_last_next  = en_copy[D-1] && (C == 1);
    end else if (!m_valid) begin
      m_valid_next = 1'b1;
      m_last_next  = shift_last;
    end else if (m_hsk) begin
      en_shift_next = !m_last;
      m_valid_next  = 1'b0;
      m_last_next   = 1'b0;
    end
  end

  always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
    if (!rstn) begin
      en_mac      <= 1'b0;
      en_shift    <= 1'b0;
      en_copy     <= '0;
      s_ready     <= 1'b0;
      m_valid     <= 1'b0;
      m_last      <= 1'b0;
      a_valid     <= '0;
      input_block <= 1'b0;
    end else begin
      en_mac      <= en_mac_next;
      en_shift    <= en_shift_next;
      en_copy     <= en_copy_next;
      s_ready     <= s_ready_next;
      m_valid     <= m_valid_next;
      m_last      <= m_last_next;
      a_valid     <= a_valid_next;
      input_block <= input_block_next;
    end
  end
  
endmodule
