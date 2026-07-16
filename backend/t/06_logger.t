#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Logger qw(set_level debug info warning error);

sub captured_stderr {
    my ($code) = @_;
    my $captured = '';
    open(my $fh, '>', \$captured) or die $!;
    my $old = select($fh);
    local *STDERR = $fh;
    $code->();
    select($old);
    close($fh);
    return $captured;
}

# --- silent by default ---
{
    my $out = captured_stderr(sub { debug('d'); info('i'); warning('w'); error('e'); });
    is($out, '', 'library is silent by default at all four levels');
}

# --- set_level(DEBUG) shows everything ---
{
    set_level('DEBUG');
    my $out = captured_stderr(sub { debug('d-msg'); info('i-msg'); warning('w-msg'); error('e-msg'); });
    like($out, qr/DEBUG.*d-msg/, 'debug message shown at DEBUG level');
    like($out, qr/INFO.*i-msg/,  'info message shown at DEBUG level');
    like($out, qr/WARNING.*w-msg/, 'warning message shown at DEBUG level');
    like($out, qr/ERROR.*e-msg/, 'error message shown at DEBUG level');
}

# --- set_level(WARNING) hides debug/info but shows warning/error ---
{
    set_level('WARNING');
    my $out = captured_stderr(sub { debug('should-not-appear'); info('also-not'); warning('w2'); error('e2'); });
    unlike($out, qr/should-not-appear/, 'debug suppressed at WARNING level');
    unlike($out, qr/also-not/, 'info suppressed at WARNING level');
    like($out, qr/w2/, 'warning still shown at WARNING level');
    like($out, qr/e2/, 'error still shown at WARNING level');
}

# --- unknown level rejected ---
{
    eval { set_level('NONSENSE') };
    ok($@, 'unknown log level is rejected');
}

set_level('SILENT');    # restore quiet default for any tests run after this file
done_testing();
