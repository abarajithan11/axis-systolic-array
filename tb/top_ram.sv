
`timescale 1ns/1ps

module top_ram #(
    parameter
        R                 = 8,
        C                 = 8,
        WK                = 8,
        WX                = 8,
        WA                = 8,
        WY                = 8,
        LM                = 1,
        LA                = 1,
        AXI_WIDTH         = 128,
        AXI_ID_WIDTH      = 6,
        AXI_STRB_WIDTH    = AXI_WIDTH/8,
        AXI_MAX_BURST_LEN = 32,
        AXI_ADDR_WIDTH    = 32,
        AXIL_WIDTH        = 32,
        AXIL_ADDR_WIDTH   = 40,
        AXIL_STRB_WIDTH   = 4,
        AXIL_BASE_ADDR    = 32'hA0000000,
        OPT_LOCK          = 1'b0,
        OPT_LOCKID        = 1'b1,
        OPT_LOWPOWER      = 1'b0,
        VALID_PROB        = 1000,
        READY_PROB        = 1000,

    localparam  LSB = $clog2(AXI_WIDTH)-3
)(
    input  wire                   clk,
    input  wire                   rstn,

    /* 
      AXI Slave
    */
    input  wire [AXI_ID_WIDTH-1:0]     s_axi_awid   ,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axi_awaddr ,
    input  wire [7:0]                  s_axi_awlen  ,
    input  wire [2:0]                  s_axi_awsize ,
    input  wire [1:0]                  s_axi_awburst,
    input  wire                        s_axi_awlock ,
    input  wire [3:0]                  s_axi_awcache,
    input  wire [2:0]                  s_axi_awprot ,
    input  wire                        s_axi_awvalid,
    output wire                        s_axi_awready,
    input  wire [AXIL_WIDTH-1:0]       s_axi_wdata  ,
    input  wire [AXIL_STRB_WIDTH-1:0]  s_axi_wstrb  ,
    input  wire                        s_axi_wlast  ,
    input  wire                        s_axi_wvalid ,
    output wire                        s_axi_wready ,
    output wire [AXI_ID_WIDTH-1:0]     s_axi_bid    ,
    output wire [1:0]                  s_axi_bresp  ,
    output wire                        s_axi_bvalid ,
    input  wire                        s_axi_bready ,
    input  wire [AXI_ID_WIDTH-1:0]     s_axi_arid   ,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axi_araddr ,
    input  wire [7:0]                  s_axi_arlen  ,
    input  wire [2:0]                  s_axi_arsize ,
    input  wire [1:0]                  s_axi_arburst,
    input  wire                        s_axi_arlock ,
    input  wire [3:0]                  s_axi_arcache,
    input  wire [2:0]                  s_axi_arprot ,
    input  wire                        s_axi_arvalid,
    output wire                        s_axi_arready,
    output wire [AXI_ID_WIDTH-1:0]     s_axi_rid    ,
    output wire [AXIL_WIDTH-1:0]       s_axi_rdata  ,
    output wire [1:0]                  s_axi_rresp  ,
    output wire                        s_axi_rlast  ,
    output wire                        s_axi_rvalid ,
    input  wire                        s_axi_rready ,

    
    output wire                            mm2s_0_ren,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_0_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_0_data,
    
    output wire                            mm2s_1_ren,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_1_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_1_data,
    
    output wire                            mm2s_2_ren,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_2_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_2_data,
    
    output wire                            s2mm_wen,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  s2mm_addr,
    output wire  [AXI_WIDTH-1:0]           s2mm_data,
    output wire  [AXI_WIDTH/8-1:0]         s2mm_strb
);

    logic [AXI_ID_WIDTH-1:0]     m_axi_awid   ;
    logic [AXIL_ADDR_WIDTH-1:0]  m_axi_awaddr ;
    logic [7:0]                  m_axi_awlen  ;
    logic [2:0]                  m_axi_awsize ;
    logic [1:0]                  m_axi_awburst;
    logic                        m_axi_awlock ;
    logic [3:0]                  m_axi_awcache;
    logic [2:0]                  m_axi_awprot ;
    logic                        m_axi_awvalid;
    logic                        m_axi_awready;
    logic [AXIL_WIDTH-1:0]       m_axi_wdata  ;
    logic [AXIL_STRB_WIDTH-1:0]  m_axi_wstrb  ;
    logic                        m_axi_wlast  ;
    logic                        m_axi_wvalid ;
    logic                        m_axi_wready ;
    logic [AXI_ID_WIDTH-1:0]     m_axi_bid    ;
    logic [1:0]                  m_axi_bresp  ;
    logic                        m_axi_bvalid ;
    logic                        m_axi_bready ;
    logic [AXI_ID_WIDTH-1:0]     m_axi_arid   ;
    logic [AXIL_ADDR_WIDTH-1:0]  m_axi_araddr ;
    logic [7:0]                  m_axi_arlen  ;
    logic [2:0]                  m_axi_arsize ;
    logic [1:0]                  m_axi_arburst;
    logic                        m_axi_arlock ;
    logic [3:0]                  m_axi_arcache;
    logic [2:0]                  m_axi_arprot ;
    logic                        m_axi_arvalid;
    logic                        m_axi_arready;
    logic [AXI_ID_WIDTH-1:0]     m_axi_rid    ;
    logic [AXIL_WIDTH-1:0]       m_axi_rdata  ;
    logic [1:0]                  m_axi_rresp  ;
    logic                        m_axi_rlast  ;
    logic                        m_axi_rvalid ;
    logic                        m_axi_rready ;

    axi_crossbar #(
        .S_COUNT         (1                             ),
        .M_COUNT         (1                             ),
        .DATA_WIDTH      (AXIL_WIDTH                    ),
        .ADDR_WIDTH      (AXIL_ADDR_WIDTH               ),
        .STRB_WIDTH      (AXIL_STRB_WIDTH               ),
        .S_ID_WIDTH      (AXI_ID_WIDTH                  ),
        .M_ID_WIDTH      (AXI_ID_WIDTH                  ),
        .AWUSER_ENABLE   (0                             ),
        .AWUSER_WIDTH    (1                             ),
        .WUSER_ENABLE    (0                             ),
        .WUSER_WIDTH     (1                             ),
        .BUSER_ENABLE    (0                             ),
        .BUSER_WIDTH     (1                             ),
        .ARUSER_ENABLE   (0                             ),
        .ARUSER_WIDTH    (1                             ),
        .RUSER_ENABLE    (0                             ),
        .RUSER_WIDTH     (1                             ),
        // .S_THREADS       ({S_COUNT{32'd2}}              ),
        // .S_ACCEPT        ({S_COUNT{32'd16}}             ),
        .M_REGIONS       (1                             ),
        .M_BASE_ADDR     (0                             ),
        .M_ADDR_WIDTH    (AXIL_ADDR_WIDTH               )
        // .M_CONNECT_READ  ({M_COUNT{{S_COUNT{1'b1}}}}    ),
        // .M_CONNECT_WRITE ({M_COUNT{{S_COUNT{1'b1}}}}    ),
        // .M_ISSUE         ({M_COUNT{32'd4}}              ),
        // .M_SECURE        ({M_COUNT{1'b0}}               ),
        // .S_AW_REG_TYPE   ({S_COUNT{2'd0}}               ),
        // .S_W_REG_TYPE    ({S_COUNT{2'd0}}               ),
        // .S_B_REG_TYPE    ({S_COUNT{2'd1}}               ),
        // .S_AR_REG_TYPE   ({S_COUNT{2'd0}}               ),
        // .S_R_REG_TYPE    ({S_COUNT{2'd2}}               ),
        // .M_AW_REG_TYPE   ({M_COUNT{2'd1}}               ),
        // .M_W_REG_TYPE    ({M_COUNT{2'd2}}               ),
        // .M_B_REG_TYPE    ({M_COUNT{2'd0}}               ),
        // .M_AR_REG_TYPE   ({M_COUNT{2'd1}}               ),
        // .M_R_REG_TYPE    ({M_COUNT{2'd0}}               )
    ) AXI_INTC (
        .clk           (clk),
        .rstn          (rstn),
        
        .s_axi_awqos   ('0),
        .s_axi_awuser  ('0),
        .s_axi_wuser   ('0),
        .s_axi_buser   (),
        .s_axi_arqos   ('0),
        .s_axi_aruser  ('0),
        .s_axi_ruser   (),

        .m_axi_awqos   (),
        .m_axi_awuser  (),
        .m_axi_wuser   (),
        .m_axi_buser   (),
        .m_axi_arqos   (),
        .m_axi_aruser  (),
        .m_axi_ruser   ('0),
        .m_axi_awregion(),
        .m_axi_arregion(),

        .s_axi_awid    ({s_axi_awid   }),
        .s_axi_awaddr  ({s_axi_awaddr }),
        .s_axi_awlen   ({s_axi_awlen  }),
        .s_axi_awsize  ({s_axi_awsize }),
        .s_axi_awburst ({s_axi_awburst}),
        .s_axi_awlock  ({s_axi_awlock }),
        .s_axi_awcache ({s_axi_awcache}),
        .s_axi_awprot  ({s_axi_awprot }),
        .s_axi_awvalid ({s_axi_awvalid}),
        .s_axi_awready ({s_axi_awready}),
        .s_axi_wdata   ({s_axi_wdata  }),
        .s_axi_wstrb   ({s_axi_wstrb  }),
        .s_axi_wlast   ({s_axi_wlast  }),
        .s_axi_wvalid  ({s_axi_wvalid }),
        .s_axi_wready  ({s_axi_wready }),
        .s_axi_bid     ({s_axi_bid    }),
        .s_axi_bresp   ({s_axi_bresp  }),
        .s_axi_bvalid  ({s_axi_bvalid }),
        .s_axi_bready  ({s_axi_bready }),
        .s_axi_arid    ({s_axi_arid   }),
        .s_axi_araddr  ({s_axi_araddr }),
        .s_axi_arlen   ({s_axi_arlen  }),
        .s_axi_arsize  ({s_axi_arsize }),
        .s_axi_arburst ({s_axi_arburst}),
        .s_axi_arlock  ({s_axi_arlock }),
        .s_axi_arcache ({s_axi_arcache}),
        .s_axi_arprot  ({s_axi_arprot }),
        .s_axi_arvalid ({s_axi_arvalid}),
        .s_axi_arready ({s_axi_arready}),
        .s_axi_rid     ({s_axi_rid    }),
        .s_axi_rdata   ({s_axi_rdata  }),
        .s_axi_rresp   ({s_axi_rresp  }),
        .s_axi_rlast   ({s_axi_rlast  }),
        .s_axi_rvalid  ({s_axi_rvalid }),
        .s_axi_rready  ({s_axi_rready }),


        .m_axi_awid    ({m_axi_awid   }),
        .m_axi_awaddr  ({m_axi_awaddr }),
        .m_axi_awlen   ({m_axi_awlen  }),
        .m_axi_awsize  ({m_axi_awsize }),
        .m_axi_awburst ({m_axi_awburst}),
        .m_axi_awlock  ({m_axi_awlock }),
        .m_axi_awcache ({m_axi_awcache}),
        .m_axi_awprot  ({m_axi_awprot }),
        .m_axi_awvalid ({m_axi_awvalid}),
        .m_axi_awready ({m_axi_awready}),
        .m_axi_wdata   ({m_axi_wdata  }),
        .m_axi_wstrb   ({m_axi_wstrb  }),
        .m_axi_wlast   ({m_axi_wlast  }),
        .m_axi_wvalid  ({m_axi_wvalid }),
        .m_axi_wready  ({m_axi_wready }),
        .m_axi_bid     ({m_axi_bid    }),
        .m_axi_bresp   ({m_axi_bresp  }),
        .m_axi_bvalid  ({m_axi_bvalid }),
        .m_axi_bready  ({m_axi_bready }),
        .m_axi_arid    ({m_axi_arid   }),
        .m_axi_araddr  ({m_axi_araddr }),
        .m_axi_arlen   ({m_axi_arlen  }),
        .m_axi_arsize  ({m_axi_arsize }),
        .m_axi_arburst ({m_axi_arburst}),
        .m_axi_arlock  ({m_axi_arlock }),
        .m_axi_arcache ({m_axi_arcache}),
        .m_axi_arprot  ({m_axi_arprot }),
        .m_axi_arvalid ({m_axi_arvalid}),
        .m_axi_arready ({m_axi_arready}),
        .m_axi_rid     ({m_axi_rid    }),
        .m_axi_rdata   ({m_axi_rdata  }),
        .m_axi_rresp   ({m_axi_rresp  }),
        .m_axi_rlast   ({m_axi_rlast  }),
        .m_axi_rvalid  ({m_axi_rvalid }),
        .m_axi_rready  ({m_axi_rready })
    );

// AXI ports from top on-chip module

    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_arid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_0_araddr;
    wire [7:0]                 m_axi_mm2s_0_arlen;
    wire [2:0]                 m_axi_mm2s_0_arsize;
    wire [1:0]                 m_axi_mm2s_0_arburst;
    wire                       m_axi_mm2s_0_arlock;
    wire [3:0]                 m_axi_mm2s_0_arcache;
    wire [2:0]                 m_axi_mm2s_0_arprot;
    wire                       m_axi_mm2s_0_arvalid;
    wire                       m_axi_mm2s_0_arvalid_zipcpu;
    wire                       m_axi_mm2s_0_arready;
    wire                       m_axi_mm2s_0_arready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_rid;
    wire [AXI_WIDTH-1:0]       m_axi_mm2s_0_rdata;
    wire [1:0]                 m_axi_mm2s_0_rresp;
    wire                       m_axi_mm2s_0_rlast;
    wire                       m_axi_mm2s_0_rvalid;
    wire                       m_axi_mm2s_0_rvalid_zipcpu;
    wire                       m_axi_mm2s_0_rready;
    wire                       m_axi_mm2s_0_rready_zipcpu;
    
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_arid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_1_araddr;
    wire [7:0]                 m_axi_mm2s_1_arlen;
    wire [2:0]                 m_axi_mm2s_1_arsize;
    wire [1:0]                 m_axi_mm2s_1_arburst;
    wire                       m_axi_mm2s_1_arlock;
    wire [3:0]                 m_axi_mm2s_1_arcache;
    wire [2:0]                 m_axi_mm2s_1_arprot;
    wire                       m_axi_mm2s_1_arvalid;
    wire                       m_axi_mm2s_1_arvalid_zipcpu;
    wire                       m_axi_mm2s_1_arready;
    wire                       m_axi_mm2s_1_arready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_rid;
    wire [AXI_WIDTH-1:0]       m_axi_mm2s_1_rdata;
    wire [1:0]                 m_axi_mm2s_1_rresp;
    wire                       m_axi_mm2s_1_rlast;
    wire                       m_axi_mm2s_1_rvalid;
    wire                       m_axi_mm2s_1_rvalid_zipcpu;
    wire                       m_axi_mm2s_1_rready;
    wire                       m_axi_mm2s_1_rready_zipcpu;
    
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_arid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_2_araddr;
    wire [7:0]                 m_axi_mm2s_2_arlen;
    wire [2:0]                 m_axi_mm2s_2_arsize;
    wire [1:0]                 m_axi_mm2s_2_arburst;
    wire                       m_axi_mm2s_2_arlock;
    wire [3:0]                 m_axi_mm2s_2_arcache;
    wire [2:0]                 m_axi_mm2s_2_arprot;
    wire                       m_axi_mm2s_2_arvalid;
    wire                       m_axi_mm2s_2_arvalid_zipcpu;
    wire                       m_axi_mm2s_2_arready;
    wire                       m_axi_mm2s_2_arready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_rid;
    wire [AXI_WIDTH-1:0]       m_axi_mm2s_2_rdata;
    wire [1:0]                 m_axi_mm2s_2_rresp;
    wire                       m_axi_mm2s_2_rlast;
    wire                       m_axi_mm2s_2_rvalid;
    wire                       m_axi_mm2s_2_rvalid_zipcpu;
    wire                       m_axi_mm2s_2_rready;
    wire                       m_axi_mm2s_2_rready_zipcpu;
    
    wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr;
    wire [7:0]                 m_axi_s2mm_awlen;
    wire [2:0]                 m_axi_s2mm_awsize;
    wire [1:0]                 m_axi_s2mm_awburst;
    wire                       m_axi_s2mm_awlock;
    wire [3:0]                 m_axi_s2mm_awcache;
    wire [2:0]                 m_axi_s2mm_awprot;
    wire                       m_axi_s2mm_awvalid;
    wire                       m_axi_s2mm_awvalid_zipcpu;
    wire                       m_axi_s2mm_awready;
    wire                       m_axi_s2mm_awready_zipcpu;
    wire [AXI_WIDTH-1:0]       m_axi_s2mm_wdata;
    wire [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb;
    wire                       m_axi_s2mm_wlast;
    wire                       m_axi_s2mm_wvalid;
    wire                       m_axi_s2mm_wvalid_zipcpu;
    wire                       m_axi_s2mm_wready;
    wire                       m_axi_s2mm_wready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_bid;
    wire [1:0]                 m_axi_s2mm_bresp;
    wire                       m_axi_s2mm_bvalid;
    wire                       m_axi_s2mm_bvalid_zipcpu;
    wire                       m_axi_s2mm_bready;
    wire                       m_axi_s2mm_bready_zipcpu;

    logic rand_mm2s_0_ar;
    logic rand_mm2s_0_r;
    logic rand_mm2s_1_ar;
    logic rand_mm2s_1_r;
    logic rand_mm2s_2_ar;
    logic rand_mm2s_2_r;
    logic rand_s2mm_aw;
    logic rand_s2mm_w;
    logic rand_s2mm_b;

    always_ff @( posedge clk ) begin
        rand_mm2s_0_r   <= $urandom_range(0, 1000) < VALID_PROB;
        rand_mm2s_0_ar  <= $urandom_range(0, 1000) < VALID_PROB;

        rand_mm2s_1_r   <= $urandom_range(0, 1000) < VALID_PROB;
        rand_mm2s_1_ar  <= $urandom_range(0, 1000) < VALID_PROB;

        rand_mm2s_2_r   <= $urandom_range(0, 1000) < VALID_PROB;
        rand_mm2s_2_ar  <= $urandom_range(0, 1000) < VALID_PROB;

        rand_s2mm_aw    <= $urandom_range(0, 1000) < READY_PROB;
        rand_s2mm_w     <= $urandom_range(0, 1000) < READY_PROB;
        rand_s2mm_b     <= $urandom_range(0, 1000) < READY_PROB;
    end
    
    assign m_axi_mm2s_0_arvalid_zipcpu = rand_mm2s_0_ar & m_axi_mm2s_0_arvalid;
    assign m_axi_mm2s_0_arready        = rand_mm2s_0_ar & m_axi_mm2s_0_arready_zipcpu;
    assign m_axi_mm2s_0_rvalid         = rand_mm2s_0_r  & m_axi_mm2s_0_rvalid_zipcpu;
    assign m_axi_mm2s_0_rready_zipcpu  = rand_mm2s_0_r  & m_axi_mm2s_0_rready;
    
    assign m_axi_mm2s_1_arvalid_zipcpu = rand_mm2s_1_ar & m_axi_mm2s_1_arvalid;
    assign m_axi_mm2s_1_arready        = rand_mm2s_1_ar & m_axi_mm2s_1_arready_zipcpu;
    assign m_axi_mm2s_1_rvalid         = rand_mm2s_1_r  & m_axi_mm2s_1_rvalid_zipcpu;
    assign m_axi_mm2s_1_rready_zipcpu  = rand_mm2s_1_r  & m_axi_mm2s_1_rready;
    
    assign m_axi_mm2s_2_arvalid_zipcpu = rand_mm2s_2_ar & m_axi_mm2s_2_arvalid;
    assign m_axi_mm2s_2_arready        = rand_mm2s_2_ar & m_axi_mm2s_2_arready_zipcpu;
    assign m_axi_mm2s_2_rvalid         = rand_mm2s_2_r  & m_axi_mm2s_2_rvalid_zipcpu;
    assign m_axi_mm2s_2_rready_zipcpu  = rand_mm2s_2_r  & m_axi_mm2s_2_rready;

    assign m_axi_s2mm_awvalid_zipcpu = rand_s2mm_aw & m_axi_s2mm_awvalid;
    assign m_axi_s2mm_awready        = rand_s2mm_aw & m_axi_s2mm_awready_zipcpu;
    assign m_axi_s2mm_wvalid_zipcpu  = rand_s2mm_w  & m_axi_s2mm_wvalid;
    assign m_axi_s2mm_wready         = rand_s2mm_w  & m_axi_s2mm_wready_zipcpu;
    assign m_axi_s2mm_bvalid         = rand_s2mm_b  & m_axi_s2mm_bvalid_zipcpu;
    assign m_axi_s2mm_bready_zipcpu  = rand_s2mm_b  & m_axi_s2mm_bready;


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
    .S_AXI_ARVALID(m_axi_mm2s_0_arvalid_zipcpu),
    .S_AXI_ARREADY(m_axi_mm2s_0_arready_zipcpu),
    .S_AXI_RID    (m_axi_mm2s_0_rid),
    .S_AXI_RDATA  (m_axi_mm2s_0_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_0_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_0_rlast),
    .S_AXI_RVALID (m_axi_mm2s_0_rvalid_zipcpu),
    .S_AXI_RREADY (m_axi_mm2s_0_rready_zipcpu)
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
    .S_AXI_ARVALID(m_axi_mm2s_1_arvalid_zipcpu),
    .S_AXI_ARREADY(m_axi_mm2s_1_arready_zipcpu),
    .S_AXI_RID    (m_axi_mm2s_1_rid),
    .S_AXI_RDATA  (m_axi_mm2s_1_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_1_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_1_rlast),
    .S_AXI_RVALID (m_axi_mm2s_1_rvalid_zipcpu),
    .S_AXI_RREADY (m_axi_mm2s_1_rready_zipcpu)
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
    .S_AXI_ARVALID(m_axi_mm2s_2_arvalid_zipcpu),
    .S_AXI_ARREADY(m_axi_mm2s_2_arready_zipcpu),
    .S_AXI_RID    (m_axi_mm2s_2_rid),
    .S_AXI_RDATA  (m_axi_mm2s_2_rdata),
    .S_AXI_RRESP  (m_axi_mm2s_2_rresp),
    .S_AXI_RLAST  (m_axi_mm2s_2_rlast),
    .S_AXI_RVALID (m_axi_mm2s_2_rvalid_zipcpu),
    .S_AXI_RREADY (m_axi_mm2s_2_rready_zipcpu)
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
    .S_AXI_AWVALID(m_axi_s2mm_awvalid_zipcpu),
    .S_AXI_AWREADY(m_axi_s2mm_awready_zipcpu),
    .S_AXI_WDATA(m_axi_s2mm_wdata),
    .S_AXI_WSTRB(m_axi_s2mm_wstrb),
    .S_AXI_WLAST(m_axi_s2mm_wlast),
    .S_AXI_WVALID(m_axi_s2mm_wvalid_zipcpu),
    .S_AXI_WREADY(m_axi_s2mm_wready_zipcpu),
    .S_AXI_BID(m_axi_s2mm_bid),
    .S_AXI_BRESP(m_axi_s2mm_bresp),
    .S_AXI_BVALID(m_axi_s2mm_bvalid_zipcpu),
    .S_AXI_BREADY(m_axi_s2mm_bready_zipcpu),
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
    .s_axi_awid   (m_axi_awid   ),
    .s_axi_awaddr (m_axi_awaddr ),
    .s_axi_awlen  (m_axi_awlen  ),
    .s_axi_awsize (m_axi_awsize ),
    .s_axi_awburst(m_axi_awburst),
    .s_axi_awlock (m_axi_awlock ),
    .s_axi_awcache(m_axi_awcache),
    .s_axi_awprot (m_axi_awprot ),
    .s_axi_awvalid(m_axi_awvalid),
    .s_axi_awready(m_axi_awready),
    .s_axi_wdata  (m_axi_wdata  ),
    .s_axi_wstrb  (m_axi_wstrb  ),
    .s_axi_wlast  (m_axi_wlast  ),
    .s_axi_wvalid (m_axi_wvalid ),
    .s_axi_wready (m_axi_wready ),
    .s_axi_bid    (m_axi_bid    ),
    .s_axi_bresp  (m_axi_bresp  ),
    .s_axi_bvalid (m_axi_bvalid ),
    .s_axi_bready (m_axi_bready ),
    .s_axi_arid   (m_axi_arid   ),
    .s_axi_araddr (m_axi_araddr ),
    .s_axi_arlen  (m_axi_arlen  ),
    .s_axi_arsize (m_axi_arsize ),
    .s_axi_arburst(m_axi_arburst),
    .s_axi_arlock (m_axi_arlock ),
    .s_axi_arcache(m_axi_arcache),
    .s_axi_arprot (m_axi_arprot ),
    .s_axi_arvalid(m_axi_arvalid),
    .s_axi_arready(m_axi_arready),
    .s_axi_rid    (m_axi_rid    ),
    .s_axi_rdata  (m_axi_rdata  ),
    .s_axi_rresp  (m_axi_rresp  ),
    .s_axi_rlast  (m_axi_rlast  ),
    .s_axi_rvalid (m_axi_rvalid ),
    .s_axi_rready (m_axi_rready ),
    .*
);

endmodule