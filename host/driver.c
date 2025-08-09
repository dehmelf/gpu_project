#include "driver.h"
#include <stdio.h>
#include <string.h>

// In simulation, these are placeholders. Real HW would speak to AXI-lite and streams.
static uint32_t regs[64];
static int16_t bufA[1024];
static int16_t bufB[1024];
static int32_t bufC[1024];

void accel_init(void) {
  memset(regs, 0, sizeof(regs));
}

void axil_write(uint8_t addr, uint32_t data) {
  regs[addr>>2] = data;
}

uint32_t axil_read(uint8_t addr) {
  return regs[addr>>2];
}

void load_tile_A(const int16_t* A, int len) {
  for (int i=0;i<len;i++) bufA[i] = A[i];
}

void load_tile_B(const int16_t* B, int len) {
  for (int i=0;i<len;i++) bufB[i] = B[i];
}

void read_tile_C(int32_t* C, int len) {
  for (int i=0;i<len;i++) C[i] = bufC[i];
}

void accel_start(int m, int n, int k) {
  axil_write(0x08, (uint32_t)m);
  axil_write(0x0C, (uint32_t)n);
  axil_write(0x10, (uint32_t)k);
  axil_write(0x00, 1u);
}

int accel_poll_done(void) {
  return (regs[0] & (1u<<1)) != 0; // placeholder
} 