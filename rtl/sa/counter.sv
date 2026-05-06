`timescale 1ns/1ps
`include "config.svh"

module counter #(
    parameter MAX=1,
    parameter W=MAX <= 1 ? 1 : $clog2(MAX)
  )(
    input  logic clk, rstn,
    input  logic start, en_active,
    output logic [W-1:0] cnt, cnt_n,
    output logic active, active_n,
    output logic last, last_n, last_en
  );

  logic [W:0] cnt_i, cnt_i_n;
  logic [W:0] last_i;

  assign last_i   = (W+1)'(MAX-1);
  assign cnt      = cnt_i[W-1:0];
  assign cnt_n    = cnt_i_n[W-1:0];
  assign active   = cnt_i != '1;
  assign active_n = cnt_i_n != '1;
  assign last     = cnt_i == last_i;
  assign last_n   = cnt_i_n == last_i;
  assign last_en  = en_active && last;

  always_comb begin
    cnt_i_n = cnt_i;

    if (start) begin
      cnt_i_n = '0;
    end else if (en_active && active) begin
      if (last) cnt_i_n = '1;
      else      cnt_i_n = cnt_i + (W+1)'(1);
    end
  end

  always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
    if (!rstn) cnt_i <= '1;
    else       cnt_i <= cnt_i_n;
  end
endmodule
