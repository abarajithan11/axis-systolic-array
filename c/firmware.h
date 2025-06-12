#include <stdint.h>
#include "config.h"

typedef struct {
  TK k [K][C];
  TX x [K][R];
  TY a [C][R];
  TY y [C][R];
} Memory_st;

#define MEM_BASEADDR    0x20000000
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

#include "wrapper.h"

extern EXT_C void run(Memory_st *restrict mp, void *p_config, int *done) {
 
  #ifdef SIM // only read/write files in simulation
    FILE *fp;
    char f_path [1000];
    int bytes;

    WAIT_INIT(DMA_WAIT);

    sprintf(f_path, "%s/kxa.bin", DIR);
    fp = fopen(f_path, "rb");
    debug_printf("DEBUG: Reading from file %s \n", f_path);
    if(!fp) debug_printf("ERROR! File not found: %s \n", f_path);
    bytes = fread(mp->k, 1, sizeof(mem_phy.k) + sizeof(mem_phy.x) + sizeof(mem_phy.a), fp);
    fclose(fp);
  #endif
  
  // Start DMA
  set_config(p_config, A_MM2S_0_ADDR , addr_64to32(mem_phy.k));
  set_config(p_config, A_MM2S_0_BYTES,      sizeof(mem_phy.k));
  set_config(p_config, A_MM2S_1_ADDR , addr_64to32(mem_phy.x));
  set_config(p_config, A_MM2S_1_BYTES,      sizeof(mem_phy.x));
  set_config(p_config, A_MM2S_2_ADDR , addr_64to32(mem_phy.a));
  set_config(p_config, A_MM2S_2_BYTES,      sizeof(mem_phy.a));
  set_config(p_config, A_S2MM_ADDR   , addr_64to32(mem_phy.y));
  set_config(p_config, A_S2MM_BYTES  ,      sizeof(mem_phy.y));
  set_config(p_config, A_START       , 1);  // Start


  WAIT(!(get_config(p_config, A_S2MM_DONE)), DMA_WAIT);

  #ifdef SIM
    sprintf(f_path, "%s/y.bin", DIR);
    fp = fopen(f_path, "wb");
    debug_printf("DEBUG: Writing to file %s \n", f_path);
    if(!fp) debug_printf("ERROR! File not found: %s \n", f_path);
    bytes = fwrite(mp->y, 1, sizeof(mem_phy.y), fp);
    fclose(fp);
  #endif
  *done = 1;
}


void randomize_inputs(Memory_st *restrict mp, int seed){
  srand(seed);

  for (int k=0; k<K; k++)
    for (int c=0;c<C; c++)
      mp->k[k][c] = rand();

  for (int k=0; k<K; k++)
    for (int r=0;r<R; r++)
      mp->x[k][r] = rand();

  for (int c=0; c<C; c++)
    for (int r=0;r<R; r++)
      mp->a[c][r] = rand();
}

void check_output(Memory_st *restrict mp){

  TY y_exp [C][R];

  for (int c=0; c<C; c++)
    for (int r=0; r<R; r++){
      int sum = 0;
      for (int k=0; k<K; k++)
        sum += (int)(mp->k[k][c]) * (int)(mp->x[k][r]);
      sum += mp->a[c][r];
      y_exp[c][r] = sum;
    }

  int error = 0;

  for (int c=0; c<C; c++)
    for (int r=0; r<R; r++)
      if (mp->y[c][r] != y_exp[c][r]){
        error += 1;
        printf("Output does not match at [r:%d,c:%d]. y=%d, y_exp=%d\n", r,c,mp->y[c][r], y_exp[c][r]);
      } else {
        printf("Outputs match at [r:%d,c:%d]. y=%d, y_exp=%d\n", r,c,mp->y[c][r], y_exp[c][r]);
      }

  printf("All outputs match. Error count: %d \n", error);
}
