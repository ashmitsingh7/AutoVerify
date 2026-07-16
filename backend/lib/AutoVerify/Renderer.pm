package AutoVerify::Renderer;
##############################################################################
# AutoVerify::Renderer - interface (abstract base).
#
# A Renderer turns a generation context (module name, ports, params, clk/rst,
# etc.) into the 9 generated file bodies. AutoVerify::Generator depends only
# on this interface, never on a concrete implementation - so the current
# heredoc-based renderer (Renderer::Heredoc) can later be swapped for a
# Template::Toolkit or Jinja-backed one without touching Generator.pm.
#
# Contract: render_all(%ctx) -> { filename => content, ... }
# %ctx keys: module_name, param_order, param_default, ports, has_params,
#            num_txns, clk_port, rst_port, rst_active_low, stim_ports,
#            resp_ports, inout_ports.
##############################################################################
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub render_all {
    my ($self) = @_;
    die ref($self) . " must implement render_all(%ctx)\n";
}

1;
