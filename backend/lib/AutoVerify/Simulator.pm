package AutoVerify::Simulator;
##############################################################################
# AutoVerify::Simulator - interface (abstract base).
#
# A Simulator backend turns (module, dut_file, gen_dir) into the shell
# commands needed to compile / run once / regress across seeds. It does NOT
# invoke a simulator binary itself in this environment (none is installed
# here) - it returns the command strings a caller would run. This keeps the
# abstraction honest: what's implemented is command construction, not
# verified simulation.
#
# Contract:
#   name()                                   -> short backend name, e.g. 'questa'
#   compile_cmd(module, dut_file, gen_dir)    -> shell command string
#   run_cmd(module, dut_file, gen_dir)        -> shell command string
#   regress_cmd(module, dut_file, gen_dir, n) -> shell command string
##############################################################################
use strict;
use warnings;

sub new { return bless {}, shift; }

sub name        { die ref($_[0]) . " must implement name()\n"; }
sub compile_cmd { die ref($_[0]) . " must implement compile_cmd()\n"; }
sub run_cmd     { die ref($_[0]) . " must implement run_cmd()\n"; }
sub regress_cmd { die ref($_[0]) . " must implement regress_cmd()\n"; }

1;
