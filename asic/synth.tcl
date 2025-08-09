# ASIC synthesis stub (not executed in CI)
# read_verilog -sv ../rtl/**/*.sv
# set clk_period 10.0
# create_clock -period $clk_period [get_ports clk]
# set_dont_touch_network [get_ports rst_n]
# elaborate top
# link
# compile_ultra
# report_timing
# write -f verilog -hierarchy -output netlist.v 