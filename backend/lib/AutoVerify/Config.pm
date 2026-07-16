package AutoVerify::Config;
##############################################################################
# AutoVerify::Config
#
# Layers configuration: built-in defaults < caller-supplied opts (from the
# CLI today; from a parsed JSON/YAML file in the future - resolve() takes
# an arbitrary list of hashrefs so adding a file layer later is additive).
#
# Existing CLI behavior is unchanged: resolve() with just CLI opts produces
# exactly the same effective options gen_tb.pl always passed to Generator.
##############################################################################
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(resolve defaults);

sub defaults {
    return {
        outdir         => undef,    # computed as gen_<module> by Generator if left undef
        clk            => undef,
        rst            => undef,
        rst_active_low => undef,
        num_txns       => 100,
    };
}

# resolve(\%layer1, \%layer2, ...) - later layers win; undef values in a
# later layer do NOT override a defined value from an earlier layer (so
# "not specified on the CLI" doesn't clobber a config-file value).
sub resolve {
    my (@layers) = @_;
    my %out = %{ defaults() };
    for my $layer (@layers) {
        next unless $layer;
        for my $key (keys %$layer) {
            next unless defined $layer->{$key};
            $out{$key} = $layer->{$key};
        }
    }
    return \%out;
}

1;
