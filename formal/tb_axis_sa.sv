`timescale 1ns/1ps

module tb_axis_sa;
  localparam int R  = 2;
  localparam int C  = 2;
  localparam int WX = 4;
  localparam int WK = 4;
  localparam int WY = 12;
  localparam int LM = 1;
  localparam int LA = 1;
  localparam int K_MAX = 10;

  logic clk, rstn, s_valid, s_last, m_ready, s_ready, m_valid, m_last;
  logic [R-1:0][WX-1:0] sx_data;
  logic [C-1:0][WK-1:0] sk_data;
  logic [R-1:0][WY-1:0] m_data;

  axis_sa #(.R(R),.C(C),.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) dut (.*);

  s_axis_formal #(.WIDTH(R*WX + C*WK + 1)) S_AXIS (
    .clk(clk),
    .rstn(rstn),
    .valid(s_valid),
    .ready(s_ready),
    .payload({sx_data, sk_data, s_last})
  );

  m_axis_formal #(.WIDTH(R*WY + 1)) M_AXIS (
    .clk(clk),
    .rstn(rstn),
    .valid(m_valid),
    .ready(m_ready),
    .payload({m_data, m_last})
  );

  wire s_stall = s_valid && !s_ready;
  wire m_stall = m_valid && !m_ready;

  wire s_hsk = s_valid && s_ready;
  wire s_hsk_last = s_hsk && s_last;
  wire m_hsk = m_valid && m_ready;
  wire m_hsk_last = m_hsk && m_last;

  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);

  // unconstrained variables
  logic arbit_start;
  localparam WIDTH_K = $clog2(K_MAX) + 1; // extra bit to allow out-of-range
  localparam WIDTH_C = $clog2(C) + 1; // extra bit to allow out-of-range
  typedef logic signed     [C-1:0][R-1:0][WY-1:0] y_mat_t;
  typedef logic signed [K_MAX-1:0][R-1:0][WX-1:0] x_mat_t;
  typedef logic signed [K_MAX-1:0][C-1:0][WK-1:0] k_mat_t;

  logic [WIDTH_K-1:0] k;
  x_mat_t x_mat;
  k_mat_t k_mat;

  k_value   : assume property ($stable(k) && (k > 0) && (k < K_MAX));
  xm_stable : assume property ($stable(x_mat));
  km_stable : assume property ($stable(k_mat));

  function automatic y_mat_t matmul(
    input x_mat_t x_mat,
    input k_mat_t k_mat,
    input int unsigned k
  );
    y_mat_t y = '0;
    logic signed [WY-1:0] sum;
    for (int c = 0; c < C; c++)
      for (int r = 0; r < R; r++) begin
        sum = '0;
        for (int i = 0; i < k; i++)
          sum = $signed(sum) + $signed(x_mat[i][r]) * $signed(k_mat[i][c]);
        y[c][r] = sum;
      end
    return y;
  endfunction

  y_mat_t y_exp_mat;
  assign y_exp_mat = matmul(x_mat, k_mat, k);

  // Constrain num_s_beats, assert num_m_beats.

  logic [WIDTH_K-1:0] s_ik;
  always_ff @(posedge clk)
    if      (!rstn)      s_ik <= 0;
    else if (s_hsk_last) s_ik <= 0;
    else if (s_hsk)      s_ik <= s_ik + 1;

  s_s_beats: assume property (s_hsk_last |-> s_ik < K_MAX);

  logic [WIDTH_C-1:0] m_ic;
  always_ff @(posedge clk)
    if      (!rstn)      m_ic <= 0;
    else if (m_hsk_last) m_ic <= 0;
    else if (m_hsk)      m_ic <= m_ic + 1;

  s_m_beats: assert property (m_hsk_last |-> m_ic == C-1);


  // Start arbitary transaction

  typedef enum {IDLE, INFLIGHT, DONE} state_t;
  state_t state, next_state;

  always_comb begin
    next_state = state;
    case (state)
      IDLE    : if (s_hsk_last && arbit_start) next_state = INFLIGHT;
      INFLIGHT: if (s_hsk_last)                next_state = DONE;
    endcase
  end
  always_ff @(posedge clk)
    if  (!rstn) state <= IDLE;
    else        state <= next_state;

  s_data_matched: assume property (
    (state == INFLIGHT && s_valid) |-> (sx_data == x_mat[s_ik]) && (sk_data == k_mat[s_ik]));

  s_last_matched_other_beats: assume property (
    (state == INFLIGHT && s_valid && (s_ik != k-1)) |-> !s_last);
  s_last_matched_last_beat: assume property (
    (state == INFLIGHT && s_valid && (s_ik == k-1)) |-> s_last);


  // Capture m_data

  y_mat_t y_mat;
  always_ff @(posedge clk)
    if      (!rstn)      y_mat       <= '0;
    else if (m_hsk)      y_mat[m_ic] <= m_data;

  a_matmul: assert property (
    $rose(state == DONE) |-> ##[1:100] ($past(m_hsk_last) && y_mat == y_exp_mat));

endmodule
