
module axi2tlul #(
  parameter 
    ADDR_WIDTH   = 32,
    DATA_WIDTH   = 32,
    AXI_ID_WIDTH = 8,

  localparam
    STRB_WIDTH      = (DATA_WIDTH/8),
    AXI_DATA_WIDTH  = DATA_WIDTH,
    AXI_STRB_WIDTH  = STRB_WIDTH,
    AXIL_DATA_WIDTH = DATA_WIDTH,
    AXIL_STRB_WIDTH = STRB_WIDTH,
    CONVERT_BURST   = 1,
    CONVERT_NARROW_BURST = 0,
    TIMEOUT = 2
)(
  input  logic                        clk,
  input  logic                        rstn,
  input  logic [AXI_ID_WIDTH-1:0]     s_axi_awid,
  input  logic [ADDR_WIDTH-1:0]       s_axi_awaddr,
  input  logic [7:0]                  s_axi_awlen,
  input  logic [2:0]                  s_axi_awsize,
  input  logic [1:0]                  s_axi_awburst,
  input  logic                        s_axi_awlock,
  input  logic [3:0]                  s_axi_awcache,
  input  logic [2:0]                  s_axi_awprot,
  input  logic                        s_axi_awvalid,
  output logic                        s_axi_awready,
  input  logic [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
  input  logic [AXI_STRB_WIDTH-1:0]   s_axi_wstrb,
  input  logic                        s_axi_wlast,
  input  logic                        s_axi_wvalid,
  output logic                        s_axi_wready,
  output logic [AXI_ID_WIDTH-1:0]     s_axi_bid,
  output logic [1:0]                  s_axi_bresp,
  output logic                        s_axi_bvalid,
  input  logic                        s_axi_bready,
  input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,
  input  logic [ADDR_WIDTH-1:0]       s_axi_araddr,
  input  logic [7:0]                  s_axi_arlen,
  input  logic [2:0]                  s_axi_arsize,
  input  logic [1:0]                  s_axi_arburst,
  input  logic                        s_axi_arlock,
  input  logic [3:0]                  s_axi_arcache,
  input  logic [2:0]                  s_axi_arprot,
  input  logic                        s_axi_arvalid,
  output logic                        s_axi_arready,
  output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
  output logic [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
  output logic [1:0]                  s_axi_rresp,
  output logic                        s_axi_rlast,
  output logic                        s_axi_rvalid,
  input  logic                        s_axi_rready,

  output wire                         reg_wr_en,
  output wire [ADDR_WIDTH-1:0]        reg_wr_addr,
  output wire [DATA_WIDTH-1:0]        reg_wr_data,
  output wire [STRB_WIDTH-1:0]        reg_wr_strb,
  input  wire                         reg_wr_wait,
  input  wire                         reg_wr_ack,

  output wire                         reg_rd_en,
  output wire [ADDR_WIDTH-1:0]        reg_rd_addr,
  input  wire [DATA_WIDTH-1:0]        reg_rd_data,
  input  wire                         reg_rd_wait,
  input  wire                         reg_rd_ack
);

  logic [ADDR_WIDTH-1:0]       m_axil_awaddr ;
  logic [2:0]                  m_axil_awprot ;
  logic                        m_axil_awvalid;
  logic                        m_axil_awready;
  logic [AXIL_DATA_WIDTH-1:0]  m_axil_wdata  ;
  logic [AXIL_STRB_WIDTH-1:0]  m_axil_wstrb  ;
  logic                        m_axil_wvalid ;
  logic                        m_axil_wready ;
  logic [1:0]                  m_axil_bresp  ;
  logic                        m_axil_bvalid ;
  logic                        m_axil_bready ;
  logic [ADDR_WIDTH-1:0]       m_axil_araddr ;
  logic [2:0]                  m_axil_arprot ;
  logic                        m_axil_arvalid;
  logic                        m_axil_arready;
  logic [AXIL_DATA_WIDTH-1:0]  m_axil_rdata  ;
  logic [1:0]                  m_axil_rresp  ;
  logic                        m_axil_rvalid ;
  logic                        m_axil_rready ;

  axi_axil_adapter #(
    .ADDR_WIDTH           (ADDR_WIDTH          ),
    .AXI_DATA_WIDTH       (AXI_DATA_WIDTH      ),
    .AXI_STRB_WIDTH       (AXI_STRB_WIDTH      ),
    .AXI_ID_WIDTH         (AXI_ID_WIDTH        ),
    .AXIL_DATA_WIDTH      (AXIL_DATA_WIDTH     ),
    .AXIL_STRB_WIDTH      (AXIL_STRB_WIDTH     ),
    .CONVERT_BURST        (CONVERT_BURST       ),
    .CONVERT_NARROW_BURST (CONVERT_NARROW_BURST)
  ) AXI_2_AXIL (
    .rst(!rstn), 
    .*
  );

  alex_axilite_ram #(
    .DATA_WR_WIDTH(DATA_WIDTH),
    .DATA_RD_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH   (ADDR_WIDTH),
    .STRB_WIDTH   (STRB_WIDTH),
    .TIMEOUT      (TIMEOUT)
  ) AXIL2RAM (
    .s_axil_awaddr  (m_axil_awaddr ),
    .s_axil_awprot  (m_axil_awprot ),
    .s_axil_awvalid (m_axil_awvalid),
    .s_axil_awready (m_axil_awready),
    .s_axil_wdata   (m_axil_wdata  ),
    .s_axil_wstrb   (m_axil_wstrb  ),
    .s_axil_wvalid  (m_axil_wvalid ),
    .s_axil_wready  (m_axil_wready ),
    .s_axil_bresp   (m_axil_bresp  ),
    .s_axil_bvalid  (m_axil_bvalid ),
    .s_axil_bready  (m_axil_bready ),
    .s_axil_araddr  (m_axil_araddr ),
    .s_axil_arprot  (m_axil_arprot ),
    .s_axil_arvalid (m_axil_arvalid),
    .s_axil_arready (m_axil_arready),
    .s_axil_rdata   (m_axil_rdata  ),
    .s_axil_rresp   (m_axil_rresp  ),
    .s_axil_rvalid  (m_axil_rvalid ),
    .s_axil_rready  (m_axil_rready ),
    .*
  );

endmodule