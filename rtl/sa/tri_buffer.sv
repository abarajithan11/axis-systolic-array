`timescale 1ns/1ps
`include "config.svh"

//              Columns (c)
//          +-------+-------+-------+-------+
// Row r=0 | x[0]  | x[1]  | x[2]  | x[3]  |   <-- Inputs (no delay)
//          +-------+-------+-------+-------+
// Row r=1 |       | b[1,1]| b[1,2]| b[1,3]|   <-- 1-cycle delayed values
//          +-------+-------+-------+-------+
// Row r=2 |       |       | b[2,2]| b[2,3]|   <-- 2-cycle delayed values
//          +-------+-------+-------+-------+
// Row r=3 |       |       |       | b[3,3]|   <-- 3-cycle delayed value
//          +-------+-------+-------+-------+


module tri_buffer #(
  parameter W=8, N=4
)(
  input  logic clk, rstn, cen,
  input  logic [N-1:0][W-1:0] x,
  output logic [N-1:0][W-1:0] y
);

  genvar c, r;
  logic signed [N-1:0][N-1:0][W-1:0] buffer; // (R,C), r=0 is comb, r=1 has N-1 reg, r=2 has N-2 reg, etc

  assign buffer[0] = x; //r==0: load input into 0th row

  for (r=1; r<N; r=r+1)  // each row is a delay
    for (c=r; c<N; c=c+1)  // each column is (C-r) elements wide
      always_ff @(posedge clk `OR_NEGEDGE(rstn))
        if (!rstn)    buffer[r][c] <= 0;
        else if (cen) buffer[r][c] <= buffer[r-1][c];

  for (c=0; c<N; c=c+1) // read output from diagonal
    assign y[c] = buffer[c][c]; // read output from diagonal

endmodule