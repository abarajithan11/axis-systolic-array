#include "platform.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xtime_l.h"
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

int main() {
  init_platform();

  Memory_st *p_mem = fb_get_mem_p();
  void *p_cfg = (void *)fb_get_cfg_p();

  xil_printf("Hello! Config:%p, Mem:%p\n", p_cfg, p_mem);

  randomize_inputs(p_mem, 500);
  printf("Starting %d runs...\n", NUM_EXP);
  XTime_GetTime(&time_start);

  for (int i=0; i<NUM_EXP; i++) {
    flush_cache(p_mem->k, sizeof(p_mem->k) + sizeof(p_mem->x) + sizeof(p_mem->a));
    run(p_mem);
    flush_cache(p_mem->y, sizeof(p_mem->y));
    usleep(0);
  }

  XTime_GetTime(&time_end);
  printf("Done. Total time taken: %ld us\n",
         (long)((1000000ULL * (time_end - time_start)) / COUNTS_PER_SECOND));

  check_output(p_mem);

  cleanup_platform();
  return 0;
}
