
`timescale 1ns/1ps

module firebridge_axi #(
  parameter
  S_COUNT          = 1,
  M_COUNT          = 1,

  M_AXI_DATA_WIDTH  = 128,
  M_AXI_ADDR_WIDTH  = 32,
  M_AXI_ID_WIDTH    = 6,
  M_AXI_STRB_WIDTH  = (M_AXI_DATA_WIDTH/8),
  S_AXI_DATA_WIDTH  = 32,
  S_AXI_ID_WIDTH    = 6,
  S_AXI_ADDR_WIDTH  = 40,
  S_AXI_STRB_WIDTH  = (S_AXI_DATA_WIDTH/8),
  S_AXI_BASE_ADDR   = {32'hA0000000},

  VALID_PROB        = 1000,
  READY_PROB        = 1000
)(
  input  logic clk,
  input  logic rstn,
  output logic firebridge_done,

  // AXI Slave
  output logic [S_COUNT-1:0][S_AXI_ID_WIDTH -1:0]   s_axi_awid   ,
  output logic [S_COUNT-1:0][S_AXI_ADDR_WIDTH-1:0]  s_axi_awaddr ,
  output logic [S_COUNT-1:0][7:0]                   s_axi_awlen  ,
  output logic [S_COUNT-1:0][2:0]                   s_axi_awsize ,
  output logic [S_COUNT-1:0][1:0]                   s_axi_awburst,
  output logic [S_COUNT-1:0]                        s_axi_awlock ,
  output logic [S_COUNT-1:0][3:0]                   s_axi_awcache,
  output logic [S_COUNT-1:0][2:0]                   s_axi_awprot ,
  output logic [S_COUNT-1:0]                        s_axi_awvalid,
  input  logic [S_COUNT-1:0]                        s_axi_awready /* verilator public */,
  output logic [S_COUNT-1:0][S_AXI_DATA_WIDTH-1:0]  s_axi_wdata  ,
  output logic [S_COUNT-1:0][S_AXI_STRB_WIDTH-1:0]  s_axi_wstrb  ,
  output logic [S_COUNT-1:0]                        s_axi_wlast  ,
  output logic [S_COUNT-1:0]                        s_axi_wvalid ,
  input  logic [S_COUNT-1:0]                        s_axi_wready /* verilator public */,
  input  logic [S_COUNT-1:0][S_AXI_ID_WIDTH-1:0]    s_axi_bid    ,
  input  logic [S_COUNT-1:0][1:0]                   s_axi_bresp  ,
  input  logic [S_COUNT-1:0]                        s_axi_bvalid /* verilator public */,
  output logic [S_COUNT-1:0]                        s_axi_bready ,
  output logic [S_COUNT-1:0][S_AXI_ID_WIDTH-1:0]    s_axi_arid   ,
  output logic [S_COUNT-1:0][S_AXI_ADDR_WIDTH-1:0]  s_axi_araddr ,
  output logic [S_COUNT-1:0][7:0]                   s_axi_arlen  ,
  output logic [S_COUNT-1:0][2:0]                   s_axi_arsize ,
  output logic [S_COUNT-1:0][1:0]                   s_axi_arburst,
  output logic [S_COUNT-1:0]                        s_axi_arlock ,
  output logic [S_COUNT-1:0][3:0]                   s_axi_arcache,
  output logic [S_COUNT-1:0][2:0]                   s_axi_arprot ,
  output logic [S_COUNT-1:0]                        s_axi_arvalid,
  input  logic [S_COUNT-1:0]                        s_axi_arready /* verilator public */,
  input  logic [S_COUNT-1:0][S_AXI_ID_WIDTH-1:0]    s_axi_rid    ,
  input  logic [S_COUNT-1:0][S_AXI_DATA_WIDTH-1:0]  s_axi_rdata  ,
  input  logic [S_COUNT-1:0][1:0]                   s_axi_rresp  ,
  input  logic [S_COUNT-1:0]                        s_axi_rlast  ,
  input  logic [S_COUNT-1:0]                        s_axi_rvalid /* verilator public */,
  output logic [S_COUNT-1:0]                        s_axi_rready ,
  // AXI Masters
  input  logic [M_COUNT-1:0][M_AXI_ID_WIDTH-1:0]    m_axi_awid   ,
  input  logic [M_COUNT-1:0][M_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr ,
  input  logic [M_COUNT-1:0][7:0]                   m_axi_awlen  ,
  input  logic [M_COUNT-1:0][2:0]                   m_axi_awsize ,
  input  logic [M_COUNT-1:0][1:0]                   m_axi_awburst,
  input  logic [M_COUNT-1:0]                        m_axi_awlock ,
  input  logic [M_COUNT-1:0][3:0]                   m_axi_awcache,
  input  logic [M_COUNT-1:0][2:0]                   m_axi_awprot ,
  input  logic [M_COUNT-1:0]                        m_axi_awvalid,
  output logic [M_COUNT-1:0]                        m_axi_awready,
  input  logic [M_COUNT-1:0][M_AXI_DATA_WIDTH-1:0]  m_axi_wdata  ,
  input  logic [M_COUNT-1:0][M_AXI_STRB_WIDTH-1:0]  m_axi_wstrb  ,
  input  logic [M_COUNT-1:0]                        m_axi_wlast  ,
  input  logic [M_COUNT-1:0]                        m_axi_wvalid ,
  output logic [M_COUNT-1:0]                        m_axi_wready ,
  output logic [M_COUNT-1:0][M_AXI_ID_WIDTH-1:0]    m_axi_bid    ,
  output logic [M_COUNT-1:0][1:0]                   m_axi_bresp  ,
  output logic [M_COUNT-1:0]                        m_axi_bvalid ,
  input  logic [M_COUNT-1:0]                        m_axi_bready ,
  input  logic [M_COUNT-1:0][M_AXI_ID_WIDTH-1:0]    m_axi_arid   ,
  input  logic [M_COUNT-1:0][M_AXI_ADDR_WIDTH-1:0]  m_axi_araddr ,
  input  logic [M_COUNT-1:0][7:0]                   m_axi_arlen  ,
  input  logic [M_COUNT-1:0][2:0]                   m_axi_arsize ,
  input  logic [M_COUNT-1:0][1:0]                   m_axi_arburst,
  input  logic [M_COUNT-1:0]                        m_axi_arlock ,
  input  logic [M_COUNT-1:0][3:0]                   m_axi_arcache,
  input  logic [M_COUNT-1:0][2:0]                   m_axi_arprot ,
  input  logic [M_COUNT-1:0]                        m_axi_arvalid,
  output logic [M_COUNT-1:0]                        m_axi_arready,
  output logic [M_COUNT-1:0][M_AXI_ID_WIDTH-1:0]    m_axi_rid    ,
  output logic [M_COUNT-1:0][M_AXI_DATA_WIDTH-1:0]  m_axi_rdata  ,
  output logic [M_COUNT-1:0][1:0]                   m_axi_rresp  ,
  output logic [M_COUNT-1:0]                        m_axi_rlast  ,
  output logic [M_COUNT-1:0]                        m_axi_rvalid ,
  input  logic [M_COUNT-1:0]                        m_axi_rready  
);

  genvar m;
  localparam  
    LSB = $clog2(M_AXI_DATA_WIDTH)-3,
    OPT_LOCK          = 1'b0,
    OPT_LOCKID        = 1'b1,
    OPT_LOWPOWER      = 1'b0;

  logic  [M_COUNT-1:0]                            ren;
  logic  [M_COUNT-1:0][M_AXI_ADDR_WIDTH-LSB-1:0]  raddr;
  logic  [M_COUNT-1:0][M_AXI_DATA_WIDTH-1:0]      rdata;
  logic  [M_COUNT-1:0]                            wen;
  logic  [M_COUNT-1:0][M_AXI_ADDR_WIDTH-LSB-1:0]  waddr;
  logic  [M_COUNT-1:0][M_AXI_DATA_WIDTH-1:0]      wdata;
  logic  [M_COUNT-1:0][M_AXI_DATA_WIDTH/8-1:0]    wstrb;

  function automatic int get_s_index(int addr);
    int index = -1;
    if (/* verilator lint_off UNSIGNED */ addr >= S_AXI_BASE_ADDR[S_COUNT-1])
      index = S_COUNT-1;
    else for (int s=0; s < S_COUNT-1; s++)
      if (/* verilator lint_off UNSIGNED */ addr >= S_AXI_BASE_ADDR[s] && addr < S_AXI_BASE_ADDR[s+1]) begin
        index = s;
        break;
      end
    return index;
  endfunction

`ifdef VERILATOR
  import "DPI-C" context function void at_posedge_clk();
  import "DPI-C" context function void wait_s_axi_awready(input int i);
  import "DPI-C" context function void wait_s_axi_wready(input int i);
  import "DPI-C" context function void wait_s_axi_bvalid(input int i);
