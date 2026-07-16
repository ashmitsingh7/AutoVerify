package AutoVerify::Simulator::VCS;
##############################################################################
# AutoVerify::Simulator::VCS
#
# UNVERIFIED: no VCS installation exists in this environment, so these
# command shapes follow standard `vcs` / simv conventions but have not been
# run against a real filelist. Treat as a starting point to validate on
# real Synopsys tooling before relying on it, not as tested behavior.
##############################################################################
use strict;
use warnings;
use AutoVerify::Simulator;
use parent -norequire, 'AutoVerify::Simulator';

sub name { return 'vcs'; }

sub compile_cmd {
    my ($self, %a) = @_;
    return sprintf('vcs -sverilog -full64 -f %s/%s_files.f -o %s/simv',
        $a{gen_dir}, $a{module}, $a{gen_dir});
}

sub run_cmd {
    my ($self, %a) = @_;
    return sprintf('%s/simv -l %s/sim.log', $a{gen_dir}, $a{gen_dir});
}

sub regress_cmd {
    my ($self, %a) = @_;
    my $seeds = $a{seeds} // 10;
    return sprintf('for s in $(seq 1 %d); do %s/simv +ntb_random_seed=$s -l %s/sim_$s.log; done',
        $seeds, $a{gen_dir}, $a{gen_dir});
}

1;
