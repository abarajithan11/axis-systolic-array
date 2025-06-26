
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
        CLK_PERIOD        = 10,
        DIR               = "./",

    localparam  LSB = $clog2(AXI_WIDTH)-3
)(
    input  logic                   clk,
    input  logic                   rstn,
    output logic                   done,

    // AXI Slave
    output logic [AXI_ID_WIDTH-1:0]     s_axi_awid   ,
    output logic [AXIL_ADDR_WIDTH-1:0]  s_axi_awaddr ,
    output logic [7:0]                  s_axi_awlen  ,
    output logic [2:0]                  s_axi_awsize ,
    output logic [1:0]                  s_axi_awburst,
    output logic                        s_axi_awlock ,
    output logic [3:0]                  s_axi_awcache,
    output logic [2:0]                  s_axi_awprot ,
    output logic                        s_axi_awvalid,
    input  logic                        s_axi_awready,
    output logic [AXIL_WIDTH-1:0]       s_axi_wdata  ,
    output logic [AXIL_STRB_WIDTH-1:0]  s_axi_wstrb  ,
    output logic                        s_axi_wlast  ,
    output logic                        s_axi_wvalid ,
    input  logic                        s_axi_wready ,
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_bid    ,
    input  logic [1:0]                  s_axi_bresp  ,
    input  logic                        s_axi_bvalid ,
    output logic                        s_axi_bready ,
    output logic [AXI_ID_WIDTH-1:0]     s_axi_arid   ,
    output logic [AXIL_ADDR_WIDTH-1:0]  s_axi_araddr ,
    output logic [7:0]                  s_axi_arlen  ,
    output logic [2:0]                  s_axi_arsize ,
    output logic [1:0]                  s_axi_arburst,
    output logic                        s_axi_arlock ,
    output logic [3:0]                  s_axi_arcache,
    output logic [2:0]                  s_axi_arprot ,
    output logic                        s_axi_arvalid,
    input  logic                        s_axi_arready,
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_rid    ,
    input  logic [AXIL_WIDTH-1:0]       s_axi_rdata  ,
    input  logic [1:0]                  s_axi_rresp  ,
    input  logic                        s_axi_rlast  ,
    input  logic                        s_axi_rvalid ,
    output logic                        s_axi_rready ,
    // Weights
    input  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_0_araddr,
    input  logic [7:0]                 m_axi_mm2s_0_arlen,
    input  logic [2:0]                 m_axi_mm2s_0_arsize,
    input  logic [1:0]                 m_axi_mm2s_0_arburst,
    input  logic                       m_axi_mm2s_0_arlock,
    input  logic [3:0]                 m_axi_mm2s_0_arcache,
    input  logic [2:0]                 m_axi_mm2s_0_arprot,
    input  logic                       m_axi_mm2s_0_arvalid,
    output logic                       m_axi_mm2s_0_arready,
    output logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_0_rid,
    output logic [AXI_WIDTH   -1:0]    m_axi_mm2s_0_rdata,
    output logic [1:0]                 m_axi_mm2s_0_rresp,
    output logic                       m_axi_mm2s_0_rlast,
    output logic                       m_axi_mm2s_0_rvalid,
    input  logic                       m_axi_mm2s_0_rready,
    // Pixels
    input  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_1_araddr,
    input  logic [7:0]                 m_axi_mm2s_1_arlen,
    input  logic [2:0]                 m_axi_mm2s_1_arsize,
    input  logic [1:0]                 m_axi_mm2s_1_arburst,
    input  logic                       m_axi_mm2s_1_arlock,
    input  logic [3:0]                 m_axi_mm2s_1_arcache,
    input  logic [2:0]                 m_axi_mm2s_1_arprot,
    input  logic                       m_axi_mm2s_1_arvalid,
    output logic                       m_axi_mm2s_1_arready,
    output logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_1_rid,
    output logic [AXI_WIDTH   -1:0]    m_axi_mm2s_1_rdata,
    output logic [1:0]                 m_axi_mm2s_1_rresp,
    output logic                       m_axi_mm2s_1_rlast,
    output logic                       m_axi_mm2s_1_rvalid,
    input  logic                       m_axi_mm2s_1_rready,
    // Partial sums
    input  logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_2_araddr,
    input  logic [7:0]                 m_axi_mm2s_2_arlen,
    input  logic [2:0]                 m_axi_mm2s_2_arsize,
    input  logic [1:0]                 m_axi_mm2s_2_arburst,
    input  logic                       m_axi_mm2s_2_arlock,
    input  logic [3:0]                 m_axi_mm2s_2_arcache,
    input  logic [2:0]                 m_axi_mm2s_2_arprot,
    input  logic                       m_axi_mm2s_2_arvalid,
    output logic                       m_axi_mm2s_2_arready,
    output logic [AXI_ID_WIDTH-1:0]    m_axi_mm2s_2_rid,
    output logic [AXI_WIDTH   -1:0]    m_axi_mm2s_2_rdata,
    output logic [1:0]                 m_axi_mm2s_2_rresp,
    output logic                       m_axi_mm2s_2_rlast,
    output logic                       m_axi_mm2s_2_rvalid,
    input  logic                       m_axi_mm2s_2_rready,
    // Output
    input  logic [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr,
    input  logic [7:0]                 m_axi_s2mm_awlen,
    input  logic [2:0]                 m_axi_s2mm_awsize,
    input  logic [1:0]                 m_axi_s2mm_awburst,
    input  logic                       m_axi_s2mm_awlock,
    input  logic [3:0]                 m_axi_s2mm_awcache,
    input  logic [2:0]                 m_axi_s2mm_awprot,
    input  logic                       m_axi_s2mm_awvalid,
    output logic                        m_axi_s2mm_awready,
    input  logic [AXI_WIDTH   -1:0]    m_axi_s2mm_wdata,
    input  logic [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb,
    input  logic                       m_axi_s2mm_wlast,
    input  logic                       m_axi_s2mm_wvalid,
    output logic                        m_axi_s2mm_wready,
    output logic [AXI_ID_WIDTH-1:0]     m_axi_s2mm_bid,
    output logic [1:0]                  m_axi_s2mm_bresp,
    output logic                        m_axi_s2mm_bvalid,
    input  logic                       m_axi_s2mm_bready
);

    logic                            mm2s_0_ren;
    logic  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_0_addr;
    logic  [AXI_WIDTH-1:0]           mm2s_0_data;
    
    logic                            mm2s_1_ren;
    logic  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_1_addr;
    logic  [AXI_WIDTH-1:0]           mm2s_1_data;
    
    logic                            mm2s_2_ren;
    logic  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_2_addr;
    logic  [AXI_WIDTH-1:0]           mm2s_2_data;
    
    logic                            s2mm_wen;
    logic  [AXI_ADDR_WIDTH-LSB-1:0]  s2mm_addr;
    logic  [AXI_WIDTH-1:0]           s2mm_data;
    logic  [AXI_WIDTH/8-1:0]         s2mm_strb;


`ifdef VERILATOR
  `define AUTOMATIC
`elsif XCELIUM
  `define AUTOMATIC
`else
  `define AUTOMATIC automatic
`endif

  export "DPI-C" task task_get_config;
  export "DPI-C" function fn_get_config;
  export "DPI-C" task set_config;
  import "DPI-C" context function byte get_byte_a32 (input int unsigned addr);
  import "DPI-C" context function void  set_byte_a32 (input int unsigned addr, input byte data);
  // import "DPI-C" context task void print_output (chandle mem_ptr_virtual);

  task axi_write(input logic [AXIL_ADDR_WIDTH-1:0] addr, input logic [AXIL_WIDTH-1:0] data);
    begin
      @(posedge clk) #10ps;
      s_axi_awid     <= 4'h1;
      s_axi_awaddr   <= addr;
      s_axi_awlen    <= 8'd0;
      s_axi_awsize   <= 3'd2; // 4 bytes
      s_axi_awburst  <= 2'b01;
      s_axi_awlock   <= 0;
      s_axi_awcache  <= 0;
      s_axi_awprot   <= 0;
      s_axi_awvalid  <= 1;

      wait (s_axi_awready);
      @(posedge clk) #10ps;
      s_axi_awvalid <= 0;

      s_axi_wdata   <= data;
      s_axi_wstrb   <= 4'hF;
      s_axi_wlast   <= 1;
      s_axi_wvalid  <= 1;

      wait (s_axi_wready);
      @(posedge clk) #10ps;
      s_axi_wvalid <= 0;

      s_axi_bready <= 1;
      wait (s_axi_bvalid);
      @(posedge clk) #10ps;
      s_axi_bready <= 0;
    end
  endtask

  task axi_read(input logic [AXIL_ADDR_WIDTH-1:0] addr, output logic [AXIL_WIDTH-1:0] rdata);
    begin
      @(posedge clk) #10ps;
      s_axi_arid     <= 4'h1;
      s_axi_araddr   <= addr;
      s_axi_arlen    <= 8'd0;
      s_axi_arsize   <= 3'd2;
      s_axi_arburst  <= 2'b01;
      s_axi_arlock   <= 0;
      s_axi_arcache  <= 0;
      s_axi_arprot   <= 0;
      s_axi_arvalid  <= 1;

      wait (s_axi_arready) #10ps;
      @(posedge clk);
      s_axi_arvalid <= 0;

      s_axi_rready <= 1;
      wait (s_axi_rvalid);
      rdata = s_axi_rdata;
      @(posedge clk) #10ps;
      s_axi_rready <= 0;
    end
  endtask

  int tmp_get_data;
  task automatic task_get_config(input chandle config_base, input int offset);
    // @(posedge clk) tmp_get_data = dut.TOP.CONTROLLER.cfg [offset];
    axi_read(AXIL_BASE_ADDR + (offset * 4), tmp_get_data);
  endtask

  function automatic int fn_get_config();
    return tmp_get_data;
  endfunction

  task automatic set_config(input chandle config_base, input int offset, input int data);
    // @(posedge clk) #10ps dut.TOP.CONTROLLER.cfg [offset] <= data;
    axi_write(AXIL_BASE_ADDR + (offset * 4), data);
  endtask

byte tmp_byte;
logic [AXI_WIDTH-1:0] tmp_data;

  always_ff @(posedge clk) begin : Axi_rw

    if (mm2s_0_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        tmp_data[i*8 +: 8] = get_byte_a32((32'(mm2s_0_addr) << LSB) + i);
      end
      mm2s_0_data <= tmp_data;
    end

    if (mm2s_1_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        tmp_data[i*8 +: 8] = get_byte_a32((32'(mm2s_1_addr) << LSB) + i);
      end
      mm2s_1_data <= tmp_data;
    end

    if (mm2s_2_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        tmp_data[i*8 +: 8] = get_byte_a32((32'(mm2s_2_addr) << LSB) + i);
      end
      mm2s_2_data <= tmp_data;
    end

    if (s2mm_wen) 
      for (int i = 0; i < AXI_WIDTH/8; i++) 
        if (s2mm_strb[i]) 
          set_byte_a32((32'(s2mm_addr) << LSB) + i, s2mm_data[i*8 +: 8]);
  end
  

  import "DPI-C" context task `AUTOMATIC run(input chandle mem_ptr_virtual, input chandle p_config);
  import "DPI-C" context function chandle get_mp ();
  



  int file_out, file_exp, status, error=0, i=0;
  byte out_byte, exp_byte;

  chandle mem_ptr_virtual, cfg_ptr_virtual;
  initial begin
    done <= 0;
    wait (rstn);
    mem_ptr_virtual = get_mp();

    run(mem_ptr_virtual, cfg_ptr_virtual);


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
    done <= 1;
  end


// AXI ports from top on-chip module

    logic m_axi_mm2s_0_arvalid_zipcpu;
    logic m_axi_mm2s_0_arready_zipcpu;
    logic m_axi_mm2s_0_rvalid_zipcpu;
    logic m_axi_mm2s_0_rready_zipcpu;
    logic m_axi_mm2s_1_arvalid_zipcpu;
    logic m_axi_mm2s_1_arready_zipcpu;
    logic m_axi_mm2s_1_rvalid_zipcpu;
    logic m_axi_mm2s_1_rready_zipcpu;
    logic m_axi_mm2s_2_arvalid_zipcpu;
    logic m_axi_mm2s_2_arready_zipcpu;
    logic m_axi_mm2s_2_rvalid_zipcpu;
    logic m_axi_mm2s_2_rready_zipcpu;
    logic m_axi_s2mm_awvalid_zipcpu;
    logic m_axi_s2mm_awready_zipcpu;
    logic m_axi_s2mm_wvalid_zipcpu;
    logic m_axi_s2mm_wready_zipcpu;
    logic m_axi_s2mm_bvalid_zipcpu;
    logic m_axi_s2mm_bready_zipcpu;

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

endmodule