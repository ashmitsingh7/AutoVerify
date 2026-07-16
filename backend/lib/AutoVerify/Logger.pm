package AutoVerify::Logger;
##############################################################################
# AutoVerify::Logger
#
# Minimal leveled logger. Library code calls debug()/info()/warning()/error()
# and nothing prints unless a caller (typically the CLI, via --verbose) has
# raised the level with set_level(). Default level is 'ERROR' silence-by-default
# for INFO/DEBUG/WARNING; even 'error' log calls are for diagnostics the
# caller chooses to display, not a replacement for thrown AutoVerify::Error
# exceptions, which propagate regardless of log level.
##############################################################################
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(set_level debug info warning error);

my %LEVELS = (DEBUG => 0, INFO => 1, WARNING => 2, ERROR => 3, SILENT => 4);
my $current_level = $LEVELS{SILENT};    # library is silent by default

sub set_level {
    my ($level) = @_;
    $level = uc($level);
    die "Unknown log level '$level'\n" unless exists $LEVELS{$level};
    $current_level = $LEVELS{$level};
}

sub _log {
    my ($level, $msg) = @_;
    return if $LEVELS{$level} < $current_level;
    printf STDERR "[%s] %s\n", $level, $msg;
}

sub debug   { _log('DEBUG',   $_[0]); }
sub info    { _log('INFO',    $_[0]); }
sub warning { _log('WARNING', $_[0]); }
sub error   { _log('ERROR',   $_[0]); }

1;
