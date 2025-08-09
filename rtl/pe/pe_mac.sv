`timescale 1ns/1ps
`default_nettype none

module pe_mac #(
  parameter int DATA_W = 16,
  parameter int ACC_W  = 32
) (
  input  logic                        clk,
  input  logic                        rst_n,
  input  logic                        en,
  input  logic signed [DATA_W-1:0]    a_in,
  input  logic signed [DATA_W-1:0]    b_in,
  input  logic signed [ACC_W-1:0]     acc_in,
  output logic signed [DATA_W-1:0]    a_out,
  output logic signed [DATA_W-1:0]    b_out,
  output logic signed [ACC_W-1:0]     acc_out
);
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      a_out  <= '0;
      b_out  <= '0;
      acc_out<= '0;
    end else begin
      a_out <= a_in;
      b_out <= b_in;
      if (en) begin
        acc_out <= acc_in + (a_in * b_in);
      end else begin
        acc_out <= acc_in;
      end
    end
  end
endmodule : pe_mac

`default_nettype wire 