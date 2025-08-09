`timescale 1ns/1ps
`default_nettype none

module axil_regs (
  input  logic clk,
  input  logic rst_n,
  // write address/data
  input  logic        awvalid,
  input  logic [7:0]  awaddr,
  input  logic        wvalid,
  input  logic [31:0] wdata,
  output logic        bvalid,
  // read address
  input  logic        arvalid,
  input  logic [7:0]  araddr,
  output logic        rvalid,
  output logic [31:0] rdata,
  // to/from core
  output logic        start_pulse,
  output logic [15:0] m,
  output logic [15:0] n,
  output logic [15:0] k,
  output logic [1:0]  dataflow,
  output logic [1:0]  fmt,
  input  logic        done,
  input  logic [31:0] cycles,
  input  logic [31:0] active,
  input  logic [31:0] stalls
);
  // regs
  logic start_req;
  logic [15:0] m_q, n_q, k_q;
  logic [1:0]  df_q, fmt_q;

  assign m = m_q; assign n = n_q; assign k = k_q; assign dataflow = df_q; assign fmt = fmt_q;

  // simple write: awvalid & wvalid in same cycle
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      bvalid <= 1'b0;
      rvalid <= 1'b0; rdata <= '0;
      start_req <= 1'b0;
      m_q <= '0; n_q <= '0; k_q <= '0; df_q <= 2'd0; fmt_q <= 2'd1; // default INT16
    end else begin
      bvalid <= 1'b0; // single-cycle response
      rvalid <= 1'b0;
      start_req <= 1'b0;
      if (awvalid && wvalid) begin
        unique case (awaddr[7:2]) // word aligned
          6'h00: begin // CTRL
            if (wdata[0]) start_req <= 1'b1; // start pulse
            df_q  <= wdata[3:2];
            fmt_q <= wdata[5:4];
          end
          6'h02: m_q <= wdata[15:0];
          6'h03: n_q <= wdata[15:0];
          6'h04: k_q <= wdata[15:0];
          default: /*do nothing*/;
        endcase
        bvalid <= 1'b1;
      end
      if (arvalid) begin
        unique case (araddr[7:2])
          6'h00: rdata <= {30'd0, done, 1'b0};
          6'h02: rdata <= {16'd0, m_q};
          6'h03: rdata <= {16'd0, n_q};
          6'h04: rdata <= {16'd0, k_q};
          6'h05: rdata <= cycles;
          6'h06: rdata <= active;
          6'h07: rdata <= stalls;
          default: rdata <= 32'h0;
        endcase
        rvalid <= 1'b1;
      end
    end
  end

  // start pulse one cycle
  assign start_pulse = start_req;
endmodule : axil_regs

`default_nettype wire 