`timescale 1ns/1ps

`include "config.svh"

module top_sa_ram #(
    parameter
        R          = `R ,
        C          = `C ,
        WK         = `WK,
        WX         = `WX,
        WY         = `WY,
        AXI_WIDTH  = `AXI_WIDTH,
        AXIL_WIDTH = `AXIL_WIDTH,
        ADDR_WIDTH = `ADDR_WIDTH,
        TIMEOUT    = 2,
        
        WA = 32,
        LM = 1,
        LA = 1,

        // Full AXI
        AXI_ID_WIDTH            = 6,
        AXI_STRB_WIDTH          = (AXI_WIDTH/8),
        AXI_MAX_BURST_LEN       = 32,
        AXIS_USER_WIDTH         = 8,         
        // AXI-Lite
        STRB_WIDTH              = 4,
        AXIL_BASE_ADDR          = 32'hB0000000

  ) (
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    // Config port
    input  wire [ADDR_WIDTH     -1:0] reg_wr_addr,
    input  wire [AXIL_WIDTH     -1:0] reg_wr_data,
    input  wire [STRB_WIDTH     -1:0] reg_wr_strb,
    input  wire                       reg_wr_en  ,
    input  wire [ADDR_WIDTH     -1:0] reg_rd_addr,
    input  wire                       reg_rd_en  ,
    output wire [AXIL_WIDTH     -1:0] reg_rd_data,

    // DMA ports
    output wire                       mm2s_0_rd_en  ,
    output wire [ADDR_WIDTH    -1:0]  mm2s_0_rd_addr,
    input  wire [AXI_WIDTH     -1:0]  mm2s_0_rd_data,
    input  wire                       mm2s_0_rd_wait,
    input  wire                       mm2s_0_rd_ack ,

    output wire                       mm2s_1_rd_en  ,
    output wire [ADDR_WIDTH    -1:0]  mm2s_1_rd_addr,
    input  wire [AXI_WIDTH     -1:0]  mm2s_1_rd_data,
    input  wire                       mm2s_1_rd_wait,
    input  wire                       mm2s_1_rd_ack ,

    output wire                       mm2s_2_rd_en  ,
    output wire [ADDR_WIDTH    -1:0]  mm2s_2_rd_addr,
    input  wire [AXI_WIDTH     -1:0]  mm2s_2_rd_data,
    input  wire                       mm2s_2_rd_wait,
    input  wire                       mm2s_2_rd_ack ,

    output wire                       s2mm_wr_en  ,
    output wire [ADDR_WIDTH    -1:0]  s2mm_wr_addr,
    output wire [AXI_WIDTH     -1:0]  s2mm_wr_data,
    output wire [AXI_STRB_WIDTH-1:0]  s2mm_wr_strb,
    input  wire                       s2mm_wr_wait,
    input  wire                       s2mm_wr_ack 
);

// Stream Side

localparam K_BUS_W = C*WK;
wire                       s_k_tready;
wire                       s_k_tvalid;
wire                       s_k_tlast ;
wire [K_BUS_W        -1:0] s_k_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_k_tuser ;

localparam X_BUS_W = R*WX;
wire                       s_x_tready;
wire                       s_x_tvalid;
wire                       s_x_tlast ;
wire [X_BUS_W        -1:0] s_x_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_x_tuser ;

localparam OUT_BUS_W = R*WY;
wire                       m_ready;
wire                       m_valid;
wire                       m_last ;
wire [OUT_BUS_W      -1:0] m_data ;

// Synchronize k & x streams
wire s_valid, s_ready, s_last;
assign s_valid    = s_k_tvalid & s_x_tvalid;
assign s_k_tready = s_ready    & s_x_tvalid;
assign s_x_tready = s_ready    & s_k_tvalid;
assign s_last     = s_k_tlast  & s_x_tlast;

axis_sa #(
    .R (R ), 
    .C (C ), 
    .WX(WX), 
    .WK(WK), 
    .WY(WY), 
    .LM(LM), 
    .LA(LA)
  ) SA (
    .clk(clk), 
    .rstn(rstn),
    .s_valid (s_valid), 
    .s_ready (s_ready), 
    .sx_data (s_x_tdata),
    .sk_data (s_k_tdata),
    .s_last  (s_last), 
    .m_ready (m_ready),
    .m_valid (m_valid), 
    .m_last  (m_last ), 
    .m_data  (m_data )
  );

localparam A_BUS_W = R*WA;
wire                       s_a_tready;
wire                       s_a_tvalid;
wire                       s_a_tlast ;
wire [A_BUS_W        -1:0] s_a_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_a_tuser ;

localparam Y_BUS_W = R*WY;
wire                       m_y_tready;
wire                       m_y_tvalid;
wire                       m_y_tlast ;
wire [Y_BUS_W     -1:0]    m_y_tdata ;

// Synchronize (m, s_a) => (m_y) streams
assign m_y_tvalid = s_a_tvalid & m_valid;
assign m_y_tlast  = s_last     & m_last;
assign m_ready    = m_y_tready & s_a_tvalid;
assign s_a_tready = m_y_tready & m_valid;

wire [Y_BUS_W-1:0] a_data_temp;
generate
    genvar r;
    for (r=0; r<R; r=r+1) begin : ADD
        assign a_data_temp[(r+1)*WY-1:r*WY] = s_a_tdata[(r+1)*WA-1:r*WA];
        assign m_y_tdata  [(r+1)*WY-1:r*WY] = $signed(m_data[(r+1)*WY-1:r*WY]) + $signed(a_data_temp[(r+1)*WY-1:r*WY]);
    end
endgenerate

// Weights
wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_arid   , m_axi_mm2s_1_arid   , m_axi_mm2s_0_arid   ;
wire [ADDR_WIDTH    -1:0]  m_axi_mm2s_2_araddr , m_axi_mm2s_1_araddr , m_axi_mm2s_0_araddr ;
wire [7:0]                 m_axi_mm2s_2_arlen  , m_axi_mm2s_1_arlen  , m_axi_mm2s_0_arlen  ;
wire [2:0]                 m_axi_mm2s_2_arsize , m_axi_mm2s_1_arsize , m_axi_mm2s_0_arsize ;
wire [1:0]                 m_axi_mm2s_2_arburst, m_axi_mm2s_1_arburst, m_axi_mm2s_0_arburst;
wire                       m_axi_mm2s_2_arlock , m_axi_mm2s_1_arlock , m_axi_mm2s_0_arlock ;
wire [3:0]                 m_axi_mm2s_2_arcache, m_axi_mm2s_1_arcache, m_axi_mm2s_0_arcache;
wire [2:0]                 m_axi_mm2s_2_arprot , m_axi_mm2s_1_arprot , m_axi_mm2s_0_arprot ;
wire                       m_axi_mm2s_2_arvalid, m_axi_mm2s_1_arvalid, m_axi_mm2s_0_arvalid;
wire                       m_axi_mm2s_2_arready, m_axi_mm2s_1_arready, m_axi_mm2s_0_arready;
wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_rid    , m_axi_mm2s_1_rid    , m_axi_mm2s_0_rid    ;
wire [AXI_WIDTH   -1:0]    m_axi_mm2s_2_rdata  , m_axi_mm2s_1_rdata  , m_axi_mm2s_0_rdata  ;
wire [1:0]                 m_axi_mm2s_2_rresp  , m_axi_mm2s_1_rresp  , m_axi_mm2s_0_rresp  ;
wire                       m_axi_mm2s_2_rlast  , m_axi_mm2s_1_rlast  , m_axi_mm2s_0_rlast  ;
wire                       m_axi_mm2s_2_rvalid , m_axi_mm2s_1_rvalid , m_axi_mm2s_0_rvalid ;
wire                       m_axi_mm2s_2_rready , m_axi_mm2s_1_rready , m_axi_mm2s_0_rready ;

