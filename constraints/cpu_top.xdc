# Common evaluation clock. Adjust only once, then use the same constraint
# for all 9 arithmetic configurations in a comparison run.
create_clock -name sys_clk -period 30.000 [get_ports clk]

# The top level is intended for implementation analysis rather than direct
# board I/O demonstration. Add PACKAGE_PIN/IOSTANDARD constraints if programming
# a physical board. Keep arithmetic/memory parameters identical across compared runs.

# Debug-only top-level ports must not define processor Fmax.
set_false_path -from [get_ports rst]
set_false_path -to [get_ports -regexp {debug_.*|halted}]
