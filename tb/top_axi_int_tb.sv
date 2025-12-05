`timescale 1ns/1ps
`include "config.svh"

module top_axi_int_tb;
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
    AXI_ADDR_WIDTH      = 32                 ,
    AXIL_WIDTH          = 32                 ,
    AXIL_ADDR_WIDTH     = 32                 ,
    AXIL_STRB_WIDTH     = (AXIL_WIDTH/8)     ,
    DATA_WR_WIDTH       = AXIL_WIDTH         ,
    DATA_RD_WIDTH       = AXIL_WIDTH         ;

  logic clk /* verilator public */ = 0, rstn, firebridge_done;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  localparam S_COUNT = 1;
  localparam M_COUNT = 1;

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


  top_axi_int #(
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
      .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH   ),
      .AXIL_WIDTH       (AXIL_WIDTH       ),
      .AXIL_ADDR_WIDTH  (AXIL_ADDR_WIDTH  ),
      .AXIL_STRB_WIDTH  (AXIL_STRB_WIDTH  ),
      .AXIL_BASE_ADDR   (AXIL_BASE_ADDR   )
  ) TOP (
  .clk (clk), 
  .rstn(rstn),

  .s_axil_awaddr (s_axi_awaddr  [0]),
  .s_axil_awprot (s_axi_awprot  [0]),
  .s_axil_awvalid(s_axi_awvalid [0]),
  .s_axil_awready(s_axi_awready [0]),
  .s_axil_wdata  (s_axi_wdata   [0]),
  .s_axil_wstrb  (s_axi_wstrb   [0]),
  .s_axil_wvalid (s_axi_wvalid  [0]),
  .s_axil_wready (s_axi_wready  [0]),
  .s_axil_bresp  (s_axi_bresp   [0]),
  .s_axil_bvalid (s_axi_bvalid  [0]),
  .s_axil_bready (s_axi_bready  [0]),
  .s_axil_araddr (s_axi_araddr  [0]),
  .s_axil_arprot (s_axi_arprot  [0]),
  .s_axil_arvalid(s_axi_arvalid [0]),
  .s_axil_arready(s_axi_arready [0]),
  .s_axil_rdata  (s_axi_rdata   [0]),
  .s_axil_rresp  (s_axi_rresp   [0]),
  .s_axil_rvalid (s_axi_rvalid  [0]),
  .s_axil_rready (s_axi_rready  [0]),

  // Weights
  .m_axi_arid   (m_axi_arid   [0]),
  .m_axi_araddr (m_axi_araddr [0]),
  .m_axi_arlen  (m_axi_arlen  [0]),
  .m_axi_arsize (m_axi_arsize [0]),
  .m_axi_arburst(m_axi_arburst[0]),
  .m_axi_arlock (m_axi_arlock [0]),
  .m_axi_arcache(m_axi_arcache[0]),
  .m_axi_arprot (m_axi_arprot [0]),
  .m_axi_arvalid(m_axi_arvalid[0]),
  .m_axi_arready(m_axi_arready[0]),
  .m_axi_rid    (m_axi_rid    [0]),
  .m_axi_rdata  (m_axi_rdata  [0]),
  .m_axi_rresp  (m_axi_rresp  [0]),
  .m_axi_rlast  (m_axi_rlast  [0]),
  .m_axi_rvalid (m_axi_rvalid [0]),
  .m_axi_rready (m_axi_rready [0]),
  .m_axi_awid   (m_axi_awid   [0]),
  .m_axi_awaddr (m_axi_awaddr [0]),
  .m_axi_awlen  (m_axi_awlen  [0]),
  .m_axi_awsize (m_axi_awsize [0]),
  .m_axi_awburst(m_axi_awburst[0]),
  .m_axi_awlock (m_axi_awlock [0]),
  .m_axi_awcache(m_axi_awcache[0]),
  .m_axi_awprot (m_axi_awprot [0]),
  .m_axi_awvalid(m_axi_awvalid[0]),
  .m_axi_awready(m_axi_awready[0]),
  .m_axi_wdata  (m_axi_wdata  [0]),
  .m_axi_wstrb  (m_axi_wstrb  [0]),
  .m_axi_wlast  (m_axi_wlast  [0]),
  .m_axi_wvalid (m_axi_wvalid [0]),
  .m_axi_wready (m_axi_wready [0]),
  .m_axi_bid    (m_axi_bid    [0]),
  .m_axi_bresp  (m_axi_bresp  [0]),
  .m_axi_bvalid (m_axi_bvalid [0]),
  .m_axi_bready (m_axi_bready [0])
  );

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars();
    #3000us;
    $fatal(1, "\n\nERROR: Timeout.\n\n");
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
