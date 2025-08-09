`timescale 1ns/1ps
`default_nettype none

module tile_bram #(
  parameter int W     = 32,
  parameter int DEPTH = 1024
) (
  input  logic              clk,
  // write port
  input  logic              we,
  input  logic [$clog2(DEPTH)-1:0] waddr,
  input  logic [W-1:0]      wdata,
  // read port
  input  logic              re,
  input  logic [$clog2(DEPTH)-1:0] raddr,
  output logic [W-1:0]      rdata
);
  logic [W-1:0] mem [0:DEPTH-1];
  logic [W-1:0] rdata_q;

  always_ff @(posedge clk) begin
    if (we) begin
      mem[waddr] <= wdata;
    end
    if (re) begin
      rdata_q <= mem[raddr];
    end
  end
  assign rdata = rdata_q;
endmodule : tile_bram

`default_nettype wire 