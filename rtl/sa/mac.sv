`timescale 1ns/1ps

module mac #(
  parameter  WX=4, WK=8, WY=16, LM=1, LA=1,
  localparam WM=WX+WK
)(
  input  wire clk, rstn, en, m_valid, m_first,
  input  wire [WX-1:0] x,
  input  wire [WK-1:0] k,
  output wire [WY-1:0] y
);
  logic signed [WM-1:0] mul_result, m;
  logic signed [WY-1:0] a_result, a;

  always_ff @(posedge clk)
    if (!rstn)    mul_result <= '0;
    else if (en)  mul_result <= $signed(x) * $signed(k);

  n_delay #(.N(LM-1),.W(WM)) mul_delay (.c(clk),.e(en),.rng(rstn),.rnl(rstn),.i(mul_result),.o(m),.d());

  always_ff @(posedge clk)
    if (!rstn)              a_result <= '0;
    else if (en && m_valid) a_result <= WY'($signed(m)) + $signed(m_first ? WY'(0) : a_result);

  n_delay #(.N(LA-1),.W(WY)) acc_delay (.c(clk),.e(en),.rng(rstn),.rnl(rstn),.i(a_result),.o(y),.d());

endmodule