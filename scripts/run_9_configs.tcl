# Run all nine adder/multiplier combinations from the repository root:
#   vivado -mode batch -source scripts/run_9_configs.tcl

set PART xc7z030ffg676-1
set MEMORY_MODE 1          ;# 0=async legacy-style, 1=BRAM-oriented
set IMEM_ADDR_WIDTH 11     ;# 2048 words = 8 KiB
set DMEM_ADDR_WIDTH 11     ;# 2048 words = 8 KiB
set JOBS 4
set OUTDIR ./build/reproduced_9config_mem${MEMORY_MODE}
file mkdir $OUTDIR
file mkdir ./build/vivado_runs

set adder_names {RCA CSLA KSA}
set mult_names  {ARRAY WALLACE VEDIC}
set rtl_files [concat \
    [glob ./rtl/adder/*.v] \
    [glob ./rtl/multiplier/*.v] \
    [glob ./rtl/divider/*.v] \
    [glob ./rtl/memory/*.v] \
    [glob ./rtl/core/*.v]]

for {set a 0} {$a < 3} {incr a} {
    for {set m 0} {$m < 3} {incr m} {
        set cfg "[lindex $adder_names $a]_[lindex $mult_names $m]"
        set projdir "./build/vivado_runs/${cfg}_[clock seconds]"
        create_project -force $cfg $projdir -part $PART
        add_files -norecurse $rtl_files
        add_files -norecurse ./program.mem
        add_files -norecurse ./data.mem
        set_property file_type {Memory Initialization Files} [get_files program.mem]
        set_property file_type {Memory Initialization Files} [get_files data.mem]
        add_files -fileset constrs_1 -norecurse ./constraints/cpu_top.xdc
        set_property top cpu_top [current_fileset]
        set_property generic "ADDER_TYPE=$a MULT_TYPE=$m MEMORY_MODE=$MEMORY_MODE IMEM_ADDR_WIDTH=$IMEM_ADDR_WIDTH DMEM_ADDR_WIDTH=$DMEM_ADDR_WIDTH" [current_fileset]
        update_compile_order -fileset sources_1

        launch_runs synth_1 -jobs $JOBS
        wait_on_run synth_1
        if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { error "Synthesis failed for $cfg" }

        launch_runs impl_1 -to_step route_design -jobs $JOBS
        wait_on_run impl_1
        open_run impl_1

        report_utilization -hierarchical -file "$OUTDIR/${cfg}_utilization.rpt"
        report_timing_summary -delay_type max -max_paths 20 -file "$OUTDIR/${cfg}_timing.rpt"

        write_checkpoint -force "$OUTDIR/${cfg}_routed.dcp"
        close_project
        puts "Finished $cfg"
    }
}
puts "All nine configurations completed. Reports: $OUTDIR"
