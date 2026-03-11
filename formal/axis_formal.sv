
`ifdef M_AXIS
  `define ASSUME assert
  `define ASSERT assume
`else
  `define ASSUME assume
  `define ASSERT assert
`endif

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

