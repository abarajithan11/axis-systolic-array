#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define STR1(x) #x
#define STR(x)  STR1(x)
#define CAT(a,b)  a##b
#define XCAT(a,b) CAT(a,b)

// Build V<tb>.h
#define VTB(tb) XCAT(V, tb)
#define VTB_H(tb) STR(VTB(tb).h)
#include VTB_H(TB_MODULE)

// Build V<tb>_<tb>.h
#define VTB_TB(tb) V##tb##_##tb
#define VTB_TB_H(tb) STR(VTB_TB(tb).h)
#include VTB_TB_H(TB_MODULE)

// Build V<tb>_firebridge_axi__pi1.h
#define VTB_FIREBRIDGE(tb) V##tb##_firebridge_axi__pi1
#define VTB_FIREBRIDGE_H(tb) STR(VTB_FIREBRIDGE(tb).h)
#include VTB_FIREBRIDGE_H(TB_MODULE)

#define VCLASS XCAT(V, TB_MODULE)

using namespace std;

vluint64_t sim_time = 0;
VCLASS *top_tb_1;
VerilatedContext *contextp;

#ifdef __cplusplus
  #define EXT_C "C"
  #define restrict __restrict__ 
#else
  #define EXT_C
#endif

// Below are helper function for axi_write and axia_read inside firebridge_axi.sv 
extern EXT_C void at_posedge_clk(){
    vluint8_t prev_clk = top_tb_1->TB_MODULE->clk;
    while(true){
        top_tb_1->eval();
        contextp->timeInc(1);

        if(prev_clk == 0 && top_tb_1->TB_MODULE->clk == 1){
            for (int i = 0; i < 10; i++){
                top_tb_1->eval();
                contextp->timeInc(1);
            }
            break;
        }
        prev_clk = top_tb_1->TB_MODULE->clk;
    }
}
extern EXT_C void wait_s_axi_awready(int i){
    while(true){
        int s_axi_awready_i = (top_tb_1->TB_MODULE->FB->s_axi_awready >> i) & 1;
        if(s_axi_awready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_wready(int i){
    while(true){
        int s_axi_wready_i = (top_tb_1->TB_MODULE->FB->s_axi_wready >> i) & 1;
        if(s_axi_wready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_bvalid(int i){
    while(true){
        int s_axi_bvalid_i = (top_tb_1->TB_MODULE->FB->s_axi_bvalid >> i) & 1;
        if(s_axi_bvalid_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_arready(int i){
    while(true){
        int s_axi_arready_i = (top_tb_1->TB_MODULE->FB->s_axi_arready >> i) & 1;
        if(s_axi_arready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_rvalid(int i){
    while(true){
        int s_axi_rvalid_i = (top_tb_1->TB_MODULE->FB->s_axi_rvalid >> i) & 1;
        if(s_axi_rvalid_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}



int main(int argc, char** argv){

    // initializations for simualtion
    contextp = new VerilatedContext();
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    top_tb_1 = new VCLASS(contextp);

    while(!contextp->gotFinish()){
        top_tb_1->eval();
        contextp->timeInc(1);
    }

    delete top_tb_1;
    delete contextp;
    return 0;
}