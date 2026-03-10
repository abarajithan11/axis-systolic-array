module s_axis_formal #(
  parameter WIDTH=8
)(
  input  logic clk, rstn,
  output logic valid,
  input  logic ready,
  output logic [WIDTH-1:0] payload
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);

`define S_AXIS
`include "axis_formal.sv"
`undef S_AXIS

endmodule
