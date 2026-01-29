#include "simple_system_common.h"
#include <stdarg.h>
#include <stdint.h>
#include "firmware_helpers.h"

#include "config.h"

Memory_st mem;

#include "fb_fw_wrap.h"
#include "firmware.h"

int main(int argc, char **argv) {
  pcount_enable(0);
  pcount_reset();
  pcount_enable(1);

  fb_reg_t *cfg = fb_get_cfg_p();

  fb_reg_t *p_addr = cfg + A_MM2S_0_ADDR;
  puts("Addr:"); puthex((uintptr_t)p_addr); putchar('\n');

  fb_write_reg(p_addr, (fb_reg_t)123u);

  fb_reg_t val = fb_read_reg(p_addr);
  puts("Val:"); puthex((uintptr_t)val); putchar('\n');

  randomize_inputs(&mem, 500);
  run(&mem);
  check_output(&mem);

  pcount_enable(0);
  return 0;
}
