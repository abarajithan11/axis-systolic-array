`timescale 1ns/1ps

module pe #(
  parameter WX=4, WK=8, WY=16, LM=1, LA=1
)(
  input  logic clk, rstn,
  input  logic en_mac, en_shift, m_first, m_valid, r_copy,
  input  logic [WK-1:0] ki,
  input  logic [WX-1:0] xi,
  input  logic [WY-1:0] ri,
  output logic [WK-1:0] ko,
  output logic [WX-1:0] xo,
  output logic [WY-1:0] ro
);

  logic [WY-1:0] ao;

  always @ (posedge clk)
    if (!rstn) begin
      ko <= '0;
      xo <= '0;
    end else if (en_mac) begin
      ko <= ki;
      xo <= xi;
    end

  mac #(.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) 
    MAC (
      .clk(clk), 
      .rstn(rstn), 
      .en(en_mac), 
      .m_valid(m_valid), 
      .m_first(m_first), 
      .x(xi), 
      .k(ki), 
      .y(ao));
  
  always_ff @(posedge clk)
    if (!rstn)         ro <= '0;
    else if (r_copy)   ro <= ao;
    else if (en_shift) ro <= ri;
endmodule