package AutoVerify::Simulator::Questa;
##############################################################################
# AutoVerify::Simulator::Questa
#
# Wraps the existing run_sim.tcl vsim flow (the only flow actually exercised
# in this project - see Makefile's `sim`/`regress` targets). This is a real,
# already-working command shape, not a guess.
##############################################################################
use strict;
use warnings;
use AutoVerify::Simulator;
use parent -norequire, 'AutoVerify::Simulator';

sub name { return 'questa'; }

sub compile_cmd {
    my ($self, %a) = @_;
    return sprintf(
        'vsim -c -do "set MODULE %s; set DUT_FILE %s; set GEN_DIR %s; source run_sim.tcl; compile; quit"',
        $a{module}, $a{dut_file}, $a{gen_dir},
    );
}

sub run_cmd {
    my ($self, %a) = @_;
    return sprintf(
        'vsim -c -do "set MODULE %s; set DUT_FILE %s; set GEN_DIR %s; source run_sim.tcl; run_once; quit"',
        $a{module}, $a{dut_file}, $a{gen_dir},
    );
}

sub regress_cmd {
    my ($self, %a) = @_;
    my $seeds = $a{seeds} // 10;
    return sprintf(
        'vsim -c -do "set MODULE %s; set DUT_FILE %s; set GEN_DIR %s; source run_sim.tcl; regress %d; quit"',
        $a{module}, $a{dut_file}, $a{gen_dir}, $seeds,
    );
}

1;
