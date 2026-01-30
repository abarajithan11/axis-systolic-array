#include <stdint.h>

void run(Memory_st *restrict mp) {

  fb_reg_t *cfg = (fb_reg_t *)CONFIG_BASEADDR;

  fb_write_reg(cfg + A_MM2S_0_ADDR , fb_shorten_ptr(mp->k, mp));
  fb_write_reg(cfg + A_MM2S_0_BYTES, sizeof(mp->k));
  fb_write_reg(cfg + A_MM2S_1_ADDR , fb_shorten_ptr(mp->x, mp));
  fb_write_reg(cfg + A_MM2S_1_BYTES, sizeof(mp->x));
  fb_write_reg(cfg + A_MM2S_2_ADDR , fb_shorten_ptr(mp->a, mp));
  fb_write_reg(cfg + A_MM2S_2_BYTES, sizeof(mp->a));
  fb_write_reg(cfg + A_S2MM_ADDR   , fb_shorten_ptr(mp->y, mp));
  fb_write_reg(cfg + A_S2MM_BYTES  , sizeof(mp->y));
  fb_write_reg(cfg + A_START       , 1);

  while (!fb_read_reg(cfg + A_S2MM_DONE)) {}
}

#ifdef SIM
extern EXT_C void run_sim(Memory_st *restrict mp) {
  FILE *fp;
  char f_path[1000];
  size_t bytes;

  sprintf(f_path, "%s/kxa.bin", DIR);
  fp = fopen(f_path, "rb");
  assert(fp);
  bytes = fread(mp->k, 1, sizeof(mp->k) + sizeof(mp->x) + sizeof(mp->a), fp);
  (void)bytes;
  fclose(fp);

  run(mp);

  sprintf(f_path, "%s/y.bin", DIR);
  fp = fopen(f_path, "wb");
  assert(fp);
  bytes = fwrite(mp->y, 1, sizeof(mp->y), fp);
  (void)bytes;
  fclose(fp);
}
#endif

void randomize_inputs(Memory_st *restrict mp, int seed) {
  srand(seed);

  for (int k=0; k<K; k++)
    for (int c=0; c<C; c++)
      mp->k[k][c] = rand();

  for (int k=0; k<K; k++)
    for (int r=0; r<R; r++)
      mp->x[k][r] = rand();

  for (int c=0; c<C; c++)
    for (int r=0; r<R; r++)
      mp->a[c][r] = rand();
}

void check_output(Memory_st *restrict mp) {
  TY y_exp[C][R];

  for (int c=0; c<C; c++)
    for (int r=0; r<R; r++) {
      int sum = 0;
      for (int k=0; k<K; k++)
        sum += (int)(mp->k[k][c]) * (int)(mp->x[k][r]);
      sum += mp->a[c][r];
      y_exp[c][r] = sum;
    }

  int err = 0;

  for (int c=0; c<C; c++)
    for (int r=0; r<R; r++)
      if (mp->y[c][r] != y_exp[c][r]) {
        err++;
        printf("Mismatch [r:%d,c:%d] y=%d exp=%d\n", r, c, mp->y[c][r], y_exp[c][r]);
      }

  if (!err) printf("All outputs match.\n");
  else      printf("Error count: %d\n", err);
}
