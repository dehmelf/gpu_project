`timescale 1ns/1ps
`default_nettype none

interface stream_if #(
  parameter int W = 32
) (
  input  logic clk,
  input  logic rst_n
);
  logic         valid;
  logic         ready;
  logic [W-1:0] data;

  // Producer drives valid/data, observes ready
  modport prod (
    input  ready,
    output valid,
    output data
  );

  // Consumer drives ready, observes valid/data
  modport cons (
    input  valid,
    input  data,
    output ready
  );
endinterface : stream_if

`default_nettype wire 