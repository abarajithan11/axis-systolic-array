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

  genvar r, c, tr, tc;
  localparam D = R+C+RT+CT-3;

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
  logic [RT-1:0][CT-1:0][RE-1:0] r_copy_e;
  logic [RT-1:0][CT-1:0][`DIAG(RE,CE)-2:0] t_en_copy;
  logic [RT-1:0][CT-1:0] x_valid_w, x_last_w, x_ready_w;
  logic [RT-1:0][CT-1:0] k_valid_n, k_last_n, k_ready_n;
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

  // Skew x and k far enough to compensate for both PE and inter-tile registers.
  for (r=0; r<R; r=r+1) begin: SKEW_X
    n_delay #(.N(r + (r / RE)), .W(WX)) DELAY_X (
      .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
      .i(s_hsk ? sx_data[r] : '0),
      .o(xi_delayed[r]),
      .d()
    );
  end

  for (c=0; c<C; c=c+1) begin: SKEW_K
    n_delay #(.N(c + (c / CE)), .W(WK)) DELAY_K (
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
        n_delay #(.N(tr*(RE+1)), .W(1)) X_TILE_VALID (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk),
          .o(x_valid_d[tr]),
          .d()
        );

        n_delay #(.N(tr*(RE+1)), .W(1)) X_TILE_LAST (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk && s_last),
          .o(x_last_d[tr]),
          .d()
        );

        if (tr == 0) begin
          assign x_w[tr][tc]       = x_d[tr];
          assign x_valid_w[tr][tc] = x_valid_d[tr];
          assign x_last_w [tr][tc] = x_last_d[tr];
        end else begin
          skid_buffer #(.WIDTH(RE*WX+1)) X_WEST_SKID (
            .clk    (clk),
            .rstn   (rstn),
            .s_valid(x_valid_d[tr]),
            .s_ready(),
            .s_data ({x_d[tr], x_last_d[tr]}),
            .m_ready(x_ready_w[tr][tc]),
            .m_valid(x_valid_w[tr][tc]),
            .m_data ({x_w[tr][tc], x_last_w[tr][tc]})
          );
        end
      end

      if (tr == 0) begin
        n_delay #(.N(tc*(CE+1)), .W(1)) K_TILE_VALID (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk),
          .o(k_valid_d[tc]),
          .d()
        );

        n_delay #(.N(tc*(CE+1)), .W(1)) K_TILE_LAST (
          .c(clk), .e(en_mac), .rng(rstn), .rnl(rstn),
          .i(s_hsk && s_last),
          .o(k_last_d[tc]),
          .d()
        );

        if (tc == 0) begin
          assign k_n[tr][tc]       = k_d[tc];
          assign k_valid_n[tr][tc] = k_valid_d[tc];
          assign k_last_n [tr][tc] = k_last_d[tc];
        end else begin
          skid_buffer #(.WIDTH(CE*WK+1)) K_NORTH_SKID (
            .clk    (clk),
            .rstn   (rstn),
            .s_valid(k_valid_d[tc]),
            .s_ready(),
            .s_data ({k_d[tc], k_last_d[tc]}),
            .m_ready(k_ready_n[tr][tc]),
            .m_valid(k_valid_n[tr][tc]),
            .m_data ({k_n[tr][tc], k_last_n[tr][tc]})
          );
        end
      end

      assign t_valid[tr][tc] = x_valid_w[tr][tc] && k_valid_n[tr][tc];
      assign t_last [tr][tc] = x_last_w [tr][tc] && k_last_n [tr][tc];
      assign x_ready_w[tr][tc] = k_valid_n[tr][tc] && t_ready[tr][tc];
      assign k_ready_n[tr][tc] = x_valid_w[tr][tc] && t_ready[tr][tc];

      if (tc == CT-1) begin
        if (tr == RT-1)
          assign t_m_ready[tr][tc] = m_ready;
        else
          assign t_m_ready[tr][tc] = m_ready && t_m_valid[RT-1][tc];
      end

      sa #(.RE(RE), .CE(CE), .WX(WX), .WK(WK), .WY(WY), .LM(LM), .LA(LA)) TILE (
        .clk       (clk),
        .rstn      (rstn),
        .s_valid_0 (t_valid[tr][tc]),
        .s_last_0  (t_last[tr][tc]),
        .s_ready_0 (t_ready[tr][tc]),
        .m_ready_0 (t_m_ready[tr][tc]),
        .m_valid_0 (t_m_valid[tr][tc]),
        .m_last_0  (t_m_last[tr][tc]),
        .en_mac_o  (t_en_mac[tr][tc]),
        .en_shift_o(t_en_shift[tr][tc]),
        .en_copy_o (t_en_copy[tr][tc]),
        .r_copy_e_o(r_copy_e[tr][tc]),
        .x_valid_o (x_valid_e[tr][tc]),
        .x_last_o  (x_last_e [tr][tc]),
        .k_valid_o (k_valid_s[tr][tc]),
        .k_last_o  (k_last_s [tr][tc]),
        .xi_data   (x_w[tr][tc]),
        .ki_data   (k_n[tr][tc]),
        .ri_data   (r_w[tr][tc]),
        .xo_data   (x_e[tr][tc]),
        .ko_data   (k_s[tr][tc]),
        .ro_data   (r_e[tr][tc])
      );

      if (tc < CT-1) begin:X_EAST_BOUNDARY
        skid_buffer #(.WIDTH(RE*WX+1)) X_SKID (
          .clk    (clk),
          .rstn   (rstn),
          .s_valid(x_valid_e[tr][tc]),
          .s_ready(),
          .s_data ({x_e[tr][tc], x_last_e[tr][tc]}),
          .m_ready(x_ready_w[tr][tc+1]),
          .m_valid(x_valid_w[tr][tc+1]),
          .m_data ({x_w[tr][tc+1], x_last_w[tr][tc+1]})
        );

        for (r=0; r<RE; r=r+1) begin:R_EAST_BOUNDARY
          skid_buffer #(.WIDTH(WY)) R_SKID (
            .clk    (clk),
            .rstn   (rstn),
            .s_valid(t_en_shift[tr][tc] || r_copy_e[tr][tc][r]),
            .s_ready(),
            .s_data (r_e[tr][tc][r]),
            .m_ready(t_en_shift[tr][tc+1]),
            .m_valid(),
            .m_data (r_w[tr][tc+1][r])
          );
        end

        assign t_m_ready[tr][tc] = 1'b1;
      end

      if (tr < RT-1) begin:K_SOUTH_BOUNDARY
        skid_buffer #(.WIDTH(CE*WK+1)) K_SKID (
          .clk    (clk),
          .rstn   (rstn),
          .s_valid(k_valid_s[tr][tc]),
          .s_ready(),
          .s_data ({k_s[tr][tc], k_last_s[tr][tc]}),
          .m_ready(k_ready_n[tr+1][tc]),
          .m_valid(k_valid_n[tr+1][tc]),
          .m_data ({k_n[tr+1][tc], k_last_n[tr+1][tc]})
        );
      end
    end
  end

endmodule
