#!/usr/bin/env perl
##############################################################################
# gen_tb.pl - HDL Testbench Generator (CLI)
#
# Thin wrapper: parses ARGV, calls AutoVerify::Generator::generate(), prints
# the same human-readable report the original monolithic script printed.
# All actual parsing/codegen logic lives in lib/AutoVerify/*.
##############################################################################
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use AutoVerify::Generator qw(generate);
use AutoVerify::Logger qw(set_level);

my %opt = (
    outdir          => undef,
    clk             => undef,
    rst             => undef,
    rst_active_low  => undef,
    num_txns        => 100,
);

my $verilog_file;
for my $arg (@ARGV) {
    if    ($arg =~ /^--outdir=(.+)$/)      { $opt{outdir} = $1; }
    elsif ($arg =~ /^--clk=(.+)$/)         { $opt{clk} = $1; }
    elsif ($arg =~ /^--rst=(.+)$/)         { $opt{rst} = $1; }
    elsif ($arg eq '--rst-active-low')     { $opt{rst_active_low} = 1; }
    elsif ($arg eq '--rst-active-high')    { $opt{rst_active_low} = 0; }
    elsif ($arg =~ /^--num-txns=(\d+)$/)   { $opt{num_txns} = $1; }
    elsif ($arg eq '--verbose')            { set_level('DEBUG'); }
    elsif ($arg eq '--help' || $arg eq '-h') { print_usage(); exit 0; }
    elsif ($arg =~ /^--/)                  { die "Unknown option: $arg\n"; }
    else                                    { $verilog_file = $arg; }
}

sub print_usage {
    print <<'USAGE';
Usage: perl gen_tb.pl <verilog_file> [options]

Options:
  --outdir=DIR       output directory (default: ./gen_<module>)
  --clk=NAME         force clock port name
  --rst=NAME         force reset port name
  --rst-active-low   treat reset as active-low
  --rst-active-high  treat reset as active-high
  --num-txns=N       number of random transactions (default 100)
  --verbose          enable DEBUG/INFO/WARNING logging to stderr
  --help             show this text
USAGE
}

if (!$verilog_file) {
    print_usage();
    die "\nError: no Verilog file given.\n";
}

my $result = generate($verilog_file, \%opt);

my $ast        = $result->{ast};
my $classified = $result->{classified};
my $has_params  = @{ $ast->{param_order} } ? 1 : 0;

print "==============================================================\n";
print " HDL Testbench Generator\n";
print "==============================================================\n";
print "Module            : $ast->{module_name}\n";
print "Parameters        : " . (@{$ast->{param_order}}
        ? join(", ", map { "$_=$ast->{param_default}{$_}" } @{$ast->{param_order}})
        : "(none)") . "\n";
print "Clock port        : " . (($classified->{clk_port} // "NOT FOUND - pass --clk=<name>")) . "\n";
print "Reset port        : " . (($classified->{rst_port} // "NOT FOUND (no reset will be generated)")) .
      ($classified->{rst_port} ? " (active-" . ($classified->{rst_active_low} ? "low" : "high") . ")" : "") . "\n";
print "Inputs (stimulus) : " . scalar(@{$classified->{stim_ports}}) . "\n";
print "Outputs (response): " . scalar(@{$classified->{resp_ports}}) . "\n";
print "Inout ports       : " . scalar(@{$classified->{inout_ports}}) . " " .
      (@{$classified->{inout_ports}} ? "(treated as plain signals, not driven)" : "") . "\n";
print "==============================================================\n";

print "Generated " . (7 + ($has_params ? 1 : 0)) . " files + filelist in: $result->{outdir}/\n";
print "Next: edit $ast->{module_name}_scoreboard.sv's check_result() with a real reference model.\n";
