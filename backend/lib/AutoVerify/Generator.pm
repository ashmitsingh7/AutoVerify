package AutoVerify::Generator;
##############################################################################
# AutoVerify::Generator
#
# The single reusable entry point: generate(verilog_file, \%opts) parses,
# validates, classifies, renders, and writes all output files - returning a
# summary hash (including any non-fatal validation diagnostics) instead of
# just printing, so a CLI, web backend, or test can consume the result
# programmatically.
#
# Depends only on the AutoVerify::Renderer interface (currently backed by
# ::Renderer::Heredoc) - never calls CodeGen directly, so a future renderer
# swap doesn't touch this file.
#
# %opts keys (all optional): outdir, clk, rst, rst_active_low, num_txns
##############################################################################
use strict;
use warnings;
use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin/../lib";

use AutoVerify::Config          qw(resolve);
use AutoVerify::Parser          qw(parse_file);
use AutoVerify::PortClassifier  qw(classify);
use AutoVerify::Validation      qw(validate);
use AutoVerify::Renderer::Heredoc;
use AutoVerify::GeneratorError;
use AutoVerify::ValidationError;
use AutoVerify::Logger qw(info debug);

our @EXPORT_OK = qw(generate);

sub generate {
    my ($verilog_file, $opts) = @_;
    my $cfg = resolve($opts);

    debug("parsing $verilog_file");
    my $ast = parse_file($verilog_file);

    my $diagnostics = validate($ast);
    my @fatal = grep { $_->{severity} eq 'error' } @$diagnostics;
    if (@fatal) {
        AutoVerify::ValidationError->throw(
            message    => join('; ', map { "[$_->{code}] $_->{message}" } @fatal),
            file       => $verilog_file,
            suggestion => 'fix the semantic issue(s) above and re-run',
        );
    }
    for my $d (grep { $_->{severity} eq 'warning' } @$diagnostics) {
        AutoVerify::Logger::warning("[$d->{code}] $d->{message}");
    }

    my $classified = classify(
        ports          => $ast->{ports},
        clk            => $cfg->{clk},
        rst            => $cfg->{rst},
        rst_active_low => $cfg->{rst_active_low},
    );

    my $module_name = $ast->{module_name};
    my $has_params  = @{ $ast->{param_order} } ? 1 : 0;
    my $outdir      = $cfg->{outdir} // "gen_${module_name}";

    system("mkdir", "-p", $outdir) == 0 or AutoVerify::GeneratorError->throw(
        message => "cannot create output directory",
        file    => $outdir,
    );

    my %ctx = (
        module_name    => $module_name,
        param_order    => $ast->{param_order},
        param_default  => $ast->{param_default},
        ports          => $ast->{ports},
        has_params     => $has_params,
        num_txns       => $cfg->{num_txns},
        %$classified,   # clk_port, rst_port, rst_active_low, stim_ports, resp_ports, inout_ports
    );

    debug("rendering $module_name via AutoVerify::Renderer::Heredoc");
    my $renderer = AutoVerify::Renderer::Heredoc->new;
    my $files    = $renderer->render_all(%ctx);

    for my $fname (sort keys %$files) {
        open(my $out, '>', "$outdir/$fname") or AutoVerify::GeneratorError->throw(
            message => "cannot write output file: $!",
            file    => "$outdir/$fname",
        );
        print $out $files->{$fname};
        close($out);
    }
    info("generated " . scalar(keys %$files) . " files for $module_name in $outdir/");

    return {
        outdir       => $outdir,
        module_name  => $module_name,
        ast          => $ast,
        classified   => $classified,
        files        => [ sort keys %$files ],
        num_files    => scalar(keys %$files),
        diagnostics  => $diagnostics,
    };
}

1;
