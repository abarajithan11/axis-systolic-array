`timescale 1ns/1ps
`include "config.svh"

module top_tb;
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
    AXIL_ADDR_WIDTH     = 40                 ,
    AXIL_STRB_WIDTH     = 4                  ,
    DATA_WR_WIDTH       = AXIL_WIDTH         ,
    DATA_RD_WIDTH       = AXIL_WIDTH         ,
    LSB                 = $clog2(AXI_WIDTH)-3;

  logic clk = 0, rstn, done=0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  logic [AXI_ID_WIDTH-1:0]     s_axi_awid   =0;
  logic [AXIL_ADDR_WIDTH-1:0]  s_axi_awaddr =0;
  logic [7:0]                  s_axi_awlen  =0;
  logic [2:0]                  s_axi_awsize =0;
  logic [1:0]                  s_axi_awburst=0;
  logic                        s_axi_awlock =0;
  logic [3:0]                  s_axi_awcache=0;
  logic [2:0]                  s_axi_awprot =0;
  logic                        s_axi_awvalid=0;
  logic                        s_axi_awready=0;
  logic [AXIL_WIDTH-1:0]       s_axi_wdata  =0;
  logic [AXIL_STRB_WIDTH-1:0]  s_axi_wstrb  =0;
  logic                        s_axi_wlast  =0;
  logic                        s_axi_wvalid =0;
  logic                        s_axi_wready ;
  logic [AXI_ID_WIDTH-1:0]     s_axi_bid    ;
  logic [1:0]                  s_axi_bresp  ;
  logic                        s_axi_bvalid ;
  logic                        s_axi_bready =0;
  logic [AXI_ID_WIDTH-1:0]     s_axi_arid   =0;
  logic [AXIL_ADDR_WIDTH-1:0]  s_axi_araddr =0;
  logic [7:0]                  s_axi_arlen  =0;
  logic [2:0]                  s_axi_arsize =0;
  logic [1:0]                  s_axi_arburst=0;
  logic                        s_axi_arlock =0;
  logic [3:0]                  s_axi_arcache=0;
  logic [2:0]                  s_axi_arprot =0;
  logic                        s_axi_arvalid=0;
  logic                        s_axi_arready;
  logic [AXI_ID_WIDTH-1:0]     s_axi_rid    ;
  logic [AXIL_WIDTH-1:0]       s_axi_rdata  ;
  logic [1:0]                  s_axi_rresp  ;
  logic                        s_axi_rlast  ;
  logic                        s_axi_rvalid ;
  logic                        s_axi_rready =0;
  // Weights
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_arid;
  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_0_araddr;
  logic [7:0]                 m_axi_mm2s_0_arlen;
  logic [2:0]                 m_axi_mm2s_0_arsize;
  logic [1:0]                 m_axi_mm2s_0_arburst;
  logic                       m_axi_mm2s_0_arlock;
  logic [3:0]                 m_axi_mm2s_0_arcache;
  logic [2:0]                 m_axi_mm2s_0_arprot;
  logic                       m_axi_mm2s_0_arvalid;
  logic                       m_axi_mm2s_0_arready;
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_rid;
  logic [AXI_WIDTH   -1:0]    m_axi_mm2s_0_rdata;
  logic [1:0]                 m_axi_mm2s_0_rresp;
  logic                       m_axi_mm2s_0_rlast;
  logic                       m_axi_mm2s_0_rvalid;
  logic                       m_axi_mm2s_0_rready;
  // Pixels
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_arid;
  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_1_araddr;
  logic [7:0]                 m_axi_mm2s_1_arlen;
  logic [2:0]                 m_axi_mm2s_1_arsize;
  logic [1:0]                 m_axi_mm2s_1_arburst;
  logic                       m_axi_mm2s_1_arlock;
  logic [3:0]                 m_axi_mm2s_1_arcache;
  logic [2:0]                 m_axi_mm2s_1_arprot;
  logic                       m_axi_mm2s_1_arvalid;
  logic                       m_axi_mm2s_1_arready;
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_rid;
  logic [AXI_WIDTH   -1:0]    m_axi_mm2s_1_rdata;
  logic [1:0]                 m_axi_mm2s_1_rresp;
  logic                       m_axi_mm2s_1_rlast;
  logic                       m_axi_mm2s_1_rvalid;
  logic                       m_axi_mm2s_1_rready;
  // Partial sums
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_arid;
  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_2_araddr;
  logic [7:0]                 m_axi_mm2s_2_arlen;
  logic [2:0]                 m_axi_mm2s_2_arsize;
  logic [1:0]                 m_axi_mm2s_2_arburst;
  logic                       m_axi_mm2s_2_arlock;
  logic [3:0]                 m_axi_mm2s_2_arcache;
  logic [2:0]                 m_axi_mm2s_2_arprot;
  logic                       m_axi_mm2s_2_arvalid;
  logic                       m_axi_mm2s_2_arready;
  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_rid;
  logic [AXI_WIDTH   -1:0]    m_axi_mm2s_2_rdata;
  logic [1:0]                 m_axi_mm2s_2_rresp;
  logic                       m_axi_mm2s_2_rlast;
  logic                       m_axi_mm2s_2_rvalid;
  logic                       m_axi_mm2s_2_rready;
  // Output
  logic [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid;
  logic [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr;
  logic [7:0]                 m_axi_s2mm_awlen;
  logic [2:0]                 m_axi_s2mm_awsize;
  logic [1:0]                 m_axi_s2mm_awburst;
  logic                       m_axi_s2mm_awlock;
  logic [3:0]                 m_axi_s2mm_awcache;
  logic [2:0]                 m_axi_s2mm_awprot;
  logic                       m_axi_s2mm_awvalid;
  logic                       m_axi_s2mm_awready;
  logic [AXI_WIDTH   -1:0]    m_axi_s2mm_wdata;
  logic [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb;
  logic                       m_axi_s2mm_wlast;
  logic                       m_axi_s2mm_wvalid;
  logic                       m_axi_s2mm_wready;
  logic [AXI_ID_WIDTH-1:0]    m_axi_s2mm_bid;
  logic [1:0]                 m_axi_s2mm_bresp;
  logic                       m_axi_s2mm_bvalid;
  logic                       m_axi_s2mm_bready;

  top_ram #(
    .R                 (R                ), 
    .C                 (C                ), 
    .WK                (WK               ), 
    .WX                (WX               ), 
    .WA                (WA               ), 
    .WY                (WY               ), 
    .LM                (LM               ), 
    .LA                (LA               ), 
    .VALID_PROB        (VALID_PROB       ),
    .READY_PROB        (READY_PROB       ),
    .AXI_WIDTH         (AXI_WIDTH        ), 
    .AXI_ID_WIDTH      (AXI_ID_WIDTH     ), 
    .AXI_STRB_WIDTH    (AXI_STRB_WIDTH   ), 
    .AXI_MAX_BURST_LEN (AXI_MAX_BURST_LEN), 
    .AXI_ADDR_WIDTH    (AXI_ADDR_WIDTH   ), 
    .AXIL_WIDTH        (AXIL_WIDTH       ), 
    .AXIL_ADDR_WIDTH   (AXIL_ADDR_WIDTH  ), 
    .AXIL_STRB_WIDTH   (AXIL_STRB_WIDTH  ), 
    .AXIL_BASE_ADDR    (AXIL_BASE_ADDR   ),
    .CLK_PERIOD        (CLK_PERIOD       ),
    .DIR               (DIR              )
  ) dut(.*);


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
      .*
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars();
    #1000us;
    $fatal(1, "Error: Timeout.");
  end

  initial begin
    rstn <= 0;
    repeat(2) @(posedge clk) #10ps;
    rstn <= 1;

    wait(done);
    $finish;
  end


endmodule
