`timescale 1ns/1ps
`default_nettype none

module tb_array;
  localparam int N=4; localparam int DATA_W=16; localparam int ACC_W=32;
  logic clk, rst_n; initial begin clk=0; forever #5 clk=~clk; end
  initial begin rst_n=0; repeat(5) @(posedge clk); rst_n=1; end

  logic en;
  logic signed [DATA_W-1:0] a_west [N];
  logic signed [DATA_W-1:0] b_north[N];
  logic                     a_v[N], a_r[N];
  logic                     b_v[N], b_r[N];
  logic signed [ACC_W-1:0]  c_south[N];
  logic                     c_v[N], c_r[N];

  for (genvar i=0;i<N;i++) assign c_r[i]=1'b1;

  systolic_array #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
    .clk, .rst_n, .en,
    .a_west(a_west), .a_valid(a_v), .a_ready(a_r),
    .b_north(b_north), .b_valid(b_v), .b_ready(b_r),
    .c_south(c_south), .c_valid(c_v), .c_ready(c_r)
  );

  initial begin
    en = 1'b0;
    for (int i=0;i<N;i++) begin a_west[i]='0; b_north[i]='0; a_v[i]=0; b_v[i]=0; end
    @(posedge rst_n);
    en = 1'b1;
    // feed simple patterns for a few cycles
    for (int t=0;t<8;t++) begin
      for (int i=0;i<N;i++) begin
        a_west[i] = i + t;
        b_north[i]= (i==0)? 1 : 0; // simple impulse on column 0
        a_v[i] = 1'b1; b_v[i] = 1'b1;
      end
      @(posedge clk);
    end
    for (int i=0;i<N;i++) begin a_v[i]=0; b_v[i]=0; end
    repeat(10) @(posedge clk);
    $display("tb_array PASS (smoke)");
    $finish;
  end
endmodule

`default_nettype wire 