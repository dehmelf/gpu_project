#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include "../driver.h"

static void gen(int16_t* A, int len) { for (int i=0;i<len;i++) A[i] = (i%7)-3; }

int main() {
  int N=4; int M=N, K=N;
  int16_t* A = (int16_t*)calloc(M*K, sizeof(int16_t));
  int16_t* B = (int16_t*)calloc(K*N, sizeof(int16_t));
  int32_t* C = (int32_t*)calloc(M*N, sizeof(int32_t));

  gen(A, M*K); gen(B, K*N);
  accel_init();
  load_tile_A(A, M*K); load_tile_B(B, K*N);
  accel_start(M,N,K);
  while(!accel_poll_done()) { /* spin */ }
  read_tile_C(C, M*N);
  printf("Done. (GFLOPS calc via counters TBD in example)\n");
  free(A); free(B); free(C);
  return 0;
} 