wire [ADDR_WIDTH    -1:0]  m_axil_mm2s_2_araddr , m_axil_mm2s_1_araddr , m_axil_mm2s_0_araddr ;
wire [2:0]                 m_axil_mm2s_2_arprot , m_axil_mm2s_1_arprot , m_axil_mm2s_0_arprot ;
wire                       m_axil_mm2s_2_arvalid, m_axil_mm2s_1_arvalid, m_axil_mm2s_0_arvalid;
wire                       m_axil_mm2s_2_arready, m_axil_mm2s_1_arready, m_axil_mm2s_0_arready;
wire [AXI_WIDTH   -1:0]    m_axil_mm2s_2_rdata  , m_axil_mm2s_1_rdata  , m_axil_mm2s_0_rdata  ;
wire [1:0]                 m_axil_mm2s_2_rresp  , m_axil_mm2s_1_rresp  , m_axil_mm2s_0_rresp  ;
wire                       m_axil_mm2s_2_rvalid , m_axil_mm2s_1_rvalid , m_axil_mm2s_0_rvalid ;
wire                       m_axil_mm2s_2_rready , m_axil_mm2s_1_rready , m_axil_mm2s_0_rready ;

wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid;
wire [ADDR_WIDTH    -1:0]  m_axi_s2mm_awaddr;
wire [7:0]                 m_axi_s2mm_awlen;
wire [2:0]                 m_axi_s2mm_awsize;
wire [1:0]                 m_axi_s2mm_awburst;
wire                       m_axi_s2mm_awlock;
wire [3:0]                 m_axi_s2mm_awcache;
wire [2:0]                 m_axi_s2mm_awprot;
wire                       m_axi_s2mm_awvalid;
wire                       m_axi_s2mm_awready;
wire [AXI_WIDTH   -1:0]    m_axi_s2mm_wdata;
wire [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb;
wire                       m_axi_s2mm_wlast;
wire                       m_axi_s2mm_wvalid;
wire                       m_axi_s2mm_wready;
wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_bid;
wire [1:0]                 m_axi_s2mm_bresp;
wire                       m_axi_s2mm_bvalid;
wire                       m_axi_s2mm_bready;

wire [ADDR_WIDTH    -1:0]  m_axil_s2mm_awaddr ;
wire [2:0]                 m_axil_s2mm_awprot ;
wire                       m_axil_s2mm_awvalid;
wire                       m_axil_s2mm_awready;
wire [AXI_WIDTH   -1:0]    m_axil_s2mm_wdata  ;
wire [AXI_STRB_WIDTH-1:0]  m_axil_s2mm_wstrb  ;
wire                       m_axil_s2mm_wvalid ;
wire                       m_axil_s2mm_wready ;
wire [1:0]                 m_axil_s2mm_bresp  ;
wire                       m_axil_s2mm_bvalid ;
wire                       m_axil_s2mm_bready ;

axi_axil_adapter #(
  .ADDR_WIDTH           (ADDR_WIDTH    ),
  .AXI_DATA_WIDTH       (AXI_WIDTH),
  .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
  .AXI_ID_WIDTH         (AXI_ID_WIDTH),
  .AXIL_DATA_WIDTH      (AXI_WIDTH),
  .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
  ) AXI_TO_AXIL_0 (
  .clk          (clk ),
  .rst          (!rstn),
  .s_axi_awid   (),
  .s_axi_awaddr (),
  .s_axi_awlen  (),
  .s_axi_awsize (),
  .s_axi_awburst(),
  .s_axi_awlock (),
  .s_axi_awcache(),
  .s_axi_awprot (),
  .s_axi_awvalid(1'b0),
  .s_axi_awready(),
  .s_axi_wdata  (),
  .s_axi_wstrb  (),
  .s_axi_wlast  (),
  .s_axi_wvalid (1'b0),
  .s_axi_wready (),
  .s_axi_bid    (),
  .s_axi_bresp  (),
  .s_axi_bvalid (),
  .s_axi_bready (1'b0),
  .s_axi_arid   (m_axi_mm2s_0_arid   ),
  .s_axi_araddr (m_axi_mm2s_0_araddr ),
  .s_axi_arlen  (m_axi_mm2s_0_arlen  ),
  .s_axi_arsize (m_axi_mm2s_0_arsize ),
  .s_axi_arburst(m_axi_mm2s_0_arburst),
  .s_axi_arlock (m_axi_mm2s_0_arlock ),
  .s_axi_arcache(m_axi_mm2s_0_arcache),
  .s_axi_arprot (m_axi_mm2s_0_arprot ),
  .s_axi_arvalid(m_axi_mm2s_0_arvalid),
  .s_axi_arready(m_axi_mm2s_0_arready),
  .s_axi_rid    (m_axi_mm2s_0_rid    ),
  .s_axi_rdata  (m_axi_mm2s_0_rdata  ),
  .s_axi_rresp  (m_axi_mm2s_0_rresp  ),
  .s_axi_rlast  (m_axi_mm2s_0_rlast  ),
  .s_axi_rvalid (m_axi_mm2s_0_rvalid ),
  .s_axi_rready (m_axi_mm2s_0_rready ),

  .m_axil_awaddr (),
  .m_axil_awprot (),
  .m_axil_awvalid(),
  .m_axil_awready(1'b0),
  .m_axil_wdata  (),
  .m_axil_wstrb  (),
  .m_axil_wvalid (),
  .m_axil_wready (1'b0),
  .m_axil_bresp  (),
  .m_axil_bvalid (1'b0),
  .m_axil_bready (),
  
  .m_axil_araddr (m_axil_mm2s_0_araddr ),
  .m_axil_arprot (m_axil_mm2s_0_arprot ),
  .m_axil_arvalid(m_axil_mm2s_0_arvalid),
  .m_axil_arready(m_axil_mm2s_0_arready),
  .m_axil_rdata  (m_axil_mm2s_0_rdata  ),
  .m_axil_rresp  (m_axil_mm2s_0_rresp  ),
  .m_axil_rvalid (m_axil_mm2s_0_rvalid ),
  .m_axil_rready (m_axil_mm2s_0_rready )
);

alex_axilite_ram #(
  .DATA_WR_WIDTH (AXI_WIDTH),
  .DATA_RD_WIDTH (AXI_WIDTH),
  .ADDR_WIDTH    (ADDR_WIDTH    ),
  .STRB_WIDTH    (AXI_STRB_WIDTH),
  .TIMEOUT       (TIMEOUT)
  ) AXIL_TO_RAM_0 (
  .clk            (clk),
  .rstn           (rstn),
  .s_axil_awaddr  (),
  .s_axil_awprot  (),
  .s_axil_awvalid (),
  .s_axil_awready (),
  .s_axil_wdata   (),
  .s_axil_wstrb   (),
  .s_axil_wvalid  (),
  .s_axil_wready  (),
  .s_axil_bresp   (),
  .s_axil_bvalid  (),
  .s_axil_bready  (),
  .s_axil_araddr  (m_axil_mm2s_0_araddr ),
  .s_axil_arprot  (m_axil_mm2s_0_arprot ),
  .s_axil_arvalid (m_axil_mm2s_0_arvalid),
  .s_axil_arready (m_axil_mm2s_0_arready),
  .s_axil_rdata   (m_axil_mm2s_0_rdata  ),
  .s_axil_rresp   (m_axil_mm2s_0_rresp  ),
  .s_axil_rvalid  (m_axil_mm2s_0_rvalid ),
  .s_axil_rready  (m_axil_mm2s_0_rready ),

  .reg_wr_en      (),
  .reg_wr_addr    (),
  .reg_wr_data    (),
  .reg_wr_strb    (),
  .reg_wr_wait    (1'b0),
  .reg_wr_ack     (1'b0),
  .reg_rd_en      (mm2s_0_rd_en  ),
  .reg_rd_addr    (mm2s_0_rd_addr),
  .reg_rd_data    (mm2s_0_rd_data),
  .reg_rd_wait    (mm2s_0_rd_wait),
  .reg_rd_ack     (mm2s_0_rd_ack )
);

axi_axil_adapter #(
  .ADDR_WIDTH           (ADDR_WIDTH    ),
  .AXI_DATA_WIDTH       (AXI_WIDTH),
  .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
  .AXI_ID_WIDTH         (AXI_ID_WIDTH),
  .AXIL_DATA_WIDTH      (AXI_WIDTH),
  .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
  ) AXI_TO_AXIL_1 (
  .clk          (clk ),
  .rst          (!rstn),
  .s_axi_awid   (),
  .s_axi_awaddr (),
  .s_axi_awlen  (),
  .s_axi_awsize (),
  .s_axi_awburst(),
  .s_axi_awlock (),
  .s_axi_awcache(),
  .s_axi_awprot (),
  .s_axi_awvalid(1'b0),
  .s_axi_awready(),
  .s_axi_wdata  (),
  .s_axi_wstrb  (),
  .s_axi_wlast  (),
  .s_axi_wvalid (1'b0),
  .s_axi_wready (),
  .s_axi_bid    (),
  .s_axi_bresp  (),
  .s_axi_bvalid (),
  .s_axi_bready (1'b0),
  .s_axi_arid   (m_axi_mm2s_1_arid   ),
  .s_axi_araddr (m_axi_mm2s_1_araddr ),
  .s_axi_arlen  (m_axi_mm2s_1_arlen  ),
  .s_axi_arsize (m_axi_mm2s_1_arsize ),
  .s_axi_arburst(m_axi_mm2s_1_arburst),
  .s_axi_arlock (m_axi_mm2s_1_arlock ),
  .s_axi_arcache(m_axi_mm2s_1_arcache),
  .s_axi_arprot (m_axi_mm2s_1_arprot ),
  .s_axi_arvalid(m_axi_mm2s_1_arvalid),
  .s_axi_arready(m_axi_mm2s_1_arready),
  .s_axi_rid    (m_axi_mm2s_1_rid    ),
  .s_axi_rdata  (m_axi_mm2s_1_rdata  ),
  .s_axi_rresp  (m_axi_mm2s_1_rresp  ),
  .s_axi_rlast  (m_axi_mm2s_1_rlast  ),
  .s_axi_rvalid (m_axi_mm2s_1_rvalid ),
  .s_axi_rready (m_axi_mm2s_1_rready ),

  .m_axil_awaddr (),
  .m_axil_awprot (),
  .m_axil_awvalid(),
  .m_axil_awready(1'b0),
  .m_axil_wdata  (),
  .m_axil_wstrb  (),
  .m_axil_wvalid (),
  .m_axil_wready (1'b0),
  .m_axil_bresp  (),
  .m_axil_bvalid (1'b0),
  .m_axil_bready (),
  
  .m_axil_araddr (m_axil_mm2s_1_araddr ),
  .m_axil_arprot (m_axil_mm2s_1_arprot ),
  .m_axil_arvalid(m_axil_mm2s_1_arvalid),
  .m_axil_arready(m_axil_mm2s_1_arready),
  .m_axil_rdata  (m_axil_mm2s_1_rdata  ),
  .m_axil_rresp  (m_axil_mm2s_1_rresp  ),
  .m_axil_rvalid (m_axil_mm2s_1_rvalid ),
  .m_axil_rready (m_axil_mm2s_1_rready )
);

alex_axilite_ram #(
  .DATA_WR_WIDTH (AXI_WIDTH),
  .DATA_RD_WIDTH (AXI_WIDTH),
  .ADDR_WIDTH    (ADDR_WIDTH    ),
  .STRB_WIDTH    (AXI_STRB_WIDTH),
  .TIMEOUT       (TIMEOUT)
  ) AXIL_TO_RAM_1 (
  .clk            (clk),
  .rstn           (rstn),
  .s_axil_awaddr  (),
  .s_axil_awprot  (),
  .s_axil_awvalid (),
  .s_axil_awready (),
  .s_axil_wdata   (),
  .s_axil_wstrb   (),
  .s_axil_wvalid  (),
  .s_axil_wready  (),
  .s_axil_bresp   (),
  .s_axil_bvalid  (),
  .s_axil_bready  (),
  .s_axil_araddr  (m_axil_mm2s_1_araddr ),
  .s_axil_arprot  (m_axil_mm2s_1_arprot ),
  .s_axil_arvalid (m_axil_mm2s_1_arvalid),
  .s_axil_arready (m_axil_mm2s_1_arready),
  .s_axil_rdata   (m_axil_mm2s_1_rdata  ),
  .s_axil_rresp   (m_axil_mm2s_1_rresp  ),
  .s_axil_rvalid  (m_axil_mm2s_1_rvalid ),
  .s_axil_rready  (m_axil_mm2s_1_rready ),

  .reg_wr_en      (),
  .reg_wr_addr    (),
  .reg_wr_data    (),
  .reg_wr_strb    (),
  .reg_wr_wait    (1'b0),
  .reg_wr_ack     (1'b0),
  .reg_rd_en      (mm2s_1_rd_en  ),
  .reg_rd_addr    (mm2s_1_rd_addr),
  .reg_rd_data    (mm2s_1_rd_data),
  .reg_rd_wait    (mm2s_1_rd_wait),
  .reg_rd_ack     (mm2s_1_rd_ack )
);

axi_axil_adapter #(
  .ADDR_WIDTH           (ADDR_WIDTH    ),
  .AXI_DATA_WIDTH       (AXI_WIDTH),
  .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
  .AXI_ID_WIDTH         (AXI_ID_WIDTH),
  .AXIL_DATA_WIDTH      (AXI_WIDTH),
  .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
  ) AXI_TO_AXIL_2 (
  .clk          (clk ),
  .rst          (!rstn),
  .s_axi_awid   (),
  .s_axi_awaddr (),
  .s_axi_awlen  (),
  .s_axi_awsize (),
  .s_axi_awburst(),
  .s_axi_awlock (),
  .s_axi_awcache(),
  .s_axi_awprot (),
  .s_axi_awvalid(1'b0),
  .s_axi_awready(),
  .s_axi_wdata  (),
  .s_axi_wstrb  (),
  .s_axi_wlast  (),
  .s_axi_wvalid (1'b0),
  .s_axi_wready (),
  .s_axi_bid    (),
  .s_axi_bresp  (),
  .s_axi_bvalid (),
  .s_axi_bready (1'b0),
  .s_axi_arid   (m_axi_mm2s_2_arid   ),
  .s_axi_araddr (m_axi_mm2s_2_araddr ),
  .s_axi_arlen  (m_axi_mm2s_2_arlen  ),
  .s_axi_arsize (m_axi_mm2s_2_arsize ),
  .s_axi_arburst(m_axi_mm2s_2_arburst),
  .s_axi_arlock (m_axi_mm2s_2_arlock ),
  .s_axi_arcache(m_axi_mm2s_2_arcache),
  .s_axi_arprot (m_axi_mm2s_2_arprot ),
  .s_axi_arvalid(m_axi_mm2s_2_arvalid),
  .s_axi_arready(m_axi_mm2s_2_arready),
  .s_axi_rid    (m_axi_mm2s_2_rid    ),
  .s_axi_rdata  (m_axi_mm2s_2_rdata  ),
  .s_axi_rresp  (m_axi_mm2s_2_rresp  ),
  .s_axi_rlast  (m_axi_mm2s_2_rlast  ),
  .s_axi_rvalid (m_axi_mm2s_2_rvalid ),
  .s_axi_rready (m_axi_mm2s_2_rready ),

  .m_axil_awaddr (),
  .m_axil_awprot (),
  .m_axil_awvalid(),
  .m_axil_awready(1'b0),
  .m_axil_wdata  (),
  .m_axil_wstrb  (),
  .m_axil_wvalid (),
  .m_axil_wready (1'b0),
  .m_axil_bresp  (),
  .m_axil_bvalid (1'b0),
  .m_axil_bready (),
  
  .m_axil_araddr (m_axil_mm2s_2_araddr ),
  .m_axil_arprot (m_axil_mm2s_2_arprot ),
  .m_axil_arvalid(m_axil_mm2s_2_arvalid),
  .m_axil_arready(m_axil_mm2s_2_arready),
  .m_axil_rdata  (m_axil_mm2s_2_rdata  ),
  .m_axil_rresp  (m_axil_mm2s_2_rresp  ),
  .m_axil_rvalid (m_axil_mm2s_2_rvalid ),
  .m_axil_rready (m_axil_mm2s_2_rready )
);

alex_axilite_ram #(
  .DATA_WR_WIDTH (AXI_WIDTH),
  .DATA_RD_WIDTH (AXI_WIDTH),
  .ADDR_WIDTH    (ADDR_WIDTH    ),
  .STRB_WIDTH    (AXI_STRB_WIDTH),
  .TIMEOUT       (TIMEOUT)
  ) AXIL_TO_RAM_2 (
  .clk            (clk),
  .rstn           (rstn),
  .s_axil_awaddr  (),
  .s_axil_awprot  (),
  .s_axil_awvalid (),
  .s_axil_awready (),
  .s_axil_wdata   (),
  .s_axil_wstrb   (),
  .s_axil_wvalid  (),
  .s_axil_wready  (),
  .s_axil_bresp   (),
  .s_axil_bvalid  (),
  .s_axil_bready  (),
  .s_axil_araddr  (m_axil_mm2s_2_araddr ),
  .s_axil_arprot  (m_axil_mm2s_2_arprot ),
  .s_axil_arvalid (m_axil_mm2s_2_arvalid),
  .s_axil_arready (m_axil_mm2s_2_arready),
  .s_axil_rdata   (m_axil_mm2s_2_rdata  ),
  .s_axil_rresp   (m_axil_mm2s_2_rresp  ),
  .s_axil_rvalid  (m_axil_mm2s_2_rvalid ),
  .s_axil_rready  (m_axil_mm2s_2_rready ),

  .reg_wr_en      (),
  .reg_wr_addr    (),
  .reg_wr_data    (),
  .reg_wr_strb    (),
  .reg_wr_wait    (1'b0),
  .reg_wr_ack     (1'b0),
  .reg_rd_en      (mm2s_2_rd_en  ),
  .reg_rd_addr    (mm2s_2_rd_addr),
  .reg_rd_data    (mm2s_2_rd_data),
  .reg_rd_wait    (mm2s_2_rd_wait),
  .reg_rd_ack     (mm2s_2_rd_ack )
);


axi_axil_adapter #(
  .ADDR_WIDTH           (ADDR_WIDTH    ),
  .AXI_DATA_WIDTH       (AXI_WIDTH),
  .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
  .AXI_ID_WIDTH         (AXI_ID_WIDTH),
  .AXIL_DATA_WIDTH      (AXI_WIDTH),
  .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
  ) AXI_TO_AXIL_3 (
  .clk          (clk ),
  .rst          (!rstn),
  .s_axi_awid   (m_axi_s2mm_awid   ),
  .s_axi_awaddr (m_axi_s2mm_awaddr ),
  .s_axi_awlen  (m_axi_s2mm_awlen  ),
  .s_axi_awsize (m_axi_s2mm_awsize ),
  .s_axi_awburst(m_axi_s2mm_awburst),
  .s_axi_awlock (m_axi_s2mm_awlock ),
  .s_axi_awcache(m_axi_s2mm_awcache),
  .s_axi_awprot (m_axi_s2mm_awprot ),
  .s_axi_awvalid(m_axi_s2mm_awvalid),
  .s_axi_awready(m_axi_s2mm_awready),
  .s_axi_wdata  (m_axi_s2mm_wdata  ),
  .s_axi_wstrb  (m_axi_s2mm_wstrb  ),
  .s_axi_wlast  (m_axi_s2mm_wlast  ),
  .s_axi_wvalid (m_axi_s2mm_wvalid ),
  .s_axi_wready (m_axi_s2mm_wready ),
  .s_axi_bid    (m_axi_s2mm_bid    ),
  .s_axi_bresp  (m_axi_s2mm_bresp  ),
  .s_axi_bvalid (m_axi_s2mm_bvalid ),
  .s_axi_bready (m_axi_s2mm_bready ),

  .s_axi_arid   (),
  .s_axi_araddr (),
  .s_axi_arlen  (),
  .s_axi_arsize (),
  .s_axi_arburst(),
  .s_axi_arlock (),
  .s_axi_arcache(),
  .s_axi_arprot (),
  .s_axi_arvalid(1'b0),
  .s_axi_arready(),
  .s_axi_rid    (),
  .s_axi_rdata  (),
  .s_axi_rresp  (),
  .s_axi_rlast  (),
  .s_axi_rvalid (),
  .s_axi_rready (1'b0),

  .m_axil_awaddr (m_axil_s2mm_awaddr ),
  .m_axil_awprot (m_axil_s2mm_awprot ),
  .m_axil_awvalid(m_axil_s2mm_awvalid),
  .m_axil_awready(m_axil_s2mm_awready),
  .m_axil_wdata  (m_axil_s2mm_wdata  ),
  .m_axil_wstrb  (m_axil_s2mm_wstrb  ),
  .m_axil_wvalid (m_axil_s2mm_wvalid ),
  .m_axil_wready (m_axil_s2mm_wready ),
  .m_axil_bresp  (m_axil_s2mm_bresp  ),
  .m_axil_bvalid (m_axil_s2mm_bvalid ),
  .m_axil_bready (m_axil_s2mm_bready ),

  .m_axil_araddr (),
  .m_axil_arprot (),
  .m_axil_arvalid(),
  .m_axil_arready(1'b0),
  .m_axil_rdata  (),
  .m_axil_rresp  (),
  .m_axil_rvalid (1'b0),
  .m_axil_rready ()
);

alex_axilite_ram #(
  .DATA_WR_WIDTH (AXI_WIDTH),
  .DATA_RD_WIDTH (AXI_WIDTH),
  .ADDR_WIDTH    (ADDR_WIDTH    ),
  .STRB_WIDTH    (AXI_STRB_WIDTH),
  .TIMEOUT       (TIMEOUT)
  ) AXIL_TO_RAM_3 (
  .clk            (clk),
  .rstn           (rstn),
  .s_axil_awaddr  (m_axil_s2mm_awaddr ),
  .s_axil_awprot  (m_axil_s2mm_awprot ),
  .s_axil_awvalid (m_axil_s2mm_awvalid),
  .s_axil_awready (m_axil_s2mm_awready),
  .s_axil_wdata   (m_axil_s2mm_wdata  ),
  .s_axil_wstrb   (m_axil_s2mm_wstrb  ),
  .s_axil_wvalid  (m_axil_s2mm_wvalid ),
  .s_axil_wready  (m_axil_s2mm_wready ),
  .s_axil_bresp   (m_axil_s2mm_bresp  ),
  .s_axil_bvalid  (m_axil_s2mm_bvalid ),
  .s_axil_bready  (m_axil_s2mm_bready ),
  .s_axil_araddr  (),
  .s_axil_arprot  (),
  .s_axil_arvalid (),
  .s_axil_arready (),
  .s_axil_rdata   (),
  .s_axil_rresp   (),
  .s_axil_rvalid  (),
  .s_axil_rready  (),

  .reg_wr_en      (s2mm_wr_en  ),
  .reg_wr_addr    (s2mm_wr_addr),
  .reg_wr_data    (s2mm_wr_data),
  .reg_wr_strb    (s2mm_wr_strb),
  .reg_wr_wait    (s2mm_wr_wait),
  .reg_wr_ack     (s2mm_wr_ack ),
  .reg_rd_en      (),
  .reg_rd_addr    (),
  .reg_rd_data    (),
  .reg_rd_wait    (1'b0),
  .reg_rd_ack     (1'b0)
);

// AXI Stream side

wire                       s_axis_mm2s_0_tready;
wire                       s_axis_mm2s_0_tvalid;
wire                       s_axis_mm2s_0_tlast ;
wire [AXI_WIDTH      -1:0] s_axis_mm2s_0_tdata ;
wire [AXI_WIDTH/8    -1:0] s_axis_mm2s_0_tkeep ;
wire [AXIS_USER_WIDTH-1:0] s_axis_mm2s_0_tuser ;

wire                       s_axis_mm2s_1_tready;
wire                       s_axis_mm2s_1_tvalid;
wire                       s_axis_mm2s_1_tlast ;
wire [AXI_WIDTH      -1:0] s_axis_mm2s_1_tdata ;
wire [AXI_WIDTH/8    -1:0] s_axis_mm2s_1_tkeep ;
wire [AXIS_USER_WIDTH-1:0] s_axis_mm2s_1_tuser ;

wire                       s_axis_mm2s_2_tready;
wire                       s_axis_mm2s_2_tvalid;
wire                       s_axis_mm2s_2_tlast ;
wire [AXI_WIDTH      -1:0] s_axis_mm2s_2_tdata ;
wire [AXI_WIDTH/8    -1:0] s_axis_mm2s_2_tkeep ;
wire [AXIS_USER_WIDTH-1:0] s_axis_mm2s_2_tuser ;

wire                       m_axis_s2mm_tready;
wire                       m_axis_s2mm_tvalid;
wire                       m_axis_s2mm_tlast ;
wire [AXI_WIDTH   -1:0]    m_axis_s2mm_tdata ;
wire [AXI_WIDTH/8 -1:0]    m_axis_s2mm_tkeep ;


alex_axis_adapter_any #(
  .S_DATA_WIDTH  (AXI_WIDTH),
  .S_KEEP_ENABLE (1),
  .S_KEEP_WIDTH  (AXI_WIDTH/8),
  .M_DATA_WIDTH  (K_BUS_W),
  .M_KEEP_ENABLE (1),
  .USER_ENABLE   (1),
  .USER_WIDTH    (AXIS_USER_WIDTH)
) ADAPTER_MM2S_K (
  .clk           (clk),
  .rstn          (rstn),
  .s_axis_tready (s_axis_mm2s_0_tready),
  .s_axis_tvalid (s_axis_mm2s_0_tvalid),
  .s_axis_tlast  (s_axis_mm2s_0_tlast ),
  .s_axis_tdata  (s_axis_mm2s_0_tdata ),
  .s_axis_tkeep  (s_axis_mm2s_0_tkeep ),
  .s_axis_tuser  (s_axis_mm2s_0_tuser ),
  .s_axis_tid    (),
  .s_axis_tdest  (),
  .m_axis_tready (s_k_tready),
  .m_axis_tvalid (s_k_tvalid),
  .m_axis_tlast  (s_k_tlast ),
  .m_axis_tdata  (s_k_tdata ),
  .m_axis_tuser  (s_k_tuser ),
  .m_axis_tkeep  (),
  .m_axis_tid    (),
  .m_axis_tdest  ()
);

alex_axis_adapter_any #(
  .S_DATA_WIDTH  (AXI_WIDTH),
  .S_KEEP_ENABLE (1),
  .S_KEEP_WIDTH  (AXI_WIDTH/8),
  .M_DATA_WIDTH  (X_BUS_W),
  .M_KEEP_ENABLE (1),
  .USER_ENABLE   (1),
  .USER_WIDTH    (AXIS_USER_WIDTH)
) ADAPTER_MM2S_X (
  .clk           (clk),
  .rstn          (rstn),
  .s_axis_tready (s_axis_mm2s_1_tready),
  .s_axis_tvalid (s_axis_mm2s_1_tvalid),
  .s_axis_tlast  (s_axis_mm2s_1_tlast ),
  .s_axis_tdata  (s_axis_mm2s_1_tdata ),
  .s_axis_tkeep  (s_axis_mm2s_1_tkeep ),
  .s_axis_tuser  (s_axis_mm2s_1_tuser ),
  .s_axis_tid    (),
  .s_axis_tdest  (),
  .m_axis_tready (s_x_tready),
  .m_axis_tvalid (s_x_tvalid),
  .m_axis_tlast  (s_x_tlast ),
  .m_axis_tdata  (s_x_tdata ),
  .m_axis_tuser  (s_x_tuser ),
  .m_axis_tkeep  (),
  .m_axis_tid    (),
  .m_axis_tdest  ()
);

alex_axis_adapter_any #(
  .S_DATA_WIDTH  (AXI_WIDTH),
  .S_KEEP_ENABLE (1),
  .M_DATA_WIDTH  (A_BUS_W),
  .M_KEEP_ENABLE (1),
  .USER_ENABLE   (1),
  .USER_WIDTH    (AXIS_USER_WIDTH)
) ADAPTER_MM2S_A (
  .clk           (clk),
  .rstn          (rstn),
  .s_axis_tready (s_axis_mm2s_2_tready),
  .s_axis_tvalid (s_axis_mm2s_2_tvalid),
  .s_axis_tlast  (s_axis_mm2s_2_tlast ),
  .s_axis_tdata  (s_axis_mm2s_2_tdata ),
  .s_axis_tkeep  (s_axis_mm2s_2_tkeep ),
  .s_axis_tuser  (s_axis_mm2s_2_tuser ),
  .s_axis_tid    (),
  .s_axis_tdest  (),
  .m_axis_tready (s_a_tready),
  .m_axis_tvalid (s_a_tvalid),
  .m_axis_tlast  (s_a_tlast ),
  .m_axis_tdata  (s_a_tdata ),
  .m_axis_tuser  (s_a_tuser ),
  .m_axis_tkeep  (),
  .m_axis_tid    (),
  .m_axis_tdest  ()
);
localparam Y_KEEP_W = Y_BUS_W/8;
alex_axis_adapter_any #(
  .S_DATA_WIDTH  (Y_BUS_W),
  .S_KEEP_ENABLE (1),
  .M_DATA_WIDTH  (AXI_WIDTH),
  .M_KEEP_ENABLE (1),
  .USER_ENABLE   (0)
) ADAPTER_S2MM (
  .clk           (clk),
  .rstn          (rstn),
  .s_axis_tready (m_y_tready),
  .s_axis_tvalid (m_y_tvalid),
  .s_axis_tlast  (m_y_tlast ),
  .s_axis_tdata  (m_y_tdata ),
  .s_axis_tkeep  ({Y_KEEP_W{1'b1}}),
  .s_axis_tuser  (),
  .s_axis_tid    (),
  .s_axis_tdest  (),
  .m_axis_tready (m_axis_s2mm_tready),
  .m_axis_tvalid (m_axis_s2mm_tvalid),
  .m_axis_tlast  (m_axis_s2mm_tlast ),
  .m_axis_tdata  (m_axis_s2mm_tdata ),
  .m_axis_tkeep  (m_axis_s2mm_tkeep ),
  .m_axis_tuser  (),
  .m_axis_tid    (),
  .m_axis_tdest  ()
);


localparam      AXI_LEN_WIDTH           = 32,

    // Alex AXI DMA RD                
                AXIS_ID_WIDTH           = AXI_ID_WIDTH,
                AXIS_KEEP_ENABLE        = 1,
                AXIS_KEEP_WIDTH         = (AXI_WIDTH/8),
                AXIS_LAST_ENABLE        = 1,
                AXIS_ID_ENABLE          = 0,
                AXIS_DEST_ENABLE        = 0,
                AXIS_DEST_WIDTH         = 8,
                LEN_WIDTH               = AXI_LEN_WIDTH,
                TAG_WIDTH               = 8,
                ENABLE_SG               = 0,
                ENABLE_UNALIGNED        = 1;
    

// Controller with Alex DMAs: desc signals (including od tag) and status signals
wire [ADDR_WIDTH    +AXI_LEN_WIDTH-1:0] s2mm_desc_tdata;
wire [TAG_WIDTH-1:0]                    s2mm_desc_tag;
wire                                    s2mm_desc_tvalid;
wire                                    s2mm_desc_tready;
wire [TAG_WIDTH-1:0]                    s2mm_status_tag;
wire [3:0]                              s2mm_status_error;
wire                                    s2mm_status_valid;

wire [ADDR_WIDTH    +AXI_LEN_WIDTH-1:0] mm2s_0_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_0_desc_tuser;
wire                                    mm2s_0_desc_tvalid;
wire                                    mm2s_0_desc_tready;
wire [3:0]                              mm2s_0_status_error;
wire                                    mm2s_0_status_valid;

wire [ADDR_WIDTH    +AXI_LEN_WIDTH-1:0] mm2s_1_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_1_desc_tuser;
wire                                    mm2s_1_desc_tvalid;
wire                                    mm2s_1_desc_tready;
wire [3:0]                              mm2s_1_status_error;
wire                                    mm2s_1_status_valid;

wire [ADDR_WIDTH    +AXI_LEN_WIDTH-1:0] mm2s_2_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_2_desc_tuser;
wire                                    mm2s_2_desc_tvalid;
wire                                    mm2s_2_desc_tready;
wire [3:0]                              mm2s_2_status_error;
wire                                    mm2s_2_status_valid;

dma_controller #(
    .ADDR_WIDTH    (ADDR_WIDTH    ),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .AXI_DATA_WIDTH(AXIL_WIDTH),
    .AXI_LEN_WIDTH(AXI_LEN_WIDTH),
    .AXI_TAG_WIDTH(TAG_WIDTH)
) CONTROLLER (
    .clk(clk),
    .rstn(rstn),

    .reg_wr_en  (reg_wr_en),
    .reg_wr_addr(reg_wr_addr[ADDR_WIDTH    -1:0]),
    .reg_wr_data(reg_wr_data),
    .reg_rd_en  (reg_rd_en),
    .reg_rd_addr(reg_rd_addr[ADDR_WIDTH    -1:0]),
    .reg_rd_data(reg_rd_data),

    .s2mm_desc        (s2mm_desc_tdata  ),
    .s2mm_tag         (s2mm_desc_tag    ),
    .s2mm_valid       (s2mm_desc_tvalid ),
    .s2mm_ready       (s2mm_desc_tready ),
    .s2mm_status_error(s2mm_status_error),
    .s2mm_status_valid(s2mm_status_valid),

    .mm2s_0_desc        (mm2s_0_desc_tdata ),
    .mm2s_0_user        (mm2s_0_desc_tuser ),
    .mm2s_0_valid       (mm2s_0_desc_tvalid),
    .mm2s_0_ready       (mm2s_0_desc_tready),
    .mm2s_0_status_error(mm2s_0_status_error),
    .mm2s_0_status_valid(mm2s_0_status_valid),
    
    .mm2s_1_desc        (mm2s_1_desc_tdata ),
    .mm2s_1_user        (mm2s_1_desc_tuser ),
    .mm2s_1_valid       (mm2s_1_desc_tvalid),
    .mm2s_1_ready       (mm2s_1_desc_tready),
    .mm2s_1_status_error(mm2s_1_status_error),
    .mm2s_1_status_valid(mm2s_1_status_valid),
    
    .mm2s_2_desc        (mm2s_2_desc_tdata ),
    .mm2s_2_user        (mm2s_2_desc_tuser ),
    .mm2s_2_valid       (mm2s_2_desc_tvalid),
    .mm2s_2_ready       (mm2s_2_desc_tready),
    .mm2s_2_status_error(mm2s_2_status_error),
    .mm2s_2_status_valid(mm2s_2_status_valid)
    
);

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .ADDR_WIDTH    (ADDR_WIDTH    ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(1),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) MM2S_0_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({AXI_ID_WIDTH{1'b0}}),
    .s_axis_read_desc_tdest       ({AXIS_DEST_WIDTH{1'b0}}),
    .s_axis_read_desc_tdata       (mm2s_0_desc_tdata),
    .s_axis_read_desc_tuser       (mm2s_0_desc_tuser),
    .s_axis_read_desc_tvalid      (mm2s_0_desc_tvalid),
    .s_axis_read_desc_tready      (mm2s_0_desc_tready),
    .m_axis_read_desc_status_error(mm2s_0_status_error),
    .m_axis_read_desc_status_valid(mm2s_0_status_valid),
    .m_axis_read_desc_status_tag  (),

    // External Stream
    .m_axis_read_data_tdata (s_axis_mm2s_0_tdata),
    .m_axis_read_data_tkeep (s_axis_mm2s_0_tkeep),
    .m_axis_read_data_tvalid(s_axis_mm2s_0_tvalid),
    .m_axis_read_data_tready(s_axis_mm2s_0_tready),
    .m_axis_read_data_tlast (s_axis_mm2s_0_tlast),
    .m_axis_read_data_tuser (s_axis_mm2s_0_tuser),
    .m_axis_read_data_tid   (),
    .m_axis_read_data_tdest (),
    // External AXI
    .m_axi_arid   (m_axi_mm2s_0_arid),
    .m_axi_araddr (m_axi_mm2s_0_araddr),
    .m_axi_arlen  (m_axi_mm2s_0_arlen),
    .m_axi_arsize (m_axi_mm2s_0_arsize),
    .m_axi_arburst(m_axi_mm2s_0_arburst),
    .m_axi_arlock (m_axi_mm2s_0_arlock),
    .m_axi_arcache(m_axi_mm2s_0_arcache),
    .m_axi_arprot (m_axi_mm2s_0_arprot),
    .m_axi_arvalid(m_axi_mm2s_0_arvalid),
    .m_axi_arready(m_axi_mm2s_0_arready),
    .m_axi_rid    (m_axi_mm2s_0_rid),
    .m_axi_rdata  (m_axi_mm2s_0_rdata),
    .m_axi_rresp  (m_axi_mm2s_0_rresp),
    .m_axi_rlast  (m_axi_mm2s_0_rlast),
    .m_axi_rvalid (m_axi_mm2s_0_rvalid),
    .m_axi_rready (m_axi_mm2s_0_rready),
    .enable(1'b1)
);

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .ADDR_WIDTH    (ADDR_WIDTH    ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(1),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) MM2S_1_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({AXI_ID_WIDTH{1'b0}}),
    .s_axis_read_desc_tdest       ({AXIS_DEST_WIDTH{1'b0}}),
    .s_axis_read_desc_tdata       (mm2s_1_desc_tdata),
    .s_axis_read_desc_tuser       (mm2s_1_desc_tuser),
    .s_axis_read_desc_tvalid      (mm2s_1_desc_tvalid),
    .s_axis_read_desc_tready      (mm2s_1_desc_tready),
    .m_axis_read_desc_status_error(mm2s_1_status_error),
    .m_axis_read_desc_status_valid(mm2s_1_status_valid),
    .m_axis_read_desc_status_tag  (),

    // External Stream
    .m_axis_read_data_tdata (s_axis_mm2s_1_tdata),
    .m_axis_read_data_tkeep (s_axis_mm2s_1_tkeep),
    .m_axis_read_data_tvalid(s_axis_mm2s_1_tvalid),
    .m_axis_read_data_tready(s_axis_mm2s_1_tready),
    .m_axis_read_data_tlast (s_axis_mm2s_1_tlast),
    .m_axis_read_data_tuser (s_axis_mm2s_1_tuser),
    .m_axis_read_data_tid   (),
    .m_axis_read_data_tdest (),
    // External AXI
    .m_axi_arid   (m_axi_mm2s_1_arid),
    .m_axi_araddr (m_axi_mm2s_1_araddr),
    .m_axi_arlen  (m_axi_mm2s_1_arlen),
    .m_axi_arsize (m_axi_mm2s_1_arsize),
    .m_axi_arburst(m_axi_mm2s_1_arburst),
    .m_axi_arlock (m_axi_mm2s_1_arlock),
    .m_axi_arcache(m_axi_mm2s_1_arcache),
    .m_axi_arprot (m_axi_mm2s_1_arprot),
    .m_axi_arvalid(m_axi_mm2s_1_arvalid),
    .m_axi_arready(m_axi_mm2s_1_arready),
    .m_axi_rid    (m_axi_mm2s_1_rid),
    .m_axi_rdata  (m_axi_mm2s_1_rdata),
    .m_axi_rresp  (m_axi_mm2s_1_rresp),
    .m_axi_rlast  (m_axi_mm2s_1_rlast),
    .m_axi_rvalid (m_axi_mm2s_1_rvalid),
    .m_axi_rready (m_axi_mm2s_1_rready),
    .enable(1'b1)
);

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .ADDR_WIDTH    (ADDR_WIDTH    ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(1),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) MM2S_2_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({AXI_ID_WIDTH{1'b0}}),
    .s_axis_read_desc_tdest       ({AXIS_DEST_WIDTH{1'b0}}),
    .s_axis_read_desc_tdata       (mm2s_2_desc_tdata),
    .s_axis_read_desc_tuser       (mm2s_2_desc_tuser),
    .s_axis_read_desc_tvalid      (mm2s_2_desc_tvalid),
    .s_axis_read_desc_tready      (mm2s_2_desc_tready),
    .m_axis_read_desc_status_error(mm2s_2_status_error),
    .m_axis_read_desc_status_valid(mm2s_2_status_valid),
    .m_axis_read_desc_status_tag  (),

    // External Stream
    .m_axis_read_data_tdata (s_axis_mm2s_2_tdata),
    .m_axis_read_data_tkeep (s_axis_mm2s_2_tkeep),
    .m_axis_read_data_tvalid(s_axis_mm2s_2_tvalid),
    .m_axis_read_data_tready(s_axis_mm2s_2_tready),
    .m_axis_read_data_tlast (s_axis_mm2s_2_tlast),
    .m_axis_read_data_tuser (s_axis_mm2s_2_tuser),
    .m_axis_read_data_tid   (),
    .m_axis_read_data_tdest (),
    // External AXI
    .m_axi_arid   (m_axi_mm2s_2_arid),
    .m_axi_araddr (m_axi_mm2s_2_araddr),
    .m_axi_arlen  (m_axi_mm2s_2_arlen),
    .m_axi_arsize (m_axi_mm2s_2_arsize),
    .m_axi_arburst(m_axi_mm2s_2_arburst),
    .m_axi_arlock (m_axi_mm2s_2_arlock),
    .m_axi_arcache(m_axi_mm2s_2_arcache),
    .m_axi_arprot (m_axi_mm2s_2_arprot),
    .m_axi_arvalid(m_axi_mm2s_2_arvalid),
    .m_axi_arready(m_axi_mm2s_2_arready),
    .m_axi_rid    (m_axi_mm2s_2_rid),
    .m_axi_rdata  (m_axi_mm2s_2_rdata),
    .m_axi_rresp  (m_axi_mm2s_2_rresp),
    .m_axi_rlast  (m_axi_mm2s_2_rlast),
    .m_axi_rvalid (m_axi_mm2s_2_rvalid),
    .m_axi_rready (m_axi_mm2s_2_rready),
    .enable(1'b1)
);

alex_axi_dma_wr #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .ADDR_WIDTH    (ADDR_WIDTH    ),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(0),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) S2MM_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_write_desc_tdata       (s2mm_desc_tdata  ),
    .s_axis_write_desc_tag         (s2mm_desc_tag    ),
    .s_axis_write_desc_tvalid      (s2mm_desc_tvalid ),
    .s_axis_write_desc_tready      (s2mm_desc_tready ),
    .m_axis_write_desc_status_len  (                 ),
    .m_axis_write_desc_status_tag  (s2mm_status_tag  ),
    .m_axis_write_desc_status_id   (                 ),
    .m_axis_write_desc_status_dest (                 ),
    .m_axis_write_desc_status_user (                 ),
    .m_axis_write_desc_status_error(s2mm_status_error),
    .m_axis_write_desc_status_valid(s2mm_status_valid),

    // External Stream
    .s_axis_write_data_tdata (m_axis_s2mm_tdata),
    .s_axis_write_data_tkeep (m_axis_s2mm_tkeep),
    .s_axis_write_data_tvalid(m_axis_s2mm_tvalid),
    .s_axis_write_data_tready(m_axis_s2mm_tready),
    .s_axis_write_data_tlast (m_axis_s2mm_tlast),
    .s_axis_write_data_tid   (),
    .s_axis_write_data_tdest (),
    .s_axis_write_data_tuser (),
    // External AXI
    .m_axi_awid(m_axi_s2mm_awid),
    .m_axi_awaddr(m_axi_s2mm_awaddr),
    .m_axi_awlen(m_axi_s2mm_awlen),
    .m_axi_awsize(m_axi_s2mm_awsize),
    .m_axi_awburst(m_axi_s2mm_awburst),
    .m_axi_awlock(m_axi_s2mm_awlock),
    .m_axi_awcache(m_axi_s2mm_awcache),
    .m_axi_awprot(m_axi_s2mm_awprot),
    .m_axi_awvalid(m_axi_s2mm_awvalid),
    .m_axi_awready(m_axi_s2mm_awready),
    .m_axi_wdata(m_axi_s2mm_wdata),
    .m_axi_wstrb(m_axi_s2mm_wstrb),
    .m_axi_wlast(m_axi_s2mm_wlast),
    .m_axi_wvalid(m_axi_s2mm_wvalid),
    .m_axi_wready(m_axi_s2mm_wready),
    .m_axi_bid(m_axi_s2mm_bid),
    .m_axi_bresp(m_axi_s2mm_bresp),
    .m_axi_bvalid(m_axi_s2mm_bvalid),
    .m_axi_bready(m_axi_s2mm_bready),
    .enable(1'b1),
    .abort(1'b0)
);

endmodule
