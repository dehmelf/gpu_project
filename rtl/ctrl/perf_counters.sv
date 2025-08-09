`timescale 1ns/1ps
`default_nettype none

module perf_counters (
  input  logic clk,
  input  logic rst_n,
  input  logic start_pulse,
  input  logic done,
  input  logic compute_cycle,
  input  logic stall_cycle,
  output logic [31:0] cycles,
  output logic [31:0] active,
  output logic [31:0] stalls
);
  logic [31:0] cycles_q, active_q, stalls_q;
  assign cycles = cycles_q;
  assign active = active_q;
  assign stalls = stalls_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      cycles_q <= '0; active_q <= '0; stalls_q <= '0;
    end else begin
      if (start_pulse) begin
        cycles_q <= '0; active_q <= '0; stalls_q <= '0;
      end else if (!done) begin
        cycles_q <= cycles_q + 1;
        if (compute_cycle) active_q <= active_q + 1;
        if (stall_cycle)   stalls_q <= stalls_q + 1;
      end
    end
  end
endmodule : perf_counters

`default_nettype wire 