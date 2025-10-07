`timescale 1ns/1ps
`include "config.svh"

module top_axi_int_tb;
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
    STRB_WIDTH          = 4                  ,
    DATA_WR_WIDTH       = AXIL_WIDTH         ,
    DATA_RD_WIDTH       = AXIL_WIDTH         ,
    LSB                 = $clog2(AXI_WIDTH)-3;


  // SIGNALS
  logic rstn = 0;
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_awaddr =0;
  logic [2:0]                s_axil_awprot =0;
  logic                      s_axil_awvalid=0;
  logic                      s_axil_awready;
  logic [DATA_WR_WIDTH-1:0]  s_axil_wdata =0;
  logic [STRB_WIDTH-1:0]     s_axil_wstrb =0;
  logic                      s_axil_wvalid=0;
  logic                      s_axil_wready;
  logic [1:0]                s_axil_bresp;
  logic                      s_axil_bvalid;
  logic                      s_axil_bready =0;
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_araddr =0;
  logic [2:0]                s_axil_arprot =0;
  logic                      s_axil_arvalid=0;
  logic                      s_axil_arready;
  logic [DATA_RD_WIDTH-1:0]  s_axil_rdata;
  logic [1:0]                s_axil_rresp;
  logic                      s_axil_rvalid;
  logic                      s_axil_rready=0;

  logic                          ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] raddr;
  logic [AXI_WIDTH    -1:0]      rdata;
  logic                          wen;
  logic [AXI_ADDR_WIDTH-LSB-1:0] waddr;
  logic [AXI_WIDTH    -1:0]      wdata;
  logic [AXI_WIDTH/8  -1:0]      wstrb;

  top_axi_int2ram_tb #(
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
    .STRB_WIDTH        (STRB_WIDTH       ), 
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
  import "DPI-C" context task `AUTOMATIC run(input chandle mem_ptr_virtual, input chandle p_config, ref int done);


  task automatic _get_config(input chandle config_base, input int offset, output int data);
    data = dut.TOP.CONTROLLER.cfg [offset];
  endtask


  task automatic set_config(input chandle config_base, input int offset, input int data);
    dut.TOP.CONTROLLER.cfg [offset] <= data;
  endtask

byte tmp_byte;
int done = 0;
logic [AXI_WIDTH-1:0] tmp_data;

  always_ff @(posedge clk) begin : Axi_rw

    if (ren) begin
      for (int i = 0; i < AXI_WIDTH/8; i++) begin
        get_byte_a32((32'(raddr) << LSB) + i, tmp_byte);
        tmp_data[i*8 +: 8] = tmp_byte;
      end
      rdata <= tmp_data;
    end

    if (wen) 
      for (int i = 0; i < AXI_WIDTH/8; i++) 
        if (wstrb[i]) 
          set_byte_a32((32'(waddr) << LSB) + i, wdata[i*8 +: 8]);
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
    
    while (done == 0) begin
      run(mem_ptr_virtual, cfg_ptr_virtual, done);
      @(posedge clk) #10ps;
    end
    done = 0;


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