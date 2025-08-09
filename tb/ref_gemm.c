#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void gemm_ref(int M, int N, int K, const int16_t* A, const int16_t* B, int32_t* C) {
  for (int i=0;i<M;i++) {
    for (int j=0;j<N;j++) {
      int32_t acc = 0;
      for (int k=0;k<K;k++) {
        int16_t a = A[i*K + k];
        int16_t b = B[k*N + j];
        acc += (int32_t)a * (int32_t)b;
      }
      C[i*N + j] = acc;
    }
  }
}

#ifdef REF_GEMM_MAIN
int main(int argc, char** argv) {
  int M = 4, N = 4, K = 4;
  int16_t* A = (int16_t*)calloc(M*K, sizeof(int16_t));
  int16_t* B = (int16_t*)calloc(K*N, sizeof(int16_t));
  int32_t* C = (int32_t*)calloc(M*N, sizeof(int32_t));
  for (int i=0;i<M*K;i++) A[i] = (i%7)-3;
  for (int i=0;i<K*N;i++) B[i] = (i%5)-2;
  gemm_ref(M,N,K,A,B,C);
  for (int i=0;i<M;i++) {
    for (int j=0;j<N;j++) printf("%d ", C[i*N+j]);
    printf("\n");
  }
  free(A); free(B); free(C);
  return 0;
}
#endif 