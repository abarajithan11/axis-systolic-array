`timescale 1ns/1ps

`include "config.svh"

module top_axi_int #(
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
        DMA_ID_WIDTH            = 6-$clog2(4),
        AXI_STRB_WIDTH          = (AXI_WIDTH/8),
        AXI_MAX_BURST_LEN       = 1,
        AXI_ADDR_WIDTH          = 32,
        AXIS_USER_WIDTH         = 8,         
        // AXI-Lite
        AXIL_WIDTH              = 32,
        AXIL_ADDR_WIDTH         = 32,
        AXIL_STRB_WIDTH         = (AXIL_WIDTH/8),
        AXIL_BASE_ADDR          = 32'hB0000000

) (
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    // AXI-Lite Slave interface
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [AXIL_WIDTH-1:0]  s_axil_wdata,
    input  wire [AXIL_STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [AXIL_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,

    // AXI4 Master interface
    output wire [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_WIDTH   -1:0]    m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0]    m_axi_arid   ,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr ,
    output wire [7:0]                 m_axi_arlen  ,
    output wire [2:0]                 m_axi_arsize ,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock ,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot ,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid    ,
    input  wire [AXI_WIDTH   -1:0]    m_axi_rdata  ,
    input  wire [1:0]                 m_axi_rresp  ,
    input  wire                       m_axi_rlast  ,
    input  wire                       m_axi_rvalid ,
    output wire                       m_axi_rready 
);

// AXI Master Interfaces
wire [DMA_ID_WIDTH-1:0]    m_axi_s2mm_awid   , m_axi_mm2s_2_awid   , m_axi_mm2s_1_awid   , m_axi_mm2s_0_awid   ;
wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr , m_axi_mm2s_2_awaddr , m_axi_mm2s_1_awaddr , m_axi_mm2s_0_awaddr ;
wire [7:0]                 m_axi_s2mm_awlen  , m_axi_mm2s_2_awlen  , m_axi_mm2s_1_awlen  , m_axi_mm2s_0_awlen  ;
wire [2:0]                 m_axi_s2mm_awsize , m_axi_mm2s_2_awsize , m_axi_mm2s_1_awsize , m_axi_mm2s_0_awsize ;
wire [1:0]                 m_axi_s2mm_awburst, m_axi_mm2s_2_awburst, m_axi_mm2s_1_awburst, m_axi_mm2s_0_awburst;
wire                       m_axi_s2mm_awlock , m_axi_mm2s_2_awlock , m_axi_mm2s_1_awlock , m_axi_mm2s_0_awlock ;
wire [3:0]                 m_axi_s2mm_awcache, m_axi_mm2s_2_awcache, m_axi_mm2s_1_awcache, m_axi_mm2s_0_awcache;
wire [2:0]                 m_axi_s2mm_awprot , m_axi_mm2s_2_awprot , m_axi_mm2s_1_awprot , m_axi_mm2s_0_awprot ;
wire                       m_axi_s2mm_awvalid, m_axi_mm2s_2_awvalid, m_axi_mm2s_1_awvalid, m_axi_mm2s_0_awvalid;
wire                       m_axi_s2mm_awready, m_axi_mm2s_2_awready, m_axi_mm2s_1_awready, m_axi_mm2s_0_awready;
wire [AXI_WIDTH   -1:0]    m_axi_s2mm_wdata  , m_axi_mm2s_2_wdata  , m_axi_mm2s_1_wdata  , m_axi_mm2s_0_wdata  ;
wire [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb  , m_axi_mm2s_2_wstrb  , m_axi_mm2s_1_wstrb  , m_axi_mm2s_0_wstrb  ;
wire                       m_axi_s2mm_wlast  , m_axi_mm2s_2_wlast  , m_axi_mm2s_1_wlast  , m_axi_mm2s_0_wlast  ;
wire                       m_axi_s2mm_wvalid , m_axi_mm2s_2_wvalid , m_axi_mm2s_1_wvalid , m_axi_mm2s_0_wvalid ;
wire                       m_axi_s2mm_wready , m_axi_mm2s_2_wready , m_axi_mm2s_1_wready , m_axi_mm2s_0_wready ;
wire [DMA_ID_WIDTH-1:0]    m_axi_s2mm_bid    , m_axi_mm2s_2_bid    , m_axi_mm2s_1_bid    , m_axi_mm2s_0_bid    ;
wire [1:0]                 m_axi_s2mm_bresp  , m_axi_mm2s_2_bresp  , m_axi_mm2s_1_bresp  , m_axi_mm2s_0_bresp  ;
wire                       m_axi_s2mm_bvalid , m_axi_mm2s_2_bvalid , m_axi_mm2s_1_bvalid , m_axi_mm2s_0_bvalid ;
wire                       m_axi_s2mm_bready , m_axi_mm2s_2_bready , m_axi_mm2s_1_bready , m_axi_mm2s_0_bready ;
wire [DMA_ID_WIDTH-1:0]    m_axi_s2mm_arid   , m_axi_mm2s_2_arid   , m_axi_mm2s_1_arid   , m_axi_mm2s_0_arid   ;
wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_araddr , m_axi_mm2s_2_araddr , m_axi_mm2s_1_araddr , m_axi_mm2s_0_araddr ;
wire [7:0]                 m_axi_s2mm_arlen  , m_axi_mm2s_2_arlen  , m_axi_mm2s_1_arlen  , m_axi_mm2s_0_arlen  ;
wire [2:0]                 m_axi_s2mm_arsize , m_axi_mm2s_2_arsize , m_axi_mm2s_1_arsize , m_axi_mm2s_0_arsize ;
wire [1:0]                 m_axi_s2mm_arburst, m_axi_mm2s_2_arburst, m_axi_mm2s_1_arburst, m_axi_mm2s_0_arburst;
wire                       m_axi_s2mm_arlock , m_axi_mm2s_2_arlock , m_axi_mm2s_1_arlock , m_axi_mm2s_0_arlock ;
wire [3:0]                 m_axi_s2mm_arcache, m_axi_mm2s_2_arcache, m_axi_mm2s_1_arcache, m_axi_mm2s_0_arcache;
wire [2:0]                 m_axi_s2mm_arprot , m_axi_mm2s_2_arprot , m_axi_mm2s_1_arprot , m_axi_mm2s_0_arprot ;
wire                       m_axi_s2mm_arvalid, m_axi_mm2s_2_arvalid, m_axi_mm2s_1_arvalid, m_axi_mm2s_0_arvalid;
wire                       m_axi_s2mm_arready, m_axi_mm2s_2_arready, m_axi_mm2s_1_arready, m_axi_mm2s_0_arready;
wire [DMA_ID_WIDTH-1:0]    m_axi_s2mm_rid    , m_axi_mm2s_2_rid    , m_axi_mm2s_1_rid    , m_axi_mm2s_0_rid    ;
wire [AXI_WIDTH   -1:0]    m_axi_s2mm_rdata  , m_axi_mm2s_2_rdata  , m_axi_mm2s_1_rdata  , m_axi_mm2s_0_rdata  ;
wire [1:0]                 m_axi_s2mm_rresp  , m_axi_mm2s_2_rresp  , m_axi_mm2s_1_rresp  , m_axi_mm2s_0_rresp  ;
wire                       m_axi_s2mm_rlast  , m_axi_mm2s_2_rlast  , m_axi_mm2s_1_rlast  , m_axi_mm2s_0_rlast  ;
wire                       m_axi_s2mm_rvalid , m_axi_mm2s_2_rvalid , m_axi_mm2s_1_rvalid , m_axi_mm2s_0_rvalid ;
wire                       m_axi_s2mm_rready , m_axi_mm2s_2_rready , m_axi_mm2s_1_rready , m_axi_mm2s_0_rready ;

// Stream Side

localparam K_BUS_W = C*WK;
wire                       s_k_tready, s_k_skid_tready;
wire                       s_k_tvalid, s_k_skid_tvalid;
wire                       s_k_tlast , s_k_skid_tlast ;
wire [K_BUS_W        -1:0] s_k_tdata , s_k_skid_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_k_tuser , s_k_skid_tuser ;

localparam X_BUS_W = R*WX;
wire                       s_x_tready, s_x_skid_tready;
wire                       s_x_tvalid, s_x_skid_tvalid;
wire                       s_x_tlast , s_x_skid_tlast ;
wire [X_BUS_W        -1:0] s_x_tdata , s_x_skid_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_x_tuser , s_x_skid_tuser ;

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
wire                       s_a_tready, s_a_skid_tready;
wire                       s_a_tvalid, s_a_skid_tvalid;
wire                       s_a_tlast , s_a_skid_tlast ;
wire [A_BUS_W        -1:0] s_a_tdata , s_a_skid_tdata ;
wire [AXIS_USER_WIDTH-1:0] s_a_tuser , s_a_skid_tuser ;

localparam Y_BUS_W = R*WY;
wire                       m_y_tready, m_y_skid_tready;
wire                       m_y_tvalid, m_y_skid_tvalid;
wire                       m_y_tlast , m_y_skid_tlast ;
wire [Y_BUS_W     -1:0]    m_y_tdata , m_y_skid_tdata ;

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



// Skid buffers to prevent valid going low

skid_buffer #(
  .WIDTH(K_BUS_W + AXIS_USER_WIDTH + 1)
  ) SKID_K (
  .clk     (clk                                             ),
  .rstn    (rstn                                            ),
  .s_ready (s_k_skid_tready                                 ),
  .s_valid (s_k_skid_tvalid                                 ),
  .s_data  ({s_k_skid_tdata, s_k_skid_tuser, s_k_skid_tlast}),
  .m_ready (s_k_tready                                      ),
  .m_valid (s_k_tvalid                                      ),
  .m_data  ({s_k_tdata,      s_k_tuser,      s_k_tlast     })
);

skid_buffer #(
  .WIDTH(X_BUS_W + AXIS_USER_WIDTH + 1)
  ) SKID_X (
  .clk     (clk                                             ),
  .rstn    (rstn                                            ),
  .s_ready (s_x_skid_tready                                 ),
  .s_valid (s_x_skid_tvalid                                 ),
  .s_data  ({s_x_skid_tdata, s_x_skid_tuser, s_x_skid_tlast}),
  .m_ready (s_x_tready                                      ),
  .m_valid (s_x_tvalid                                      ),
  .m_data  ({s_x_tdata,      s_x_tuser,      s_x_tlast     })
);