`else

  task at_posedge_clk();
    @(posedge clk) #10ps;
  endtask

  task wait_s_axi_awready(input int i);
    wait (s_axi_awready[i]);
  endtask

  task wait_s_axi_wready(input int i);
    wait (s_axi_wready[i]);
  endtask

  task wait_s_axi_bvalid(input int i);
    wait (s_axi_bvalid[i]);
  endtask
`endif

  task axi_write(input logic [S_AXI_ADDR_WIDTH-1:0] addr, input logic [S_AXI_DATA_WIDTH-1:0] data);

    automatic int i = get_s_index(addr);

    // @(posedge clk) #10ps;
    at_posedge_clk();
    s_axi_awid   [i]  <= S_AXI_ID_WIDTH'(1);
    s_axi_awaddr [i]  <= addr;
    s_axi_awlen  [i]  <= 8'd0;
    s_axi_awsize [i]  <= 3'd2; // 4 bytes
    s_axi_awburst[i]  <= 2'b01;
    s_axi_awlock [i]  <= 0;
    s_axi_awcache[i]  <= 0;
    s_axi_awprot [i]  <= 0;
    s_axi_awvalid[i]  <= 1;

    // wait (s_axi_awready[i]);
    // @(posedge clk) #10ps;
    wait_s_axi_awready(i);
    at_posedge_clk();
    s_axi_awvalid[i]  <= 0;
    s_axi_wdata  [i]  <= data;
    s_axi_wstrb  [i]  <= S_AXI_STRB_WIDTH'(4'hF);
    s_axi_wlast  [i]  <= 1;
    s_axi_wvalid [i]  <= 1;

    // wait (s_axi_wready[i]);
    // @(posedge clk) #10ps;
    wait_s_axi_wready(i);
    at_posedge_clk();
    s_axi_wvalid [i] <= 0;
    s_axi_bready [i] <= 1;

    // wait (s_axi_bvalid[i]);
    // @(posedge clk) #10ps;
    wait_s_axi_bvalid(i);
    at_posedge_clk();
    s_axi_bready[i] <= 0;
  endtask

