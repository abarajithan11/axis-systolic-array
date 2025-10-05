// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "simple_system_common.h"

#define R               4
#define C               8
#define K               8
#define TK              int8_t
#define TX              int8_t
#define TY              int32_t
#define CONFIG_BASEADDR 0x40000

#define A_START         0x0
#define A_MM2S_0_DONE   0x1
#define A_MM2S_0_ADDR   0x2
#define A_MM2S_0_BYTES  0x3
#define A_MM2S_0_TUSER  0x4
#define A_MM2S_1_DONE   0x5
#define A_MM2S_1_ADDR   0x6
#define A_MM2S_1_BYTES  0x7
#define A_MM2S_1_TUSER  0x8
#define A_MM2S_2_DONE   0x9
#define A_MM2S_2_ADDR   0xA
#define A_MM2S_2_BYTES  0xB
#define A_MM2S_2_TUSER  0xC
#define A_S2MM_DONE     0xD
#define A_S2MM_ADDR     0xE
#define A_S2MM_BYTES    0xF

#include "sa.h"

int main(int argc, char **argv) {
  pcount_enable(0);
  pcount_reset();
  pcount_enable(1);

  puts("My name is Aba\n");
  puthex(0xDEADBEEF); putchar('\n');
  puthex(0xBAADF00D); putchar('\n');
  
  volatile uint32_t * const cfg = (volatile uint32_t *)CONFIG_BASEADDR;
  volatile uint32_t * const p_addr = &cfg[A_MM2S_0_ADDR];
  
  puts("Addr:"); puthex((uintptr_t)p_addr); putchar('\n');
  *p_addr = 123u;
  puthex(0xDEADBEEF); putchar('\n');
  uint32_t val = *p_addr;
  puts("Val:"); puthex(val); putchar('\n');

  int done;
  Memory_st *p_mem = &mem_phy;
  randomize_inputs(p_mem, 500);
  run(p_mem, (void*)cfg, &done);
  check_output(p_mem);

  pcount_enable(0);

  // Enable periodic timer interrupt
  // (the actual timebase is a bit meaningless in simulation)
  timer_enable(2000);

  uint64_t last_elapsed_time = get_elapsed_time();

  while (last_elapsed_time <= 4) {
    uint64_t cur_time = get_elapsed_time();
    if (cur_time != last_elapsed_time) {
      last_elapsed_time = cur_time;

      if (last_elapsed_time & 1) {
        puts("Tick!\n");
      } else {
        puts("Tock!\n");
      }
    }
    asm volatile("wfi");
  }

  return 0;
}
