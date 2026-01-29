#ifndef FB_FW_WRAP_H
#define FB_FW_WRAP_H

#ifndef RISCV
  #include <assert.h>
  #include <stdlib.h>
#endif
#include <limits.h>
#include <stdint.h>

typedef int8_t   i8 ;
typedef int16_t  i16;
typedef int32_t  i32;
typedef int64_t  i64;
typedef uint8_t  u8 ;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float    f32;
typedef double   f64;

#ifdef __cplusplus
  #define EXT_C "C"
  #define restrict __restrict__
#else
  #define EXT_C
#endif

#ifndef REG_WIDTH
  #define REG_WIDTH 32
#endif

#if (REG_WIDTH == 32)
  typedef volatile u32 fb_reg_t;
#elif (REG_WIDTH == 64)
  typedef volatile u64 fb_reg_t;
#else
  #error "REG_WIDTH must be 32 or 64"
#endif

static inline fb_reg_t *fb_get_cfg_p(void) {
  return (fb_reg_t *)(uintptr_t)CONFIG_BASEADDR;
}

extern EXT_C void *fb_get_mem_p(){
  return &mem;
}

#ifdef SIM
  #define XDEBUG
  #include <stdio.h>
  #include <stdbool.h>

  extern EXT_C void fb_task_write_reg(u64 addr, u64 data);
  extern EXT_C void fb_task_read_reg(u64 addr);
  extern EXT_C u64  fb_fn_read_reg(void);

  static inline fb_reg_t fb_read_reg(fb_reg_t *addr) {
    fb_task_read_reg((u64)(uintptr_t)addr);
    return (fb_reg_t)fb_fn_read_reg();
  }

  static inline void fb_write_reg(fb_reg_t *addr, fb_reg_t data) {
    fb_task_write_reg((u64)(uintptr_t)addr, (u64)data);
  }

  static inline void flush_cache(void *addr, uint32_t bytes) { (void)addr; (void)bytes; }

#else
  #define sim_fprintf(...)

  static inline fb_reg_t fb_read_reg(fb_reg_t *addr) {
    return *addr;
  }

  static inline void fb_write_reg(fb_reg_t *addr, fb_reg_t data) {
    *addr = data;
  }

  static inline void flush_cache(void *addr, uint32_t bytes) { (void)addr; (void)bytes; }
#endif

#ifdef XDEBUG
  #define debug_printf printf
  #define assert_printf(v1, op, v2, optional_debug_info,...) ((v1  op v2) || (debug_printf("ASSERT FAILED: \n CONDITION: "), debug_printf("( " #v1 " " #op " " #v2 " )"), debug_printf(", VALUES: ( %d %s %d ), ", v1, #op, v2), debug_printf("DEBUG_INFO: " optional_debug_info), debug_printf(" " __VA_ARGS__), debug_printf("\n\n"), assert(v1 op v2), 0))
#else
  #define assert_printf(...)
  #define debug_printf(...)
#endif

// Rest of the helper functions used in simulation.
#ifdef SIM

extern EXT_C u32 fb_addr_64to32(void* restrict addr){
  u64 offset = (u64)(uintptr_t)addr - (u64)(uintptr_t)&mem;
  return (u32)offset + (u32)0x20000000u;
}

extern EXT_C u64 fb_sim_addr_32to64(u32 addr){
  return (u64)addr - (u64)0x20000000u + (u64)(uintptr_t)&mem;
}

extern EXT_C u8 fb_c_read_ddr8_addr32 (u32 addr_32){
  u64 addr = fb_sim_addr_32to64(addr_32);
  u8 val = *(u8*restrict)(uintptr_t)addr;
  return val;
}

extern EXT_C void fb_c_write_ddr8_addr32 (u32 addr_32, u8 data){
  u64 addr = fb_sim_addr_32to64(addr_32);
  *(u8*restrict)(uintptr_t)addr = data;
}

#else

u32 fb_addr_64to32 (void* addr){
  return (u32)((uintptr_t)addr);
}
#endif

#endif