skid_buffer #(
  .WIDTH(A_BUS_W + AXIS_USER_WIDTH + 1)
  ) SKID_A (
  .clk     (clk                                             ),
  .rstn    (rstn                                            ),
  .s_ready (s_a_skid_tready                                 ),
  .s_valid (s_a_skid_tvalid                                 ),
  .s_data  ({s_a_skid_tdata, s_a_skid_tuser, s_a_skid_tlast}),
  .m_ready (s_a_tready                                      ),
  .m_valid (s_a_tvalid                                      ),
  .m_data  ({s_a_tdata,      s_a_tuser,      s_a_tlast     })
);

skid_buffer #(
  .WIDTH(Y_BUS_W + 1)
  ) SKID_Y (
  .clk     (clk                             ),
  .rstn    (rstn                            ),
  .s_ready (m_y_tready                      ),
  .s_valid (m_y_tvalid                      ),
  .s_data  ({m_y_tdata,      m_y_tlast     }),
  .m_ready (m_y_skid_tready                 ),
  .m_valid (m_y_skid_tvalid                 ),
  .m_data  ({m_y_skid_tdata, m_y_skid_tlast})
);



// AXI side

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
  .m_axis_tready (s_k_skid_tready),
  .m_axis_tvalid (s_k_skid_tvalid),
  .m_axis_tlast  (s_k_skid_tlast ),
  .m_axis_tdata  (s_k_skid_tdata ),
  .m_axis_tuser  (s_k_skid_tuser ),
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
  .m_axis_tready (s_x_skid_tready),
  .m_axis_tvalid (s_x_skid_tvalid),
  .m_axis_tlast  (s_x_skid_tlast ),
  .m_axis_tdata  (s_x_skid_tdata ),
  .m_axis_tuser  (s_x_skid_tuser ),
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
  .m_axis_tready (s_a_skid_tready),
  .m_axis_tvalid (s_a_skid_tvalid),
  .m_axis_tlast  (s_a_skid_tlast ),
  .m_axis_tdata  (s_a_skid_tdata ),
  .m_axis_tuser  (s_a_skid_tuser ),
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
  .s_axis_tready (m_y_skid_tready),
  .s_axis_tvalid (m_y_skid_tvalid),
  .s_axis_tlast  (m_y_skid_tlast ),
  .s_axis_tdata  (m_y_skid_tdata ),
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



