`timescale 1ns/1ps
`define DIAG(a, b) (a+b)

module axis_sa #(
    parameter  R=4, C=8, WX=4, WK=8, WY=16, LM=1, LA=1
    // rows, columns, x_width, k_width, y_width, multiplier latency, accumulator latency
  )(
    input  logic clk, rstn,
    input  logic s_valid, s_last, m_ready,
    output logic s_ready, m_valid, m_last, 
    input  logic [R-1:0][WX-1:0] sx_data,
    input  logic [C-1:0][WK-1:0] sk_data,
    output logic [R-1:0][WY-1:0] m_data
  );

  genvar r, c, d ;
  localparam D  = `DIAG(R,C)-1; // length of diagonal
  localparam WM = WX + WK;

  logic en_mac, en_shift;

  logic [R-1:0][WX-1:0] xi_delayed;
  logic [C-1:0][WK-1:0] ki_delayed, sk_reversed;

  // Control Signals are passed diagonally through the array
  logic [D-1:0] r_valid, r_last, r_copy, r_clear, conflict, a_valid, m_first;
  logic [LM+LA+D-1:0] valid, vlast;

  // Global Control
  assign en_mac   = !(|conflict); // pull en_mac down if any acc is pushing data (avalid) and reg already has data (r_valid)
  assign en_shift = r_valid[D-1] && m_ready;  // shift only when entire array is full (m_valid) and mready
  assign s_ready  = en_mac;

  // Reverse the columns of K matrix, so that outputs come out with C=0 first
  for (c=0; c<C; c=c+1)
    assign sk_reversed[c] = sk_data[C-1-c];

  // Triangular Buffer for x and k
  tri_buffer #(.W(WX), .N(R)) TRI_X (.clk(clk), .rstn(rstn), .cen(en_mac), .x(sx_data    ), .y(xi_delayed));
  tri_buffer #(.W(WK), .N(C)) TRI_K (.clk(clk), .rstn(rstn), .cen(en_mac), .x(sk_reversed), .y(ki_delayed));

  // Delay control signals
  n_delay #(.N(LM+LA+D), .W(1)) VALID (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_valid           ), .o(), .d(valid));
  n_delay #(.N(LM+LA+D), .W(1)) VLAST (.c(clk), .e(en_mac), .rng(rstn), .rnl(rstn), .i(s_valid && s_last ), .o(), .d(vlast));

  // Output Register Control
  for (d=0; d<D; d=d+1) begin

    always_ff @(posedge clk)
      if (!rstn)            m_first[d] <= 1'b1;
      else if (valid[LM+d]) m_first[d] <= vlast[LM+d];

    if (d==0)
      assign r_last[0] = r_valid[0];
    else
      always_ff @(posedge clk)
        if (!rstn)                r_last[d] <= 0;
        else if (en_shift) 
          if (m_last)             r_last[d] <= 0;            // At the last beat, clear all diagonal regs beyond C
          else                    r_last[d] <= r_last[d-1];  // on non-last beats, shift right
  
    always_ff @(posedge clk)
      if (!rstn)                a_valid[d] <= 0;
      else if (en_mac)          a_valid[d] <= vlast[LM+LA+d-1];

    assign conflict [d] = a_valid[d]  &&  r_valid[d]; // acc wants to send data, but reg already has data
    assign r_copy   [d] = a_valid[d]  && !r_valid[d]; // copy only if acc can send data (a_valid) and reg is empty (!r_valid)
    assign r_clear  [d] = en_shift    &&  r_last [d]; // clear if current reg is last

    always_ff @(posedge clk)
      if (!rstn)                               r_valid[d] <= 0;
      else if (en_shift && m_last)             r_valid[d] <= 0; // At the last beat, clear all diagonal regs beyond C
      else if (r_copy [d])                     r_valid[d] <= 1;
      else if (r_clear[d])                     r_valid[d] <= 0;
  end

  assign m_valid = r_valid[D-1];
  assign m_last  = r_last [D-1];

  logic [R-1:0][C-1:0][WX-1:0] xo;
  logic [R-1:0][C-1:0][WK-1:0] ko;
  logic [R-1:0][C-1:0][WY-1:0] ro;

  for (r=0; r<R; r=r+1) begin:PER
    for (c=0; c<C; c=c+1) begin:PEC

      wire [WX-1:0] xi = c == 0 ? xi_delayed[r] : xo[r][c-1];
      wire [WK-1:0] ki = r == 0 ? ki_delayed[c] : ko[r-1][c];
      wire [WY-1:0] ri = c == 0 ? WY'(0) : ro[r][c-1];

      pe #(.WX(WX),.WK(WK),.WY(WY),.LM(LM),.LA(LA)) PE (
        .clk     (clk),
        .rstn    (rstn),
        .en_mac  (en_mac),
        .en_shift(en_shift),
        .m_first (m_first[`DIAG(r,c)]),
        .m_valid (valid[LM+`DIAG(r,c)]),
        .r_copy  (r_copy[`DIAG(r,c)]),
        .ki      (ki),
        .xi      (xi),
        .ri      (ri),
        .ko      (ko[r][c]),
        .xo      (xo[r][c]),
        .ro      (ro[r][c])
      );
  end end

  for (r=0; r<R; r=r+1)
    assign m_data[r] = ro[r][C-1];
  
endmodule