`timescale 1ns/1ps
`default_nettype none

package cfg_pkg;
  typedef enum logic [0:0] {
    DF_OUT_STATIONARY      = 1'b0,
    DF_WEIGHT_STATIONARY   = 1'b1
  } dataflow_e;

  typedef enum logic [1:0] {
    FMT_INT8  = 2'd0,
    FMT_INT16 = 2'd1,
    FMT_FP16  = 2'd2 // TODO: implement FP16 datapath
  } fmt_e;

  parameter int ARRAY_N = 8;
  parameter int DATA_W  = 16;
  parameter int ACC_W   = 32;
endpackage : cfg_pkg

`default_nettype wire 