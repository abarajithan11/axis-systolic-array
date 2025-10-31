
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
    // Randomizer for AXI4 requests
        VALID_PROB        = 1000,
        READY_PROB        = 1000
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
    output wire  [AXI_ADDR_WIDTH-1:0]      raddr,
    input  wire  [AXI_WIDTH-1:0]           rdata,
    output wire                            wen,
    output wire  [AXI_ADDR_WIDTH-1:0]      waddr,
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

    wire [AXI_ADDR_WIDTH-1:0]  axil_araddr ;
    wire [2:0]                 axil_arprot ;
    wire                       axil_arvalid;
    wire                       axil_arready;
    wire [AXI_WIDTH   -1:0]    axil_rdata  ;
    wire [1:0]                 axil_rresp  ;
    wire                       axil_rvalid ;
    wire                       axil_rready ;
    wire [AXI_ADDR_WIDTH-1:0]  axil_awaddr ;
    wire [2:0]                 axil_awprot ;
    wire                       axil_awvalid;
    wire                       axil_awready;
    wire [AXI_WIDTH   -1:0]    axil_wdata  ;
    wire [AXI_STRB_WIDTH-1:0]  axil_wstrb  ;
    wire                       axil_wvalid ;
    wire                       axil_wready ;
    wire [1:0]                 axil_bresp  ;
    wire                       axil_bvalid ;
    wire                       axil_bready ;


    axi_axil_adapter #(
    .ADDR_WIDTH           (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH       (AXI_WIDTH),
    .AXI_STRB_WIDTH       (AXI_STRB_WIDTH),
    .AXI_ID_WIDTH         (AXI_ID_WIDTH),
    .AXIL_DATA_WIDTH      (AXI_WIDTH),
    .AXIL_STRB_WIDTH      (AXI_STRB_WIDTH)
    ) AXI2AXIL (
    .clk          (clk                 ),
    .rst          (!rstn               ),
    .s_axi_awid   (m_axi_awid          ),
    .s_axi_awaddr (m_axi_awaddr        ),
    .s_axi_awlen  (m_axi_awlen         ),
    .s_axi_awsize (m_axi_awsize        ),
    .s_axi_awburst(m_axi_awburst       ),
    .s_axi_awlock (m_axi_awlock        ),
    .s_axi_awcache(m_axi_awcache       ),
    .s_axi_awprot (m_axi_awprot        ),
    .s_axi_awvalid(m_axi_awvalid_zipcpu),
    .s_axi_awready(m_axi_awready_zipcpu),
    .s_axi_wdata  (m_axi_wdata         ),
    .s_axi_wstrb  (m_axi_wstrb         ),
    .s_axi_wlast  (m_axi_wlast         ),
    .s_axi_wvalid (m_axi_wvalid_zipcpu ),
    .s_axi_wready (m_axi_wready_zipcpu ),
    .s_axi_bid    (m_axi_bid           ),
    .s_axi_bresp  (m_axi_bresp         ),
    .s_axi_bvalid (m_axi_bvalid_zipcpu ),
    .s_axi_bready (m_axi_bready_zipcpu ),
    .s_axi_arid   (m_axi_arid          ),
    .s_axi_araddr (m_axi_araddr        ),
    .s_axi_arlen  (m_axi_arlen         ),
    .s_axi_arsize (m_axi_arsize        ),
    .s_axi_arburst(m_axi_arburst       ),
    .s_axi_arlock (m_axi_arlock        ),
    .s_axi_arcache(m_axi_arcache       ),
    .s_axi_arprot (m_axi_arprot        ),
    .s_axi_arvalid(m_axi_arvalid_zipcpu),
    .s_axi_arready(m_axi_arready_zipcpu),
    .s_axi_rid    (m_axi_rid           ),
    .s_axi_rdata  (m_axi_rdata         ),
    .s_axi_rresp  (m_axi_rresp         ),
    .s_axi_rlast  (m_axi_rlast         ),
    .s_axi_rvalid (m_axi_rvalid_zipcpu ),
    .s_axi_rready (m_axi_rready_zipcpu ),

    .m_axil_awaddr (axil_awaddr ),
    .m_axil_awprot (axil_awprot ),
    .m_axil_awvalid(axil_awvalid),
    .m_axil_awready(axil_awready),
    .m_axil_wdata  (axil_wdata  ),
    .m_axil_wstrb  (axil_wstrb  ),
    .m_axil_wvalid (axil_wvalid ),
    .m_axil_wready (axil_wready ),
    .m_axil_bresp  (axil_bresp  ),
    .m_axil_bvalid (axil_bvalid ),
    .m_axil_bready (axil_bready ),
    .m_axil_araddr (axil_araddr ),
    .m_axil_arprot (axil_arprot ),
    .m_axil_arvalid(axil_arvalid),
    .m_axil_arready(axil_arready),
    .m_axil_rdata  (axil_rdata  ),
    .m_axil_rresp  (axil_rresp  ),
    .m_axil_rvalid (axil_rvalid ),
    .m_axil_rready (axil_rready )
    );

    alex_axilite_ram #(
    .DATA_WR_WIDTH (AXI_WIDTH),
    .DATA_RD_WIDTH (AXI_WIDTH),
    .ADDR_WIDTH    (AXI_ADDR_WIDTH),
    .STRB_WIDTH    (AXI_STRB_WIDTH),
    .TIMEOUT       (2)
    ) AXIL2RAM (
    .clk            (clk),
    .rstn           (rstn),
    .s_axil_awaddr  (axil_awaddr ),
    .s_axil_awprot  (axil_awprot ),
    .s_axil_awvalid (axil_awvalid),
    .s_axil_awready (axil_awready),
    .s_axil_wdata   (axil_wdata  ),
    .s_axil_wstrb   (axil_wstrb  ),
    .s_axil_wvalid  (axil_wvalid ),
    .s_axil_wready  (axil_wready ),
    .s_axil_bresp   (axil_bresp  ),
    .s_axil_bvalid  (axil_bvalid ),
    .s_axil_bready  (axil_bready ),
    .s_axil_araddr  (axil_araddr ),
    .s_axil_arprot  (axil_arprot ),
    .s_axil_arvalid (axil_arvalid),
    .s_axil_arready (axil_arready),
    .s_axil_rdata   (axil_rdata  ),
    .s_axil_rresp   (axil_rresp  ),
    .s_axil_rvalid  (axil_rvalid ),
    .s_axil_rready  (axil_rready ),

    .reg_wr_en      (wen    ),
    .reg_wr_addr    (waddr  ),
    .reg_wr_data    (wdata  ),
    .reg_wr_strb    (wstrb  ),
    .reg_rd_en      (ren    ),
    .reg_rd_addr    (raddr  ),
    .reg_rd_data    (rdata  ),
    .reg_rd_wait    (1'b0   ),
    .reg_rd_ack     (1'b1   ),
    .reg_wr_wait    (1'b0   ),
    .reg_wr_ack     (1'b1   )
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