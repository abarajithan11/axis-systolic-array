#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop_tb.h"
#include "Vtop_tb_top_tb.h"
#include "Vtop_tb_firebridge_axi__pi1.h"
using namespace std;

vluint64_t sim_time = 0;
Vtop_tb *top_tb_1;
VerilatedContext *contextp;

#ifdef __cplusplus
  #define EXT_C "C"
  #define restrict __restrict__ 
#else
  #define EXT_C
#endif

extern EXT_C void at_posedge_clk(){
    while(true){
        if(top_tb_1->top_tb->clk){
            for (int i = 0; i < 10; i++){
                top_tb_1->eval();
                contextp->timeInc(1);
            }
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_awready(int i){
    while(true){
        int s_axi_awready_i = (top_tb_1->top_tb->FB->s_axi_awready >> i) & 1;
        if(s_axi_awready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_wready(int i){
    while(true){
        int s_axi_wready_i = (top_tb_1->top_tb->FB->s_axi_wready >> i) & 1;
        if(s_axi_wready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_bvalid(int i){
    while(true){
        int s_axi_bvalid_i = (top_tb_1->top_tb->FB->s_axi_bvalid >> i) & 1;
        if(s_axi_bvalid_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_arready(int i){
    while(true){
        int s_axi_arready_i = (top_tb_1->top_tb->FB->s_axi_arready >> i) & 1;
        if(s_axi_arready_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}
extern EXT_C void wait_s_axi_rvalid(int i){
    while(true){
        int s_axi_rvalid_i = (top_tb_1->top_tb->FB->s_axi_rvalid >> i) & 1;
        if(s_axi_rvalid_i){
            break;
        }
        top_tb_1->eval();
        contextp->timeInc(1);
    }
}

int main(int argc, char** argv){
    printf("Beginning\n");

    // initializations for simualtion
    contextp = new VerilatedContext();
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    top_tb_1 = new Vtop_tb(contextp);

    while(!contextp->gotFinish()){
        top_tb_1->eval();
        contextp->timeInc(1);
    }

    printf("End\n");

    delete top_tb_1;
    delete contextp;
    return 0;
}