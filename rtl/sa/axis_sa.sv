`timescale 1ns/1ps
`define DIAG(a, b) (a+b)

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
  localparam WM = WX + WK;

  localparam MAX_DC = D > C ? D : C;
  localparam WDC    = MAX_DC <= 1 ? 1 : $clog2(MAX_DC);

  logic [R-1:0][WX-1:0] xi_delayed;
  logic [C-1:0][WK-1:0] ki_delayed, sk_reversed;
  logic [R-1:0][C-1:0][WX-1:0] xo;
  logic [R-1:0][C-1:0][WK-1:0] ko;
  logic [R-1:0][C-1:0][WY-1:0] ro;

  logic [D-1:0] r_copy, r_copy_next, a_valid, a_valid_next, m_first;
  logic [LM+LA+D-1:0] valid, vlast;

  enum logic { MAC_FILL, MAC_WAIT } mac_state, mac_state_next;
  enum logic { SHIFT_IDLE, SHIFT_BUSY } shift_state, shift_state_next;

  logic en_mac, en_mac_next;
  logic en_shift, en_shift_next;
  logic s_ready_next, m_valid_next, m_last_next;
  logic s_hsk, mac_stall_next;
  logic [WDC-1:0] shift_count, shift_count_next;

  // ---------- DATAPATH ----------

  // Reverse the columns of K matrix, so that outputs come out with C=0 first.
  for (c=0; c<C; c=c+1)
    assign sk_reversed[c] = sk_data[C-1-c];

  // Triangular buffer for x and k.
  tri_buffer #(.W(WX), .N(R)) TRI_X (.clk(clk), .rstn(rstn), .cen(en_mac), .x(sx_data    ), .y(xi_delayed));
  tri_buffer #(.W(WK), .N(C)) TRI_K (.clk(clk), .rstn(rstn), .cen(en_mac), .x(sk_reversed), .y(ki_delayed));

  for (r=0; r<R; r=r+1) begin:PER
    for (c=0; c<C; c=c+1) begin:PEC

      pe #(.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) PE (
        .clk     (clk),
        .rstn    (rstn),
        .en_mac  (en_mac),
        .en_shift(en_shift),
        .m_first (m_first[`DIAG(r,c)]),
        .m_valid (valid[LM+`DIAG(r,c)]),
        .r_copy  (r_copy[`DIAG(r,c)]),
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

  assign s_hsk = s_valid && s_ready;

  n_delay #(.N(LM+LA+D), .W(1)) VALID (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk          ), .o(), .d(valid));
  n_delay #(.N(LM+LA+D), .W(1)) VLAST (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_hsk && s_last), .o(), .d(vlast));

  for (d=0; d<D; d=d+1) begin
    always_ff @(posedge clk)
      if (!rstn)            m_first[d] <= 1'b1;
      else if (valid[LM+d]) m_first[d] <= vlast[LM+d];
  end

  always_comb begin
    a_valid_next = a_valid;
    if (en_mac)
      for (int i=0; i<D; i=i+1)
        a_valid_next[i] = vlast[LM+LA+i-1];
    mac_stall_next = (shift_state_next == SHIFT_BUSY) && a_valid_next[0];
  end

  // State machines

  always_comb begin
    shift_state_next = shift_state;
    case (shift_state)
      SHIFT_IDLE: if (r_copy[D-1])
        shift_state_next = SHIFT_BUSY;
      SHIFT_BUSY: if (m_valid && m_ready && m_last)
        shift_state_next = SHIFT_IDLE;
    endcase
  end

  always_comb begin
    mac_state_next = mac_state;
    case (mac_state)
      MAC_FILL: if (mac_stall_next)
        mac_state_next = MAC_WAIT;
      MAC_WAIT: if (shift_state_next == SHIFT_IDLE)
        mac_state_next = MAC_FILL;
    endcase
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      mac_state   <= MAC_FILL;
      shift_state <= SHIFT_IDLE;
    end else begin
      mac_state   <= mac_state_next;
      shift_state <= shift_state_next;
    end
  end

  always_comb begin
    en_shift_next    = 1'b0;
    m_valid_next     = m_valid;
    m_last_next      = m_last;
    shift_count_next = shift_count;

    if (shift_state == SHIFT_IDLE) begin
      m_valid_next     = 1'b0;
      m_last_next      = 1'b0;
      shift_count_next = '0;
      if (r_copy[D-1]) begin
        m_valid_next = 1'b1;
        m_last_next  = C == 1;
      end
    end else if (!m_valid) begin
      m_valid_next = 1'b1;
      m_last_next  = shift_count == WDC'(C-1);
    end else if (m_ready) begin
      if (m_last) begin
        m_valid_next     = 1'b0;
        m_last_next      = 1'b0;
        shift_count_next = '0;
      end else begin
        en_shift_next    = 1'b1;
        m_valid_next     = 1'b0;
        m_last_next      = 1'b0;
        shift_count_next = shift_count + WDC'(1);
      end
    end

    en_mac_next = mac_state_next == MAC_FILL;
    s_ready_next = en_mac_next;
    r_copy_next = en_mac_next ? a_valid_next : '0;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      en_mac      <= 1'b0;
      en_shift    <= 1'b0;
      s_ready     <= 1'b0;
      m_valid     <= 1'b0;
      m_last      <= 1'b0;
      r_copy      <= '0;
      a_valid     <= '0;
      shift_count <= '0;
    end else begin
      en_mac      <= en_mac_next;
      en_shift    <= en_shift_next;
      s_ready     <= s_ready_next;
      m_valid     <= m_valid_next;
      m_last      <= m_last_next;
      r_copy      <= r_copy_next;
      a_valid     <= a_valid_next;
      shift_count <= shift_count_next;
    end
  end
  
endmodule
