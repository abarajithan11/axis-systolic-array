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

  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);


endmodule
