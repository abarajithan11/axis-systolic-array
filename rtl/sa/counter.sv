`timescale 1ns/1ps
`include "config.svh"

module counter #(
    parameter MAX=1,
    parameter W=MAX <= 1 ? 1 : $clog2(MAX)
  )(
    input  logic clk, rstn,
    input  logic start, en,
    output logic [W-1:0] cnt, cnt_n,
    output logic active, active_n,
    output logic last, last_n, last_en
  );

  localparam logic [W-1:0] LAST = W'(MAX-1);

  assign last_en = en && last;

  always_comb begin
    cnt_n    = cnt;
    active_n = active;

    if (start) begin
      active_n = 1'b1;
      cnt_n    = '0;
    end else if (en && active) begin
      if (last) begin
        active_n = 1'b0;
        cnt_n    = '0;
      end else begin
        active_n = 1'b1;
        cnt_n    = cnt + W'(1);
      end
    end
    last_n = active_n && (cnt_n == LAST);
  end

  always_ff @(posedge clk `OR_NEGEDGE(rstn)) begin
    if (!rstn) begin
      active <= 1'b0;
      cnt    <= '0;
      last   <= 1'b0;
    end else begin
      active <= active_n;
      cnt    <= cnt_n;
      last   <= last_n;
    end
  end
endmodule