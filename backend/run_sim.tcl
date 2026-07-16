##############################################################################
# run_sim.tcl - simulation automation for HDL Testbench Generator output
#
# Written for Questa/ModelSim's `vsim -c -do run_sim.tcl` flow, which is the
# most common Tcl-driven flow in industry. The compile/elaborate/run steps
# are isolated in procs so this is easy to adapt to VCS (`vcs` + `simv -ucli`)
# or Xcelium (`xrun` Tcl mode) if that's what your site uses.
#
# Usage examples:
#   vsim -c -do "set MODULE counter; set DUT_FILE examples/counter.v; source run_sim.tcl"
#   vsim -c -do run_sim.tcl                 (uses the defaults below)
#
# Or from a shell:
#   vsim -c -do run_sim.tcl -do "regress 10; quit"
##############################################################################

# ---------------------------------------------------------------------------
# Config - override any of these with `set NAME value` before `source`-ing,
# or edit the defaults directly.
# ---------------------------------------------------------------------------
if {![info exists MODULE]}    { set MODULE     "counter" }
if {![info exists DUT_FILE]}  { set DUT_FILE   "examples/${MODULE}.v" }
if {![info exists GEN_DIR]}   { set GEN_DIR    "gen_${MODULE}" }
if {![info exists WORKLIB]}   { set WORKLIB    "work" }
if {![info exists TOP]}       { set TOP        "${MODULE}_tb_top" }
if {![info exists WAVES]}     { set WAVES      1 }

set FILELIST "${GEN_DIR}/${MODULE}_files.f"

# ---------------------------------------------------------------------------
# compile: (re)build the work library and compile DUT + generated testbench
# ---------------------------------------------------------------------------
proc compile {} {
    global MODULE DUT_FILE GEN_DIR WORKLIB FILELIST

    if {[file exists $WORKLIB]} {
        vdel -lib $WORKLIB -all
    }
    vlib $WORKLIB
    vmap work $WORKLIB

    puts "\[run_sim.tcl\] Compiling DUT: $DUT_FILE"
    vlog -sv $DUT_FILE

    puts "\[run_sim.tcl\] Compiling generated testbench from: $FILELIST"
    set fh [open $FILELIST r]
    while {[gets $fh line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string match "//*" $line]} { continue }
        vlog -sv "${GEN_DIR}/${line}"
    }
    close $fh

    puts "\[run_sim.tcl\] Compile complete."
}

# ---------------------------------------------------------------------------
# elaborate + run one simulation. seed lets you re-run with a different
# random stream without recompiling.
# ---------------------------------------------------------------------------
proc run_once {{seed 1}} {
    global TOP WAVES

    vsim -sv_seed $seed -voptargs=+acc work.$TOP

    if {$WAVES} {
        log -r /*
    }

    run -all
    quit -sim
}

# ---------------------------------------------------------------------------
# regress: compile once, then run N seeds back to back - handy for shaking
# out issues that only show up with certain random stimulus.
# ---------------------------------------------------------------------------
proc regress {{num_seeds 5}} {
    compile
    for {set s 1} {$s <= $num_seeds} {incr s} {
        puts "\[run_sim.tcl\] ---- seed $s / $num_seeds ----"
        run_once $s
    }
    puts "\[run_sim.tcl\] Regression complete: $num_seeds seed(s) run."
}

# ---------------------------------------------------------------------------
# Default action when this script is sourced directly: one compile + run.
# Comment this out if you'd rather call compile/run_once/regress by hand
# from the vsim prompt.
# ---------------------------------------------------------------------------
compile
run_once 1
