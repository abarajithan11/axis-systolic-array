`timescale 1ns/1ps

module tb_axis_sa;
  localparam int R  = 2;
  localparam int C  = 2;
  localparam int WX = 4;
  localparam int WK = 4;
  localparam int WY = 12;
  localparam int LM = 1;
  localparam int LA = 1;

  logic clk, rstn;
  logic s_valid, s_last, m_ready;
  logic s_ready, m_valid, m_last;
  logic [R-1:0][WX-1:0] sx_data;
  logic [C-1:0][WK-1:0] sk_data;
  logic [R-1:0][WY-1:0] m_data;

  axis_sa #(
    .R(R),
    .C(C),
    .WX(WX),
    .WK(WK),
    .WY(WY),
    .LM(LM),
    .LA(LA)
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .s_valid(s_valid),
    .s_last(s_last),
    .m_ready(m_ready),
    .s_ready(s_ready),
    .m_valid(m_valid),
    .m_last(m_last),
    .sx_data(sx_data),
    .sk_data(sk_data),
    .m_data(m_data)
  );

  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);

  wire s_stall = s_valid && !s_ready;
  wire m_stall = m_valid && !m_ready;

  // Keep only stable handshake properties for now.
  a_stable_s_valid : assume property (s_stall |=> $stable(s_valid));
  a_stable_s_last  : assume property (s_stall |=> $stable(s_last));
  a_stable_sx_data : assume property (s_stall |=> $stable(sx_data));
  a_stable_sk_data : assume property (s_stall |=> $stable(sk_data));

  a_stable_m_valid : assert property (m_stall |=> $stable(m_valid));
  a_stable_m_last  : assert property (m_stall |=> $stable(m_last));
  a_stable_m_data  : assert property (m_stall |=> $stable(m_data));

endmodule
