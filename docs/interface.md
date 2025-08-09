### AXI-lite-like Register Map (abstracted)

Base address 0x0000 (word addresses):

- 0x00 CTRL: [0] start (W1S), [1] done (RO), [3:2] dataflow, [5:4] fmt
- 0x04 STATUS: [31:0] reserved (RO)
- 0x08 M (rows of A/C)
- 0x0C N (cols of B/C)
- 0x10 K (cols of A / rows of B)
- 0x14 cycles (RO)
- 0x18 active (RO)
- 0x1C stalls (RO)

Start is write-one-to-start; `done` is RO and deasserts on next `start`.

### Tile Format

- Row-major order
- A tile: M×K elements
- B tile: K×N elements
- C tile: M×N elements
- Element packing: LSB-aligned, sign-extended in MAC path

### Streaming Interfaces

- Ready/valid protocol with `data[W-1:0]`
- Producer drives `valid` and holds data until `ready`
- Consumer asserts `ready` when able to accept

For array edges:
- West A ports: N independent streams of rows
- North B ports: N independent streams of columns
- South C ports: N streams of partial sums (row-wise) 