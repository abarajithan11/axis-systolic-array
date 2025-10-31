
`timescale 1ns/1ps

module top_ram #(
    // Parameters for DNN engine
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
        AXIL_ADDR_WIDTH   = 32,
        STRB_WIDTH        = 4,
        AXIL_BASE_ADDR    = 32'hA0000000,
        TIMEOUT           = 2, // since 0 gives error
    // Randomizer for AXI4 requests
        VALID_PROB        = 1000,
        READY_PROB        = 1000,

    localparam  LSB = $clog2(AXI_WIDTH)-3
)(
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    //AXI-Lite slave interface
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]                  s_axil_awprot,
    input  wire                        s_axil_awvalid,
    output wire                        s_axil_awready,
    input  wire [AXIL_WIDTH-1:0]       s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]       s_axil_wstrb,
    input  wire                        s_axil_wvalid,
    output wire                        s_axil_wready,
    output wire [1:0]                  s_axil_bresp,
    output wire                        s_axil_bvalid,
    input  wire                        s_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]                  s_axil_arprot,
    input  wire                        s_axil_arvalid,
    output wire                        s_axil_arready,
    output wire [AXIL_WIDTH-1:0]       s_axil_rdata,
    output wire [1:0]                  s_axil_rresp,
    output wire                        s_axil_rvalid,
    input  wire                        s_axil_rready,
    
    // ram rw interface for interacting with DDR in sim
    output wire                            mm2s_0_rd_en,
    output wire  [AXI_ADDR_WIDTH-1:0]      mm2s_0_rd_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_0_rd_data,
    
    output wire                            mm2s_1_rd_en,
    output wire  [AXI_ADDR_WIDTH-1:0]      mm2s_1_rd_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_1_rd_data,
    
    output wire                            mm2s_2_rd_en,
    output wire  [AXI_ADDR_WIDTH-1:0]      mm2s_2_rd_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_2_rd_data,

    output wire                            s2mm_wr_en,
    output wire  [AXI_ADDR_WIDTH-1:0]      s2mm_wr_addr,
    output wire  [AXI_WIDTH-1:0]           s2mm_wr_data,
    output wire  [AXI_WIDTH/8-1:0]         s2mm_wr_strb
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

    // Randomizer for AXI4 requests
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

    wire [AXI_ADDR_WIDTH-1:0]  m_axil_mm2s_2_araddr , m_axil_mm2s_1_araddr , m_axil_mm2s_0_araddr ;
    wire [2:0]                 m_axil_mm2s_2_arprot , m_axil_mm2s_1_arprot , m_axil_mm2s_0_arprot ;
    wire                       m_axil_mm2s_2_arvalid, m_axil_mm2s_1_arvalid, m_axil_mm2s_0_arvalid;
    wire                       m_axil_mm2s_2_arready, m_axil_mm2s_1_arready, m_axil_mm2s_0_arready;
    wire [AXI_WIDTH   -1:0]    m_axil_mm2s_2_rdata  , m_axil_mm2s_1_rdata  , m_axil_mm2s_0_rdata  ;
    wire [1:0]                 m_axil_mm2s_2_rresp  , m_axil_mm2s_1_rresp  , m_axil_mm2s_0_rresp  ;
    wire                       m_axil_mm2s_2_rvalid , m_axil_mm2s_1_rvalid , m_axil_mm2s_0_rvalid ;
    wire                       m_axil_mm2s_2_rready , m_axil_mm2s_1_rready , m_axil_mm2s_0_rready ;

    wire [AXI_ADDR_WIDTH-1:0]  m_axil_s2mm_awaddr ;
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
    .ADDR_WIDTH           (AXI_ADDR_WIDTH),
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
    .s_axi_arid   (m_axi_mm2s_0_arid           ),
    .s_axi_araddr (m_axi_mm2s_0_araddr         ),
    .s_axi_arlen  (m_axi_mm2s_0_arlen          ),
    .s_axi_arsize (m_axi_mm2s_0_arsize         ),
    .s_axi_arburst(m_axi_mm2s_0_arburst        ),
    .s_axi_arlock (m_axi_mm2s_0_arlock         ),
    .s_axi_arcache(m_axi_mm2s_0_arcache        ),
    .s_axi_arprot (m_axi_mm2s_0_arprot         ),
    .s_axi_arvalid(m_axi_mm2s_0_arvalid_zipcpu ),
    .s_axi_arready(m_axi_mm2s_0_arready_zipcpu ),
    .s_axi_rid    (m_axi_mm2s_0_rid            ),
    .s_axi_rdata  (m_axi_mm2s_0_rdata          ),
    .s_axi_rresp  (m_axi_mm2s_0_rresp          ),
    .s_axi_rlast  (m_axi_mm2s_0_rlast          ),
    .s_axi_rvalid (m_axi_mm2s_0_rvalid_zipcpu  ),
    .s_axi_rready (m_axi_mm2s_0_rready_zipcpu  ),

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
    .ADDR_WIDTH    (AXI_ADDR_WIDTH),
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
    .reg_rd_wait    (1'b0),
    .reg_rd_ack     (1'b1)
    );

    axi_axil_adapter #(
    .ADDR_WIDTH           (AXI_ADDR_WIDTH),
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
    .s_axi_arid   (m_axi_mm2s_1_arid          ),
    .s_axi_araddr (m_axi_mm2s_1_araddr        ),
    .s_axi_arlen  (m_axi_mm2s_1_arlen         ),
    .s_axi_arsize (m_axi_mm2s_1_arsize        ),
    .s_axi_arburst(m_axi_mm2s_1_arburst       ),
    .s_axi_arlock (m_axi_mm2s_1_arlock        ),
    .s_axi_arcache(m_axi_mm2s_1_arcache       ),
    .s_axi_arprot (m_axi_mm2s_1_arprot        ),
    .s_axi_arvalid(m_axi_mm2s_1_arvalid_zipcpu),
    .s_axi_arready(m_axi_mm2s_1_arready_zipcpu),
    .s_axi_rid    (m_axi_mm2s_1_rid           ),
    .s_axi_rdata  (m_axi_mm2s_1_rdata         ),
    .s_axi_rresp  (m_axi_mm2s_1_rresp         ),
    .s_axi_rlast  (m_axi_mm2s_1_rlast         ),
    .s_axi_rvalid (m_axi_mm2s_1_rvalid_zipcpu ),
    .s_axi_rready (m_axi_mm2s_1_rready_zipcpu ),

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
    .ADDR_WIDTH    (AXI_ADDR_WIDTH),
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
    .reg_rd_wait    (1'b0),
    .reg_rd_ack     (1'b1)
    );

    axi_axil_adapter #(
    .ADDR_WIDTH           (AXI_ADDR_WIDTH),
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
    .s_axi_arid   (m_axi_mm2s_2_arid           ),
    .s_axi_araddr (m_axi_mm2s_2_araddr         ),
    .s_axi_arlen  (m_axi_mm2s_2_arlen          ),
    .s_axi_arsize (m_axi_mm2s_2_arsize         ),
    .s_axi_arburst(m_axi_mm2s_2_arburst        ),
    .s_axi_arlock (m_axi_mm2s_2_arlock         ),
    .s_axi_arcache(m_axi_mm2s_2_arcache        ),
    .s_axi_arprot (m_axi_mm2s_2_arprot         ),
    .s_axi_arvalid(m_axi_mm2s_2_arvalid_zipcpu ),
    .s_axi_arready(m_axi_mm2s_2_arready_zipcpu ),
    .s_axi_rid    (m_axi_mm2s_2_rid            ),
    .s_axi_rdata  (m_axi_mm2s_2_rdata          ),
    .s_axi_rresp  (m_axi_mm2s_2_rresp          ),
    .s_axi_rlast  (m_axi_mm2s_2_rlast          ),
    .s_axi_rvalid (m_axi_mm2s_2_rvalid_zipcpu  ),
    .s_axi_rready (m_axi_mm2s_2_rready_zipcpu  ),

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
    .ADDR_WIDTH    (AXI_ADDR_WIDTH),
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
    .reg_rd_wait    (1'b0),
    .reg_rd_ack     (1'b1)
    );


    axi_axil_adapter #(
    .ADDR_WIDTH           (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH       (AXI_WIDTH),
    .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
    .AXI_ID_WIDTH         (AXI_ID_WIDTH),
    .AXIL_DATA_WIDTH      (AXI_WIDTH),
    .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
    ) AXI_TO_AXIL_3 (
    .clk          (clk ),
    .rst          (!rstn),
    .s_axi_awid   (m_axi_s2mm_awid          ),
    .s_axi_awaddr (m_axi_s2mm_awaddr        ),
    .s_axi_awlen  (m_axi_s2mm_awlen         ),
    .s_axi_awsize (m_axi_s2mm_awsize        ),
    .s_axi_awburst(m_axi_s2mm_awburst       ),
    .s_axi_awlock (m_axi_s2mm_awlock        ),
    .s_axi_awcache(m_axi_s2mm_awcache       ),
    .s_axi_awprot (m_axi_s2mm_awprot        ),
    .s_axi_awvalid(m_axi_s2mm_awvalid_zipcpu),
    .s_axi_awready(m_axi_s2mm_awready_zipcpu),
    .s_axi_wdata  (m_axi_s2mm_wdata         ),
    .s_axi_wstrb  (m_axi_s2mm_wstrb         ),
    .s_axi_wlast  (m_axi_s2mm_wlast         ),
    .s_axi_wvalid (m_axi_s2mm_wvalid_zipcpu ),
    .s_axi_wready (m_axi_s2mm_wready_zipcpu ),
    .s_axi_bid    (m_axi_s2mm_bid           ),
    .s_axi_bresp  (m_axi_s2mm_bresp         ),
    .s_axi_bvalid (m_axi_s2mm_bvalid_zipcpu ),
    .s_axi_bready (m_axi_s2mm_bready_zipcpu ),

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
    .ADDR_WIDTH    (AXI_ADDR_WIDTH),
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
    .reg_wr_wait    (1'b0),
    .reg_wr_ack     (1'b1),
    .reg_rd_en      (),
    .reg_rd_addr    (),
    .reg_rd_data    (),
    .reg_rd_wait    (1'b0),
    .reg_rd_ack     (1'b0)
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
    .STRB_WIDTH       (STRB_WIDTH       ),
    .AXIL_BASE_ADDR   (AXIL_BASE_ADDR   )
) TOP (
    .*
);

endmodule