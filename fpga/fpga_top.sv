`timescale 1ns/1ps
`default_nettype none

module fpga_top (
  input  logic clk,
  input  logic rst_n
  // TODO: vendor-specific I/Os (AXI, DDR, etc.)
);
  // Stub wiring for synthesis later
  // TODO: Map AXI-lite and streams to platform interfaces
  // This module intentionally left minimal for now.
endmodule : fpga_top

`default_nettype wire 