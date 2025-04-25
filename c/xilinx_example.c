#include "platform.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xil_sleeptimer.h"
#include "xil_mmu.h"
#include "sleep.h"

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>

static inline void flush_cache(void *addr, uint32_t bytes) {
  Xil_DCacheFlushRange((INTPTR)addr, bytes);
}

#include "firmware.h"

XTime time_start, time_end;
#define NUM_EXP 100

int main()
{
  init_platform();

  // For baremetal, give physical address
  Memory_st *p_mem = (Memory_st *)MEM_BASEADDR;
  void *p_config = (void *)CONFIG_BASEADDR;
  // For linux, give virtual address
  // Memory_st *p_mem = (Memory_st *)mmap(NULL, sizeof(Memory_st), PROT_READ | PROT_WRITE, MAP_SHARED, dh, MEM_BASEADDR);
  // void *p_config = mmap(NULL, 4*16+N_BUNDLES*32, PROT_READ | PROT_WRITE, MAP_SHARED, dh, CONFIG_BASEADDR);

  xil_printf("Hello! Config:%p, Mem:%p\n", p_config, p_mem);

  randomize_inputs(p_mem, 500);
  printf("Starting %d runs...\n", NUM_EXP);
  XTime_GetTime(&time_start);

  for (int i=0; i<NUM_EXP; i++){
    flush_cache(p_mem->k, sizeof(p_mem->k)+sizeof(p_mem->x)+sizeof(p_mem->a));
    run(p_mem, p_config);
    flush_cache(p_mem->y, sizeof(p_mem->y));
    usleep(0);
  }
  XTime_GetTime(&time_end);
  printf("Done. Total time taken: %ld us\n", (1000000*(time_end-time_start))/COUNTS_PER_SECOND);

  check_output(p_mem);

  cleanup_platform();
  return 0;
}
