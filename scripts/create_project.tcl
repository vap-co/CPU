# Vivado batch usage:
#   vivado -mode batch -source scripts/create_project.tcl
# Run this script from the repository root.

set PROJECT_NAME RV32IM_3x3_CPU
set PART xc7z030ffg676-1
set PROJ_DIR ./vivado_project

create_project -force $PROJECT_NAME $PROJ_DIR -part $PART

set rtl_files [concat \
    [glob ./rtl/adder/*.v] \
    [glob ./rtl/multiplier/*.v] \
    [glob ./rtl/divider/*.v] \
    [glob ./rtl/memory/*.v] \
    [glob ./rtl/core/*.v]]
add_files -norecurse $rtl_files
add_files -norecurse ./program.mem
add_files -norecurse ./data.mem
set_property file_type {Memory Initialization Files} [get_files program.mem]
set_property file_type {Memory Initialization Files} [get_files data.mem]
add_files -fileset constrs_1 -norecurse ./constraints/cpu_top.xdc

set sim_files [glob ./sim/*.v]
add_files -fileset sim_1 -norecurse $sim_files
set_property top cpu_top [get_filesets sources_1]
set_property top cpu_9config_bram_tb [get_filesets sim_1]
# No project-level generic override: synthesis uses the defaults in cpu_top.v.
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Created $PROJECT_NAME at $PROJ_DIR"
puts "Default simulation top: cpu_9config_bram_tb (all nine configurations, BRAM)"
