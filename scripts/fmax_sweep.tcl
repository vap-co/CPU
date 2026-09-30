# Run from the repository root: vivado -mode batch -source scripts/fmax_sweep.tcl
# Each trial uses a fresh in-memory project.
set part xc7z030ffg676-1
set output ./build/fmax
file mkdir $output
set rtl_files [concat [glob ./rtl/adder/*.v] [glob ./rtl/multiplier/*.v] \
    [glob ./rtl/divider/*.v] [glob ./rtl/memory/*.v] [glob ./rtl/core/*.v]]
set adder_names {RCA CSLA KSA}
set mult_names {ARRAY WALLACE VEDIC}

proc measure_period {part rtl_files adder multiplier period report_file} {
    set xdc_file "[file dirname $report_file]/temp.xdc"
    set source_xdc [open ./constraints/cpu_top.xdc r]
    set xdc_text [read $source_xdc]
    close $source_xdc
    if {![regsub -- {-period 30\.000} $xdc_text "-period $period" xdc_text]} {
        error "Expected 30 ns reference clock not found in cpu_top.xdc"
    }
    set xdc [open $xdc_file w]
    puts -nonewline $xdc $xdc_text
    close $xdc
    create_project -in_memory -part $part
    add_files -norecurse $rtl_files
    add_files -fileset constrs_1 -norecurse $xdc_file
    synth_design -top cpu_top -part $part -generic ADDER_TYPE=$adder -generic MULT_TYPE=$multiplier -generic MEMORY_MODE=1 -generic IMEM_ADDR_WIDTH=11 -generic DMEM_ADDR_WIDTH=11
    opt_design
    place_design
    route_design
    set paths [get_timing_paths -setup -max_paths 1]
    if {[llength $paths] == 0} { error "No setup timing path found" }
    set wns [get_property SLACK [lindex $paths 0]]
    report_timing_summary -delay_type max -file $report_file
    close_project
    return $wns
}

set summary [open "$output/fmax_summary.csv" w]
puts $summary "Configuration,Min_Passing_Period_ns,WNS_at_Pass_ns,Nearest_Failing_Period_ns,WNS_at_Fail_ns,Timing_Closure_Fmax_MHz,Status"
for {set a 0} {$a < 3} {incr a} {
    for {set m 0} {$m < 3} {incr m} {
        set cfg "[lindex $adder_names $a]_[lindex $mult_names $m]"
        set dir "$output/$cfg"
        file mkdir $dir
        set pass_period 30.0
        set pass_wns [measure_period $part $rtl_files $a $m $pass_period "$dir/passing_timing.rpt"]
        if {$pass_wns < 0} { error "$cfg fails even at 30 ns" }
        set fail_period 10.0
        set fail_wns [measure_period $part $rtl_files $a $m $fail_period "$dir/failing_timing.rpt"]
        if {$fail_wns >= 0} { error "$cfg still passes at 10 ns; widen the search range" }
        while {($pass_period - $fail_period) > 0.1} {
            set trial [expr {round(($pass_period + $fail_period) * 5.0) / 10.0}]
            if {$trial <= $fail_period || $trial >= $pass_period} { break }
            set report "$dir/trial_timing.rpt"
            set wns [measure_period $part $rtl_files $a $m $trial $report]
            if {$wns >= 0} {
                set pass_period $trial
                set pass_wns $wns
                file copy -force $report "$dir/passing_timing.rpt"
            } else {
                set fail_period $trial
                set fail_wns $wns
                file copy -force $report "$dir/failing_timing.rpt"
            }
            file delete $report
        }
        set mhz [format %.2f [expr {1000.0 / $pass_period}]]
        puts $summary "$cfg,$pass_period,$pass_wns,$fail_period,$fail_wns,$mhz,PASS"
        flush $summary
    }
}
close $summary
