`timescale 1ns/1ps
`default_nettype none

`include "ctrl/cfg_pkg.sv"

module top #(
  parameter int N       = cfg_pkg::ARRAY_N,
  parameter int DATA_W  = cfg_pkg::DATA_W,
  parameter int ACC_W   = cfg_pkg::ACC_W,
  parameter int TILE_K  = N // simplified: K=N for smoke test
) (
  input  logic clk,
  input  logic rst_n,
  // AXI-lite-like
  input  logic        awvalid,
  input  logic [7:0]  awaddr,
  input  logic        wvalid,
  input  logic [31:0] wdata,
  output logic        bvalid,
  input  logic        arvalid,
  input  logic [7:0]  araddr,
  output logic        rvalid,
  output logic [31:0] rdata,
  // host streams for A and B tiles
  input  logic              a_valid,
  output logic              a_ready,
  input  logic [DATA_W-1:0] a_data,
  input  logic              b_valid,
  output logic              b_ready,
  input  logic [DATA_W-1:0] b_data,
  // C readback port for sim
  input  logic                      c_rd_en,
  input  logic [$clog2(N*N)-1:0]    c_rd_addr,
  output logic signed [ACC_W-1:0]   c_rd_data,
  output logic                      done_o
);
  import cfg_pkg::*;

  // regs
  logic        start_pulse;
  logic [15:0] m, n, k;
  logic [1:0]  dataflow, fmt;
  logic        done;

  logic [31:0] cycles, active, stalls;

  axil_regs u_regs (
    .clk(clk), .rst_n(rst_n),
    .awvalid, .awaddr, .wvalid, .wdata, .bvalid,
    .arvalid, .araddr, .rvalid, .rdata,
    .start_pulse, .m, .n, .k, .dataflow, .fmt,
    .done, .cycles, .active, .stalls
  );

  // perf counters
  logic compute_cycle, stall_cycle;
  perf_counters u_perf (
    .clk, .rst_n, .start_pulse, .done,
    .compute_cycle, .stall_cycle,
    .cycles, .active, .stalls
  );

  // Tile BRAMs sized for N*N and N*N (A/B as N*N for demo), C as N*N
  localparam int DEPTH_A = N*N; // assumes K=N for smoke
  localparam int DEPTH_B = N*N;
  localparam int DEPTH_C = N*N;

  // A and B DMA loaders (single buffer depth used per run)
  logic a_load_done, b_load_done;
  logic a_we; logic [$clog2(DEPTH_A)-1:0] a_waddr; logic [DATA_W-1:0] a_wdata;
  logic b_we; logic [$clog2(DEPTH_B)-1:0] b_waddr; logic [DATA_W-1:0] b_wdata;

  tile_dma #(.W(DATA_W), .DEPTH(DEPTH_A)) u_dma_a (
    .clk, .rst_n,
    .in_valid(a_valid), .in_ready(a_ready), .in_data(a_data),
    .bram_we(a_we), .bram_waddr(a_waddr), .bram_wdata(a_wdata),
    .start_load(start_pulse), .load_done(a_load_done), .sel_buf()
  );
  tile_dma #(.W(DATA_W), .DEPTH(DEPTH_B)) u_dma_b (
    .clk, .rst_n,
    .in_valid(b_valid), .in_ready(b_ready), .in_data(b_data),
    .bram_we(b_we), .bram_waddr(b_waddr), .bram_wdata(b_wdata),
    .start_load(start_pulse), .load_done(b_load_done), .sel_buf()
  );

  // BRAMs for tiles
  logic                         a_re; logic [$clog2(DEPTH_A)-1:0] a_raddr; logic [DATA_W-1:0] a_rdata;
  logic                         b_re; logic [$clog2(DEPTH_B)-1:0] b_raddr; logic [DATA_W-1:0] b_rdata;
  tile_bram #(.W(DATA_W), .DEPTH(DEPTH_A)) u_bram_a (
    .clk,
    .we(a_we), .waddr(a_waddr), .wdata(a_wdata),
    .re(a_re), .raddr(a_raddr), .rdata(a_rdata)
  );
  tile_bram #(.W(DATA_W), .DEPTH(DEPTH_B)) u_bram_b (
    .clk,
    .we(b_we), .waddr(b_waddr), .wdata(b_wdata),
    .re(b_re), .raddr(b_raddr), .rdata(b_rdata)
  );

  // Output C BRAM, written during compute
  logic                         c_we; logic [$clog2(DEPTH_C)-1:0] c_waddr; logic signed [ACC_W-1:0] c_wdata;
  tile_bram #(.W(ACC_W), .DEPTH(DEPTH_C)) u_bram_c (
    .clk,
    .we(c_we), .waddr(c_waddr), .wdata(c_wdata),
    .re(c_rd_en), .raddr(c_rd_addr), .rdata(c_rd_data)
  );

  // Array instance
  logic signed [DATA_W-1:0] a_west [N];
  logic signed [DATA_W-1:0] b_north[N];
  logic signed [ACC_W-1:0]  c_south[N];
  logic a_v [N], a_r [N], b_v [N], b_r [N];
  logic c_v [N], c_r [N];

  for (genvar i=0;i<N;i++) begin
    assign a_v[i] = compute_cycle; // drive when computing
    assign b_v[i] = compute_cycle;
    assign c_r[i] = 1'b1;
  end

  systolic_array #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) u_array (
    .clk, .rst_n, .en(compute_cycle),
    .a_west(a_west), .a_valid(a_v), .a_ready(a_r),
    .b_north(b_north), .b_valid(b_v), .b_ready(b_r),
    .c_south(c_south), .c_valid(c_v), .c_ready(c_r)
  );

  // Simple controller: LOAD -> COMPUTE -> STORE (write C)
  typedef enum logic [1:0] {S_IDLE, S_WAIT_LOAD, S_COMPUTE, S_DONE} state_e;
  state_e state;
  logic [15:0] m_l, n_l, k_l;
  logic [$clog2(N):0] row, col;
  logic [$clog2(N):0] kk;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE; done <= 1'b0; compute_cycle <= 1'b0; stall_cycle <= 1'b0;
      m_l <= '0; n_l <= '0; k_l <= '0; row <= '0; col <= '0; kk <= '0;
      a_re <= 1'b0; b_re <= 1'b0; c_we <= 1'b0; c_waddr <= '0; c_wdata <= '0; a_raddr <= '0; b_raddr <= '0;
    end else begin
      c_we <= 1'b0; a_re <= 1'b0; b_re <= 1'b0; compute_cycle <= 1'b0; stall_cycle <= 1'b0;
      unique case (state)
        S_IDLE: begin
          done <= 1'b0;
          if (start_pulse) begin
            m_l <= (m==0)? N : m[15:0];
            n_l <= (n==0)? N : n[15:0];
            k_l <= (k==0)? N : k[15:0];
            state <= S_WAIT_LOAD;
          end
        end
        S_WAIT_LOAD: begin
          if (a_load_done && b_load_done) begin
            kk <= 0; row <= 0; col <= 0; c_waddr <= 0;
            state <= S_COMPUTE;
          end
        end
        S_COMPUTE: begin
          // feed edges from BRAM: a[row, kk], b[kk, col]
          // Addressing: A row-major [row*N + kk], B row-major [kk*N + col]
          a_raddr <= row*N + kk; a_re <= 1'b1;
          b_raddr <= kk*N + col; b_re <= 1'b1;
          a_west[row]  <= a_rdata;
          b_north[col] <= b_rdata;
          compute_cycle <= 1'b1;

          // Accumulate and write C when kk reaches k_l-1
          if (kk == k_l-1) begin
            // write result c[row,col]
            c_waddr <= row*N + col;
            c_wdata <= c_south[row];
            c_we    <= 1'b1;
            kk <= 0;
            if (col == n_l-1) begin
              col <= 0;
              if (row == m_l-1) begin
                state <= S_DONE;
              end else begin
                row <= row + 1;
              end
            end else begin
              col <= col + 1;
            end
          end else begin
            kk <= kk + 1;
          end
        end
        S_DONE: begin
          done <= 1'b1;
          if (start_pulse) state <= S_WAIT_LOAD; // allow retrigger
        end
      endcase
    end
  end

  assign done_o = done;
endmodule : top

`default_nettype wire 