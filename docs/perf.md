### Performance Counters

The top-level exposes three 32-bit counters:
- `cycles`: total cycles from `start` asserted until `done`
- `active`: cycles where compute is active (array enabled)
- `stalls`: cycles where compute is stalled (due to input/output backpressure)

Counters clear on `start` and freeze at `done`.

### GFLOPS Computation

For GEMM with dimensions M×K (A) and K×N (B):

- MACs = M × N × K
- FLOPs = 2 × MACs
- Given:
  - `active_cycles` from counter
  - Clock frequency `f_clk` (Hz)

GFLOPS = (FLOPs / active_cycles) × f_clk / 1e9

If your measurement window includes prologue/epilogue, use `cycles` instead of `active` to reflect end-to-end throughput. 