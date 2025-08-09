# Systolic GEMM Accelerator (FPGA/ASIC)

A small, clean, parameterizable N×N systolic GEMM accelerator monorepo targeting FPGA/ASIC. Written in SystemVerilog-2017 with Verilator-compatible testbenches, a C golden model, simple host driver stubs, CI, and docs.

- Default params: `ARRAY_N=8`, `DATA_W=16` (INT16), `ACC_W=32`
- Formats: `FMT_INT8`, `FMT_INT16`, `FMT_FP16` (FP16 stubbed/TODO)
- Dataflows: `DF_OUT_STATIONARY` (default), `DF_WEIGHT_STATIONARY` (TODO)
- Interfaces: simple ready/valid streams and abstracted AXI-lite-like control regs
- Memory: double-buffered BRAM tiles (modeled), minimal tile DMA shim

## Quickstart (Verilator)

Requirements:
- Verilator (>= 4.x)
- GCC/Clang, Make, Python3 (for scripts)

Build and run smoke tests:

```sh
cd sim
make lint
make sim
```

This builds and runs:
- tb_pe (PE MAC unit test)
- tb_array (4×4 systolic array)
- tb_top (top-level with AXI-lite regs + DMA shims)

On success, each test prints PASS and exits. VCD traces are produced on failure.

## GFLOPS from Counters

Perf counters are exposed via AXI-lite regs (see `docs/interface.md`). To compute GFLOPS for INT16 path:

- MACs per output element = K
- Total MACs = M × N × K
- FLOPs = 2 × MACs
- Active time in cycles = `active` counter
- Frequency (Hz) = your sim/target clock
- GFLOPS = (FLOPs / active_cycles) × freq / 1e9

See `docs/perf.md` for details.

## Layout

- `rtl/` SystemVerilog RTL
- `tb/` testbenches and C golden model
- `sim/Makefile` Verilator build rules
- `scripts/` helpers and smoke runner
- `docs/` microarch, perf, and interfaces
- `host/` simple host driver stubs and example
- `fpga/`, `asic/` stubs for future flows 