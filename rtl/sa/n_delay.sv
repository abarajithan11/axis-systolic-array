`timescale 1ns/1ps

module n_delay #(
  parameter N = 1,
            NO = N==0 ? 1 : N,
            W = 8
)(
  input  logic c, e, rng, rnl,
  input  logic    [W-1:0] i,
  output logic    [W-1:0] o,
  output logic [NO*W-1:0] d
);
  logic [W-1:0] o_temp;

  genvar n;
  generate
  if (N == 0) begin : gen_no_delay
    assign d = i;
    assign o = i;
  end
  else begin : gen_delay
    logic [((N+1)*W)-1:0] data;
    assign data[W-1:0] = i;
    for (n=0 ; n < N; n++)
      always_ff @(posedge c or negedge rng)
        if (!rng)      data[((n+1)*W) +: W] <= 0;
        else if (!rnl) data[((n+1)*W) +: W] <= 0;
        else if (e)    data[((n+1)*W) +: W] <= data[(n*W) +: W];
    assign d = data[(N*W)-1:0];
    assign o = data[(N*W) +: W];
  end
  endgenerate

endmodule
