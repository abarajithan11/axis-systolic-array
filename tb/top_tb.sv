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




endmodule
