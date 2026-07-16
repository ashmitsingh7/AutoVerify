#!/usr/bin/env perl
##############################################################################
# benchmark.pl - measures AutoVerify::Generator throughput.
#
# Generates N synthetic modules in memory (8 ports each: clk, rst_n, 3 stim,
# 3 resp - representative of the two shipped examples) and runs the full
# parse -> validate -> classify -> render -> write pipeline on each,
# reporting wall-clock time and peak RSS. Real numbers from this machine,
# not extrapolated.
##############################################################################
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(time);
use File::Temp qw(tempdir);

use AutoVerify::Generator qw(generate);

sub synthetic_module {
    my ($i) = @_;
    return <<SV;
module bench_mod_$i #(parameter WIDTH = 8) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic en,
    output logic [WIDTH-1:0] sum,
    output logic valid,
    output logic done
);
endmodule
SV
}

sub run_n {
    my ($n) = @_;
    my $tmpdir = tempdir(CLEANUP => 1);
    my @srcfiles;
    for my $i (1 .. $n) {
        my $path = "$tmpdir/bench_mod_$i.v";
        open(my $fh, '>', $path) or die $!;
        print $fh synthetic_module($i);
        close($fh);
        push @srcfiles, $path;
    }

    my $t0 = time();
    for my $i (0 .. $#srcfiles) {
        generate($srcfiles[$i], { outdir => "$tmpdir/gen_$i", num_txns => 10 });
    }
    my $elapsed = time() - $t0;

    my $rss_kb = 0;
    if (open(my $status, '<', "/proc/$$/status")) {
        while (my $line = <$status>) {
            if ($line =~ /^VmRSS:\s*(\d+)\s*kB/) { $rss_kb = $1; last; }
        }
        close($status);
    }

    return { n => $n, elapsed => $elapsed, per_module_ms => ($elapsed / $n) * 1000, rss_kb => $rss_kb };
}

print "AutoVerify::Generator benchmark (real measurements, this machine)\n";
printf "%-8s %-14s %-16s %-10s\n", "N", "total (s)", "per-module (ms)", "RSS (kB)";
for my $n (100, 500, 1000) {
    my $r = run_n($n);
    printf "%-8d %-14.3f %-16.3f %-10d\n", $r->{n}, $r->{elapsed}, $r->{per_module_ms}, $r->{rss_kb};
}
