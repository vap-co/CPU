# Standalone adder and multiplier implementation.
# Usage: vivado -mode batch -source scripts/run_standalone.tcl

set PART xc7z030ffg676-1
set JOBS 4
set OUTDIR ./build/standalone
file mkdir $OUTDIR
file mkdir ./build/vivado_runs
set common_files [concat [glob ./rtl/adder/*.v] [glob ./rtl/multiplier/*.v]]

set adder_names {RCA CSLA KSA}
for {set a 0} {$a < 3} {incr a} {
    set cfg "ADDER_[lindex $adder_names $a]"
    set projdir "./build/vivado_runs/${cfg}_[clock seconds]"
    create_project -force $cfg $projdir -part $PART
    add_files -norecurse $common_files
    add_files -norecurse ./rtl/benchmark/standalone_adder_top.v
    add_files -fileset constrs_1 -norecurse ./constraints/standalone.xdc
    set_property top standalone_adder_top [current_fileset]
    set_property generic "ADDER_TYPE=$a" [current_fileset]
    update_compile_order -fileset sources_1
    launch_runs synth_1 -jobs $JOBS; wait_on_run synth_1
    launch_runs impl_1 -to_step route_design -jobs $JOBS; wait_on_run impl_1
    open_run impl_1
    report_utilization -file "$OUTDIR/${cfg}_utilization.rpt"
    report_timing_summary -delay_type max -max_paths 20 -file "$OUTDIR/${cfg}_timing.rpt"
    close_project
}

set mult_names {ARRAY WALLACE VEDIC}
for {set m 0} {$m < 3} {incr m} {
    set cfg "MULT_[lindex $mult_names $m]"
    set projdir "./build/vivado_runs/${cfg}_[clock seconds]"
    create_project -force $cfg $projdir -part $PART
    add_files -norecurse $common_files
    add_files -norecurse ./rtl/benchmark/standalone_multiplier_top.v
    add_files -fileset constrs_1 -norecurse ./constraints/standalone.xdc
    set_property top standalone_multiplier_top [current_fileset]
    set_property generic "MULT_TYPE=$m" [current_fileset]
    update_compile_order -fileset sources_1
    launch_runs synth_1 -jobs $JOBS; wait_on_run synth_1
    launch_runs impl_1 -to_step route_design -jobs $JOBS; wait_on_run impl_1
    open_run impl_1
    report_utilization -file "$OUTDIR/${cfg}_utilization.rpt"
    report_timing_summary -delay_type max -max_paths 20 -file "$OUTDIR/${cfg}_timing.rpt"
    close_project
}
puts "Standalone reports written to $OUTDIR"
