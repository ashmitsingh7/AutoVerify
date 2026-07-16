#!/usr/bin/env perl
##############################################################################
# autoverify_bridge.pl - JSON-in/JSON-out bridge into AutoVerify::Core.
#
# This exists because the Core is Perl and the service/API layer is Python.
# It contains zero parsing/generation logic of its own - it only calls
# AutoVerify::Validation::validate and AutoVerify::Generator::generate and
# marshals their inputs/outputs to JSON, so the FastAPI layer never has to
# (and per the brief, must not) reimplement any Core behavior.
#
# Usage:
#   perl autoverify_bridge.pl validate  <verilog_file>
#   perl autoverify_bridge.pl generate  <verilog_file> <outdir> [opts_json]
#
# opts_json (optional 3rd arg to generate) is a JSON object with any of:
#   clk, rst, rst_active_low, num_txns
#
# Always prints exactly one JSON object to stdout and exits 0, even on
# failure - the JSON's own "ok" field carries success/failure, so the Python
# side never has to parse stderr or guess at exit-code semantics.
##############################################################################
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON::PP qw(encode_json decode_json);

use AutoVerify::Parser     qw(parse_file);
use AutoVerify::Validation qw(validate);
use AutoVerify::Generator  qw(generate);

my ($cmd, @rest) = @ARGV;

sub emit {
    my (%result) = @_;
    print encode_json(\%result), "\n";
    exit 0;
}

sub emit_error {
    my ($err) = @_;
    if (ref($err) && $err->isa('AutoVerify::Error')) {
        emit(
            ok         => JSON::PP::false,
            error_type => ref($err),
            message    => $err->message,
            file       => $err->file,
            line       => $err->line,
            column     => $err->column,
            suggestion => $err->suggestion,
        );
    }
    emit(ok => JSON::PP::false, error_type => 'UnknownError', message => "$err");
}

# strip ports' internal-only fields before returning to JSON consumers
sub public_ports {
    my ($ports) = @_;
    return [ map {
        { name => $_->{name}, dir => $_->{dir}, type => $_->{type}, width => $_->{width}, signed => $_->{signed} }
    } @$ports ];
}

if (!$cmd) {
    emit(ok => JSON::PP::false, error_type => 'UsageError', message => 'no command given (expected validate|generate)');
}

if ($cmd eq 'validate') {
    my ($verilog_file) = @rest;
    my $ast = eval { parse_file($verilog_file) };
    if ($@) { emit_error($@); }
    my $diagnostics = validate($ast);
    emit(
        ok            => JSON::PP::true,
        module_name   => $ast->{module_name},
        param_order   => $ast->{param_order},
        param_default => $ast->{param_default},
        ports         => public_ports($ast->{ports}),
        diagnostics   => $diagnostics,
    );
}
elsif ($cmd eq 'generate') {
    my ($verilog_file, $outdir, $opts_json) = @rest;
    my $opts = {};
    if (defined $opts_json && length $opts_json) {
        $opts = eval { decode_json($opts_json) };
        if ($@) { emit(ok => JSON::PP::false, error_type => 'UsageError', message => "invalid opts JSON: $@"); }
    }
    $opts->{outdir} = $outdir;

    my $result = eval { generate($verilog_file, $opts) };
    if ($@) { emit_error($@); }

    emit(
        ok          => JSON::PP::true,
        outdir      => $result->{outdir},
        module_name => $result->{module_name},
        files       => $result->{files},
        num_files   => $result->{num_files},
        diagnostics => $result->{diagnostics},
        ports       => public_ports($result->{ast}{ports}),
        clk_port    => $result->{classified}{clk_port},
        rst_port    => $result->{classified}{rst_port},
    );
}
else {
    emit(ok => JSON::PP::false, error_type => 'UsageError', message => "unknown command '$cmd' (expected validate|generate)");
}
