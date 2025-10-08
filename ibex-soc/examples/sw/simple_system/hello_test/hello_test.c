// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "simple_system_common.h"
#include <stdarg.h>
#include <stdint.h>

#include "firmware_helpers.h"
#include "firmware.h"

int main(int argc, char **argv) {
  pcount_enable(0);
  pcount_reset();
  pcount_enable(1);

  int done;
  volatile uint32_t * const cfg = (volatile uint32_t *)CONFIG_BASEADDR;
  Memory_st *p_mem = &mem_phy;
  
  
  // Test read/write to config regs
  volatile uint32_t * const p_addr = &cfg[A_MM2S_0_ADDR];
  puts("Addr:"); puthex((uintptr_t)p_addr); putchar('\n');
  *p_addr = 123u;
  puthex(0xDEADBEEF); putchar('\n');
  uint32_t val = *p_addr;
  puts("Val:"); puthex(val); putchar('\n');

  // Run the test
  randomize_inputs(p_mem, 500);
  run(p_mem, (void*)cfg, &done);
  check_output(p_mem);

  pcount_enable(0);
  return 0;
}
