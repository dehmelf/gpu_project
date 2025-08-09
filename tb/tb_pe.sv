`timescale 1ns/1ps
`default_nettype none

module tb_pe;
  localparam int DATA_W = 16;
  localparam int ACC_W  = 32;

  logic clk, rst_n;
  initial begin clk=0; forever #5 clk=~clk; end
  initial begin rst_n=0; repeat(5) @(posedge clk); rst_n=1; end

  logic en;
  logic signed [DATA_W-1:0] a_in, b_in;
  logic signed [ACC_W-1:0] acc_in, acc_out;
  logic signed [DATA_W-1:0] a_out, b_out;

  pe_mac #(.DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
    .clk, .rst_n, .en,
    .a_in, .b_in, .acc_in,
    .a_out, .b_out, .acc_out
  );

  int errors = 0;
  initial begin
    en = 1'b0; a_in = '0; b_in = '0; acc_in = '0;
    @(posedge rst_n);
    for (int i=0;i<100;i++) begin
      automatic int signed ai = $urandom_range(-50,50);
      automatic int signed bi = $urandom_range(-50,50);
      automatic int signed ac = $urandom_range(-1000,1000);
      a_in = ai; b_in = bi; acc_in = ac; en = 1'b1;
      @(posedge clk);
      // check accumulation
      if (acc_out !== (ac + ai*bi)) begin
        $display("ERR: i=%0d exp=%0d got=%0d", i, ac + ai*bi, acc_out);
        errors++;
      end
    end
    if (errors==0) $display("tb_pe PASS"); else $display("tb_pe FAIL: %0d errors", errors);
    $finish;
  end
endmodule

`default_nettype wire 