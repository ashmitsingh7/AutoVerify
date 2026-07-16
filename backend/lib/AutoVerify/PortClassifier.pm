package AutoVerify::PortClassifier;
##############################################################################
# AutoVerify::PortClassifier
#
# Given the parsed port list plus optional CLI overrides, determines:
#   - clk_port          (name or undef)
#   - rst_port          (name or undef)
#   - rst_active_low    (1/0, only meaningful if rst_port defined)
#   - stim_ports        (inputs, minus clk/rst)
#   - resp_ports        (outputs)
#   - inout_ports
#
# Extracted verbatim from gen_tb.pl's auto-detect + split block.
##############################################################################
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(classify);

sub classify {
    my (%args) = @_;
    my $ports          = $args{ports} || [];
    my $clk_port        = $args{clk};
    my $rst_port        = $args{rst};
    my $rst_active_low  = defined($args{rst_active_low}) ? $args{rst_active_low} : undef;

    for my $p (@$ports) {
        next unless $p->{dir} eq 'input';
        if (!$clk_port && $p->{name} =~ /^(clk|clock)$/i) { $clk_port = $p->{name}; }
    }
    if (!$clk_port) {
        for my $p (@$ports) {
            next unless $p->{dir} eq 'input';
            if ($p->{name} =~ /(_clk|_clock)$/i) { $clk_port = $p->{name}; last; }
        }
    }

    for my $p (@$ports) {
        next unless $p->{dir} eq 'input';
        if (!$rst_port && $p->{name} =~ /^(rst|reset|rstn|rst_n|resetn|reset_n)$/i) {
            $rst_port = $p->{name};
        }
    }
    if (!$rst_port) {
        for my $p (@$ports) {
            next unless $p->{dir} eq 'input';
            if ($p->{name} =~ /(_rst|_reset|_rst_n|_rstn|_reset_n)$/i) { $rst_port = $p->{name}; last; }
        }
    }
    if (defined $rst_port && !defined $rst_active_low) {
        $rst_active_low = ($rst_port =~ /(_n$|n$)/i && $rst_port =~ /rst|reset/i) ? 1 : 0;
    }

    my (@stim_ports, @resp_ports, @inout_ports);
    for my $p (@$ports) {
        next if $clk_port && $p->{name} eq $clk_port;
        next if $rst_port && $p->{name} eq $rst_port;
        if    ($p->{dir} eq 'input')  { push @stim_ports, $p; }
        elsif ($p->{dir} eq 'output') { push @resp_ports, $p; }
        else                          { push @inout_ports, $p; }
    }

    return {
        clk_port         => $clk_port,
        rst_port         => $rst_port,
        rst_active_low   => $rst_active_low,
        stim_ports       => \@stim_ports,
        resp_ports       => \@resp_ports,
        inout_ports      => \@inout_ports,
    };
}

1;
