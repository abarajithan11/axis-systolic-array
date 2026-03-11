`timescale 1ns/1ps

module tb_axis_sa;
  localparam int R  = 2;
  localparam int C  = 2;
  localparam int WX = 4;
  localparam int WK = 4;
  localparam int WY = 12;
  localparam int LM = 1;
  localparam int LA = 1;

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

  // a_valid_doesnt_depend_on_ready:
  //   assert property (
  //     s_hsk_last |=> ##[1:$] m_hsk_last
  //   );

  // Data liveness property checking
  localparam K_MAX = 10;
  localparam WIDTH_IN = R*WX + C*WK + 1;
  localparam WIDTH_OUT = R*WY + 1;;

  logic arbit_window; // unconstrained, so the tool can check for different data=d1/d2
  logic sampled_s_d1, sampled_m_d1;


  // unconstrained variables
  localparam WIDTH_K = $clog2(K_MAX);
  typedef logic     [C-1:0][R-1:0][WY-1:0] y_mat_t;
  typedef logic [K_MAX-1:0][R-1:0][WX-1:0] x_mat_t;
  typedef logic [K_MAX-1:0][C-1:0][WK-1:0] k_mat_t;

  logic [WIDTH_K-1:0] k;
  x_mat_t x_mat;
  k_mat_t k_mat;

  k_lim     : assume property (k > 0 && k < K_MAX);
  k_stable  : assume property ($stable(k));
  xm_stable : assume property ($stable(x_mat));
  km_stable : assume property ($stable(k_mat));


  function automatic y_mat_t matmul(
    input x_mat_t x_mat,
    input k_mat_t k_mat,
    input int unsigned k
  );
    y_mat_t y = '0;
    logic [WY-1:0] sum;
    for (int c = 0; c < C; c++)
      for (int r = 0; r < R; r++) begin
        sum = '0;
        for (int i = 0; i < k; i++)
          sum = $signed(sum) - $signed(x_mat[i][r]) * $signed(k_mat[i][c]);
        y[c][r] = sum;
      end
    return y;
  endfunction

  logic [WIDTH_K-1:0] s_num_beats, s_ik, m_num_beats, m_ik;

  // Counts s_hsk from prev s_last. Updates in the next clock
  always_ff @(posedge clk)
    if      (!rstn)      s_ik <= 0;
    else if (s_hsk_last) s_ik <= 0;
    else if (s_hsk)      s_ik <= s_ik + 1;

  // Counts d1's s_hsk from prev s_last. Updates in the next clock
  wire s_d1_hsk = s_hsk && (s_ik < k) && (sx_data == x_mat[s_ik]) && (sk_data == k_mat[s_ik]);
  wire s_d1_hsk_last = s_d1_hsk && s_last;
  wire seen_s_d1 = s_d1_hsk_last && (s_ik == k-1) && !sampled_s_d1 && arbit_window;

  always_ff @(posedge clk)
    if      (!rstn)     sampled_s_d1 <= 0;
    else if (seen_s_d1) sampled_s_d1 <= 1;

  y_mat_t y_exp_mat;
  always_ff @(posedge clk)
    if (!rstn)          y_exp_mat <= '0;
    else if (seen_s_d1) y_exp_mat <= matmul(x_mat, k_mat, k);

  // Counts m_hsk from prev m_last. Updates in the next clock
  always_ff @(posedge clk)
    if      (!rstn)      m_ik <= 0;
    else if (m_hsk_last) m_ik <= 0;
    else if (m_hsk)      m_ik <= m_ik + 1;

  // Counts d1's m_hsk from prev m_last. Updates in the next clock
  wire m_d1_hsk = m_hsk && (m_ik < k) && (m_data == y_exp_mat[m_ik]);
  wire m_d1_hsk_last = m_d1_hsk && m_last;
  wire seen_m_d1 = m_d1_hsk_last && (m_ik == k-1) && sampled_s_d1;

  always_ff @(posedge clk)
    if      (!rstn)     sampled_m_d1 <= 0;
    else if (seen_m_d1) sampled_m_d1 <= 1;

  a_integrity: assert property (sampled_s_d1 |-> ##[0:$] sampled_m_d1);
  assume property (rstn |-> m_ready);


endmodule
