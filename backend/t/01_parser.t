#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Parser qw(parse_file);

# --- counter.v: has a parameter, active-low sync reset, load port ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/counter.v");
    is($ast->{module_name}, 'counter', 'counter: module name parsed');
    is_deeply($ast->{param_order}, ['WIDTH'], 'counter: param order');
    ok(exists $ast->{param_default}{WIDTH}, 'counter: WIDTH has a default');

    my @names = map { $_->{name} } @{ $ast->{ports} };
    ok((grep { $_ eq 'clk' } @names), 'counter: clk port present');
    ok(scalar(@names) > 0, 'counter: ports non-empty');
}

# --- fifo_sync.v: no parameters, multiple signals sharing one input keyword ---
{
    my $ast = parse_file("$FindBin::Bin/../examples/fifo_sync.v");
    is($ast->{module_name}, 'fifo_sync', 'fifo_sync: module name parsed');
    is_deeply($ast->{param_order}, [], 'fifo_sync: no parameters');

    my @names = map { $_->{name} } @{ $ast->{ports} };
    ok(scalar(@names) > 1, 'fifo_sync: multiple ports parsed from shared-keyword decl');
}

# --- split_top_level / extract_balanced edge cases ---
{
    my $src = "module m #(parameter W=8, parameter D=[1:0]) (input clk, output [W-1:0] o);";
    my $ast = eval { AutoVerify::Parser::parse_source($src, 'inline') };
    ok($ast, 'inline module with bracketed default parses without dying');
    is($ast->{module_name}, 'm', 'inline: module name');
}

done_testing();
