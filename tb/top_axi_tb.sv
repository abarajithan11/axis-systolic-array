`timescale 1ns/1ps
`include "config.svh"

module top_axi_tb;
  localparam
    // Defined in config.svh
    R                   = `R                 ,
    C                   = `C                 ,
    WK                  = `WK                ,
    WX                  = `WX                ,
    WY                  = `WY                ,
    AXIL_BASE_ADDR      = `AXIL_BASE_ADDR    ,
    VALID_PROB          = `VALID_PROB        ,
    READY_PROB          = `READY_PROB        ,
    CLK_PERIOD          = `CLK_PERIOD        ,
    AXI_WIDTH           = `AXI_WIDTH         ,
    DIR                 = `DIR               ,
    WA                  = 32                 ,
    LM                  = 1                  ,
    LA                  = 1                  ,
    AXI_ID_WIDTH        = 6                  ,
    AXI_STRB_WIDTH      = AXI_WIDTH/8        ,
    AXI_MAX_BURST_LEN   = 32                 ,
    AXI_ADDR_WIDTH      = 32                 ,
    AXIL_WIDTH          = 32                 ,
    AXIL_ADDR_WIDTH     = 32                 ,
    AXIL_STRB_WIDTH     = (AXIL_WIDTH/8)     ,
    DATA_WR_WIDTH       = AXIL_WIDTH         ,
    DATA_RD_WIDTH       = AXIL_WIDTH         ;

  logic clk /* verilator public */ = 0, rstn, firebridge_done;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  localparam S_COUNT = 1;
  localparam M_COUNT = 4;

  wire [S_COUNT-1:0][AXI_ID_WIDTH   -1:0]   s_axi_awid   ;
  wire [S_COUNT-1:0][AXIL_ADDR_WIDTH-1:0]   s_axi_awaddr ;
  wire [S_COUNT-1:0][7:0]                   s_axi_awlen  ;
  wire [S_COUNT-1:0][2:0]                   s_axi_awsize ;
  wire [S_COUNT-1:0][1:0]                   s_axi_awburst;
  wire [S_COUNT-1:0]                        s_axi_awlock ;
  wire [S_COUNT-1:0][3:0]                   s_axi_awcache;
  wire [S_COUNT-1:0][2:0]                   s_axi_awprot ;
  wire [S_COUNT-1:0]                        s_axi_awvalid;
  wire [S_COUNT-1:0]                        s_axi_awready;
  wire [S_COUNT-1:0][AXIL_WIDTH-1:0]        s_axi_wdata  ;
  wire [S_COUNT-1:0][AXIL_STRB_WIDTH-1:0]   s_axi_wstrb  ;
  wire [S_COUNT-1:0]                        s_axi_wlast  ;
  wire [S_COUNT-1:0]                        s_axi_wvalid ;
  wire [S_COUNT-1:0]                        s_axi_wready ;
  wire [S_COUNT-1:0][AXI_ID_WIDTH-1:0]      s_axi_bid    ;
  wire [S_COUNT-1:0][1:0]                   s_axi_bresp  ;
  wire [S_COUNT-1:0]                        s_axi_bvalid ;
  wire [S_COUNT-1:0]                        s_axi_bready ;
  wire [S_COUNT-1:0][AXI_ID_WIDTH-1:0]      s_axi_arid   ;
  wire [S_COUNT-1:0][AXIL_ADDR_WIDTH-1:0]   s_axi_araddr ;
  wire [S_COUNT-1:0][7:0]                   s_axi_arlen  ;
  wire [S_COUNT-1:0][2:0]                   s_axi_arsize ;
  wire [S_COUNT-1:0][1:0]                   s_axi_arburst;
  wire [S_COUNT-1:0]                        s_axi_arlock ;
  wire [S_COUNT-1:0][3:0]                   s_axi_arcache;
  wire [S_COUNT-1:0][2:0]                   s_axi_arprot ;
  wire [S_COUNT-1:0]                        s_axi_arvalid;
  wire [S_COUNT-1:0]                        s_axi_arready;
  wire [S_COUNT-1:0][AXI_ID_WIDTH-1:0]      s_axi_rid    ;
  wire [S_COUNT-1:0][AXIL_WIDTH-1:0]        s_axi_rdata  ;
  wire [S_COUNT-1:0][1:0]                   s_axi_rresp  ;
  wire [S_COUNT-1:0]                        s_axi_rlast  ;
  wire [S_COUNT-1:0]                        s_axi_rvalid ;
  wire [S_COUNT-1:0]                        s_axi_rready ;
  wire [M_COUNT-1:0][AXI_ID_WIDTH-1:0]      m_axi_awid   ;
  wire [M_COUNT-1:0][AXI_ADDR_WIDTH-1:0]    m_axi_awaddr ;
  wire [M_COUNT-1:0][7:0]                   m_axi_awlen  ;
  wire [M_COUNT-1:0][2:0]                   m_axi_awsize ;
  wire [M_COUNT-1:0][1:0]                   m_axi_awburst;
  wire [M_COUNT-1:0]                        m_axi_awlock ;
  wire [M_COUNT-1:0][3:0]                   m_axi_awcache;
  wire [M_COUNT-1:0][2:0]                   m_axi_awprot ;
  wire [M_COUNT-1:0]                        m_axi_awvalid;
  wire [M_COUNT-1:0]                        m_axi_awready;
  wire [M_COUNT-1:0][AXI_WIDTH-1:0]         m_axi_wdata  ;
  wire [M_COUNT-1:0][AXI_STRB_WIDTH-1:0]    m_axi_wstrb  ;
  wire [M_COUNT-1:0]                        m_axi_wlast  ;
  wire [M_COUNT-1:0]                        m_axi_wvalid ;
  wire [M_COUNT-1:0]                        m_axi_wready ;
  wire [M_COUNT-1:0][AXI_ID_WIDTH-1:0]      m_axi_bid    ;
  wire [M_COUNT-1:0][1:0]                   m_axi_bresp  ;
  wire [M_COUNT-1:0]                        m_axi_bvalid ;
  wire [M_COUNT-1:0]                        m_axi_bready ;
  wire [M_COUNT-1:0][AXI_ID_WIDTH-1:0]      m_axi_arid   ;
  wire [M_COUNT-1:0][AXI_ADDR_WIDTH-1:0]    m_axi_araddr ;
  wire [M_COUNT-1:0][7:0]                   m_axi_arlen  ;
  wire [M_COUNT-1:0][2:0]                   m_axi_arsize ;
  wire [M_COUNT-1:0][1:0]                   m_axi_arburst;
  wire [M_COUNT-1:0]                        m_axi_arlock ;
  wire [M_COUNT-1:0][3:0]                   m_axi_arcache;
  wire [M_COUNT-1:0][2:0]                   m_axi_arprot ;
  wire [M_COUNT-1:0]                        m_axi_arvalid;
  wire [M_COUNT-1:0]                        m_axi_arready;
  wire [M_COUNT-1:0][AXI_ID_WIDTH-1:0]      m_axi_rid    ;
  wire [M_COUNT-1:0][AXI_WIDTH-1:0]         m_axi_rdata  ;
  wire [M_COUNT-1:0][1:0]                   m_axi_rresp  ;
  wire [M_COUNT-1:0]                        m_axi_rlast  ;
  wire [M_COUNT-1:0]                        m_axi_rvalid ;
  wire [M_COUNT-1:0]                        m_axi_rready ;

  fb_axi_vip #(
    .S_COUNT           (S_COUNT          ),
    .M_COUNT           (M_COUNT          ),
    .M_AXI_DATA_WIDTH  (AXI_WIDTH        ), 
    .M_AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH   ), 
    .M_AXI_ID_WIDTH    (AXI_ID_WIDTH     ), 
    .M_AXI_STRB_WIDTH  (AXI_STRB_WIDTH   ), 
    .S_AXI_DATA_WIDTH  (AXIL_WIDTH       ), 
    .S_AXI_ADDR_WIDTH  (AXIL_ADDR_WIDTH  ), 
    .S_AXI_STRB_WIDTH  (AXIL_STRB_WIDTH  ), 
    .S_AXI_BASE_ADDR   (AXIL_BASE_ADDR   ),
    .VALID_PROB        (VALID_PROB       ),
    .READY_PROB        (READY_PROB       )
  ) FB (.*);


  top #(
      .R (R ),
      .C (C ),
      .WK(WK),
      .WX(WX),
      .WA(WA),
      .WY(WY),
      .LM(LM),
      .LA(LA),
      .AXI_WIDTH        (AXI_WIDTH        ),
      .AXI_ID_WIDTH     (AXI_ID_WIDTH     ),
      .AXI_STRB_WIDTH   (AXI_STRB_WIDTH   ),
      .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
      .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH   ),
      .AXIL_WIDTH       (AXIL_WIDTH       ),
      .AXIL_ADDR_WIDTH  (AXIL_ADDR_WIDTH  ),
      .AXIL_STRB_WIDTH  (AXIL_STRB_WIDTH  ),
      .AXIL_BASE_ADDR   (AXIL_BASE_ADDR   )
  ) TOP (
  .clk (clk), 
  .rstn(rstn),

  .s_axi_awid    (s_axi_awid   ),
  .s_axi_awaddr  (s_axi_awaddr ),
  .s_axi_awlen   (s_axi_awlen  ),
  .s_axi_awsize  (s_axi_awsize ),
  .s_axi_awburst (s_axi_awburst),
  .s_axi_awlock  (s_axi_awlock ),
  .s_axi_awcache (s_axi_awcache),
  .s_axi_awprot  (s_axi_awprot ),
  .s_axi_awvalid (s_axi_awvalid),
  .s_axi_awready (s_axi_awready),
  .s_axi_wdata   (s_axi_wdata  ),
  .s_axi_wstrb   (s_axi_wstrb  ),
  .s_axi_wlast   (s_axi_wlast  ),
  .s_axi_wvalid  (s_axi_wvalid ),
  .s_axi_wready  (s_axi_wready ),
  .s_axi_bid     (s_axi_bid    ),
  .s_axi_bresp   (s_axi_bresp  ),
  .s_axi_bvalid  (s_axi_bvalid ),
  .s_axi_bready  (s_axi_bready ),
  .s_axi_arid    (s_axi_arid   ),
  .s_axi_araddr  (s_axi_araddr ),
  .s_axi_arlen   (s_axi_arlen  ),
  .s_axi_arsize  (s_axi_arsize ),
  .s_axi_arburst (s_axi_arburst),
  .s_axi_arlock  (s_axi_arlock ),
  .s_axi_arcache (s_axi_arcache),
  .s_axi_arprot  (s_axi_arprot ),
  .s_axi_arvalid (s_axi_arvalid),
  .s_axi_arready (s_axi_arready),
  .s_axi_rid     (s_axi_rid    ),
  .s_axi_rdata   (s_axi_rdata  ),
  .s_axi_rresp   (s_axi_rresp  ),
  .s_axi_rlast   (s_axi_rlast  ),
  .s_axi_rvalid  (s_axi_rvalid ),
  .s_axi_rready  (s_axi_rready ),
  // Weights
  .m_axi_mm2s_0_arid   (m_axi_arid   [0]),
  .m_axi_mm2s_0_araddr (m_axi_araddr [0]),
  .m_axi_mm2s_0_arlen  (m_axi_arlen  [0]),
  .m_axi_mm2s_0_arsize (m_axi_arsize [0]),
  .m_axi_mm2s_0_arburst(m_axi_arburst[0]),
  .m_axi_mm2s_0_arlock (m_axi_arlock [0]),
  .m_axi_mm2s_0_arcache(m_axi_arcache[0]),
  .m_axi_mm2s_0_arprot (m_axi_arprot [0]),
  .m_axi_mm2s_0_arvalid(m_axi_arvalid[0]),
  .m_axi_mm2s_0_arready(m_axi_arready[0]),
  .m_axi_mm2s_0_rid    (m_axi_rid    [0]),
  .m_axi_mm2s_0_rdata  (m_axi_rdata  [0]),
  .m_axi_mm2s_0_rresp  (m_axi_rresp  [0]),
  .m_axi_mm2s_0_rlast  (m_axi_rlast  [0]),
  .m_axi_mm2s_0_rvalid (m_axi_rvalid [0]),
  .m_axi_mm2s_0_rready (m_axi_rready [0]),

  .m_axi_mm2s_1_arid   (m_axi_arid   [1]),
  .m_axi_mm2s_1_araddr (m_axi_araddr [1]),
  .m_axi_mm2s_1_arlen  (m_axi_arlen  [1]),
  .m_axi_mm2s_1_arsize (m_axi_arsize [1]),
  .m_axi_mm2s_1_arburst(m_axi_arburst[1]),
  .m_axi_mm2s_1_arlock (m_axi_arlock [1]),
  .m_axi_mm2s_1_arcache(m_axi_arcache[1]),
  .m_axi_mm2s_1_arprot (m_axi_arprot [1]),
  .m_axi_mm2s_1_arvalid(m_axi_arvalid[1]),
  .m_axi_mm2s_1_arready(m_axi_arready[1]),
  .m_axi_mm2s_1_rid    (m_axi_rid    [1]),
  .m_axi_mm2s_1_rdata  (m_axi_rdata  [1]),
  .m_axi_mm2s_1_rresp  (m_axi_rresp  [1]),
  .m_axi_mm2s_1_rlast  (m_axi_rlast  [1]),
  .m_axi_mm2s_1_rvalid (m_axi_rvalid [1]),
  .m_axi_mm2s_1_rready (m_axi_rready [1]),

  .m_axi_mm2s_2_arid   (m_axi_arid   [2]),
  .m_axi_mm2s_2_araddr (m_axi_araddr [2]),
  .m_axi_mm2s_2_arlen  (m_axi_arlen  [2]),
  .m_axi_mm2s_2_arsize (m_axi_arsize [2]),
  .m_axi_mm2s_2_arburst(m_axi_arburst[2]),
  .m_axi_mm2s_2_arlock (m_axi_arlock [2]),
  .m_axi_mm2s_2_arcache(m_axi_arcache[2]),
  .m_axi_mm2s_2_arprot (m_axi_arprot [2]),
  .m_axi_mm2s_2_arvalid(m_axi_arvalid[2]),
  .m_axi_mm2s_2_arready(m_axi_arready[2]),
  .m_axi_mm2s_2_rid    (m_axi_rid    [2]),
  .m_axi_mm2s_2_rdata  (m_axi_rdata  [2]),
  .m_axi_mm2s_2_rresp  (m_axi_rresp  [2]),
  .m_axi_mm2s_2_rlast  (m_axi_rlast  [2]),
  .m_axi_mm2s_2_rvalid (m_axi_rvalid [2]),
  .m_axi_mm2s_2_rready (m_axi_rready [2]),

  .m_axi_s2mm_awid     (m_axi_awid   [3]),
  .m_axi_s2mm_awaddr   (m_axi_awaddr [3]),
  .m_axi_s2mm_awlen    (m_axi_awlen  [3]),
  .m_axi_s2mm_awsize   (m_axi_awsize [3]),
  .m_axi_s2mm_awburst  (m_axi_awburst[3]),
  .m_axi_s2mm_awlock   (m_axi_awlock [3]),
  .m_axi_s2mm_awcache  (m_axi_awcache[3]),
  .m_axi_s2mm_awprot   (m_axi_awprot [3]),
  .m_axi_s2mm_awvalid  (m_axi_awvalid[3]),
  .m_axi_s2mm_awready  (m_axi_awready[3]),
  .m_axi_s2mm_wdata    (m_axi_wdata  [3]),
  .m_axi_s2mm_wstrb    (m_axi_wstrb  [3]),
  .m_axi_s2mm_wlast    (m_axi_wlast  [3]),
  .m_axi_s2mm_wvalid   (m_axi_wvalid [3]),
  .m_axi_s2mm_wready   (m_axi_wready [3]),
  .m_axi_s2mm_bid      (m_axi_bid    [3]),
  .m_axi_s2mm_bresp    (m_axi_bresp  [3]),
  .m_axi_s2mm_bvalid   (m_axi_bvalid [3]),
  .m_axi_s2mm_bready   (m_axi_bready [3])
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars();
    #1000000us;
    $fatal(1, "Error: Timeout.");
  end

  int file_out, file_exp, status, error=0, i=0;
  byte out_byte, exp_byte;

  initial begin
    rstn <= 0;
    repeat(2) @(posedge clk) #10ps;
    rstn <= 1;
    
    wait(firebridge_done);

    // Read from output & expected and compare
    file_out = $fopen({DIR, "/y.bin"}, "rb");
    file_exp = $fopen({DIR, "/y_exp.bin" }, "rb");
    if (file_out==0 || file_exp==0) $fatal(0, "Error: Failed to open output/expected file(s).");

    while($feof(file_exp) == 0) begin
      if ($feof(file_out)) $fatal(0, "Error: output file is shorter than expected file.");
      else begin
        out_byte = $fgetc(file_out);
        exp_byte = $fgetc(file_exp);
        // Compare
        if (exp_byte != out_byte) begin
          $display("Mismatch at index %0d: Expected %h, Found %h", i, exp_byte, out_byte);
          error += 1;
        end 
      end
      i += 1;
    end
    $fclose(file_exp);
    $fclose(file_out);
    
    if (error==0) $display("\n\nVerification successful: Output matches Expected data. \nError count: %0d\n\n", error);
    else          $fatal (0, "\n\nERROR: Output data does not match Expected data.\n\n");

    $finish;
  end

endmodule
