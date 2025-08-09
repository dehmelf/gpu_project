`timescale 1ns/1ps
`default_nettype none

module tb_top;
  localparam int N=4; localparam int DATA_W=16; localparam int ACC_W=32;
  logic clk, rst_n; initial begin clk=0; forever #5 clk=~clk; end
  initial begin rst_n=0; repeat(5) @(posedge clk); rst_n=1; end

  // AXI-lite
  logic awvalid; logic [7:0] awaddr; logic wvalid; logic [31:0] wdata; logic bvalid;
  logic arvalid; logic [7:0] araddr; logic rvalid; logic [31:0] rdata;

  // streams
  logic a_valid, a_ready; logic [DATA_W-1:0] a_data;
  logic b_valid, b_ready; logic [DATA_W-1:0] b_data;

  // C readback
  logic                      c_rd_en;
  logic [$clog2(N*N)-1:0]    c_rd_addr;
  logic signed [ACC_W-1:0]   c_rd_data;
  logic done;

  top #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
    .clk, .rst_n,
    .awvalid, .awaddr, .wvalid, .wdata, .bvalid,
    .arvalid, .araddr, .rvalid, .rdata,
    .a_valid, .a_ready, .a_data,
    .b_valid, .b_ready, .b_data,
    .c_rd_en, .c_rd_addr, .c_rd_data,
    .done_o(done)
  );

  // helpers
  task axil_write(input [7:0] addr, input [31:0] data);
    awaddr=addr; wdata=data; awvalid=1; wvalid=1; @(posedge clk); awvalid=0; wvalid=0; @(posedge clk);
  endtask
  function [31:0] axil_read(input [7:0] addr);
    araddr=addr; arvalid=1; @(posedge clk); arvalid=0; @(posedge clk); return rdata;
  endfunction

  // Test matrices (row-major) small 4x4
  int signed A [0:N*N-1];
  int signed B [0:N*N-1];
  int signed Cref [0:N*N-1];

  initial begin
    awvalid=0; wvalid=0; arvalid=0; a_valid=0; b_valid=0; c_rd_en=0; c_rd_addr='0; a_data='0; b_data='0;
    @(posedge rst_n);
    // init A,B
    for (int i=0;i<N*N;i++) begin A[i] = (i%7)-3; B[i] = (i%5)-2; end
    // program dims M=N=K=N
    axil_write(8'h08, N);
    axil_write(8'h0C, N);
    axil_write(8'h10, N);
    // start -> triggers DMA load
    axil_write(8'h00, 32'h1);
    // stream A then B (DEPTH=N*N each)
    for (int i=0;i<N*N;i++) begin
      a_data = A[i]; a_valid=1; while(!a_ready) @(posedge clk); @(posedge clk); a_valid=0; @(posedge clk);
    end
    for (int i=0;i<N*N;i++) begin
      b_data = B[i]; b_valid=1; while(!b_ready) @(posedge clk); @(posedge clk); b_valid=0; @(posedge clk);
    end
    // wait for done
    wait(done==1'b1);
    // compute reference
    for (int i=0;i<N;i++) begin
      for (int j=0;j<N;j++) begin
        int acc=0; for (int k=0;k<N;k++) acc += A[i*N+k]*B[k*N+j]; Cref[i*N+j]=acc;
      end
    end
    // compare C
    int errors=0;
    for (int idx=0; idx<N*N; idx++) begin
      c_rd_addr = idx; c_rd_en = 1'b1; @(posedge clk); c_rd_en=1'b0; @(posedge clk);
      if (c_rd_data !== Cref[idx]) begin
        $display("Mismatch @%0d: got %0d exp %0d", idx, c_rd_data, Cref[idx]); errors++;
      end
    end
    if (errors==0) $display("tb_top PASS"); else $display("tb_top FAIL: %0d errors", errors);
    $finish;
  end
endmodule

`default_nettype wire 