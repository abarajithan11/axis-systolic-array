
`define CONCAT(a,b) a``b

// Default is MASTER, to drive a slave
// valid, payload are driven by fvip (assumed),
// ready is observed (asserted)
`ifdef SLAVE
  `define ROLE   m
  `define ASSUME assert
  `define ASSERT assume
`else
  `define ROLE   s
  `define ASSUME assume
  `define ASSERT assert
`endif

`ifdef MASTER
module m_axis_fvip #(
`else
module s_axis_fvip #(
`endif
    parameter WIDTH=8,
    parameter AXI_MAX_STALL = 20,
    parameter AXI_MAX_READY_IDLE = 50
  )(
    input logic             clk,
    input logic             rstn,
    input logic             valid,
    input logic             ready,
    input logic [WIDTH-1:0] payload
  );

  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);

  wire stall = valid && !ready;
  wire handshake = valid && ready;

  a_valid_low_during_reset:
    `ASSUME property (@(posedge clk) disable iff (1'b0)
      !rstn |=> !valid
    );

  a_valid_not_unknown:
    `ASSUME property (
      !$isunknown(valid)
      );
  a_ready_not_unknown:
    `ASSERT property (
      !$isunknown(ready)
      );

  a_valid_after_reset_rise:
    `ASSUME property (
      @(posedge clk) $rose(rstn) |-> !valid
      );

  a_valid_stall_stable:
    `ASSUME property (
      @(posedge clk) stall |=> $stable(valid)
      );
  a_payload_stall_stable:
    `ASSUME property (
      @(posedge clk) stall |=> $stable(payload)
      );

  a_payload_known_when_valid:
    `ASSUME property (
      @(posedge clk) valid |-> !$isunknown(payload)
      );
endmodule


`undef ROLE
`undef CONCAT
`undef ASSUME
`undef ASSERT
