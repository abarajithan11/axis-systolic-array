`timescale 1ns/1ps
`include "config.svh"
`define DIAG(a, b) (a+b)
`define MIN(a, b) ((a) < (b) ? (a) : (b))
`define MAX(a, b) ((a) > (b) ? (a) : (b))

module tile_boundary_skid #(
    parameter N=1, W=8
  )(
    input  logic clk, rstn,
    input  logic s_valid, s_last, m_ready,
    input  logic [N-1:0][W-1:0] s_data,
    output logic s_ready, m_valid, m_last,
    output logic [N-1:0][W-1:0] m_data
  );

  genvar i;
  localparam int DW = N*W;
  logic [DW+1:0] s_flat, m_flat;

  for (i=0; i<N; i=i+1) begin:LANE
    assign s_flat[i*W +: W] = s_data[i];
    assign m_data[i] = m_flat[i*W +: W];
  end
  assign s_flat[DW]   = s_valid;
  assign s_flat[DW+1] = s_last;
  assign m_valid      = m_flat[DW];
  assign m_last       = m_flat[DW+1];

  skid_buffer #(.WIDTH(DW+2)) SKID (
    .clk    (clk),
    .rstn   (rstn),
    .s_valid(1'b1),
    .s_ready(s_ready),
    .s_data (s_flat),
    .m_ready(m_ready),
    .m_valid(),
    .m_data (m_flat)
  );
endmodule

module result_boundary_skid #(
    parameter N=1, W=8
  )(
    input  logic clk, rstn,
    input  logic s_valid, m_ready,
    input  logic [N-1:0][W-1:0] s_data,
    output logic s_ready, m_valid,
    output logic [N-1:0][W-1:0] m_data
  );

  genvar i;
  logic [N*W-1:0] s_flat, m_flat;

  for (i=0; i<N; i=i+1) begin:LANE
    assign s_flat[i*W +: W] = s_data[i];
    assign m_data[i] = m_flat[i*W +: W];
  end

  skid_buffer #(.WIDTH(N*W)) SKID (
    .clk    (clk),
    .rstn   (rstn),
    .s_valid(s_valid),
    .s_ready(s_ready),
    .s_data (s_flat),
    .m_ready(m_ready),
    .m_valid(m_valid),
    .m_data (m_flat)
  );
endmodule

module axis_sa #(
    parameter  R=4, C=8, WX=4, WK=8, WY=16, LM=1, LA=1,
    parameter  RT=1, CT=1,
    parameter  RE=R/RT, CE=C/CT
    // rows, columns, x_width, k_width, y_width, multiplier latency, accumulator latency
  )(
    input  logic clk, rstn,
    input  logic s_valid, s_last, m_ready,
    output logic s_ready, m_valid, m_last,
    input  logic [R-1:0][WX-1:0] sx_data,
    input  logic [C-1:0][WK-1:0] sk_data,
    output logic [R-1:0][WY-1:0] m_data
  );

  genvar r, c, tr, tc, rp, cp;
  logic [R-1:0][WX-1:0] xi_delayed;
  logic [C-1:0][WK-1:0] ki_delayed, sk_reversed;
  logic [RT-1:0][RE-1:0][WX-1:0] x_d;
  logic [CT-1:0][CE-1:0][WK-1:0] k_d;
  logic [RT-1:0] x_valid_d, x_last_d;
  logic [CT-1:0] k_valid_d, k_last_d;
  logic [RT-1:0][CT-1:0][RE-1:0][WX-1:0] x_w, x_e;
  logic [RT-1:0][CT-1:0][CE-1:0][WK-1:0] k_n, k_s;
  logic [RT-1:0][CT-1:0][RE-1:0][WY-1:0] r_w, r_e;
  logic [RT-1:0][CT-1:0] t_valid, t_last, t_ready, t_m_valid, t_m_last, t_m_ready;
  logic [RT-1:0][CT-1:0] t_en_mac, t_en_shift;
  logic [RT-1:0][CT-1:0] x_valid_e, x_last_e, k_valid_s, k_last_s;
  logic [RT-1:0][CT-1:0] x_valid_w, x_last_w;
  logic [RT-1:0][CT-1:0] k_valid_n, k_last_n;
  logic [RT-1:0][CT-1:0] x_ready_e, k_ready_s;
  logic en_mac;
  logic s_hsk;

  // ---------- DATAPATH ----------

  initial begin
    if (RT < 1 || CT < 1 || R % RT != 0 || C % CT != 0) begin
      $fatal(1, "axis_sa requires RT/CT to evenly divide R/C");
    end
  end

  // Reverse the columns of K matrix, so that outputs come out with C=0 first.
  for (c=0; c<C; c=c+1)
    assign sk_reversed[c] = sk_data[C-1-c];

  // Skew x and k for the global wavefront. Tile-boundary skids add their own
  // elasticity as data moves east/south.
  for (r=0; r<R; r=r+1) begin: SKEW_X
    n_delay #(.N(r), .W(WX)) DELAY_X (
      .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
      .i(s_hsk ? sx_data[r] : '0),
      .o(xi_delayed[r]),
      .d()
    );
  end

  for (c=0; c<C; c=c+1) begin: SKEW_K
    n_delay #(.N(c), .W(WK)) DELAY_K (
      .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
      .i(s_hsk ? sk_reversed[c] : '0),
      .o(ki_delayed[c]),
      .d()
    );
  end

  assign s_hsk = s_valid && s_ready;
  assign en_mac = t_en_mac[0][0];

  assign s_ready = t_ready[0][0];

  assign m_valid = t_m_valid[RT-1][CT-1];
  assign m_last  = t_m_last [RT-1][CT-1];

  for (tr=0; tr<RT; tr=tr+1) begin:TILE_R
    for (tc=0; tc<CT; tc=tc+1) begin:TILE_C
      for (r=0; r<RE; r=r+1) begin:TILE_XR
        localparam int GR = tr*RE + r;

        if (tc == 0) begin
          assign x_d[tr][r] = xi_delayed[GR];
          assign r_w[tr][tc][r] = '0;
        end
        if (tc == CT-1) begin
          assign m_data[GR] = r_e[tr][tc][r];
        end
      end

      for (c=0; c<CE; c=c+1) begin:TILE_KC
        localparam int GC = tc*CE + c;

        if (tr == 0)
          assign k_d[tc][c] = ki_delayed[GC];
      end

      if (tc == 0) begin
        n_delay #(.N(tr*RE), .W(1)) X_TILE_VALID (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk),
          .o(x_valid_d[tr]),
          .d()
        );

        n_delay #(.N(tr*RE), .W(1)) X_TILE_LAST (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk && s_last),
          .o(x_last_d[tr]),
          .d()
        );

        if (tr == 0) begin
          assign x_valid_w[tr][tc] = x_valid_d[tr];
          assign x_last_w [tr][tc] = x_last_d[tr];

          for (rp=0; rp<RE; rp=rp+1) begin:X_WEST_DIRECT
            assign x_w[tr][tc][rp] = x_d[tr][rp];
          end
        end else begin
          tile_boundary_skid #(.N(RE), .W(WX)) X_WEST_SKID (
            .clk         (clk),
            .rstn        (rstn),
            .s_valid     (x_valid_d[tr]),
            .s_last      (x_last_d[tr]),
            .s_data      (x_d[tr]),
            .s_ready     (),
            .m_ready      (t_en_mac[tr][tc]),
            .m_valid     (x_valid_w[tr][tc]),
            .m_last      (x_last_w[tr][tc]),
            .m_data      (x_w[tr][tc])
          );
        end
      end

      if (tr == 0) begin
        n_delay #(.N(tc*CE), .W(1)) K_TILE_VALID (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk),
          .o(k_valid_d[tc]),
          .d()
        );

        n_delay #(.N(tc*CE), .W(1)) K_TILE_LAST (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk && s_last),
          .o(k_last_d[tc]),
          .d()
        );

        if (tc == 0) begin
          assign k_valid_n[tr][tc] = k_valid_d[tc];
          assign k_last_n [tr][tc] = k_last_d[tc];

          for (cp=0; cp<CE; cp=cp+1) begin:K_NORTH_DIRECT
            assign k_n[tr][tc][cp] = k_d[tc][cp];
          end
        end else begin
          tile_boundary_skid #(.N(CE), .W(WK)) K_NORTH_SKID (
            .clk         (clk),
            .rstn        (rstn),
            .s_valid     (k_valid_d[tc]),
            .s_last      (k_last_d[tc]),
            .s_data      (k_d[tc]),
            .s_ready     (),
            .m_ready      (t_en_mac[tr][tc]),
            .m_valid     (k_valid_n[tr][tc]),
            .m_last      (k_last_n[tr][tc]),
            .m_data      (k_n[tr][tc])
          );
        end
      end

      assign t_valid[tr][tc] = x_valid_w[tr][tc] && k_valid_n[tr][tc];
      assign t_last [tr][tc] = x_last_w [tr][tc] && k_last_n [tr][tc];

      if (tc == CT-1) begin
        if (tr == RT-1)
          assign t_m_ready[tr][tc] = m_ready;
        else
          assign t_m_ready[tr][tc] = m_ready && t_m_valid[RT-1][tc];
      end

      sa #(.RE(RE), .CE(CE), .WX(WX), .WK(WK), .WY(WY), .LM(LM), .LA(LA), .OC((tc+1)*CE)) TILE (
        .clk       (clk),
        .rstn      (rstn),
        .s_valid_0 (t_valid[tr][tc]),
        .s_last_0  (t_last[tr][tc]),
        .x_ready   (x_ready_e[tr][tc]),
        .k_ready   (k_ready_s[tr][tc]),
        .s_ready_0 (t_ready[tr][tc]),
        .m_ready_0 (t_m_ready[tr][tc]),
        .m_valid_0 (t_m_valid[tr][tc]),
        .m_last_0  (t_m_last[tr][tc]),
        .en_mac    (t_en_mac[tr][tc]),
        .en_shift  (t_en_shift[tr][tc]),
        .x_valid   (x_valid_e[tr][tc]),
        .x_last    (x_last_e [tr][tc]),
        .k_valid   (k_valid_s[tr][tc]),
        .k_last    (k_last_s [tr][tc]),
        .xi_data   (x_w[tr][tc]),
        .ki_data   (k_n[tr][tc]),
        .ri_data   (r_w[tr][tc]),
        .xo_data   (x_e[tr][tc]),
        .ko_data   (k_s[tr][tc]),
        .ro_data   (r_e[tr][tc])
      );

      if (tc < CT-1) begin:X_EAST_BOUNDARY
        tile_boundary_skid #(.N(RE), .W(WX)) X_EAST_SKID (
          .clk         (clk),
          .rstn        (rstn),
          .s_valid     (x_valid_e[tr][tc]),
          .s_last      (x_last_e[tr][tc]),
          .s_data      (x_e[tr][tc]),
          .s_ready     (x_ready_e[tr][tc]),
          .m_ready      (t_en_mac[tr][tc+1]),
          .m_valid     (x_valid_w[tr][tc+1]),
          .m_last      (x_last_w[tr][tc+1]),
          .m_data      (x_w[tr][tc+1])
        );

        result_boundary_skid #(.N(RE), .W(WY)) R_EAST_SKID (
          .clk    (clk),
          .rstn   (rstn),
          .s_valid(t_m_valid[tr][tc]),
          .s_ready(t_m_ready[tr][tc]),
          .s_data (r_e[tr][tc]),
          .m_ready(t_en_shift[tr][tc+1]),
          .m_valid(),
          .m_data (r_w[tr][tc+1])
        );
      end
      else begin:X_NO_EAST_BOUNDARY
        assign x_ready_e[tr][tc] = 1'b1;
      end

      if (tr < RT-1) begin:K_SOUTH_BOUNDARY
        tile_boundary_skid #(.N(CE), .W(WK)) K_SOUTH_SKID (
          .clk         (clk),
          .rstn        (rstn),
          .s_valid     (k_valid_s[tr][tc]),
          .s_last      (k_last_s[tr][tc]),
          .s_data      (k_s[tr][tc]),
          .s_ready     (k_ready_s[tr][tc]),
          .m_ready      (t_en_mac[tr+1][tc]),
          .m_valid     (k_valid_n[tr+1][tc]),
          .m_last      (k_last_n[tr+1][tc]),
          .m_data      (k_n[tr+1][tc])
        );
      end
      else begin:K_NO_SOUTH_BOUNDARY
        assign k_ready_s[tr][tc] = 1'b1;
      end
    end
  end

endmodule
