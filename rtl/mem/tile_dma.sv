`timescale 1ns/1ps
`default_nettype none

module tile_dma #(
  parameter int W      = 16,
  parameter int DEPTH  = 256
) (
  input  logic clk,
  input  logic rst_n,
  // host stream in
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  // BRAM write port
  output logic              bram_we,
  output logic [$clog2(DEPTH)-1:0] bram_waddr,
  output logic [W-1:0]      bram_wdata,
  // control
  input  logic              start_load,
  output logic              load_done,
  output logic              sel_buf // which buffer was filled last
);
  typedef enum logic [1:0] {S_IDLE, S_LOAD, S_DONE} state_e;
  state_e state, nstate;

  logic [$clog2(DEPTH):0] wr_count;
  logic sel_q;

  assign in_ready = (state == S_LOAD);
  assign bram_we = (state == S_LOAD) & in_valid & in_ready;
  assign bram_waddr = wr_count[$clog2(DEPTH)-1:0] + (sel_q ? DEPTH[$clog2(DEPTH)-1:0] : '0);
  assign bram_wdata = in_data;
  assign sel_buf = sel_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE;
      wr_count <= '0;
      sel_q <= 1'b0;
    end else begin
      state <= nstate;
      if (state == S_LOAD && bram_we) begin
        wr_count <= wr_count + 1'b1;
      end else if (state == S_IDLE) begin
        wr_count <= '0;
      end
      if (state == S_DONE) begin
        sel_q <= ~sel_q; // toggle buffer
      end
    end
  end

  always_comb begin
    nstate = state;
    load_done = 1'b0;
    unique case (state)
      S_IDLE: if (start_load) nstate = S_LOAD;
      S_LOAD: if (wr_count == DEPTH-1 && in_valid) nstate = S_DONE;
      S_DONE: begin load_done = 1'b1; nstate = S_IDLE; end
      default: nstate = S_IDLE;
    endcase
  end
endmodule : tile_dma

`default_nettype wire 