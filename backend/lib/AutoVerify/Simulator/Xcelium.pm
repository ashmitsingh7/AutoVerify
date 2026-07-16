package AutoVerify::Simulator::Xcelium;
##############################################################################
# AutoVerify::Simulator::Xcelium
#
# UNVERIFIED: no Xcelium installation exists in this environment. Command
# shapes follow standard `xrun` conventions but haven't been run against a
# real filelist - validate on real Cadence tooling before relying on it.
##############################################################################
use strict;
use warnings;
use AutoVerify::Simulator;
use parent -norequire, 'AutoVerify::Simulator';

sub name { return 'xcelium'; }

sub compile_cmd {
    my ($self, %a) = @_;
    return sprintf('xrun -sv -f %s/%s_files.f -elaborate -xmlibdirname %s/xcelium.d',
        $a{gen_dir}, $a{module}, $a{gen_dir});
}

sub run_cmd {
    my ($self, %a) = @_;
    return sprintf('xrun -R -xmlibdirname %s/xcelium.d -l %s/sim.log', $a{gen_dir}, $a{gen_dir});
}

sub regress_cmd {
    my ($self, %a) = @_;
    my $seeds = $a{seeds} // 10;
    return sprintf('for s in $(seq 1 %d); do xrun -R -svseed $s -xmlibdirname %s/xcelium.d -l %s/sim_$s.log; done',
        $seeds, $a{gen_dir}, $a{gen_dir});
}

1;
