#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Simulator::Questa;
use AutoVerify::Simulator::VCS;
use AutoVerify::Simulator::Xcelium;

my %args = (module => 'counter', dut_file => 'examples/counter.v', gen_dir => 'gen_counter', seeds => 5);

for my $class (qw(AutoVerify::Simulator::Questa AutoVerify::Simulator::VCS AutoVerify::Simulator::Xcelium)) {
    my $sim = $class->new;
    isa_ok($sim, 'AutoVerify::Simulator', "$class");
    ok($sim->name, "$class: name() returns something");
    ok($sim->compile_cmd(%args), "$class: compile_cmd() returns a command string");
    ok($sim->run_cmd(%args),     "$class: run_cmd() returns a command string");
    ok($sim->regress_cmd(%args), "$class: regress_cmd() returns a command string");
}

# --- Questa specifically: this is the flow the Makefile already drives, so
#     verify it matches the same shape run_sim.tcl / Makefile expect ---
{
    my $q = AutoVerify::Simulator::Questa->new;
    is($q->name, 'questa', 'Questa backend identifies itself correctly');
    like($q->compile_cmd(%args), qr/set MODULE counter/, 'Questa compile_cmd sets MODULE');
    like($q->compile_cmd(%args), qr/source run_sim\.tcl/, 'Questa compile_cmd sources run_sim.tcl');
    like($q->regress_cmd(%args), qr/regress 5/, 'Questa regress_cmd passes seed count through');
}

# --- base class refuses to be used directly (interface, not implementation) ---
{
    my $base = AutoVerify::Simulator->new;
    eval { $base->name };
    ok($@, 'base Simulator class dies if name() is called without a real backend');
}

done_testing();
