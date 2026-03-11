module m_axis_formal #(
  parameter WIDTH=8
)(
  input  logic clk, rstn,
  input  logic valid,
  output logic ready,
  input  logic [WIDTH-1:0] payload
);

`define M_AXIS
`include "axis_formal.sv"
`undef M_AXIS

endmodule
