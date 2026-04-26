`timescale 1ns/1ps
`define DIAG(a, b) (a+b)
`include "config.svh"

module axis_sa_tb;
  localparam 
    R          = `R, // Rows of SA == rows of output matrix
    C          = `C, // Cols of SA == cols of output matrix
    K_MIN      = 5, // Cols of matrix_k and rows of matrix_k
    K_MAX      = 30,
    WX         = `WX, // word width of matrix_k
    WK         = `WX, // word width of matrix_k
    LM         = 2, // latency of multiplier
    LA         = 3, // latency of accumulator
    WM         = WX + WK,            // word width of multiplier
    WY         = WM + $clog2(K_MAX), // word width of accumulator
    P_VALID    = `VALID_PROB,  // Probability with which s_valid is toggled
    P_READY    = `READY_PROB, // Probability with which m_ready is toggled
    CLK_PERIOD = `CLK_PERIOD,
    NUM_EXP    = 50;  // Number of experiments

  logic clk=0, rstn=0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  // Systolic Array
  logic s_ready, sk_valid, sk_last, sx_valid, sx_last, m_ready, m_valid, m_last;
  logic [R-1:0][WX-1:0] sx_data;
  logic [C-1:0][WK-1:0] sk_data;
  logic [R-1:0][WY-1:0] m_data;

  // Synchronize two streams
  wire s_valid  = sx_valid && sk_valid;
  wire s_last   = sx_last  && sk_last;
  wire sx_ready = sk_valid && s_ready;
  wire sk_ready = sx_valid && s_ready;
  wire [R-1:0] m_keep = '1;

  axis_sa #(.R(R), .C(C), .WX(WX), .WK(WK), .WY(WY), .LM(LM), .LA(LA)) DUT (.*);

  axis_source #(.WORD_W(WX), .BUS_W(WX*R), .PROB_VALID(P_VALID)) source_x (.clk(clk), .s_valid(sx_valid), .s_ready(sx_ready), .s_last(sx_last), .s_keep(), .s_data(sx_data));
  axis_source #(.WORD_W(WK), .BUS_W(WK*C), .PROB_VALID(P_VALID)) source_k (.clk(clk), .s_valid(sk_valid), .s_ready(sk_ready), .s_last(sk_last), .s_keep(), .s_data(sk_data));
  axis_sink   #(.WORD_W(WY), .BUS_W(WY*R), .PROB_READY(P_READY)) sink_y   (.*);

  typedef logic signed [WX-1:0] xp_t [$];
  typedef logic signed [WK-1:0] kp_t [$];
  typedef logic signed [WY-1:0] yp_t [$];

  xp_t x_packets [NUM_EXP], x_packet;
  kp_t k_packets [NUM_EXP], k_packet;
  yp_t y_packets [NUM_EXP], e_packet;

  logic signed [WY-1:0] val;
  int rand_ks [NUM_EXP];

  initial begin
    $dumpfile ("trace.vcd"); $dumpvars;
    
    for (int n=0; n<NUM_EXP; n++)
      rand_ks[n] = $urandom_range(K_MIN, K_MAX);

    repeat(5) @(posedge clk);
    rstn <= 1;

    for (int n=0; n<NUM_EXP; n++) begin
      x_packet = {};
      source_x.get_random_queue(x_packet, rand_ks[n]*R); // (K,R)
      x_packets[n] = x_packet;
      source_x.axis_push_packet(x_packet);
    end
  end

  initial begin
    wait(rstn);
    for (int n=0; n<NUM_EXP; n++) begin
      k_packet = {};
      source_k.get_random_queue(k_packet, rand_ks[n]*C); // (K,C)
      k_packets[n] = k_packet;
      source_k.axis_push_packet(k_packet);
    end
  end

  initial begin
    wait(rstn);
    $display("Waiting for packets to be received...");
    for (int n=0; n<NUM_EXP; n++) begin
      sink_y.axis_pull_packet(y_packets[n]);

      e_packet = {};
      for (int c=0; c<C; c++)
        for (int r=0; r<R; r++) begin
          val = 0;
          for (int k=0; k<rand_ks[n]; k++) 
            val = $signed(val) + $signed(k_packets[n][k*C+c]) * $signed(x_packets[n][k*R+r]);
          e_packet.push_back(val);
        end

      if(y_packets[n] == e_packet)
        $display("Packet[%0d]: Outputs match: %p\n", n, e_packet);
      else begin
        $display("Packet[%0d]: Expected: \n%p \n != \n Received: \n%p", n, e_packet, y_packets[n]);
        $fatal(1, "Failed");
      end
    end
    $finish();
  end

endmodule 