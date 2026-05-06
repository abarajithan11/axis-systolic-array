`timescale 1ns/1ps
`include "config.svh"
`define DIAG(a, b) (a+b)
`define MIN(a, b) ((a) < (b) ? (a) : (b))
`define MAX(a, b) ((a) > (b) ? (a) : (b))

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

  genvar rg, cg, rt, ct, re, ce;
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
  logic en_mac_nw, s_hsk;

  // ---------- DATAPATH ----------

  initial begin
    if (RT < 1 || CT < 1 || R % RT != 0 || C % CT != 0) begin
      $fatal(1, "axis_sa requires RT/CT to evenly divide R/C");
    end
  end

  // Reverse the columns of K matrix, so that outputs come out with C=0 first.
  for (cg=0; cg<C; cg=cg+1)
    assign sk_reversed[cg] = sk_data[C-1-cg];

  // Skew x and k for the global wavefront. Tile-boundary skids add their own
  // elasticity as data moves east/south.
  for (rg=0; rg<R; rg=rg+1) begin: SKEW_X
    n_delay #(.N(rg), .W(WX)) DELAY_X (
      .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(),
      .i(s_hsk ? sx_data[rg] : '0), .o(xi_delayed[rg]));
  end

  for (cg=0; cg<C; cg=cg+1) begin: SKEW_K
    n_delay #(.N(cg), .W(WK)) DELAY_K (
      .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(),
      .i(s_hsk ? sk_reversed[cg] : '0), .o(ki_delayed[cg]));
  end

  always_comb begin
    en_mac_nw  = t_en_mac[0][0];
    s_ready = t_ready[0][0];
    s_hsk   = s_valid && s_ready;
    m_valid = t_m_valid[RT-1][CT-1];
    m_last  = t_m_last [RT-1][CT-1];
  end

  for (rt=0; rt<RT; rt=rt+1) begin:TR
    for (ct=0; ct<CT; ct=ct+1) begin:TC

      // Connect edge signals
      for (re=0; re<RE; re=re+1) begin:XTR
        if (ct == 0) begin
          assign x_d[rt][re] = xi_delayed[rt*RE + re];
          assign r_w[rt][ct][re] = '0;
        end
        if (ct == CT-1) begin
          assign m_data[rt*RE + re] = r_e[rt][ct][re];
        end
      end
      for (ce=0; ce<CE; ce=ce+1) begin:KTC
        if (rt == 0)
          assign k_d[ct][ce] = ki_delayed[ct*CE + ce];
      end

      if (ct == 0) begin
        n_delay #(.N(rt*RE), .W(1)) X_TILE_VALID (
          .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(),
          .i(s_hsk), .o(x_valid_d[rt]));

        n_delay #(.N(rt*RE), .W(1)) X_TILE_LAST (
          .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(),
          .i(s_hsk && s_last), .o(x_last_d[rt]));

        if (rt == 0) begin
          assign x_valid_w[rt][ct] = x_valid_d[rt];
          assign x_last_w [rt][ct] = x_last_d [rt];
          assign x_w      [rt][ct] = x_d      [rt]; // vector to vector
        end else begin
          skid_buffer #(.WIDTH(RE*WX+2)) X_WEST_SKID (
            .clk (clk), .rstn (rstn), .s_ready(), .m_valid(), .s_valid(1'b1),
            .m_ready (t_en_mac[rt][ct]),
            .s_data  ({x_valid_d[rt]    , x_last_d[rt]    , x_d[rt]    }),
            .m_data  ({x_valid_w[rt][ct], x_last_w[rt][ct], x_w[rt][ct]})
          );
        end
      end

      if (rt == 0) begin
        n_delay #(.N(ct*CE), .W(1)) K_TILE_VALID (
          .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(),
          .i(s_hsk), .o(k_valid_d[ct]));

        n_delay #(.N(ct*CE), .W(1)) K_TILE_LAST (
          .c(clk), .e(en_mac_nw), .rng(rstn), .rnl(rstn), .d(), 
          .i(s_hsk && s_last), .o(k_last_d[ct]));

        if (ct == 0) begin
          assign k_valid_n[rt][ct] = k_valid_d[ct];
          assign k_last_n [rt][ct] = k_last_d [ct];
          assign k_n      [rt][ct] = k_d      [ct]; // vector to vector
        end else begin
          skid_buffer #(.WIDTH(CE*WK+2)) K_NORTH_SKID (
            .clk(clk), .rstn(rstn), .s_ready(), .m_valid(), .s_valid(1'b1),
            .m_ready (t_en_mac[rt][ct]),
            .s_data  ({k_valid_d[ct]    , k_last_d[ct]    , k_d[ct]    }),
            .m_data  ({k_valid_n[rt][ct], k_last_n[rt][ct], k_n[rt][ct]})
          );
        end
      end

      assign t_valid[rt][ct] = x_valid_w[rt][ct] && k_valid_n[rt][ct];
      assign t_last [rt][ct] = x_last_w [rt][ct] && k_last_n [rt][ct];

      if (ct == CT-1) begin
        if (rt == RT-1) assign t_m_ready[rt][ct] = m_ready;
        else            assign t_m_ready[rt][ct] = t_m_valid[RT-1][ct];
      end

      sa #(.RE(RE), .CE(CE), .WX(WX), .WK(WK), .WY(WY), 
           .LM(LM), .LA(LA), .OC((ct+1)*CE)
      ) TILE (
        .clk       (clk),
        .rstn      (rstn),
        .s_valid_0 (t_valid   [rt][ct]),
        .s_last_0  (t_last    [rt][ct]),
        .x_ready   (x_ready_e [rt][ct]),
        .k_ready   (k_ready_s [rt][ct]),
        .s_ready_0 (t_ready   [rt][ct]),
        .m_ready_0 (t_m_ready [rt][ct]),
        .m_valid_0 (t_m_valid [rt][ct]),
        .m_last_0  (t_m_last  [rt][ct]),
        .en_mac    (t_en_mac  [rt][ct]),
        .en_shift  (t_en_shift[rt][ct]),
        .x_valid   (x_valid_e [rt][ct]),
        .x_last    (x_last_e  [rt][ct]),
        .k_valid   (k_valid_s [rt][ct]),
        .k_last    (k_last_s  [rt][ct]),
        .xi_data   (x_w       [rt][ct]),
        .ki_data   (k_n       [rt][ct]),
        .ri_data   (r_w       [rt][ct]),
        .xo_data   (x_e       [rt][ct]),
        .ko_data   (k_s       [rt][ct]),
        .ro_data   (r_e       [rt][ct])
      );

      if (ct < CT-1) begin:X_EAST_BOUNDARY
        skid_buffer #(.WIDTH(RE*WX+2)) X_EAST_SKID (
          .clk(clk), .rstn(rstn), .s_valid(1'b1), .m_valid(),
          .s_ready (x_ready_e [rt][ct]),
          .m_ready (t_en_mac  [rt][ct+1]),
          .s_data  ({x_valid_e[rt][ct]  , x_last_e[rt][ct]  , x_e[rt][ct]  }),
          .m_data  ({x_valid_w[rt][ct+1], x_last_w[rt][ct+1], x_w[rt][ct+1]})
        );

        skid_buffer #(.WIDTH(RE*WY)) R_EAST_SKID (
          .clk(clk), .rstn(rstn), .m_valid(),
          .s_valid(t_m_valid  [rt][ct]),
          .s_ready(t_m_ready  [rt][ct]),
          .s_data (r_e        [rt][ct]),
          .m_ready(t_en_shift [rt][ct+1]),
          .m_data (r_w        [rt][ct+1])
        );
      end else begin:X_NO_EAST_BOUNDARY
        assign x_ready_e[rt][ct] = 1'b1;
      end

      if (rt < RT-1) begin:K_SOUTH_BOUNDARY
        skid_buffer #(.WIDTH(CE*WK+2)) K_SOUTH_SKID (
          .clk(clk), .rstn(rstn), .s_valid(1'b1), .m_valid(),
          .s_ready (k_ready_s [rt][ct]),
          .m_ready (t_en_mac  [rt+1][ct]),
          .s_data  ({k_valid_s[rt][ct]  , k_last_s[rt][ct]  , k_s[rt][ct]}),
          .m_data  ({k_valid_n[rt+1][ct], k_last_n[rt+1][ct], k_n[rt+1][ct]})
        );
      end else begin:K_NO_SOUTH_BOUNDARY
        assign k_ready_s[rt][ct] = 1'b1;
      end
    end
  end

endmodule
