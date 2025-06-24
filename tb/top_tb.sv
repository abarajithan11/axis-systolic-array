`timescale 1ns/1ps
`include "config.svh"

module top_tb;
  localparam
    // Defined in config.svh
    R                   = `R                 ,
    C                   = `C                 ,
    WK                  = `WK                ,
    WX                  = `WX                ,
    WY                  = `WY                ,
    AXIL_BASE_ADDR      = `AXIL_BASE_ADDR    ,
    VALID_PROB          = `VALID_PROB        ,
    READY_PROB          = `READY_PROB        ,
    CLK_PERIOD          = `CLK_PERIOD        ,
    AXI_WIDTH           = `AXI_WIDTH         ,
    DIR                 = `DIR               ,
    WA                  = 32                 ,
    LM                  = 1                  ,
    LA                  = 1                  ,
    AXI_ID_WIDTH        = 6                  ,
    AXI_STRB_WIDTH      = AXI_WIDTH/8        ,
    AXI_MAX_BURST_LEN   = 32                 ,
    AXI_ADDR_WIDTH      = 32                 ,
    AXIL_WIDTH          = 32                 ,
    AXIL_ADDR_WIDTH     = 40                 ,
    AXIL_STRB_WIDTH     = 4                  ,
    DATA_WR_WIDTH       = AXIL_WIDTH         ,
    DATA_RD_WIDTH       = AXIL_WIDTH         ,
    LSB                 = $clog2(AXI_WIDTH)-3;


  // SIGNALS
  logic rstn = 0;
  /* 
    AXI Slave
  */
  logic [AXI_ID_WIDTH-1:0]     s_axi_awid   =0;
  logic [AXIL_ADDR_WIDTH-1:0]  s_axi_awaddr =0;
  logic [7:0]                  s_axi_awlen  =0;
  logic [2:0]                  s_axi_awsize =0;
  logic [1:0]                  s_axi_awburst=0;
  logic                        s_axi_awlock =0;
  logic [3:0]                  s_axi_awcache=0;
  logic [2:0]                  s_axi_awprot =0;
  logic                        s_axi_awvalid=0;
  logic                        s_axi_awready=0;
  logic [AXIL_WIDTH-1:0]       s_axi_wdata  =0;
  logic [AXIL_STRB_WIDTH-1:0]  s_axi_wstrb  =0;
  logic                        s_axi_wlast  =0;
  logic                        s_axi_wvalid =0;
  logic                        s_axi_wready ;
  logic [AXI_ID_WIDTH-1:0]     s_axi_bid    ;
  logic [1:0]                  s_axi_bresp  ;
  logic                        s_axi_bvalid ;
  logic                        s_axi_bready =0;
  logic [AXI_ID_WIDTH-1:0]     s_axi_arid   =0;
  logic [AXIL_ADDR_WIDTH-1:0]  s_axi_araddr =0;
  logic [7:0]                  s_axi_arlen  =0;
  logic [2:0]                  s_axi_arsize =0;
  logic [1:0]                  s_axi_arburst=0;
  logic                        s_axi_arlock =0;
  logic [3:0]                  s_axi_arcache=0;
  logic [2:0]                  s_axi_arprot =0;
  logic                        s_axi_arvalid=0;
  logic                        s_axi_arready;
  logic [AXI_ID_WIDTH-1:0]     s_axi_rid    ;
  logic [AXIL_WIDTH-1:0]       s_axi_rdata  ;
  logic [1:0]                  s_axi_rresp  ;
  logic                        s_axi_rlast  ;
  logic                        s_axi_rvalid ;
  logic                        s_axi_rready =0;

  logic                          mm2s_0_ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] mm2s_0_addr;
  logic [AXI_WIDTH    -1:0]      mm2s_0_data;
  logic                          mm2s_1_ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] mm2s_1_addr;
  logic [AXI_WIDTH    -1:0]      mm2s_1_data;
  logic                          mm2s_2_ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] mm2s_2_addr;
  logic [AXI_WIDTH    -1:0]      mm2s_2_data;

  logic                          s2mm_wen;
  logic [AXI_ADDR_WIDTH-LSB-1:0] s2mm_addr;
  logic [AXI_WIDTH    -1:0]      s2mm_data;
  logic [AXI_WIDTH/8  -1:0]      s2mm_strb;

  top_ram #(
    .R                 (R                ), 
    .C                 (C                ), 
    .WK                (WK               ), 
    .WX                (WX               ), 
    .WA                (WA               ), 
    .WY                (WY               ), 
    .LM                (LM               ), 
    .LA                (LA               ), 
    .VALID_PROB        (VALID_PROB       ),
    .READY_PROB        (READY_PROB       ),
    .AXI_WIDTH         (AXI_WIDTH        ), 
    .AXI_ID_WIDTH      (AXI_ID_WIDTH     ), 
    .AXI_STRB_WIDTH    (AXI_STRB_WIDTH   ), 
    .AXI_MAX_BURST_LEN (AXI_MAX_BURST_LEN), 
    .AXI_ADDR_WIDTH    (AXI_ADDR_WIDTH   ), 
    .AXIL_WIDTH        (AXIL_WIDTH       ), 
    .AXIL_ADDR_WIDTH   (AXIL_ADDR_WIDTH  ), 
    .AXIL_STRB_WIDTH   (AXIL_STRB_WIDTH  ), 
    .AXIL_BASE_ADDR    (AXIL_BASE_ADDR   ) 
  ) dut(.*);

  logic clk = 0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

`ifdef VERILATOR
  `define AUTOMATIC
`else
  `define AUTOMATIC automatic
`endif

  export "DPI-C" task _get_config;
  export "DPI-C" task set_config;
  import "DPI-C" context task get_byte_a32 (input int unsigned addr, output byte data);
  import "DPI-C" context task set_byte_a32 (input int unsigned addr, input byte data);
  import "DPI-C" context function chandle get_mp ();
  // import "DPI-C" context task void print_output (chandle mem_ptr_virtual);
  import "DPI-C" context task `AUTOMATIC run(input chandle mem_ptr_virtual, input chandle p_config);

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


  task automatic _get_config(input chandle config_base, input int offset, output int data);
    // data = dut.TOP.CONTROLLER.cfg [offset];
    axi_read(AXIL_BASE_ADDR + (offset * 4), data);
  endtask


  task automatic set_config(input chandle config_base, input int offset, input int data);
    // dut.TOP.CONTROLLER.cfg [offset] <= data;
    axi_write(AXIL_BASE_ADDR + (offset * 4), data);
  endtask

byte tmp_byte;
logic [AXI_WIDTH-1:0] tmp_data;

  always_ff @(posedge clk) begin : Axi_rw

    if (mm2s_0_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        get_byte_a32((32'(mm2s_0_addr) << LSB) + i, tmp_byte);
        tmp_data[i*8 +: 8] = tmp_byte;
      end
      mm2s_0_data <= tmp_data;
    end

    if (mm2s_1_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        get_byte_a32((32'(mm2s_1_addr) << LSB) + i, tmp_byte);
        tmp_data[i*8 +: 8] = tmp_byte;
      end
      mm2s_1_data <= tmp_data;
    end

    if (mm2s_2_ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        get_byte_a32((32'(mm2s_2_addr) << LSB) + i, tmp_byte);
        tmp_data[i*8 +: 8] = tmp_byte;
      end
      mm2s_2_data <= tmp_data;
    end

    if (s2mm_wen) 
      for (int i = 0; i < AXI_WIDTH/8; i++) 
        if (s2mm_strb[i]) 
          set_byte_a32((32'(s2mm_addr) << LSB) + i, s2mm_data[i*8 +: 8]);
  end
  
  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars();
    #1000us;
    $fatal(1, "Error: Timeout.");
  end

  int file_out, file_exp, status, error=0, i=0;
  byte out_byte, exp_byte;

  chandle mem_ptr_virtual, cfg_ptr_virtual;
  initial begin
    rstn <= 0;
    repeat(2) @(posedge clk) #10ps;
    rstn <= 1;
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
    $finish;
  end

endmodule
