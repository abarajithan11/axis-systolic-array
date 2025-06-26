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
        
        WA = 32,
        LM = 1,
        LA = 1,

        // Full AXI
        AXI_ID_WIDTH            = 6,
        AXI_STRB_WIDTH          = (AXI_WIDTH/8),
        AXI_MAX_BURST_LEN       = 32,
        AXI_ADDR_WIDTH          = 32,
        AXIS_USER_WIDTH         = 8,         
        LSB                     = $clog2(AXI_WIDTH)-3,
        // AXI-Lite
        AXIL_WIDTH              = 32,
        AXIL_ADDR_WIDTH         = 40,
        STRB_WIDTH              = 4,
        AXIL_BASE_ADDR          = 32'hB0000000

) (
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    // Config port
    input  wire [AXIL_ADDR_WIDTH-1:0]      reg_wr_addr,
    input  wire [AXIL_WIDTH     -1:0]      reg_wr_data,
    input  wire [STRB_WIDTH     -1:0]      reg_wr_strb,
    input  wire                            reg_wr_en  ,
    input  wire [AXIL_ADDR_WIDTH-1:0]      reg_rd_addr,
    input  wire                            reg_rd_en  ,
    output wire [AXIL_WIDTH     -1:0]      reg_rd_data,

    // DMA ports
    output wire                            mm2s_0_ren ,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_0_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_0_data,
    
    output wire                            mm2s_1_ren ,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_1_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_1_data,
    
    output wire                            mm2s_2_ren ,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_2_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_2_data,
    
    output wire                            s2mm_wen   ,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  s2mm_addr  ,
    output wire  [AXI_WIDTH-1:0]           s2mm_data  ,
    output wire  [AXI_WIDTH/8-1:0]         s2mm_strb  
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

// AXI side

// Weights
wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_arid   , m_axi_mm2s_1_arid   , m_axi_mm2s_0_arid   ;
wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_2_araddr , m_axi_mm2s_1_araddr , m_axi_mm2s_0_araddr ;
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

wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid;
wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr;
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

localparam  OPT_LOCK          = 1'b0,
            OPT_LOCKID        = 1'b1,
            OPT_LOWPOWER      = 1'b0;

zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_mm2s_0 (
    .o_we(),
    .o_waddr(),
    .o_wdata(),
    .o_wstrb(),
    .o_rd   (mm2s_0_ren),
    .o_raddr(mm2s_0_addr),
    .i_rdata(mm2s_0_data),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(),
    .S_AXI_AWADDR(),
    .S_AXI_AWLEN(),
    .S_AXI_AWSIZE(),
    .S_AXI_AWBURST(),
    .S_AXI_AWLOCK(),
    .S_AXI_AWCACHE(),
    .S_AXI_AWPROT(),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID('0),
    .S_AXI_AWREADY(),
    .S_AXI_WDATA(),
    .S_AXI_WSTRB(),
    .S_AXI_WLAST(),
    .S_AXI_WVALID(1'b0),
    .S_AXI_WREADY(),
    .S_AXI_BID(),
    .S_AXI_BRESP(),
    .S_AXI_BVALID(),
    .S_AXI_BREADY(),
    .S_AXI_ARID   (m_axi_mm2s_0_arid),
    .S_AXI_ARADDR (m_axi_mm2s_0_araddr),
    .S_AXI_ARLEN  (m_axi_mm2s_0_arlen),
    .S_AXI_ARSIZE (m_axi_mm2s_0_arsize),
    .S_AXI_ARBURST(m_axi_mm2s_0_arburst),
    .S_AXI_ARLOCK (m_axi_mm2s_0_arlock),
    .S_AXI_ARCACHE(m_axi_mm2s_0_arcache),
    .S_AXI_ARPROT (m_axi_mm2s_0_arprot),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(m_axi_mm2s_0_arvalid),
    .S_AXI_ARREADY(m_axi_mm2s_0_arready),
    .S_AXI_RID    (m_axi_mm2s_0_rid),
    .S_AXI_RDATA  (m_axi_mm2s_0_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_0_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_0_rlast),
    .S_AXI_RVALID (m_axi_mm2s_0_rvalid),
    .S_AXI_RREADY (m_axi_mm2s_0_rready)
);
zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_mm2s_1 (
    .o_we(),
    .o_waddr(),
    .o_wdata(),
    .o_wstrb(),
    .o_rd   (mm2s_1_ren),
    .o_raddr(mm2s_1_addr),
    .i_rdata(mm2s_1_data),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(),
    .S_AXI_AWADDR(),
    .S_AXI_AWLEN(),
    .S_AXI_AWSIZE(),
    .S_AXI_AWBURST(),
    .S_AXI_AWLOCK(),
    .S_AXI_AWCACHE(),
    .S_AXI_AWPROT(),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID('0),
    .S_AXI_AWREADY(),
    .S_AXI_WDATA(),
    .S_AXI_WSTRB(),
    .S_AXI_WLAST(),
    .S_AXI_WVALID(1'b0),
    .S_AXI_WREADY(),
    .S_AXI_BID(),
    .S_AXI_BRESP(),
    .S_AXI_BVALID(),
    .S_AXI_BREADY(),
    .S_AXI_ARID   (m_axi_mm2s_1_arid),
    .S_AXI_ARADDR (m_axi_mm2s_1_araddr),
    .S_AXI_ARLEN  (m_axi_mm2s_1_arlen),
    .S_AXI_ARSIZE (m_axi_mm2s_1_arsize),
    .S_AXI_ARBURST(m_axi_mm2s_1_arburst),
    .S_AXI_ARLOCK (m_axi_mm2s_1_arlock),
    .S_AXI_ARCACHE(m_axi_mm2s_1_arcache),
    .S_AXI_ARPROT (m_axi_mm2s_1_arprot),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(m_axi_mm2s_1_arvalid),
    .S_AXI_ARREADY(m_axi_mm2s_1_arready),
    .S_AXI_RID    (m_axi_mm2s_1_rid),
    .S_AXI_RDATA  (m_axi_mm2s_1_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_1_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_1_rlast),
    .S_AXI_RVALID (m_axi_mm2s_1_rvalid),
    .S_AXI_RREADY (m_axi_mm2s_1_rready)
);
zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_mm2s_2 (
    .o_we(),
    .o_waddr(),
    .o_wdata(),
    .o_wstrb(),
    .o_rd   (mm2s_2_ren),
    .o_raddr(mm2s_2_addr),
    .i_rdata(mm2s_2_data),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(),
    .S_AXI_AWADDR(),
    .S_AXI_AWLEN(),
    .S_AXI_AWSIZE(),
    .S_AXI_AWBURST(),
    .S_AXI_AWLOCK(),
    .S_AXI_AWCACHE(),
    .S_AXI_AWPROT(),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID('0),
    .S_AXI_AWREADY(),
    .S_AXI_WDATA(),
    .S_AXI_WSTRB(),
    .S_AXI_WLAST(),
    .S_AXI_WVALID(1'b0),
    .S_AXI_WREADY(),
    .S_AXI_BID(),
    .S_AXI_BRESP(),
    .S_AXI_BVALID(),
    .S_AXI_BREADY(),
    .S_AXI_ARID   (m_axi_mm2s_2_arid),
    .S_AXI_ARADDR (m_axi_mm2s_2_araddr),
    .S_AXI_ARLEN  (m_axi_mm2s_2_arlen),
    .S_AXI_ARSIZE (m_axi_mm2s_2_arsize),
    .S_AXI_ARBURST(m_axi_mm2s_2_arburst),
    .S_AXI_ARLOCK (m_axi_mm2s_2_arlock),
    .S_AXI_ARCACHE(m_axi_mm2s_2_arcache),
    .S_AXI_ARPROT (m_axi_mm2s_2_arprot),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(m_axi_mm2s_2_arvalid),
    .S_AXI_ARREADY(m_axi_mm2s_2_arready),
    .S_AXI_RID    (m_axi_mm2s_2_rid),
    .S_AXI_RDATA  (m_axi_mm2s_2_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_2_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_2_rlast),
    .S_AXI_RVALID (m_axi_mm2s_2_rvalid),
    .S_AXI_RREADY (m_axi_mm2s_2_rready)
);

zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_s2mm (
    .o_we(s2mm_wen),
    .o_waddr(s2mm_addr),
    .o_wdata(s2mm_data),
    .o_wstrb(s2mm_strb),
    .o_rd(),
    .o_raddr(),
    .i_rdata(),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(m_axi_s2mm_awid),
    .S_AXI_AWADDR(m_axi_s2mm_awaddr),
    .S_AXI_AWLEN(m_axi_s2mm_awlen),
    .S_AXI_AWSIZE(m_axi_s2mm_awsize),
    .S_AXI_AWBURST(m_axi_s2mm_awburst),
    .S_AXI_AWLOCK(m_axi_s2mm_awlock),
    .S_AXI_AWCACHE(m_axi_s2mm_awcache),
    .S_AXI_AWPROT(m_axi_s2mm_awprot),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID(m_axi_s2mm_awvalid),
    .S_AXI_AWREADY(m_axi_s2mm_awready),
    .S_AXI_WDATA(m_axi_s2mm_wdata),
    .S_AXI_WSTRB(m_axi_s2mm_wstrb),
    .S_AXI_WLAST(m_axi_s2mm_wlast),
    .S_AXI_WVALID(m_axi_s2mm_wvalid),
    .S_AXI_WREADY(m_axi_s2mm_wready),
    .S_AXI_BID(m_axi_s2mm_bid),
    .S_AXI_BRESP(m_axi_s2mm_bresp),
    .S_AXI_BVALID(m_axi_s2mm_bvalid),
    .S_AXI_BREADY(m_axi_s2mm_bready),
    .S_AXI_ARID(),
    .S_AXI_ARADDR(),
    .S_AXI_ARLEN(),
    .S_AXI_ARSIZE(),
    .S_AXI_ARBURST(),
    .S_AXI_ARLOCK(),
    .S_AXI_ARCACHE(),
    .S_AXI_ARPROT(),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(1'b0),
    .S_AXI_ARREADY(),
    .S_AXI_RID(),
    .S_AXI_RDATA(),
    .S_AXI_RRESP(),
    .S_AXI_RLAST(),
    .S_AXI_RVALID(),
    .S_AXI_RREADY(1'b0)
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


// Veriltor width mismatch bullshit
localparam AXIL_ADDR_EXTRA = AXIL_ADDR_WIDTH - 32;
wire [AXIL_ADDR_EXTRA -1:0] axil_addr_zeros = 0;
wire [AXIL_ADDR_WIDTH-1:0] reg_wr_addr_ctrl = (reg_wr_addr-{axil_addr_zeros, AXIL_BASE_ADDR}) >> 2;
wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr_ctrl = (reg_rd_addr-{axil_addr_zeros,AXIL_BASE_ADDR})  >> 2;


localparam      AXI_LEN_WIDTH           = 32,
                TIMEOUT                 = 2, // since 0 gives error

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
wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] s2mm_desc_tdata;
wire [TAG_WIDTH-1:0]                    s2mm_desc_tag;
wire                                    s2mm_desc_tvalid;
wire                                    s2mm_desc_tready;
wire [TAG_WIDTH-1:0]                    s2mm_status_tag;
wire [3:0]                              s2mm_status_error;
wire                                    s2mm_status_valid;

wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] mm2s_0_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_0_desc_tuser;
wire                                    mm2s_0_desc_tvalid;
wire                                    mm2s_0_desc_tready;
wire [3:0]                              mm2s_0_status_error;
wire                                    mm2s_0_status_valid;

wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] mm2s_1_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_1_desc_tuser;
wire                                    mm2s_1_desc_tvalid;
wire                                    mm2s_1_desc_tready;
wire [3:0]                              mm2s_1_status_error;
wire                                    mm2s_1_status_valid;

wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] mm2s_2_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_2_desc_tuser;
wire                                    mm2s_2_desc_tvalid;
wire                                    mm2s_2_desc_tready;
wire [3:0]                              mm2s_2_status_error;
wire                                    mm2s_2_status_valid;

dma_controller #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .AXI_DATA_WIDTH(AXIL_WIDTH),
    .AXI_LEN_WIDTH(AXI_LEN_WIDTH),
    .AXI_TAG_WIDTH(TAG_WIDTH)
) CONTROLLER (
    .clk(clk),
    .rstn(rstn),

    .reg_wr_en  (reg_wr_en),
    .reg_wr_addr(reg_wr_addr_ctrl[AXI_ADDR_WIDTH-1:0]),
    .reg_wr_data(reg_wr_data),
    .reg_rd_en  (reg_rd_en),
    .reg_rd_addr(reg_rd_addr_ctrl[AXI_ADDR_WIDTH-1:0]),
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
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
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
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
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
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
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
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
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
