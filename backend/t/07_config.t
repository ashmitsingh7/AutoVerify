#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Config qw(resolve defaults);

# --- defaults alone ---
{
    my $cfg = resolve();
    is($cfg->{num_txns}, 100, 'default num_txns is 100');
    is($cfg->{outdir}, undef, 'default outdir is undef (computed later from module name)');
}

# --- a single CLI-style layer overrides defaults ---
{
    my $cfg = resolve({ num_txns => 500, clk => 'clk_i' });
    is($cfg->{num_txns}, 500, 'explicit num_txns overrides default');
    is($cfg->{clk}, 'clk_i', 'explicit clk passed through');
    is($cfg->{rst}, undef, 'unspecified rst remains undef');
}

# --- later layers win, but undef in a later layer does not clobber an earlier defined value ---
{
    my $cfg = resolve({ num_txns => 500 }, { num_txns => undef, clk => 'clk2' });
    is($cfg->{num_txns}, 500, 'undef in a later layer does not overwrite an earlier explicit value');
    is($cfg->{clk}, 'clk2', 'later layer still wins when it does specify a value');
}

# --- defaults() returns a fresh hashref each call (no shared-mutable-state bug) ---
{
    my $d1 = defaults();
    $d1->{num_txns} = 999;
    my $d2 = defaults();
    is($d2->{num_txns}, 100, 'mutating one defaults() call does not affect the next');
}

done_testing();
