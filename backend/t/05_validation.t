#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Parser     qw(parse_source);
use AutoVerify::Validation qw(validate);

sub diag_codes { return [ map { $_->{code} } @{ $_[0] } ]; }

# --- clean module: no diagnostics at all ---
{
    my $ast = parse_source("module m (input clk, input rst_n, input a, output b);", 'clean');
    my $diags = validate($ast);
    is_deeply($diags, [], 'clean module produces zero diagnostics');
}

# --- duplicate port names ---
{
    my $ast = parse_source("module m (input clk, input a, input a);", 'dup_port');
    my $codes = diag_codes(validate($ast));
    ok((grep { $_ eq 'duplicate_port' } @$codes), 'duplicate port name detected');
}

# --- duplicate parameters ---
{
    my $ast = parse_source("module m #(parameter W=8, parameter W=16) (input clk);", 'dup_param');
    my $codes = diag_codes(validate($ast));
    ok((grep { $_ eq 'duplicate_parameter' } @$codes), 'duplicate parameter detected');
}

# --- malformed parameter entry (skipped by parser, flagged by validation) ---
{
    my $ast = parse_source("module m #(parameter, parameter W=8) (input clk);", 'malformed_param');
    my $codes = diag_codes(validate($ast));
    ok((grep { $_ eq 'malformed_parameter' } @$codes), 'malformed parameter entry flagged');
    is_deeply($ast->{param_order}, ['W'], 'well-formed parameter still parsed alongside the malformed one');
}

# --- multidimensional packed array (warning, not fatal) ---
{
    my $ast = parse_source("module m (input clk, input [3:0][7:0] data);", 'multidim');
    my $diags = validate($ast);
    my ($d) = grep { $_->{code} eq 'unsupported_multidim_packed_array' } @$diags;
    ok($d, 'multidim packed array flagged');
    is($d->{severity}, 'warning', 'multidim packed array is a warning, not an error');
}

# --- generate block present ---
{
    my $ast = parse_source("module m (input clk); generate endgenerate endmodule", 'has_generate');
    my $codes = diag_codes(validate($ast));
    ok((grep { $_ eq 'unsupported_generate_block' } @$codes), 'generate block flagged');
}

# --- virtual interface port reference ---
{
    my $ast = parse_source("module m (input clk); virtual interface foo_if vif; endmodule", 'has_vif');
    my $codes = diag_codes(validate($ast));
    ok((grep { $_ eq 'unsupported_interface_port' } @$codes), 'virtual interface reference flagged');
}

# --- diagnostics never crash validate(), even when several trigger at once ---
{
    my $ast = parse_source(
        "module m #(parameter W=8, parameter W=16) (input clk, input a, input a, input [3:0][7:0] d); generate endgenerate",
        'combo'
    );
    my $diags = eval { validate($ast) };
    ok(!$@, 'validate() does not die even with multiple simultaneous issues');
    ok(scalar(@$diags) >= 3, 'multiple diagnostics collected in one pass');
}

done_testing();
