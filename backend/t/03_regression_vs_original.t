#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use File::Compare qw(compare);

use AutoVerify::Generator qw(generate);

my $baseline_root = "$FindBin::Bin/../../baseline";
my $tmp_root       = "$FindBin::Bin/../../regress_out";
system("rm", "-rf", $tmp_root);
system("mkdir", "-p", $tmp_root);

my %cases = (
    counter    => "$FindBin::Bin/../examples/counter.v",
    fifo_sync  => "$FindBin::Bin/../examples/fifo_sync.v",
);

for my $mod (sort keys %cases) {
    my $outdir = "$tmp_root/$mod";
    my $result = generate($cases{$mod}, { outdir => $outdir, num_txns => 100 });
    ok($result->{num_files} > 0, "$mod: generate() produced files");

    my $baseline_dir = "$baseline_root/$mod";
    ok(-d $baseline_dir, "$mod: baseline directory exists for comparison") or next;

    opendir(my $dh, $baseline_dir) or die $!;
    my @baseline_files = grep { -f "$baseline_dir/$_" } readdir($dh);
    closedir($dh);

    for my $fname (sort @baseline_files) {
        my $new_path      = "$outdir/$fname";
        my $baseline_path = "$baseline_dir/$fname";
        ok(-f $new_path, "$mod/$fname: exists in new output");
        next unless -f $new_path;
        my $diff = compare($new_path, $baseline_path);
        is($diff, 0, "$mod/$fname: byte-identical to original script's output");
    }
}

done_testing();