// Wires connecting AXIL2RAM to CONTROLLER
wire [AXIL_ADDR_WIDTH-1:0] reg_wr_addr;
wire [AXIL_WIDTH-1:0] reg_wr_data;
wire [AXIL_STRB_WIDTH-1:0] reg_wr_strb;
wire reg_wr_en;
wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr;
wire reg_rd_en;
wire [AXIL_WIDTH-1:0] reg_rd_data;

wire [AXIL_ADDR_WIDTH-1:0] reg_wr_addr_ctrl = (reg_wr_addr-AXIL_BASE_ADDR) >> 2;
wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr_ctrl = (reg_rd_addr-AXIL_BASE_ADDR) >> 2;


localparam      AXI_LEN_WIDTH           = 32,
                TIMEOUT                 = 2, // since 0 gives error

    // Alex AXI DMA RD                
                AXIS_ID_WIDTH           = DMA_ID_WIDTH,
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

alex_axilite_ram #(
    .DATA_WR_WIDTH(AXIL_WIDTH),
    .DATA_RD_WIDTH(AXIL_WIDTH),
    .ADDR_WIDTH(AXIL_ADDR_WIDTH),
    .STRB_WIDTH(AXIL_STRB_WIDTH),
    .TIMEOUT(TIMEOUT)
) AXIL2RAM (
    .clk(clk),
    .rstn(rstn),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .reg_wr_strb(reg_wr_strb),
    .reg_wr_en(reg_wr_en),
    .reg_wr_wait(1'b0),
    .reg_wr_ack(1'b1),
    .reg_rd_addr(reg_rd_addr),
    .reg_rd_en(reg_rd_en),
    .reg_rd_data(reg_rd_data),
    .reg_rd_wait(1'b0),
    .reg_rd_ack(1'b1)
);

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

wire m_axi_mm2s_0_arvalid_masked = m_axi_mm2s_0_arvalid && s_axis_mm2s_0_tready;
wire m_axi_mm2s_0_arready_masked = m_axi_mm2s_0_arready && s_axis_mm2s_0_tready;

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(DMA_ID_WIDTH),
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
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED),
    .AXI_ID(0)
) MM2S_0_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({DMA_ID_WIDTH{1'b0}}),
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
    .m_axi_arid   (),
    .m_axi_araddr (m_axi_mm2s_0_araddr),
    .m_axi_arlen  (m_axi_mm2s_0_arlen),
    .m_axi_arsize (m_axi_mm2s_0_arsize),
    .m_axi_arburst(m_axi_mm2s_0_arburst),
    .m_axi_arlock (m_axi_mm2s_0_arlock),
    .m_axi_arcache(m_axi_mm2s_0_arcache),
    .m_axi_arprot (m_axi_mm2s_0_arprot),
    .m_axi_arvalid(m_axi_mm2s_0_arvalid),
    .m_axi_arready(m_axi_mm2s_0_arready_masked),
    .m_axi_rid    (m_axi_mm2s_0_rid),
    .m_axi_rdata  (m_axi_mm2s_0_rdata),
    .m_axi_rresp  (m_axi_mm2s_0_rresp),
    .m_axi_rlast  (m_axi_mm2s_0_rlast),
    .m_axi_rvalid (m_axi_mm2s_0_rvalid),
    .m_axi_rready (m_axi_mm2s_0_rready),
    .enable(1'b1)
);

wire m_axi_mm2s_1_arvalid_masked = m_axi_mm2s_1_arvalid && s_axis_mm2s_1_tready;
wire m_axi_mm2s_1_arready_masked = m_axi_mm2s_1_arready && s_axis_mm2s_1_tready;

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(DMA_ID_WIDTH),
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
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED),
    .AXI_ID(1)
) MM2S_1_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({DMA_ID_WIDTH{1'b0}}),
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
    .m_axi_arid   (),
    .m_axi_araddr (m_axi_mm2s_1_araddr),
    .m_axi_arlen  (m_axi_mm2s_1_arlen),
    .m_axi_arsize (m_axi_mm2s_1_arsize),
    .m_axi_arburst(m_axi_mm2s_1_arburst),
    .m_axi_arlock (m_axi_mm2s_1_arlock),
    .m_axi_arcache(m_axi_mm2s_1_arcache),
    .m_axi_arprot (m_axi_mm2s_1_arprot),
    .m_axi_arvalid(m_axi_mm2s_1_arvalid),
    .m_axi_arready(m_axi_mm2s_1_arready_masked),
    .m_axi_rid    (m_axi_mm2s_1_rid),
    .m_axi_rdata  (m_axi_mm2s_1_rdata),
    .m_axi_rresp  (m_axi_mm2s_1_rresp),
    .m_axi_rlast  (m_axi_mm2s_1_rlast),
    .m_axi_rvalid (m_axi_mm2s_1_rvalid),
    .m_axi_rready (m_axi_mm2s_1_rready),
    .enable(1'b1)
);

wire m_axi_mm2s_2_arvalid_masked = m_axi_mm2s_2_arvalid && s_axis_mm2s_2_tready;
wire m_axi_mm2s_2_arready_masked = m_axi_mm2s_2_arready && s_axis_mm2s_2_tready;

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(DMA_ID_WIDTH),
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
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED),
    .AXI_ID(2)
) MM2S_2_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tag         ({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid         ({DMA_ID_WIDTH{1'b0}}),
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
    .m_axi_arid   (),
    .m_axi_araddr (m_axi_mm2s_2_araddr),
    .m_axi_arlen  (m_axi_mm2s_2_arlen),
    .m_axi_arsize (m_axi_mm2s_2_arsize),
    .m_axi_arburst(m_axi_mm2s_2_arburst),
    .m_axi_arlock (m_axi_mm2s_2_arlock),
    .m_axi_arcache(m_axi_mm2s_2_arcache),
    .m_axi_arprot (m_axi_mm2s_2_arprot),
    .m_axi_arvalid(m_axi_mm2s_2_arvalid),
    .m_axi_arready(m_axi_mm2s_2_arready_masked),
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
    .AXI_ID_WIDTH(DMA_ID_WIDTH),
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
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED),
    .AXI_ID(3)
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
    .m_axi_awid(),
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

assign m_axi_mm2s_0_arid   = DMA_ID_WIDTH'(0); // i
assign m_axi_mm2s_1_arid   = DMA_ID_WIDTH'(0); // i
assign m_axi_mm2s_2_arid   = DMA_ID_WIDTH'(0); // i
assign m_axi_s2mm_awid     = DMA_ID_WIDTH'(0); // i


assign {m_axi_mm2s_2_awid   , m_axi_mm2s_1_awid   , m_axi_mm2s_0_awid   } = 0; // i
assign {m_axi_mm2s_2_awaddr , m_axi_mm2s_1_awaddr , m_axi_mm2s_0_awaddr } = 0; // i
assign {m_axi_mm2s_2_awlen  , m_axi_mm2s_1_awlen  , m_axi_mm2s_0_awlen  } = 0; // i
assign {m_axi_mm2s_2_awsize , m_axi_mm2s_1_awsize , m_axi_mm2s_0_awsize } = 0; // i
assign {m_axi_mm2s_2_awburst, m_axi_mm2s_1_awburst, m_axi_mm2s_0_awburst} = 0; // i
assign {m_axi_mm2s_2_awlock , m_axi_mm2s_1_awlock , m_axi_mm2s_0_awlock } = 0; // i
assign {m_axi_mm2s_2_awcache, m_axi_mm2s_1_awcache, m_axi_mm2s_0_awcache} = 0; // i
assign {m_axi_mm2s_2_awprot , m_axi_mm2s_1_awprot , m_axi_mm2s_0_awprot } = 0; // i
assign {m_axi_mm2s_2_awvalid, m_axi_mm2s_1_awvalid, m_axi_mm2s_0_awvalid} = 0; // i
assign {m_axi_mm2s_2_wdata  , m_axi_mm2s_1_wdata  , m_axi_mm2s_0_wdata  } = 0; // i
assign {m_axi_mm2s_2_wstrb  , m_axi_mm2s_1_wstrb  , m_axi_mm2s_0_wstrb  } = 0; // i
assign {m_axi_mm2s_2_wlast  , m_axi_mm2s_1_wlast  , m_axi_mm2s_0_wlast  } = 0; // i
assign {m_axi_mm2s_2_wvalid , m_axi_mm2s_1_wvalid , m_axi_mm2s_0_wvalid } = 0; // i
assign {m_axi_mm2s_2_bready , m_axi_mm2s_1_bready , m_axi_mm2s_0_bready } = 0; // i
assign m_axi_s2mm_arid    = 0; // i
assign m_axi_s2mm_araddr  = 0; // i
assign m_axi_s2mm_arlen   = 0; // i
assign m_axi_s2mm_arsize  = 0; // i
assign m_axi_s2mm_arburst = 0; // i
assign m_axi_s2mm_arlock  = 0; // i
assign m_axi_s2mm_arcache = 0; // i
assign m_axi_s2mm_arprot  = 0; // i
assign m_axi_s2mm_arvalid = 0; // i
assign m_axi_s2mm_rready  = 0; // i

localparam S_COUNT = 4;
localparam M_COUNT = 1;

axi_crossbar #(
  .S_COUNT         (4                             ),
  .M_COUNT         (1                             ),
  .DATA_WIDTH      (AXI_WIDTH                     ),
  .ADDR_WIDTH      (AXI_ADDR_WIDTH                ),
  .STRB_WIDTH      (AXI_STRB_WIDTH                ),
  .S_ID_WIDTH      (DMA_ID_WIDTH                  ),
  .M_ID_WIDTH      (AXI_ID_WIDTH                  ),
  // .AWUSER_ENABLE   (0                             ),
  // .AWUSER_WIDTH    (1                             ),
  // .WUSER_ENABLE    (0                             ),
  // .WUSER_WIDTH     (1                             ),
  // .BUSER_ENABLE    (0                             ),
  // .BUSER_WIDTH     (1                             ),
  // .ARUSER_ENABLE   (0                             ),
  // .ARUSER_WIDTH    (1                             ),
  // .RUSER_ENABLE    (0                             ),
  // .RUSER_WIDTH     (1                             ),
  // .S_THREADS       ({S_COUNT{32'd2}}              ),
  // .S_ACCEPT        ({S_COUNT{32'd16}}             ),
  .M_REGIONS       (1                             ),
  .M_BASE_ADDR     (0                             ),
  .M_ADDR_WIDTH    (AXI_ADDR_WIDTH                ),
  // .M_CONNECT_READ  ({M_COUNT{{S_COUNT{1'b1}}}}    ),
  // .M_CONNECT_WRITE ({M_COUNT{{S_COUNT{1'b1}}}}    ),
  // .M_ISSUE         ({M_COUNT{32'd4}}              ),
  // .M_SECURE        ({M_COUNT{1'b0}}               ),
  .S_AW_REG_TYPE   ({S_COUNT{2'd2}}               ),
  .S_W_REG_TYPE    ({S_COUNT{2'd2}}               ),
  .S_B_REG_TYPE    ({S_COUNT{2'd2}}               ),
  .S_AR_REG_TYPE   ({S_COUNT{2'd2}}               ),
  .S_R_REG_TYPE    ({S_COUNT{2'd2}}               ),
  .M_AW_REG_TYPE   ({M_COUNT{2'd2}}               ),
  .M_W_REG_TYPE    ({M_COUNT{2'd2}}               ),
  .M_B_REG_TYPE    ({M_COUNT{2'd2}}               ),
  .M_AR_REG_TYPE   ({M_COUNT{2'd2}}               ),
  .M_R_REG_TYPE    ({M_COUNT{2'd2}}               )
) CROSSBAR (
  .clk           (clk),
  .rstn          (rstn),
  
  .s_axi_awqos   (0),
  .s_axi_awuser  (0),
  .s_axi_wuser   (0),
  .s_axi_buser   (),
  .s_axi_arqos   (0),
  .s_axi_aruser  (0),
  .s_axi_ruser   (),

  .m_axi_awqos   (),
  .m_axi_awuser  (),
  .m_axi_wuser   (),
  .m_axi_buser   (),
  .m_axi_arqos   (),
  .m_axi_aruser  (),
  .m_axi_ruser   (0),
  .m_axi_awregion(),
  .m_axi_arregion(),

  .s_axi_awid    ({m_axi_s2mm_awid   , m_axi_mm2s_2_awid   , m_axi_mm2s_1_awid   , m_axi_mm2s_0_awid   }), // i
  .s_axi_awaddr  ({m_axi_s2mm_awaddr , m_axi_mm2s_2_awaddr , m_axi_mm2s_1_awaddr , m_axi_mm2s_0_awaddr }), // i
  .s_axi_awlen   ({m_axi_s2mm_awlen  , m_axi_mm2s_2_awlen  , m_axi_mm2s_1_awlen  , m_axi_mm2s_0_awlen  }), // i
  .s_axi_awsize  ({m_axi_s2mm_awsize , m_axi_mm2s_2_awsize , m_axi_mm2s_1_awsize , m_axi_mm2s_0_awsize }), // i
  .s_axi_awburst ({m_axi_s2mm_awburst, m_axi_mm2s_2_awburst, m_axi_mm2s_1_awburst, m_axi_mm2s_0_awburst}), // i
  .s_axi_awlock  ({m_axi_s2mm_awlock , m_axi_mm2s_2_awlock , m_axi_mm2s_1_awlock , m_axi_mm2s_0_awlock }), // i
  .s_axi_awcache ({m_axi_s2mm_awcache, m_axi_mm2s_2_awcache, m_axi_mm2s_1_awcache, m_axi_mm2s_0_awcache}), // i
  .s_axi_awprot  ({m_axi_s2mm_awprot , m_axi_mm2s_2_awprot , m_axi_mm2s_1_awprot , m_axi_mm2s_0_awprot }), // i
  .s_axi_awvalid ({m_axi_s2mm_awvalid, m_axi_mm2s_2_awvalid, m_axi_mm2s_1_awvalid, m_axi_mm2s_0_awvalid}), // i
  .s_axi_awready ({m_axi_s2mm_awready, m_axi_mm2s_2_awready, m_axi_mm2s_1_awready, m_axi_mm2s_0_awready}), // o
  .s_axi_wdata   ({m_axi_s2mm_wdata  , m_axi_mm2s_2_wdata  , m_axi_mm2s_1_wdata  , m_axi_mm2s_0_wdata  }), // i
  .s_axi_wstrb   ({m_axi_s2mm_wstrb  , m_axi_mm2s_2_wstrb  , m_axi_mm2s_1_wstrb  , m_axi_mm2s_0_wstrb  }), // i
  .s_axi_wlast   ({m_axi_s2mm_wlast  , m_axi_mm2s_2_wlast  , m_axi_mm2s_1_wlast  , m_axi_mm2s_0_wlast  }), // i
  .s_axi_wvalid  ({m_axi_s2mm_wvalid , m_axi_mm2s_2_wvalid , m_axi_mm2s_1_wvalid , m_axi_mm2s_0_wvalid }), // i
  .s_axi_wready  ({m_axi_s2mm_wready , m_axi_mm2s_2_wready , m_axi_mm2s_1_wready , m_axi_mm2s_0_wready }), // o
  .s_axi_bid     ({m_axi_s2mm_bid    , m_axi_mm2s_2_bid    , m_axi_mm2s_1_bid    , m_axi_mm2s_0_bid    }), // o
  .s_axi_bresp   ({m_axi_s2mm_bresp  , m_axi_mm2s_2_bresp  , m_axi_mm2s_1_bresp  , m_axi_mm2s_0_bresp  }), // o
  .s_axi_bvalid  ({m_axi_s2mm_bvalid , m_axi_mm2s_2_bvalid , m_axi_mm2s_1_bvalid , m_axi_mm2s_0_bvalid }), // o
  .s_axi_bready  ({m_axi_s2mm_bready , m_axi_mm2s_2_bready , m_axi_mm2s_1_bready , m_axi_mm2s_0_bready }), // i
  .s_axi_arid    ({m_axi_s2mm_arid   , m_axi_mm2s_2_arid   , m_axi_mm2s_1_arid   , m_axi_mm2s_0_arid   }), // i
  .s_axi_araddr  ({m_axi_s2mm_araddr , m_axi_mm2s_2_araddr , m_axi_mm2s_1_araddr , m_axi_mm2s_0_araddr }), // i
  .s_axi_arlen   ({m_axi_s2mm_arlen  , m_axi_mm2s_2_arlen  , m_axi_mm2s_1_arlen  , m_axi_mm2s_0_arlen  }), // i
  .s_axi_arsize  ({m_axi_s2mm_arsize , m_axi_mm2s_2_arsize , m_axi_mm2s_1_arsize , m_axi_mm2s_0_arsize }), // i
  .s_axi_arburst ({m_axi_s2mm_arburst, m_axi_mm2s_2_arburst, m_axi_mm2s_1_arburst, m_axi_mm2s_0_arburst}), // i
  .s_axi_arlock  ({m_axi_s2mm_arlock , m_axi_mm2s_2_arlock , m_axi_mm2s_1_arlock , m_axi_mm2s_0_arlock }), // i
  .s_axi_arcache ({m_axi_s2mm_arcache, m_axi_mm2s_2_arcache, m_axi_mm2s_1_arcache, m_axi_mm2s_0_arcache}), // i
  .s_axi_arprot  ({m_axi_s2mm_arprot , m_axi_mm2s_2_arprot , m_axi_mm2s_1_arprot , m_axi_mm2s_0_arprot }), // i
  .s_axi_arvalid ({m_axi_s2mm_arvalid, m_axi_mm2s_2_arvalid_masked, m_axi_mm2s_1_arvalid_masked, m_axi_mm2s_0_arvalid_masked}), // i
  .s_axi_arready ({m_axi_s2mm_arready, m_axi_mm2s_2_arready, m_axi_mm2s_1_arready, m_axi_mm2s_0_arready}), // o
  .s_axi_rid     ({m_axi_s2mm_rid    , m_axi_mm2s_2_rid    , m_axi_mm2s_1_rid    , m_axi_mm2s_0_rid    }), // o
  .s_axi_rdata   ({m_axi_s2mm_rdata  , m_axi_mm2s_2_rdata  , m_axi_mm2s_1_rdata  , m_axi_mm2s_0_rdata  }), // o
  .s_axi_rresp   ({m_axi_s2mm_rresp  , m_axi_mm2s_2_rresp  , m_axi_mm2s_1_rresp  , m_axi_mm2s_0_rresp  }), // o
  .s_axi_rlast   ({m_axi_s2mm_rlast  , m_axi_mm2s_2_rlast  , m_axi_mm2s_1_rlast  , m_axi_mm2s_0_rlast  }), // o
  .s_axi_rvalid  ({m_axi_s2mm_rvalid , m_axi_mm2s_2_rvalid , m_axi_mm2s_1_rvalid , m_axi_mm2s_0_rvalid }), // o
  .s_axi_rready  ({m_axi_s2mm_rready , m_axi_mm2s_2_rready , m_axi_mm2s_1_rready , m_axi_mm2s_0_rready }), // i



  .m_axi_awid    (m_axi_awid   ), // o
  .m_axi_awaddr  (m_axi_awaddr ), // o
  .m_axi_awlen   (m_axi_awlen  ), // o
  .m_axi_awsize  (m_axi_awsize ), // o
  .m_axi_awburst (m_axi_awburst), // o
  .m_axi_awlock  (m_axi_awlock ), // o
  .m_axi_awcache (m_axi_awcache), // o
  .m_axi_awprot  (m_axi_awprot ), // o
  .m_axi_awvalid (m_axi_awvalid), // o
  .m_axi_awready (m_axi_awready), // i
  .m_axi_wdata   (m_axi_wdata  ), // o
  .m_axi_wstrb   (m_axi_wstrb  ), // o
  .m_axi_wlast   (m_axi_wlast  ), // o
  .m_axi_wvalid  (m_axi_wvalid ), // o
  .m_axi_wready  (m_axi_wready ), // i
  .m_axi_bid     (m_axi_bid    ), // i
  .m_axi_bresp   (m_axi_bresp  ), // i
  .m_axi_bvalid  (m_axi_bvalid ), // i
  .m_axi_bready  (m_axi_bready ), // o
  .m_axi_arid    (m_axi_arid   ), // o
  .m_axi_araddr  (m_axi_araddr ), // o
  .m_axi_arlen   (m_axi_arlen  ), // o
  .m_axi_arsize  (m_axi_arsize ), // o
  .m_axi_arburst (m_axi_arburst), // o
  .m_axi_arlock  (m_axi_arlock ), // o
  .m_axi_arcache (m_axi_arcache), // o
  .m_axi_arprot  (m_axi_arprot ), // o
  .m_axi_arvalid (m_axi_arvalid), // o
  .m_axi_arready (m_axi_arready), // i
  .m_axi_rid     (m_axi_rid    ), // i
  .m_axi_rdata   (m_axi_rdata  ), // i
  .m_axi_rresp   (m_axi_rresp  ), // i
  .m_axi_rlast   (m_axi_rlast  ), // i
  .m_axi_rvalid  (m_axi_rvalid ), // i
  .m_axi_rready  (m_axi_rready )  // o
);

endmodule