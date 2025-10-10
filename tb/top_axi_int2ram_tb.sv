
`timescale 1ns/1ps

module top_axi_int2ram_tb #(
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
        AXI_MAX_BURST_LEN = 4,
        AXI_ADDR_WIDTH    = 32,
        AXIL_WIDTH        = 32,
        AXIL_ADDR_WIDTH   = 32,
        STRB_WIDTH        = 4,
        AXIL_BASE_ADDR    = 32'hA0000000,
        OPT_LOCK          = 1'b0,
        OPT_LOCKID        = 1'b1,
        OPT_LOWPOWER      = 1'b0,
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
    output wire                            ren,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  raddr,
    input  wire  [AXI_WIDTH-1:0]           rdata,
    output wire                            wen,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  waddr,
    output wire  [AXI_WIDTH-1:0]           wdata,
    output wire  [AXI_WIDTH/8-1:0]         wstrb
);

// AXI ports from top on-chip module

    wire [AXI_ID_WIDTH-1:0]    m_axi_arid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr;
    wire [7:0]                 m_axi_arlen;
    wire [2:0]                 m_axi_arsize;
    wire [1:0]                 m_axi_arburst;
    wire                       m_axi_arlock;
    wire [3:0]                 m_axi_arcache;
    wire [2:0]                 m_axi_arprot;
    wire                       m_axi_arvalid;
    wire                       m_axi_arvalid_zipcpu;
    wire                       m_axi_arready;
    wire                       m_axi_arready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_rid;
    wire [AXI_WIDTH-1:0]       m_axi_rdata;
    wire [1:0]                 m_axi_rresp;
    wire                       m_axi_rlast;
    wire                       m_axi_rvalid;
    wire                       m_axi_rvalid_zipcpu;
    wire                       m_axi_rready;
    wire                       m_axi_rready_zipcpu;
    
    wire [AXI_ID_WIDTH-1:0]    m_axi_awid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr;
    wire [7:0]                 m_axi_awlen;
    wire [2:0]                 m_axi_awsize;
    wire [1:0]                 m_axi_awburst;
    wire                       m_axi_awlock;
    wire [3:0]                 m_axi_awcache;
    wire [2:0]                 m_axi_awprot;
    wire                       m_axi_awvalid;
    wire                       m_axi_awvalid_zipcpu;
    wire                       m_axi_awready;
    wire                       m_axi_awready_zipcpu;
    wire [AXI_WIDTH-1:0]       m_axi_wdata;
    wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb;
    wire                       m_axi_wlast;
    wire                       m_axi_wvalid;
    wire                       m_axi_wvalid_zipcpu;
    wire                       m_axi_wready;
    wire                       m_axi_wready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_bid;
    wire [1:0]                 m_axi_bresp;
    wire                       m_axi_bvalid;
    wire                       m_axi_bvalid_zipcpu;
    wire                       m_axi_bready;
    wire                       m_axi_bready_zipcpu;

    logic rand_ar;
    logic rand_r;
    logic rand_aw;
    logic rand_w;
    logic rand_b;

    // Randomizer for AXI4 requests
    always_ff @( posedge clk ) begin
        rand_r   <= $urandom_range(0, 1000) < VALID_PROB;
        rand_ar  <= $urandom_range(0, 1000) < VALID_PROB;
        rand_aw  <= $urandom_range(0, 1000) < READY_PROB;
        rand_w   <= $urandom_range(0, 1000) < READY_PROB;
        rand_b   <= $urandom_range(0, 1000) < READY_PROB;
    end


    assign m_axi_arvalid_zipcpu   = rand_ar & m_axi_arvalid;
    assign m_axi_arready          = rand_ar & m_axi_arready_zipcpu;
    assign m_axi_rvalid           = rand_r  & m_axi_rvalid_zipcpu;
    assign m_axi_rready_zipcpu    = rand_r  & m_axi_rready;

    assign m_axi_awvalid_zipcpu   = rand_aw & m_axi_awvalid;
    assign m_axi_awready          = rand_aw & m_axi_awready_zipcpu;
    assign m_axi_wvalid_zipcpu    = rand_w  & m_axi_wvalid;
    assign m_axi_wready           = rand_w  & m_axi_wready_zipcpu;
    assign m_axi_bvalid           = rand_b  & m_axi_bvalid_zipcpu;
    assign m_axi_bready_zipcpu    = rand_b  & m_axi_bready;


zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP (
    .o_we   (wen  ),
    .o_waddr(waddr),
    .o_wdata(wdata),
    .o_wstrb(wstrb),
    .o_rd   (ren  ),
    .o_raddr(raddr),
    .i_rdata(rdata),

    .S_AXI_ACLK    (clk),
    .S_AXI_ARESETN (rstn),
    .S_AXI_AWID    (m_axi_awid),
    .S_AXI_AWADDR  (m_axi_awaddr),
    .S_AXI_AWLEN   (m_axi_awlen),
    .S_AXI_AWSIZE  (m_axi_awsize),
    .S_AXI_AWBURST (m_axi_awburst),
    .S_AXI_AWLOCK  (m_axi_awlock),
    .S_AXI_AWCACHE (m_axi_awcache),
    .S_AXI_AWPROT  (m_axi_awprot),
    .S_AXI_AWQOS   (),
    .S_AXI_AWVALID (m_axi_awvalid_zipcpu),
    .S_AXI_AWREADY (m_axi_awready_zipcpu),
    .S_AXI_WDATA   (m_axi_wdata),
    .S_AXI_WSTRB   (m_axi_wstrb),
    .S_AXI_WLAST   (m_axi_wlast),
    .S_AXI_WVALID  (m_axi_wvalid_zipcpu),
    .S_AXI_WREADY  (m_axi_wready_zipcpu),
    .S_AXI_BID     (m_axi_bid),
    .S_AXI_BRESP   (m_axi_bresp),
    .S_AXI_BVALID  (m_axi_bvalid_zipcpu),
    .S_AXI_BREADY  (m_axi_bready_zipcpu),
    .S_AXI_ARID    (m_axi_arid),
    .S_AXI_ARADDR  (m_axi_araddr),
    .S_AXI_ARLEN   (m_axi_arlen),
    .S_AXI_ARSIZE  (m_axi_arsize),
    .S_AXI_ARBURST (m_axi_arburst),
    .S_AXI_ARLOCK  (m_axi_arlock),
    .S_AXI_ARCACHE (m_axi_arcache),
    .S_AXI_ARPROT  (m_axi_arprot),
    .S_AXI_ARQOS   (),
    .S_AXI_ARVALID (m_axi_arvalid_zipcpu),
    .S_AXI_ARREADY (m_axi_arready_zipcpu),
    .S_AXI_RID     (m_axi_rid),
    .S_AXI_RDATA   (m_axi_rdata),
    .S_AXI_RRESP   (m_axi_rresp),
    .S_AXI_RLAST   (m_axi_rlast),
    .S_AXI_RVALID  (m_axi_rvalid_zipcpu),
    .S_AXI_RREADY  (m_axi_rready_zipcpu)
);

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