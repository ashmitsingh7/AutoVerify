#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Parser         qw(parse_file);
use AutoVerify::PortClassifier qw(classify);

# --- counter.v: active-low reset by naming convention ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/counter.v");
    my $c = classify(ports => $ast->{ports});
    ok($c->{clk_port}, 'counter: clock auto-detected');
    ok($c->{rst_port}, 'counter: reset auto-detected');
    ok($c->{rst_active_low}, 'counter: reset correctly inferred active-low from name');
}

# --- fifo_sync.v: reset_n naming ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/fifo_sync.v");
    my $c = classify(ports => $ast->{ports});
    ok($c->{rst_port}, 'fifo_sync: reset auto-detected (reset_n style)');
    ok($c->{rst_active_low}, 'fifo_sync: reset_n inferred active-low');
    ok(scalar(@{$c->{stim_ports}}) > 0, 'fifo_sync: stim ports split out');
    ok(scalar(@{$c->{resp_ports}}) > 0, 'fifo_sync: resp ports split out');
}

# --- override: force active-high on a name ending in _n ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/counter.v");
    my $c = classify(ports => $ast->{ports}, rst_active_low => 0);
    is($c->{rst_active_low}, 0, 'explicit --rst-active-high override respected');
}

# --- clk/rst never leak into stim_ports ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/counter.v");
    my $c = classify(ports => $ast->{ports});
    my @stim_names = map { $_->{name} } @{ $c->{stim_ports} };
    ok(!(grep { $_ eq $c->{clk_port} } @stim_names), 'clk excluded from stim_ports');
    ok(!(grep { $_ eq $c->{rst_port} } @stim_names), 'rst excluded from stim_ports');
}

done_testing();
