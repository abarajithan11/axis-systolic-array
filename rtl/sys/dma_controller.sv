`timescale 1ns/1ps

module dma_controller #(
  parameter
    AXI_ADDR_WIDTH     = 32  ,
    AXI_DATA_WIDTH     = 32  ,
    AXIS_USER_WIDTH    = 65  ,
    AXI_LEN_WIDTH      = 32  ,
    AXI_TAG_WIDTH      = 8   ,
  
  localparam 
    DESC_WIDTH = AXI_ADDR_WIDTH + AXI_LEN_WIDTH
)(
  input  logic clk,
  input  logic rstn,

  // SRAM port
  // (* mark_debug = "true" *) 
  input  logic reg_wr_en, reg_rd_en,
  input  logic [AXI_ADDR_WIDTH-1:0] reg_wr_addr, reg_rd_addr,
  input  logic [AXI_DATA_WIDTH-1:0] reg_wr_data,
  output logic [AXI_DATA_WIDTH-1:0] reg_rd_data,

  // S2MM descriptor
  output logic [DESC_WIDTH    -1:0]  s2mm_desc ,
  output logic [AXI_TAG_WIDTH -1:0]  s2mm_tag  ,
  output logic                       s2mm_valid,
  input  logic                       s2mm_ready,
  input  logic  [3:0]                s2mm_status_error,
  input  logic                       s2mm_status_valid,

  // MM2S_0 descriptor
  output logic [DESC_WIDTH     -1:0] mm2s_0_desc,
  output logic [AXIS_USER_WIDTH-1:0] mm2s_0_user ,
  output logic                       mm2s_0_valid,
  input  logic                       mm2s_0_ready,
  input  logic  [3:0]                mm2s_0_status_error,
  input  logic                       mm2s_0_status_valid,
  // MM2S_1 descriptor
  output logic [DESC_WIDTH     -1:0] mm2s_1_desc,
  output logic [AXIS_USER_WIDTH-1:0] mm2s_1_user ,
  output logic                       mm2s_1_valid,
  input  logic                       mm2s_1_ready,
  input  logic  [3:0]                mm2s_1_status_error,
  input  logic                       mm2s_1_status_valid,
  // MM2S_2 descriptor
  output logic [DESC_WIDTH     -1:0] mm2s_2_desc,
  output logic [AXIS_USER_WIDTH-1:0] mm2s_2_user ,
  output logic                       mm2s_2_valid,
  input  logic                       mm2s_2_ready,
  input  logic  [3:0]                mm2s_2_status_error,
  input  logic                       mm2s_2_status_valid
);

  // Register 

  localparam 
    A_START       = 'h0,

    A_MM2S_0_DONE = 'h1,
    A_MM2S_0_ADDR = 'h2,
    A_MM2S_0_BYTES= 'h3,
    A_MM2S_0_TUSER= 'h4,
    
    A_MM2S_1_DONE = 'h5,
    A_MM2S_1_ADDR = 'h6,
    A_MM2S_1_BYTES= 'h7,
    A_MM2S_1_TUSER= 'h8,
    
    A_MM2S_2_DONE = 'h9,
    A_MM2S_2_ADDR = 'hA,
    A_MM2S_2_BYTES= 'hB,
    A_MM2S_2_TUSER= 'hC,
    
    A_S2MM_DONE   = 'hD,
    A_S2MM_ADDR   = 'hE,
    A_S2MM_BYTES  = 'hF
    ;
  logic [15:0][AXI_DATA_WIDTH-1:0] cfg ;

  // For debug
  wire [AXI_DATA_WIDTH-1:0] cfg_START        = cfg[A_START       ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_0_DONE  = cfg[A_MM2S_0_DONE ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_0_ADDR  = cfg[A_MM2S_0_ADDR ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_0_BYTES = cfg[A_MM2S_0_BYTES];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_0_TUSER = cfg[A_MM2S_0_TUSER];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_1_DONE  = cfg[A_MM2S_1_DONE ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_1_ADDR  = cfg[A_MM2S_1_ADDR ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_1_BYTES = cfg[A_MM2S_1_BYTES];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_1_TUSER = cfg[A_MM2S_1_TUSER];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_2_DONE  = cfg[A_MM2S_2_DONE ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_2_ADDR  = cfg[A_MM2S_2_ADDR ];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_2_BYTES = cfg[A_MM2S_2_BYTES];
  wire [AXI_DATA_WIDTH-1:0] cfg_MM2S_2_TUSER = cfg[A_MM2S_2_TUSER];
  wire [AXI_DATA_WIDTH-1:0] cfg_S2MM_DONE    = cfg[A_S2MM_DONE   ];
  wire [AXI_DATA_WIDTH-1:0] cfg_S2MM_ADDR    = cfg[A_S2MM_ADDR   ];
  wire [AXI_DATA_WIDTH-1:0] cfg_S2MM_BYTES   = cfg[A_S2MM_BYTES  ];

  assign reg_rd_data = cfg[reg_rd_addr];
  
  // MM2S_0 Controller
  logic mm2s_0_done;
  logic [AXI_ADDR_WIDTH-1:0] mm2s_0_addr;
  logic [AXI_LEN_WIDTH -1:0] mm2s_0_len ;

  always_comb begin 
    mm2s_0_addr  = cfg[A_MM2S_0_ADDR];
    mm2s_0_user  = AXIS_USER_WIDTH'(cfg[A_MM2S_0_TUSER]);
    mm2s_0_len   = cfg[A_MM2S_0_BYTES];
    mm2s_0_valid = 1'(cfg[A_START]) && s2mm_ready;
    mm2s_0_done  = mm2s_0_status_valid && (mm2s_0_status_error == 4'b0);
    mm2s_0_desc  = {mm2s_0_len, mm2s_0_addr};
  end
  
  // MM2S_1 Controller
  logic mm2s_1_done;
  logic [AXI_ADDR_WIDTH-1:0] mm2s_1_addr;
  logic [AXI_LEN_WIDTH -1:0] mm2s_1_len ;

  always_comb begin 
    mm2s_1_addr  = cfg[A_MM2S_1_ADDR];
    mm2s_1_user  = AXIS_USER_WIDTH'(cfg[A_MM2S_1_TUSER]);
    mm2s_1_len   = cfg[A_MM2S_1_BYTES];
    mm2s_1_valid = 1'(cfg[A_START]) && s2mm_ready;
    mm2s_1_done  = mm2s_1_status_valid && (mm2s_1_status_error == 4'b0);
    mm2s_1_desc  = {mm2s_1_len, mm2s_1_addr};
  end
  
  // MM2S_2 Controller
  logic mm2s_2_done;
  logic [AXI_ADDR_WIDTH-1:0] mm2s_2_addr;
  logic [AXI_LEN_WIDTH -1:0] mm2s_2_len ;

  always_comb begin 
    mm2s_2_addr  = cfg[A_MM2S_2_ADDR];
    mm2s_2_user  = AXIS_USER_WIDTH'(cfg[A_MM2S_2_TUSER]);
    mm2s_2_len   = cfg[A_MM2S_2_BYTES];
    mm2s_2_valid = 1'(cfg[A_START]) && s2mm_ready;
    mm2s_2_done  = mm2s_2_status_valid && (mm2s_2_status_error == 4'b0);
    mm2s_2_desc  = {mm2s_2_len, mm2s_2_addr};
  end

  // S2MM Controller
  logic s2mm_done;
  logic [AXI_ADDR_WIDTH-1:0] s2mm_addr;
  logic [AXI_LEN_WIDTH -1:0] s2mm_len ;

  always_comb begin 
    s2mm_addr  = cfg[A_S2MM_ADDR];
    s2mm_len   = cfg[A_S2MM_BYTES];
    s2mm_valid = 1'(cfg[A_START]) && mm2s_0_ready;
    s2mm_done  = s2mm_status_valid && (s2mm_status_error == 4'b0);
    s2mm_desc  = {s2mm_len, s2mm_addr};
  end

  always_ff @(posedge clk) // All cfg written in this always block
    if (!rstn) cfg <= '0;
    else begin
      if (mm2s_0_done)
        cfg[A_MM2S_0_DONE] <= 1;
      if (mm2s_1_done)
        cfg[A_MM2S_1_DONE] <= 1;
      if (mm2s_2_done)
        cfg[A_MM2S_2_DONE] <= 1;

      if (s2mm_done)
        cfg[A_S2MM_DONE] <= 1;
      if (cfg[A_START][0] && s2mm_ready && mm2s_0_ready && mm2s_1_ready && mm2s_2_ready) 
        cfg[A_START] <= 0; // written by PS after all config, stays high for only 1 clock

      if (reg_wr_en) // PS has priority in writing to registers
        cfg[reg_wr_addr] <= reg_wr_data;
    end
endmodule
