`timescale 1ns/1ps
`define DIAG(a, b) (a+b)

module smoke_tb;
  localparam 
    R          = 2, // Rows of SA == rows of output matrix
    C          = 2, // Cols of SA == cols of output matrix
    K          = 6, // Cols of matrix_k and rows of matrix_k
    WX         = 8, // word width of matrix_k
    WK         = 4, // word width of matrix_k
    LM         = 2, // latency of multiplier
    LA         = 3, // latency of accumulator
    WM         = WX + WK,            // word width of multiplier
    WY         = WM + $clog2(K), // word width of accumulator
    P_VALID    = 1,  // Probability with which s_valid is toggled
    P_READY    = 100, // Probability with which m_ready is toggled
    CLK_PERIOD = 100;


  logic clk=0, rstn=0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  // Systolic Array
  logic s_ready, s_valid=0, s_last=0, m_ready=0, m_valid, m_last;
  logic [R-1:0][WX-1:0] sx_data;
  logic [C-1:0][WK-1:0] sk_data;
  logic [R-1:0][WY-1:0] m_data;

  axis_sa #(.R(R), .C(C), .WX(WX), .WK(WK), .WY(WY), .LM(LM), .LA(LA)) DUT (.*);


  logic signed [K-1:0][C-1:0][WK-1:0] mat_k;
  logic signed [K-1:0][R-1:0][WX-1:0] mat_x;
  logic signed [C-1:0][R-1:0][WY-1:0] mat_y_sim, mat_y_ref = '0;

  // y(C,R) = k(K,C).T @ x(K,R)

  int c=0;

  initial begin
    $dumpfile ("trace.vcd"); $dumpvars;

    // Generate random input data
    for (int k=0; k<K; k++)
      for (int c=0; c<C; c++)
        mat_k[k][c] = WK'($urandom_range(-2**(WK-1), 2**(WK-1)-1));

    for (int k=0; k<K; k++)
      for (int r=0; r<R; r++)
        mat_x[k][r] = WX'($urandom_range(-2**(WX-1), 2**(WX-1)-1));

    // Generate reference output data
    for (int r=0; r<R; r++)
      for (int c=0; c<C; c++)
        for (int k=0; k<K; k++)
          mat_y_ref[c][r] = $signed(mat_y_ref[c][r]) + $signed(mat_x[k][r]) * $signed(mat_k[k][c]);

    // Print Inputs & Outputs for debugging
    $display("Matrix K(K,C):");
    for (int k=0; k<K; k++) begin
      $write("  K[%0d]: ", k);
      for (int c=0; c<C; c++)
        $write("%0d ", $signed(mat_k[k][c]));
      $display("");
    end
    $display("Matrix X(K,R):");
    for (int k=0; k<K; k++) begin
      $write("  X[%0d]: ", k);
      for (int r=0; r<R; r++)
        $write("%0d ", $signed(mat_x[k][r]));
      $display("");
    end
    $display("Matrix Y_ref(C,R):");
    for (int c=0; c<C; c++) begin
      $write("  Y[%0d]: ", c);
      for (int r=0; r<R; r++)
        $write("%0d ", $signed(mat_y_ref[c][r]));
      $display("");
    end

    // Start simulation

    @(posedge clk);
    rstn <= 1;
    repeat(2) @(posedge clk);

    // Send data to DUT
    for (int k=0; k<K; k++) begin
      #1ps;
      s_valid <= 1;
      s_last <= (k == K-1) ? 1 : 0;
      sx_data <= mat_x[k];
      sk_data <= mat_k[k];
      @(posedge clk);
    end

    #1ps;
    s_valid <= 0;
    s_last <= 0;
    m_ready <= 1;

    while(1) begin
      @(posedge clk);
      if (m_valid) begin
        for (int r=0; r<R; r++)
          mat_y_sim[c][r] <= m_data[r];
        c++;
        if (m_last) break;
      end
    end
    @(posedge clk);


    // Done
    $display("Matrix Y_sim(C,R):");
    for (int c=0; c<C; c++) begin
      $write("  Y[%0d]: ", c);
      for (int r=0; r<R; r++)
        $write("%0d ", $signed(mat_y_sim[c][r]));
      $display("");
    end

    $finish();
  end

endmodule 