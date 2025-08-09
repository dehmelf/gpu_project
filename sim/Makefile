VERILATOR ?= verilator
TOPS := ../rtl/ctrl/cfg_pkg.sv ../rtl/pe/pe_mac.sv ../rtl/array/systolic_array.sv ../rtl/mem/tile_bram.sv ../rtl/mem/tile_dma.sv ../rtl/axi/axil_regs.sv ../rtl/ctrl/perf_counters.sv ../rtl/top.sv
TB_PE := ../tb/tb_pe.sv
TB_ARRAY := ../tb/tb_array.sv
TB_TOP := ../tb/tb_top.sv
REF_C := ../tb/ref_gemm.c

CFLAGS := -O2 -DVL_USER_FINISH -DREF_GEMM
LDFLAGS :=

all: sim

lint:
	$(VERILATOR) --sv --lint-only $(TOPS) $(TB_PE) $(TB_ARRAY) $(TB_TOP)

sim: build_pe build_array build_top run_pe run_array run_top

build_pe:
	$(VERILATOR) -Wall --trace --cc --exe $(TB_PE) $(TOPS) $(REF_C) --CFLAGS "$(CFLAGS)" --LDFLAGS "$(LDFLAGS)" --top-module tb_pe --build

build_array:
	$(VERILATOR) -Wall --trace --cc --exe $(TB_ARRAY) $(TOPS) $(REF_C) --CFLAGS "$(CFLAGS)" --LDFLAGS "$(LDFLAGS)" --top-module tb_array --build

build_top:
	$(VERILATOR) -Wall --trace --cc --exe $(TB_TOP) $(TOPS) $(REF_C) --CFLAGS "$(CFLAGS)" --LDFLAGS "$(LDFLAGS)" --top-module tb_top --build

run_pe:
	./obj_dir/Vtb_pe

run_array:
	./obj_dir/Vtb_array

run_top:
	./obj_dir/Vtb_top

waves:
	[ -f obj_dir/Vtb_top.vcd ] && (gtkwave obj_dir/Vtb_top.vcd || true) || true

clean:
	rm -rf obj_dir logs *.vcd 