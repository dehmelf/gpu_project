### Microarchitecture Overview

The accelerator implements an N×N systolic array of processing elements (PEs) to compute C = A × B. Data streams in along the west (rows of A) and north (columns of B) edges. Each PE performs a multiply-accumulate (MAC) and forwards operands east/south.

- **Default dataflow**: out-stationary (partial sums are held in place as operands flow through). Weight-stationary is a TODO.
- **Formats**: INT8/INT16 supported; FP16 path is stubbed as a TODO.

### PE Datapath

- Inputs: `a_in`, `b_in`, `acc_in`
- Operation: `acc_out = acc_in + sign_extend(a_in) * sign_extend(b_in)`
- Pass-through: `a_out=a_in`, `b_out=b_in`
- Enable `en` gates the accumulation

### Array Wiring

- West edge has N input streams for A rows
- North edge has N input streams for B columns
- South edge produces N output streams of partial sums for C rows

### Pipeline Prologue/Epilogue

- Prologue latency ≈ 2N cycles to fill the array (A sweeps east, B sweeps south)
- Steady-state: 1 operand pair per PE per cycle (no bubbles) if inputs are continuously valid and outputs are ready
- Epilogue drains over ≈ 2N cycles after last inputs

A minimal valid/ready propagation is implemented; exact corner cases (e.g., backpressure deep in the array) are simplified with TODO markers for future refinement. 