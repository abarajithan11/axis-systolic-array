#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#if VM_TRACE
  #if VM_TRACE_FST
  #include <verilated_fst_c.h>
  #else
  #include <verilated_vcd_c.h>
  #endif
#endif

// TB_MODULE and FB_MODULE are defined from outside via -D option

#define STR1(x) #x
#define STR(x)  STR1(x)
#define CAT(a,b)  a##b
#define XCAT(a,b) CAT(a,b)

// Build V<tb>.h
#define VTB(tb) XCAT(V, tb)
#define VTB_H(tb) STR(VTB(tb).h)
#include VTB_H(TB_MODULE)

#define VCLASS XCAT(V, TB_MODULE)

using namespace std;

#ifndef CLK_HALF_TS
#define CLK_HALF_TS 5
#endif

vluint64_t sim_time = 0;
VCLASS *top;
VerilatedContext *contextp;
#if VM_TRACE
  #if VM_TRACE_FST
  VerilatedFstC *tfp;
  #else
  VerilatedVcdC *tfp;
  #endif
#endif

#ifdef __cplusplus
  #define EXT_C "C"
  #define restrict __restrict__ 
#else
  #define EXT_C
#endif

// Below are helper functions to pass time inside SV

extern "C" unsigned char get_clk();

extern "C" void step_time_veri() {
    top->eval();
#if VM_TRACE
    tfp->dump(contextp->time());
#endif
    contextp->timeInc(CLK_HALF_TS);
}

extern "C" void at_posedge_clk(){
    vluint8_t prev_clk = get_clk();
    while(true){
        step_time_veri();
        if(prev_clk == 0 && get_clk() == 1) break;
        prev_clk = get_clk();
    }
}



int main(int argc, char** argv){

    contextp = new VerilatedContext();
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    top = new VCLASS(contextp);
#if VM_TRACE
  #if VM_TRACE_FST
    tfp = new VerilatedFstC();
    top->trace(tfp, 99);
    tfp->open("trace.fst");
  #else
    tfp = new VerilatedVcdC();
    top->trace(tfp, 99);
    tfp->open("trace.vcd");
  #endif
#endif

    while(!contextp->gotFinish()) step_time_veri();

#if VM_TRACE
    tfp->close();
    delete tfp;
#endif
    delete top;
    delete contextp;
    return 0;
}
