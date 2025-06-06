#include <assert.h>
#include <stdlib.h>
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

#ifdef SIM
  #define XDEBUG
  #include <stdio.h>
  #define sim_fprintf fprintf
  #include <stdbool.h>
  #define STRINGIFY(x) #x
  #define TO_STRING(x) STRINGIFY(x)

  Memory_st mem_phy;
  extern EXT_C void set_config(void*, u32, u32);
	extern EXT_C void _get_config(void*, u32, u32*);
	u32 get_config(void* base, u32 offset){
    u32 data = 0;
    _get_config(base, offset, &data);
    return data;
  }
  static inline void flush_cache(void *addr, uint32_t bytes) {} // Do nothing

#else
  #define sim_fprintf(...)
  #define mem_phy (*(Memory_st* restrict)MEM_BASEADDR)

  volatile u32 get_config(void *config_base, u32 offset){
    return *(volatile u32 *)(config_base + offset*4);
  }

  void set_config(void *config_base, u32 offset, u32 data){	
    *(volatile u32 *restrict)(config_base + offset*4) = data;
  }
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

extern EXT_C u32 addr_64to32(void* restrict addr){
  u64 offset = (u64)addr - (u64)&mem_phy;
  return (u32)offset + MEM_BASEADDR;
}

extern EXT_C u64 sim_addr_32to64(u32 addr){
  return (u64)addr - (u64)MEM_BASEADDR + (u64)&mem_phy;
}

extern EXT_C void get_byte_a32 (u32 addr_32, u8* data){
  u64 addr = sim_addr_32to64(addr_32);
  u8 val = *(u8*restrict)addr;
  //debug_printf("get_byte_a32: addr32:0x%x, addr64:0x%lx, val:0x%x\n", addr_32, addr, val);
  *data = val;
}

extern EXT_C void set_byte_a32 (u32 addr_32, u8 data){
  u64 addr = sim_addr_32to64(addr_32);
  *(u8*restrict)addr = data;
}

extern EXT_C void *get_mp(){
  return &mem_phy;
}
#else

u32 addr_64to32 (void* addr){
  return (u32)((u64)addr);
}
#endif

// Wait loop
#ifdef SIM
  #define WAIT_INIT(label) \
    static char label##_is_first_call = 1; \
    if (label##_is_first_call) label##_is_first_call = 0; \
    else goto label;

  // if sim, return. so SV can pass time, and call again, which will jump to DMA_WAIT again
  #define WAIT(cond, LABEL) do { \
      LABEL: \
      if (cond) return 1; \
    } while(0)
#else
  #define WAIT_INIT(...)
  // if FPGA, run a while loop
  #define WAIT(cond, LABEL) do { \
      while (cond) {} \
    } while(0)
#endif