`ifdef VERILATOR
  import "DPI-C" context function void wait_s_axi_arready(input int i);
  import "DPI-C" context function void wait_s_axi_rvalid(input int i);
`else
  task wait_s_axi_arready(input int i);
    wait (s_axi_arready[i]);
  endtask
  task wait_s_axi_rvalid(input int i);
    wait (s_axi_rvalid[i]);
  endtask
`endif

  task axi_read(input logic [S_AXI_ADDR_WIDTH-1:0] addr, output logic [S_AXI_DATA_WIDTH-1:0] rdata);

    automatic int i = get_s_index(addr);

    // @(posedge clk) #10ps;
    at_posedge_clk();
    s_axi_arid   [i]  <= S_AXI_ID_WIDTH'(1);
    s_axi_araddr [i]  <= addr;
    s_axi_arlen  [i]  <= 8'd0;
    s_axi_arsize [i]  <= 3'd2;
    s_axi_arburst[i]  <= 2'b01;
    s_axi_arlock [i]  <= 0;
    s_axi_arcache[i]  <= 0;
    s_axi_arprot [i]  <= 0;
    s_axi_arvalid[i]  <= 1;

    // wait (s_axi_arready[i]);
    // @(posedge clk) #10ps;
    wait_s_axi_arready(i);
    at_posedge_clk();
    s_axi_arvalid[i] <= 0;
    s_axi_rready [i] <= 1;

    // wait (s_axi_rvalid [i]);
    wait_s_axi_rvalid(i);
    rdata = s_axi_rdata[i];

    // @(posedge clk) #10ps;
    at_posedge_clk();
    s_axi_rready[i] <= 0;
  endtask

  export "DPI-C" task fb_task_read_reg32;
  export "DPI-C" function fb_fn_read_reg32;
  export "DPI-C" task fb_task_write_reg32;

  int tmp_get_data;
  task automatic fb_task_read_reg32(input longint addr);
    axi_read(S_AXI_ADDR_WIDTH'(addr), tmp_get_data);
  endtask

  function automatic int fb_fn_read_reg32();
    return tmp_get_data;
  endfunction

  task automatic fb_task_write_reg32(input longint addr, input int data);
    axi_write(S_AXI_ADDR_WIDTH'(addr), data);
  endtask


  // Memory Congestion Emulation

  logic [M_COUNT-1:0] m_axi_arvalid_zipcpu;
  logic [M_COUNT-1:0] m_axi_arready_zipcpu;
  logic [M_COUNT-1:0] m_axi_rvalid_zipcpu;
  logic [M_COUNT-1:0] m_axi_rready_zipcpu;
  logic [M_COUNT-1:0] m_axi_awvalid_zipcpu;
  logic [M_COUNT-1:0] m_axi_awready_zipcpu;
  logic [M_COUNT-1:0] m_axi_wvalid_zipcpu;
  logic [M_COUNT-1:0] m_axi_wready_zipcpu;
  logic [M_COUNT-1:0] m_axi_bvalid_zipcpu;
  logic [M_COUNT-1:0] m_axi_bready_zipcpu;
  logic [M_COUNT-1:0] rand_ar;
  logic [M_COUNT-1:0] rand_r;
  logic [M_COUNT-1:0] rand_aw;
  logic [M_COUNT-1:0] rand_w;
  logic [M_COUNT-1:0] rand_b;

  assign m_axi_arvalid_zipcpu = rand_ar & m_axi_arvalid       ;
  assign m_axi_arready        = rand_ar & m_axi_arready_zipcpu;
  assign m_axi_rvalid         = rand_r  & m_axi_rvalid_zipcpu ;
  assign m_axi_rready_zipcpu  = rand_r  & m_axi_rready        ;
  assign m_axi_awvalid_zipcpu = rand_aw & m_axi_awvalid       ;
  assign m_axi_awready        = rand_aw & m_axi_awready_zipcpu;
  assign m_axi_wvalid_zipcpu  = rand_w  & m_axi_wvalid        ;
  assign m_axi_wready         = rand_w  & m_axi_wready_zipcpu ;
  assign m_axi_bvalid         = rand_b  & m_axi_bvalid_zipcpu ;
  assign m_axi_bready_zipcpu  = rand_b  & m_axi_bready        ;
  

  // Handle M Masters
  import "DPI-C" context function byte fb_c_read_ddr8_addr32  (input int unsigned addr);
  import "DPI-C" context function void fb_c_write_ddr8_addr32 (input int unsigned addr, input byte data);

  for (m=0; m< M_COUNT; m++) begin

    always_ff @( posedge clk ) begin
      rand_r  [m]  <= $urandom_range(0, 1000) < VALID_PROB;
      rand_ar [m]  <= $urandom_range(0, 1000) < VALID_PROB;
      rand_aw [m]  <= $urandom_range(0, 1000) < READY_PROB;
      rand_w  [m]  <= $urandom_range(0, 1000) < READY_PROB;
      rand_b  [m]  <= $urandom_range(0, 1000) < READY_PROB;
    end

    zipcpu_axi2ram #(
      .C_S_AXI_ID_WIDTH   (M_AXI_ID_WIDTH  ),
      .C_S_AXI_DATA_WIDTH (M_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH (M_AXI_ADDR_WIDTH),
      .OPT_LOCK           (OPT_LOCK        ),
      .OPT_LOCKID         (OPT_LOCKID      ),
      .OPT_LOWPOWER       (OPT_LOWPOWER    )
    ) zip_axi2ram (

      .o_we      (wen   [m]),
      .o_waddr   (waddr [m]),
      .o_wdata   (wdata [m]),
      .o_wstrb   (wstrb [m]),
      .o_rd      (ren   [m]),
      .o_raddr   (raddr [m]),
      .i_rdata   (rdata [m]),

      .S_AXI_ACLK   (clk),
      .S_AXI_ARESETN(rstn),

      .S_AXI_AWID   (m_axi_awid           [m]),
      .S_AXI_AWADDR (m_axi_awaddr         [m]),
      .S_AXI_AWLEN  (m_axi_awlen          [m]),
      .S_AXI_AWSIZE (m_axi_awsize         [m]),
      .S_AXI_AWBURST(m_axi_awburst        [m]),
      .S_AXI_AWLOCK (m_axi_awlock         [m]),
      .S_AXI_AWCACHE(m_axi_awcache        [m]),
      .S_AXI_AWPROT (m_axi_awprot         [m]),
      .S_AXI_AWQOS  (),
      .S_AXI_AWVALID(m_axi_awvalid_zipcpu [m]),
      .S_AXI_AWREADY(m_axi_awready_zipcpu [m]),
      .S_AXI_WDATA  (m_axi_wdata          [m]),
      .S_AXI_WSTRB  (m_axi_wstrb          [m]),
      .S_AXI_WLAST  (m_axi_wlast          [m]),
      .S_AXI_WVALID (m_axi_wvalid_zipcpu  [m]),
      .S_AXI_WREADY (m_axi_wready_zipcpu  [m]),
      .S_AXI_BID    (m_axi_bid            [m]),
      .S_AXI_BRESP  (m_axi_bresp          [m]),
      .S_AXI_BVALID (m_axi_bvalid_zipcpu  [m]),
      .S_AXI_BREADY (m_axi_bready_zipcpu  [m]),
      .S_AXI_ARID   (m_axi_arid           [m]),
      .S_AXI_ARADDR (m_axi_araddr         [m]),
      .S_AXI_ARLEN  (m_axi_arlen          [m]),
      .S_AXI_ARSIZE (m_axi_arsize         [m]),
      .S_AXI_ARBURST(m_axi_arburst        [m]),
      .S_AXI_ARLOCK (m_axi_arlock         [m]),
      .S_AXI_ARCACHE(m_axi_arcache        [m]),
      .S_AXI_ARPROT (m_axi_arprot         [m]),
      .S_AXI_ARQOS(),
      .S_AXI_ARVALID(m_axi_arvalid_zipcpu [m]),
      .S_AXI_ARREADY(m_axi_arready_zipcpu [m]),
      .S_AXI_RID    (m_axi_rid            [m]),
      .S_AXI_RDATA  (m_axi_rdata          [m]),
      .S_AXI_RRESP  (m_axi_rresp          [m]),
      .S_AXI_RLAST  (m_axi_rlast          [m]),
      .S_AXI_RVALID (m_axi_rvalid_zipcpu  [m]),
      .S_AXI_RREADY (m_axi_rready_zipcpu  [m])
    );

    // DDR Read & Write

    byte tmp_byte;
    logic [M_AXI_DATA_WIDTH-1:0] tmp_data;

    always_ff @(posedge clk) begin
      if (ren[m]) begin
        for (int i = 0; i < M_AXI_DATA_WIDTH/8; i++) begin
          tmp_data[i*8 +: 8] = fb_c_read_ddr8_addr32((32'(raddr[m]) << LSB) + i);
        end
        rdata[m] <= tmp_data;
      end
      if (wen[m]) 
        for (int i = 0; i < M_AXI_DATA_WIDTH/8; i++) 
          if (wstrb[m][i]) 
            fb_c_write_ddr8_addr32((32'(waddr[m]) << LSB) + i, wdata[m][i*8 +: 8]);
    end
  end


  // Simulation

`ifdef VERILATOR
  `define AUTOMATIC
`elsif XCELIUM
  `define AUTOMATIC
`else
  `define AUTOMATIC automatic
`endif

  import "DPI-C" context task `AUTOMATIC run(input chandle mem_ptr_virtual);
  import "DPI-C" context function chandle fb_get_mp ();

  chandle mem_ptr_virtual;
  initial begin
    firebridge_done <= 0;
    wait (rstn);
    mem_ptr_virtual = fb_get_mp();
    run(mem_ptr_virtual);
    firebridge_done <= 1;
  end

endmodule