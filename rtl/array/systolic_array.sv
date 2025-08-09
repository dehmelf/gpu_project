`timescale 1ns/1ps
`default_nettype none

module systolic_array #(
  parameter int N       = 8,
  parameter int DATA_W  = 16,
  parameter int ACC_W   = 32
) (
  input  logic clk,
  input  logic rst_n,
  input  logic en,
  // West edge A inputs
  input  logic signed [DATA_W-1:0] a_west   [N],
  input  logic                     a_valid  [N],
  output logic                     a_ready  [N],
  // North edge B inputs
  input  logic signed [DATA_W-1:0] b_north  [N],
  input  logic                     b_valid  [N],
  output logic                     b_ready  [N],
  // South edge C outputs
  output logic signed [ACC_W-1:0]  c_south  [N],
  output logic                     c_valid  [N],
  input  logic                     c_ready  [N]
);
  // Simple: always ready; propagate valid after minimal latency
  for (genvar r = 0; r < N; r++) begin : gen_ready_a
    assign a_ready[r] = 1'b1;
  end
  for (genvar c = 0; c < N; c++) begin : gen_ready_b
    assign b_ready[c] = 1'b1;
  end

  // Internal wiring
  logic signed [DATA_W-1:0] a_bus [N][N+1];
  logic signed [DATA_W-1:0] b_bus [N+1][N];
  logic signed [ACC_W-1:0]  acc_bus [N][N+1];

  // Initialize west/north edges
  for (genvar i = 0; i < N; i++) begin : gen_edges
    assign a_bus[i][0] = (a_valid[i]) ? a_west[i] : '0; // gate with valid
    assign b_bus[0][i] = (b_valid[i]) ? b_north[i]: '0;
    assign acc_bus[i][0] = '0; // zero partial sums at west boundary
  end

  // Instantiate PEs
  for (genvar r = 0; r < N; r++) begin : gen_row
    for (genvar c = 0; c < N; c++) begin : gen_col
      pe_mac #(.DATA_W(DATA_W), .ACC_W(ACC_W)) u_pe (
        .clk(clk), .rst_n(rst_n), .en(en),
        .a_in (a_bus[r][c]),
        .b_in (b_bus[r][c]),
        .acc_in(acc_bus[r][c]),
        .a_out(a_bus[r][c+1]),
        .b_out(b_bus[r+1][c]),
        .acc_out(acc_bus[r][c+1])
      );
    end
  end

  // South outputs are the last acc values in each row
  for (genvar r = 0; r < N; r++) begin : gen_out
    assign c_south[r] = acc_bus[r][N];
    // Valid is a simple registered version of the conjunction of a_valid/b_valid; simplified TODO: model fill/drain more accurately
    logic v_q;
    always_ff @(posedge clk) begin
      if (!rst_n) v_q <= 1'b0; else if (en) v_q <= |(a_valid[r]) & |(b_valid); // weak heuristic
    end
    assign c_valid[r] = v_q & c_ready[r];
  end
endmodule : systolic_array

`default_nettype wire 