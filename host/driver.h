#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void accel_init(void);
void axil_write(uint8_t addr, uint32_t data);
uint32_t axil_read(uint8_t addr);
void load_tile_A(const int16_t* A, int len);
void load_tile_B(const int16_t* B, int len);
void read_tile_C(int32_t* C, int len);
void accel_start(int m, int n, int k);
int accel_poll_done(void);

#ifdef __cplusplus
}
#endif 